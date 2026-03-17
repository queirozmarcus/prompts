# Skill: Networking

## Scope

Design e operação de redes em AWS e Kubernetes. Cobre VPC design, subnet strategy, security groups, NAT Gateway, opções de conectividade VPC (Peering, Transit Gateway, PrivateLink), DNS com Route53, load balancers (ALB vs NLB), networking no Kubernetes (CNI, Services, Ingress, NetworkPolicy) e troubleshooting com comandos reais.

## Core Principles

- **Design for failure** — multi-AZ by default; no single points of failure in network path
- **Least privilege at network layer** — security groups as default deny; open only what's needed
- **Plan CIDR space carefully** — expanding later is painful; plan for 5x growth
- **Avoid public IPs** — use private subnets + load balancers; public IPs = attack surface
- **Cost-aware routing** — cross-AZ and NAT Gateway traffic costs money; minimize unnecessary hops
- **Consistent naming** — subnet names, security group names, and tags must convey purpose clearly

## VPC Design & Architecture

**Standard 3-Tier Layout:**
```
VPC: 10.0.0.0/16
  ├── Public Subnets (10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20)
  │     ALB, NAT Gateway, Bastion (if needed)
  ├── Private Subnets (10.0.48.0/20, 10.0.64.0/20, 10.0.80.0/20)
  │     EC2, EKS nodes, Lambda, ECS tasks
  └── Database Subnets (10.0.96.0/24, 10.0.97.0/24, 10.0.98.0/24)
        RDS, ElastiCache, OpenSearch
```

