# Skill: Frontend

## Scope

React and Next.js frontend development with TypeScript. Covers component patterns, state management, rendering strategies (CSR/SSR/SSG/ISR), bundle optimization, testing with Vitest and React Testing Library, accessibility basics, and production deployment patterns.

## Related Agent: architect, code-reviewer (Dev pack)
## Related Playbook: dependency-update.md

## Core Principles

- **TypeScript strict mode** — no `any`, no silent failures; types document intent
- **Component-driven** — small, focused, composable components; single responsibility
- **Server-first (Next.js)** — Server Components by default, Client Components only when needed
- **Test user behavior, not implementation** — React Testing Library over snapshot tests
- **Performance budget** — track bundle size; LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Accessibility by default** — semantic HTML, ARIA labels, keyboard navigation

## TypeScript Configuration

**tsconfig.json (strict mode):**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": false,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "incremental": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## React Patterns

**Component design:**
```typescript
// Props interface — explicit, documented
interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
  className?: string;
}

// Functional component with explicit return type
export function UserCard({ user, onEdit, className }: UserCardProps): JSX.Element {
  return (
    <article className={cn('rounded-lg border p-4', className)}>
      <h2 className="text-lg font-semibold">{user.name}</h2>
      {onEdit && (
        <button
          onClick={() => onEdit(user.id)}
          aria-label={`Edit ${user.name}`}
        >
          Edit
        </button>
      )}
    </article>
  );
}
```

**Custom hooks for logic encapsulation:**
```typescript
function useUsers(filters: UserFilters) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchUsers() {
      try {
        setLoading(true);
        const data = await api.getUsers(filters);
        if (!cancelled) setUsers(data);
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err : new Error(String(err)));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void fetchUsers();
    return () => { cancelled = true; };
  }, [filters]);

  return { users, loading, error };
}
```

**Context for cross-cutting concerns (auth, theme):**
```typescript
// Only use context for truly global state; prefer prop drilling for local state
const AuthContext = createContext<AuthState | null>(null);

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
```

## Next.js App Router

**Project structure:**
```
src/
├── app/
│   ├── layout.tsx          # Root layout (Server Component)
│   ├── page.tsx            # Home page (Server Component)
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── dashboard/
│   │   ├── layout.tsx      # Dashboard layout
│   │   └── page.tsx
│   └── api/
│       └── users/route.ts  # API route handler
├── components/
│   ├── ui/                 # Generic UI components (Button, Input)
│   └── features/           # Feature-specific components
├── lib/
│   ├── api.ts              # API client
│   ├── auth.ts             # Auth utilities
│   └── utils.ts            # Shared utilities
├── types/
│   └── index.ts            # Shared type definitions
└── hooks/
    └── use-users.ts        # Custom hooks (Client side)
```

**Server vs Client Components:**
```typescript
// Server Component (default) — runs on server, can be async
// app/users/page.tsx
async function UsersPage() {
  // Direct data fetching — no useEffect, no loading state
  const users = await fetchUsers();

  return (
    <main>
      <h1>Users</h1>
      <UserList users={users} />  {/* Can be Server Component */}
      <AddUserButton />           {/* Must be Client if it has onClick */}
    </main>
  );
}

// Client Component — only when needed for interactivity
'use client';

import { useState } from 'react';

function AddUserButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button onClick={() => setOpen(true)}>Add User</button>
      {open && <AddUserModal onClose={() => setOpen(false)} />}
    </>
  );
}
```

**Data fetching patterns:**
```typescript
// Server Component: fetch with cache
async function getUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`, {
    next: { revalidate: 3600 },  // ISR: revalidate every hour
  });
  if (!res.ok) throw new Error('Failed to fetch user');
  return res.json() as Promise<User>;
}

