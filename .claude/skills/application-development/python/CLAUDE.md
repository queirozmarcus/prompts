# Skill: Python

## Scope

Python development following PEP 8 and modern best practices. Covers formatting (Black/Ruff), type hints, dependency management (Poetry/pip-tools), testing (pytest), async patterns, FastAPI, and production-grade code quality. Applicable to any Python project or script.

## Related Agent: architect, code-reviewer (Dev pack)
## Related Playbook: dependency-update.md

## Core Principles

- **PEP 8 + Black** — formatting is non-negotiable; run Black and Ruff before every commit
- **Type hints everywhere** — annotate all function signatures; enables static analysis and IDE support
- **Explicit over implicit** — Python's philosophy; avoid magic, be clear about intent
- **Fail loudly** — raise specific exceptions with context; never `except Exception: pass`
- **Testable by default** — inject dependencies, avoid global state, write pure functions where possible
- **Virtual environments** — never install project packages globally; always isolate

## Code Style

- **Indentation:** 4 spaces (PEP 8)
- **Line length:** 88 characters (Black default)
- **Quotes:** Double quotes (Black default)
- **Naming:**
  - `snake_case` for variables, functions, modules
  - `PascalCase` for classes
  - `UPPER_SNAKE_CASE` for constants
  - `_private` with leading underscore for internal
- **Imports:** Sorted with `isort` (stdlib → third-party → local), one per line

## Toolchain

**Formatter + Linter:**
```bash
# Black — opinionated formatter (no config needed)
black .

# Ruff — fast linter replacing flake8, isort, and more
ruff check . --fix
ruff format .  # Can replace Black in new projects

# Type checking
mypy src/ --strict

# Combined pre-commit hook
pre-commit run --all-files
```

**pyproject.toml baseline:**
```toml
[tool.black]
line-length = 88
target-version = ["py311"]

[tool.ruff]
line-length = 88
target-version = "py311"
select = ["E", "F", "I", "N", "W", "UP", "B", "S", "A"]
ignore = ["S101"]  # Allow assert in tests

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = false

[tool.isort]
profile = "black"
```

## Dependency Management

**Poetry (preferred for applications):**
```bash
# Initialize project
poetry new myproject
poetry add fastapi uvicorn[standard]
poetry add --group dev pytest pytest-cov black ruff mypy

# Install and run
poetry install
poetry run python main.py
poetry run pytest

# Export for Docker
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

**pip-tools (preferred for libraries/simple projects):**
```bash
# requirements.in (abstract dependencies)
fastapi>=0.100
uvicorn[standard]

# Compile to pinned requirements.txt
pip-compile requirements.in --output-file requirements.txt

# Sync environment
pip-sync requirements.txt requirements-dev.txt
```

**Never:** `pip install package` without a lockfile mechanism.

## Type Hints

```python
from typing import Optional, Union, TypeVar, Generic
from collections.abc import Sequence, Callable, AsyncGenerator

# Function signatures — always annotate
def get_user(user_id: int) -> Optional[User]:
    ...

# Modern union syntax (Python 3.10+)
def process(data: str | bytes | None) -> dict[str, int]:
    ...

# TypedDict for structured dicts
from typing import TypedDict

class UserConfig(TypedDict):
    name: str
    email: str
    age: int | None

# Protocol for duck typing
from typing import Protocol

class Serializable(Protocol):
    def to_dict(self) -> dict[str, object]: ...

# Generics
T = TypeVar("T")

class Repository(Generic[T]):
    def get(self, id: int) -> T | None: ...
    def save(self, entity: T) -> T: ...
```

**Type narrowing:**
```python
from typing import assert_never

def process(value: str | int | None) -> str:
    if value is None:
        return "empty"
    elif isinstance(value, str):
        return value.upper()  # mypy knows it's str here
    elif isinstance(value, int):
        return str(value)
    else:
        assert_never(value)  # Exhaustiveness check
```

## Project Structure

**FastAPI application:**
```
src/
├── main.py              # App factory, startup/shutdown
├── api/
│   ├── __init__.py
│   ├── deps.py          # Dependency injection (DB sessions, auth)
│   ├── v1/
│   │   ├── router.py    # APIRouter aggregation
│   │   ├── users.py     # /users endpoints
│   │   └── items.py     # /items endpoints
├── core/
│   ├── config.py        # Settings via pydantic-settings
│   ├── security.py      # Auth utilities
│   └── logging.py       # Structured logging setup
├── models/
│   ├── domain.py        # Business entities (pure Python classes)
│   └── db.py            # SQLAlchemy models
├── schemas/
│   └── users.py         # Pydantic request/response models
├── services/
│   └── user_service.py  # Business logic (no HTTP knowledge)
├── repositories/
│   └── user_repo.py     # DB access layer
└── tests/
    ├── conftest.py      # Shared fixtures
    ├── test_users.py    # Route tests
    └── unit/            # Unit tests for services
