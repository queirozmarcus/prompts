# Playbook: Network Troubleshooting

## Systematic Approach

Always work from lower layers up. Don't assume the issue is at the application layer when it might be DNS or routing.

```
L3 (IP routing)  →  L4 (TCP/UDP ports)  →  L7 (application protocol)
    DNS          →    connectivity       →    health checks
```

---

## Step 1: DNS Resolution

```bash
# Basic DNS lookup
dig api.example.com
nslookup api.example.com

# Specify nameserver explicitly (rule out resolver issue)
dig @8.8.8.8 api.example.com
dig @169.254.169.253 api.example.com  # AWS internal resolver (from EC2)

# Check CNAME chain
dig +trace api.example.com

# Verify Route53 record is correct
aws route53 list-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --query "ResourceRecordSets[?Name=='api.example.com.']"

# Route53 health check status
aws route53 get-health-check-status --health-check-id ${HEALTH_CHECK_ID}

# Check DNS propagation (multi-region)
for NS in 8.8.8.8 1.1.1.1 208.67.222.222; do
  echo "=== $NS ==="
  dig @${NS} api.example.com +short
done
```

**Common DNS issues:**
- TTL too high (300-3600s): old records take time to propagate after change
- CNAME vs A record: ALB requires ALIAS record in Route53 (not CNAME for apex domain)
- Private hosted zone: only resolvable from within the VPC
- Split-horizon DNS: different responses inside/outside VPC

---

## Step 2: Layer 3/4 Connectivity

```bash
# Can we reach the host at all? (ICMP)
ping -c 4 10.0.1.100

# Is the port open? (TCP)
nc -zv 10.0.1.100 8080       # timeout after 3 seconds by default
nc -zvw 3 10.0.1.100 443     # explicit timeout

# Full TCP connect test with timing
time curl -o /dev/null -s -w "%{http_code}" http://10.0.1.100:8080/health

# Trace the network path (find where packets drop)
traceroute -T -p 443 api.example.com    # TCP traceroute (better through NAT)
mtr --tcp --port 443 api.example.com    # Continuous traceroute

# From within a Kubernetes pod
kubectl exec -it pod/my-pod -n production -- sh
# Then inside the pod:
# nslookup other-service.other-namespace.svc.cluster.local
# wget -qO- http://other-service/health
# nc -zv other-service 80
```

---

## Step 3: AWS-Specific Connectivity Checks

### Security Groups
```bash
# List security group rules for an instance/ENI
aws ec2 describe-security-groups \
  --group-ids sg-0123456789abcdef \
  --query 'SecurityGroups[0].{
    Inbound:IpPermissions[*].{Port:FromPort,Protocol:IpProtocol,Sources:IpRanges[*].CidrIp},
    Outbound:IpPermissionsEgress[*].{Port:FromPort,Protocol:IpProtocol,Destinations:IpRanges[*].CidrIp}
  }'

# Find security group of a specific EC2 instance
aws ec2 describe-instances \
  --instance-ids i-1234567890 \
  --query 'Reservations[0].Instances[0].SecurityGroups'
```

### VPC Reachability Analyzer (AWS tool — costs per analysis)
```bash
# Create a path analysis between two resources
aws ec2 create-network-insights-path \
  --source ${SOURCE_ID} \
  --destination ${DEST_ID} \
  --protocol tcp \
  --destination-port 5432

# Run the analysis
aws ec2 start-network-insights-analysis \
  --network-insights-path-id ${PATH_ID}

# Get results (may take 1-2 minutes)
aws ec2 describe-network-insights-analyses \
  --network-insights-analysis-ids ${ANALYSIS_ID} \
  --query 'NetworkInsightsAnalyses[0].{Status:Status,NetworkPathFound:NetworkPathFound,ExplanationCodes:Explanations[*].ExplanationCode}'
```

### VPC Flow Logs Analysis
```bash
# Query VPC Flow Logs in CloudWatch Logs Insights
aws logs start-query \
  --log-group-name /vpc/flow-logs \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string '
    fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action, protocol
    | filter dstAddr like "10.0.1.100"
    | filter action = "REJECT"
    | stats count(*) by srcAddr, dstPort
    | sort count desc
    | limit 20
  '
```

---