// Route handler: API endpoint
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest): Promise<NextResponse> {
  const { searchParams } = request.nextUrl;
  const page = Number(searchParams.get('page') ?? 1);

  const users = await db.user.findMany({ skip: (page - 1) * 20, take: 20 });
  return NextResponse.json(users);
}
```

## State Management

**Decision matrix:**
| Scope | Solution |
|-------|---------|
| Local UI state | `useState`, `useReducer` |
| Shared component state | Lift state up / `useContext` |
| Server data + caching | TanStack Query (react-query) |
| Complex client state | Zustand (prefer over Redux for simplicity) |
| URL state | `useSearchParams` + `useRouter` |

**TanStack Query for server state:**
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => api.getUsers(filters),
    staleTime: 5 * 60 * 1000,  // Consider fresh for 5 min
  });
}

function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateUserInput) => api.updateUser(data),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}
```

## Testing

**Vitest + React Testing Library:**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      thresholds: { lines: 80, branches: 75 },
    },
  },
});

// src/test/setup.ts
import '@testing-library/jest-dom';
import { vi } from 'vitest';

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn() }),
  useSearchParams: () => new URLSearchParams(),
}));
```

**Test user behavior, not implementation:**
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  it('calls onEdit with user id when edit button is clicked', async () => {
    const user = { id: '1', name: 'Alice', email: 'alice@example.com' };
    const onEdit = vi.fn();
    const userActions = userEvent.setup();

    render(<UserCard user={user} onEdit={onEdit} />);

    await userActions.click(screen.getByRole('button', { name: /edit alice/i }));

    expect(onEdit).toHaveBeenCalledWith('1');
  });
});
```

## Bundle Optimization

**Next.js built-in:**
```typescript
// Dynamic imports for code splitting
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,  // Disable SSR for client-only libraries
});

// Image optimization
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  priority  // Preload above-the-fold images
  placeholder="blur"
/>
```

**Bundle analysis:**
```bash
# Analyze bundle sizes
ANALYZE=true next build

# Track bundle size over time
npx bundlesize --config bundlesize.config.json
```

**Performance rules:**
- Lazy-load everything below the fold
- Use `next/font` for zero layout shift on fonts
- Preload critical resources with `<link rel="preload">`
- Avoid importing entire libraries: `import { debounce } from 'lodash'` not `import _ from 'lodash'`

## Rendering Strategies

| Strategy | When to use | Next.js |
|----------|-------------|---------|
| **SSR** | Dynamic, user-specific, auth-gated pages | `fetch` with `no-store` or `cache: 'no-store'` |
| **SSG** | Static content, blogs, docs | `fetch` with `force-cache` or `revalidate: false` |
| **ISR** | Semi-static: product pages, dashboards | `next: { revalidate: N }` |
| **CSR** | Highly interactive, real-time data | TanStack Query + client components |

## Common Mistakes / Anti-Patterns

- **`useEffect` for data fetching** — use TanStack Query or Server Components instead
- **Large context re-renders** — split context by update frequency; use `memo` + `useCallback` judiciously
- **`any` type** — defeats TypeScript; use `unknown` + type narrowing
- **Missing `key` prop** — always use stable, unique keys (not array index) in lists
- **Prop drilling 3+ levels** — signals need for context, state lift, or component restructure
- **`'use client'` everywhere** — kills Server Component benefits; push client boundary as far down as possible
- **Unhandled loading/error states** — every async operation needs loading and error handling

## Communication Style

When this skill is active:
- Specify Server vs Client Component and explain the rationale
- Include TypeScript generics in hook return types
- Recommend TanStack Query for async data over custom useEffect patterns
- Flag bundle size implications for large third-party library additions
- Note accessibility requirements (roles, aria-labels) for interactive elements

## Expected Output Quality

- Complete TypeScript components with typed props interfaces
- Tests using `@testing-library/react` querying by accessible roles
- Server/Client Component distinction explicit in all Next.js examples
- Data fetching with proper loading, error, and empty state handling

---
**Skill type:** Passive
**Applies with:** api-design, nodejs, ci-cd, docker
**Pairs well with:** architect (Dev pack)