**Terraform VPC (baseline):**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "production"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets   = ["10.0.0.0/20",  "10.0.16.0/20", "10.0.32.0/20"]
  private_subnets  = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
  database_subnets = ["10.0.96.0/24", "10.0.97.0/24", "10.0.98.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false  # HA: one per AZ (cost: ~$97/month each)
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Required tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

## Subnets & CIDR Planning

**CIDR Sizing Guide:**
| Subnet Type    | Recommended Size | Hosts Available | Rationale                         |
|----------------|-----------------|-----------------|-----------------------------------|
| Public         | /20             | 4,091           | ALBs, NAT GWs — few resources     |
| Private        | /20             | 4,091           | EKS nodes, EC2 — need room to grow |
| Database       | /24             | 251             | DB instances — small, stable count |
| VPC total      | /16             | 65,531          | Room for future subnets           |

**Avoid:**
- /28 subnets for EKS (AWS VPC CNI uses IPs from node's subnet — runs out fast)
- Overlapping CIDRs with on-premises or other VPCs you may peer
- /8 or /16 for subnets (wasteful; complicates routing tables)

**EKS IP Planning:**
- Each node reserves ENI slots: m5.large = 3 ENIs x 10 IPs = 29 pods max per node
- With VPC CNI, each pod gets a real VPC IP — size subnets accordingly
- Alternative: use `--prefix-delegation` mode (m5.large -> 290 IPs per node)

## Security Groups & NACLs

**Security Group Best Practices:**
```hcl
# ALB Security Group
resource "aws_security_group" "alb" {
  name   = "alb-public"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]  # reference, not CIDR
  }
}

# App Security Group
resource "aws_security_group" "app" {
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # only from ALB
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Security Groups vs NACLs:**
| Feature          | Security Groups         | NACLs                          |
|-----------------|-------------------------|-------------------------------|
| Level           | Instance/ENI            | Subnet                         |
| State           | Stateful                | Stateless (need both in+out)   |
| Rules           | Allow only              | Allow + Deny                   |
| Evaluation      | All rules evaluated     | Rules evaluated in order (number) |
| Use for         | Default, fine-grained   | Subnet-level block lists       |

**NACL Rule Numbering:** Use increments of 10 (100, 110, 120) to allow inserting rules later.

## NAT Gateway & Internet Access

**Single vs Per-AZ NAT Gateway:**
- Single NAT: $32/month + data transfer — OK for dev, single point of failure
- Per-AZ: $32/month x 3 AZs = $96/month + data transfer — required for production HA
- Cross-AZ traffic cost: $0.01/GB each direction — use per-AZ NAT to avoid

**Reduce NAT Gateway costs:**
```bash
# Add VPC Gateway Endpoints (free) for S3 and DynamoDB
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --vpc-endpoint-type Gateway \
  --route-table-ids rtb-xxx

# Check how much traffic goes through NAT GW
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToDestination \
  --dimensions Name=NatGatewayId,Value=nat-xxx \
  --period 86400 --statistics Sum \
  --start-time 2026-01-01T00:00:00Z \
  --end-time 2026-02-01T00:00:00Z
```

## VPC Connectivity Options

| Option          | Use case                             | Cost                        | Limits                        |
|----------------|--------------------------------------|-----------------------------|-------------------------------|
| VPC Peering     | 2 VPCs, simple, same/cross-account   | Data transfer only          | Non-transitive; complex at scale |
| Transit Gateway | Hub-and-spoke, many VPCs             | $0.05/hr + $0.02/GB         | Scales to thousands of VPCs   |
| PrivateLink     | Expose service to other VPCs/accounts | $0.01/hr + $0.01/GB        | One-directional; service model |
| VPN (Site-to-Site) | On-premises to AWS               | $0.05/hr per connection     | 1.25 Gbps per tunnel          |
| Direct Connect  | Dedicated on-premises connection     | Port + data transfer        | Lower latency, higher cost    |

**Decision:**
- 2-3 VPCs in same org: VPC Peering
- 5+ VPCs or hub-and-spoke required: Transit Gateway
- Exposing a service (not full network access): PrivateLink

```bash
# Check existing VPC endpoints
aws ec2 describe-vpc-endpoints \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName,State]' \
  --output table

# Transit Gateway route table
aws ec2 describe-transit-gateway-route-tables \
  --query 'TransitGatewayRouteTables[*].[TransitGatewayRouteTableId,State]'
```

## DNS & Route53

**Key Record Types:**
- `A` — hostname to IPv4 address
- `CNAME` — hostname to hostname (cannot be apex/root domain)
- `ALIAS` — like CNAME but works at apex; no extra DNS lookup; free for AWS resources
- `NS` — nameserver records (set at registrar)
- `SOA` — start of authority
- `SRV` — service discovery (used by Kubernetes)

**Private Hosted Zones:**
```hcl
resource "aws_route53_zone" "private" {
  name = "internal.mycompany.com"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.internal.mycompany.com"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.main.address]
}
```

**Health Checks & Failover:**
- Use Route53 health checks + failover routing for active-passive
- Minimum health check interval: 10 seconds (fast, extra cost) vs 30 seconds
- Use low TTLs (60s) during migrations; increase after cutover

**Troubleshoot DNS:**
```bash
# Check DNS resolution from inside a pod
kubectl exec -n production deploy/api -- nslookup db.internal.mycompany.com
kubectl exec -n production deploy/api -- dig db.internal.mycompany.com

# Check which nameserver is being used
dig +trace myservice.production.svc.cluster.local

# Verify Route53 private hosted zone resolution
dig @169.254.169.253 db.internal.mycompany.com  # VPC DNS resolver
```

## Load Balancers (ALB / NLB)

| Feature          | ALB (Layer 7)                   | NLB (Layer 4)                      |
|-----------------|----------------------------------|------------------------------------|
| Protocol        | HTTP, HTTPS, gRPC                | TCP, UDP, TLS                      |
| Routing         | Path, host, header, query string | IP + Port only                     |
| Latency         | ~400ms                           | ~100us (ultra-low)                 |
| TLS termination | Yes (ACM)                        | Yes (ACM) or passthrough           |
| Static IP       | No (DNS only)                    | Yes (Elastic IP per AZ)            |
| Cost            | $0.008/LCU-hr                    | $0.006/NLCU-hr                     |
| Use for         | HTTP APIs, web apps              | gRPC, WebSockets, TCP, gaming      |

**ALB Ingress in EKS (AWS Load Balancer Controller):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 8080
```

## Kubernetes Networking

**Service Types:**
- `ClusterIP` — internal only; default
- `NodePort` — exposed on node IP:port (avoid in production; use Ingress instead)
- `LoadBalancer` — provisions ALB/NLB (expensive if every service has one)
- `ExternalName` — CNAME to external service

**NetworkPolicy (default deny + explicit allow):**
```yaml
# Default deny all ingress in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes: [Ingress]

---
# Allow api -> database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - port: 5432
```

**CoreDNS Troubleshooting:**
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS from pod
kubectl run dnstest --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup kubernetes.default

# CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```

## Network Troubleshooting Toolkit

**Connectivity from within a pod:**
```bash
# Open debug shell in running pod
kubectl exec -n production -it deploy/api -- /bin/sh

# Test TCP connectivity
curl -v --connect-timeout 5 http://db-service:5432
nc -zv db-service 5432

# DNS resolution
nslookup db-service.production.svc.cluster.local
dig +short db-service.production.svc.cluster.local

# Trace route
traceroute -n 10.0.96.5

# Check if service exists and has endpoints
kubectl get svc db-service -n production
kubectl get endpoints db-service -n production
```

**From EC2 / node-level:**
```bash
# Test security group rules (from EC2 in same SG)
curl -v --connect-timeout 5 http://internal-alb-xxx.us-east-1.elb.amazonaws.com

# Check VPC Flow Logs for rejected traffic (CloudWatch Logs Insights)
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| filter dstAddr = "10.0.96.5"
| sort @timestamp desc
| limit 20

# Check effective security groups on an instance
aws ec2 describe-instance-attribute \
  --instance-id i-xxx \
  --attribute groupSet

# Check route table for subnet
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-xxx"
```

**DNS debugging:**
```bash
# Test from AWS VPC DNS resolver
dig @169.254.169.253 myservice.internal.example.com

# Check Route53 resolver inbound/outbound endpoints
aws route53resolver list-resolver-endpoints \
  --query 'ResolverEndpoints[*].[Name,Direction,Status]'

# Verify private hosted zone is associated with VPC
aws route53 list-hosted-zones-by-vpc \
  --vpc-id vpc-xxx \
  --vpc-region us-east-1
```

## Common Connectivity Issues

| Symptom | Likely Cause | Check |
|---------|-------------|-------|
| Pod can't reach external internet | NAT Gateway misconfigured or missing | Route table for private subnet; NAT GW state |
| Pod can't reach RDS | Security group blocking 5432 | DB security group inbound rules; correct source SG |
| Service not resolving in cluster | CoreDNS issue or wrong service name | `kubectl get svc`; CoreDNS logs; full DNS name |
| ALB returning 502 | Target group unhealthy | `aws elbv2 describe-target-health`; pod logs |
| Cross-VPC DNS not resolving | Private hosted zone not associated | Route53 zone VPC associations |
| Intermittent timeouts | CPU throttling, connection pool exhaustion | Check throttling metrics; DB connections |
| High latency between pods | Cross-AZ traffic | Check AZ of pods and nodes; topology hints |

## Common Mistakes / Anti-Patterns

- All EKS nodes in one AZ (no redundancy; rescheduling fails if AZ goes down)
- Overlapping CIDR blocks when setting up VPC peering (non-recoverable)
- Using `NodePort` services directly in production instead of Ingress + ALB
- No NetworkPolicy (flat network; any pod can reach any other pod)
- Hardcoding IP addresses instead of service names / DNS
- Single NAT Gateway for production (AZ failure = all private subnet outbound fails)
- Security groups with overly broad source `0.0.0.0/0` for internal services
- Not tagging subnets for EKS (ALB provisioning fails silently)
- Forgetting to add routes after VPC Peering (peering alone doesn't enable routing)

## Communication Style

When this skill is active:
- Provide specific commands for the likely problem, not generic networking theory
- Distinguish between Layer 3 (routing), Layer 4 (TCP/security groups), Layer 7 (ALB/app)
- Always ask: is this a DNS issue, a security group issue, or a routing issue?
- Include cost implications of networking decisions (NAT, cross-AZ, PrivateLink)

## Expected Output Quality

- Copy-paste kubectl/aws CLI commands for diagnosis
- Terraform HCL for network resource configuration
- Specific checklist for each connectivity problem type
- Clear distinction between AWS networking and Kubernetes networking layers

---
**Skill type:** Passive
**Applies with:** aws, kubernetes, security, observability
**Pairs well with:** aws-platform-agent, incident-agent