```

## FastAPI Patterns

```python
from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from pydantic_settings import BaseSettings

# Settings via environment variables
class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False

    model_config = {"env_file": ".env"}

settings = Settings()

# Pydantic models for validation
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr

class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    model_config = {"from_attributes": True}  # ORM mode

# Dependency injection
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# Route handler
@router.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    user = await user_service.create(db, body)
    return UserResponse.model_validate(user)
```

## Async Patterns

```python
import asyncio
import httpx
from contextlib import asynccontextmanager

# Async context manager for app lifecycle
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await db.connect()
    yield
    # Shutdown
    await db.disconnect()

app = FastAPI(lifespan=lifespan)

# Concurrent requests with asyncio.gather
async def fetch_multiple(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
    return [r.json() for r in responses if not isinstance(r, Exception)]

# Background tasks
from fastapi import BackgroundTasks

@router.post("/email")
async def send_email(
    background_tasks: BackgroundTasks,
    email: EmailSchema,
) -> dict:
    background_tasks.add_task(send_email_async, email)
    return {"message": "Email queued"}
```

## Testing (pytest)

```python
# conftest.py — shared fixtures
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine) as session:
        yield session

@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    app.dependency_overrides[get_db] = lambda: db_session
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        yield client
    app.dependency_overrides.clear()

# Test file
@pytest.mark.asyncio
async def test_create_user(client: AsyncClient) -> None:
    response = await client.post("/users", json={"name": "Alice", "email": "alice@example.com"})
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Alice"
    assert "id" in data
```

**pytest.ini / pyproject.toml:**
```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"
```

## Error Handling

```python
# Custom exception hierarchy
class AppError(Exception):
    """Base application error."""
    def __init__(self, message: str, code: str | None = None) -> None:
        super().__init__(message)
        self.code = code

class NotFoundError(AppError): ...
class ValidationError(AppError): ...
class ConflictError(AppError): ...

# FastAPI exception handler
from fastapi.requests import Request
from fastapi.responses import JSONResponse

@app.exception_handler(NotFoundError)
async def not_found_handler(request: Request, exc: NotFoundError) -> JSONResponse:
    return JSONResponse(
        status_code=404,
        content={"error": str(exc), "code": exc.code},
    )

# Service layer — raise specific exceptions
async def get_user(db: AsyncSession, user_id: int) -> User:
    user = await db.get(User, user_id)
    if not user:
        raise NotFoundError(f"User {user_id} not found", code="USER_NOT_FOUND")
    return user
```

## Logging (Structured)

```python
import logging
import structlog

# structlog setup (JSON in production)
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),  # In prod
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
)

log = structlog.get_logger(__name__)

# Usage — structured context, not string interpolation
log.info("user_created", user_id=user.id, email=user.email)
log.error("payment_failed", user_id=user_id, error=str(exc), amount=amount)
```

## Security Best Practices

- **Input validation:** Pydantic models with `Field` constraints on all inputs
- **Password hashing:** `passlib[bcrypt]` — never store plaintext
- **JWT:** `python-jose` or `PyJWT` with RS256 (asymmetric) for production
- **SQL injection:** Always use ORM or parameterized queries; never f-strings in SQL
- **Secrets:** `pydantic-settings` from env vars; never hardcode or commit
- **Rate limiting:** `slowapi` for FastAPI route-level rate limiting
- **CORS:** Explicit origins; never `allow_origins=["*"]` in production

## Common Mistakes / Anti-Patterns

- **Mutable default arguments:** `def f(items=[]): ...` — use `None` and initialize inside
- **Bare `except:`** — always catch specific exceptions; `except Exception` at minimum
- **`from module import *`** — pollutes namespace; use explicit imports
- **`assert` for input validation** — assertions are stripped with `-O` flag; use `if/raise`
- **Sync code in async routes** — blocks the event loop; use `run_in_executor` for CPU-bound
- **Missing `await`** — coroutines silently do nothing without await; enable `asyncio` debug mode
- **`global` variables** — anti-pattern; use dependency injection or module-level singletons
- **Schema = DB model** — separate SQLAlchemy models from Pydantic schemas

## Communication Style

When this skill is active:
- Provide complete, runnable Python code with proper type annotations
- Include `pyproject.toml` configuration when relevant
- Highlight breaking changes between Python versions (3.9, 3.10, 3.11, 3.12)
- Recommend async-first for FastAPI/web; sync is fine for scripts and CLI tools
- Flag any pattern that defeats type checking (untyped dicts, `Any`, `cast`)

## Expected Output Quality

- Full function/class definitions with type annotations on all signatures
- `pyproject.toml` sections for Black, Ruff, mypy, pytest
- Tests included for non-trivial logic (pytest, async-compatible)
- Pydantic models for all API request/response schemas

---
**Skill type:** Passive
**Applies with:** api-design, docker, security, observability, ci-cd
**Pairs well with:** architect (Dev pack)