## Step 4: Kubernetes Networking

```bash
# Pod-to-pod connectivity
kubectl exec -it pod/source-pod -n production -- \
  wget -qO- http://target-service.target-namespace.svc.cluster.local:80/health

# DNS resolution inside cluster
kubectl exec -it pod/debug-pod -n production -- nslookup kubernetes.default.svc.cluster.local
kubectl exec -it pod/debug-pod -n production -- cat /etc/resolv.conf

# CoreDNS health
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Service endpoints (verify backend pods are registered)
kubectl get endpoints -n production
kubectl describe endpoints my-service -n production

# Check NetworkPolicy (may be blocking traffic)
kubectl get networkpolicy -n production
kubectl describe networkpolicy default-deny -n production

# Run debug pod with networking tools
kubectl run debug --image=nicolaka/netshoot --rm -it -n production -- bash
# Inside: curl, dig, nslookup, tcpdump, ping, nc, traceroute all available
```

### Istio Networking
```bash
# Check Envoy proxy config for a specific pod
istioctl proxy-config cluster my-pod.production

# Check if traffic policy is blocking something
istioctl proxy-config listener my-pod.production | grep 5432  # Look for DB port

# Check mtls status between services
istioctl x check-inject -n production

# Analyze Istio configuration for errors
istioctl analyze -n production

# Check VirtualService/DestinationRule for errors
kubectl get virtualservice,destinationrule -n production
```

---

## Step 5: Load Balancer Debugging

```bash
# ALB target health — most useful first check
aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --query 'TargetHealthDescriptions[*].{
    Target:Target.Id,
    Port:Target.Port,
    State:TargetHealth.State,
    Reason:TargetHealth.Reason,
    Description:TargetHealth.Description
  }' \
  --output table

# Check ALB access logs (if enabled on S3)
aws s3 ls s3://my-alb-logs/AWSLogs/ACCOUNT_ID/elasticloadbalancing/us-east-1/ | tail -5
# Download and grep:
aws s3 cp s3://my-alb-logs/${LOG_FILE} - | gzip -d | grep " 5[0-9][0-9] " | head -20

# Check ALB listener rules
aws elbv2 describe-rules \
  --listener-arn ${LISTENER_ARN} \
  --query 'Rules[*].{Priority:Priority,Conditions:Conditions,Actions:Actions}' \
  --output table
```

---

## Common Issues Reference

| Symptom | Likely Cause | Check |
|---------|-------------|-------|
| DNS NXDOMAIN | Record doesn't exist | `dig api.example.com` + Route53 console |
| Connection timeout | SG blocking port | VPC Reachability Analyzer |
| Connection refused | Service not listening | `nc -zv HOST PORT` + app logs |
| 504 Gateway Timeout | Target not responding in time | ALB target health, pod logs |
| 502 Bad Gateway | Target returning error | Pod readiness probe failing |
| Intermittent failures | Single AZ issue | Check per-AZ target health |
| Slow DNS resolution | CoreDNS overloaded | `kubectl top pods -n kube-system` |
| Pod can't reach RDS | SG misconfiguration | Compare pod SG with RDS SG |
| Service not resolving in K8s | CoreDNS issue | Check CoreDNS pods, logs, ConfigMap |
| Cross-namespace traffic blocked | NetworkPolicy | `kubectl describe networkpolicy` |

---

## Quick Diagnostic Script

```bash
#!/bin/bash
HOST="${1:-api.example.com}"
PORT="${2:-443}"
echo "=== Diagnosing ${HOST}:${PORT} ==="
echo ""
echo "1. DNS:"
dig +short ${HOST}
echo ""
echo "2. TCP connectivity:"
nc -zvw 3 ${HOST} ${PORT} 2>&1
echo ""
echo "3. HTTP response:"
curl -o /dev/null -s -w "HTTP %{http_code} in %{time_total}s\n" https://${HOST}/health
echo ""
echo "4. Traceroute:"
traceroute -T -p ${PORT} -w 2 ${HOST} 2>/dev/null | head -15
```

---
**Used by:** sre-engineer (DevOps pack), aws-cloud-engineer (DevOps pack), kubernetes-engineer (DevOps pack)
**Related playbooks:** incident-response.md, dr-restore.md
