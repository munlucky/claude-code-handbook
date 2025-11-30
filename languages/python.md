# Python

## Style Guide

- PEP 8 준수
- 들여쓰기: 4 spaces
- 최대 줄 길이: 88자 (Black 기본값)
- Formatter: Black, Linter: Ruff 권장

## Type Hints

```python
from typing import Optional, List, Dict, Union, TypeVar, Generic
from collections.abc import Callable, Sequence

# 기본 타입 힌트
def greet(name: str) -> str:
    return f"Hello, {name}"

# Optional (None 가능)
def find_user(user_id: int) -> Optional[User]:
    ...

# 컬렉션
def process_items(items: list[str]) -> dict[str, int]:
    ...

# Callable
Handler = Callable[[Request], Response]

# TypeVar (제네릭)
T = TypeVar('T')
def first(items: Sequence[T]) -> T:
    return items[0]
```

## Environment & Packaging
- 가상환경: `python -m venv .venv && source .venv/bin/activate`
- pyproject 기반
  - uv: `uv pip install -r requirements.txt`
  - pip-tools: `pip-compile pyproject.toml && pip-sync`

## Async/Concurrency 주의
- 이벤트 루프에서 블로킹 I/O 금지 → `asyncio.to_thread`/전용 스레드 풀 사용
- `asyncio.wait_for`로 타임아웃 감싸기, `gather(..., return_exceptions=True)`로 부분 실패 처리
- Linux이면 `uvloop.install()`로 성능 개선 가능(테스트 후 적용)

## Dataclasses & Pydantic

```python
# 간단한 데이터 구조
from dataclasses import dataclass, field

@dataclass
class User:
    id: int
    name: str
    email: str
    tags: list[str] = field(default_factory=list)

# 검증이 필요한 경우 Pydantic
from pydantic import BaseModel, EmailStr, validator

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    
    @validator('name')
    def name_not_empty(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v
```

## Error Handling

```python
# 커스텀 예외
class AppError(Exception):
    def __init__(self, message: str, code: str):
        self.message = message
        self.code = code
        super().__init__(message)

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(f"{resource} not found: {id}", "NOT_FOUND")

# 예외 처리
def get_user(user_id: int) -> User:
    try:
        user = db.query(User).get(user_id)
        if not user:
            raise NotFoundError("User", str(user_id))
        return user
    except DatabaseError as e:
        logger.error(f"Database error: {e}")
        raise AppError("Database unavailable", "DB_ERROR") from e
```

## Context Managers

```python
from contextlib import contextmanager

# 클래스 기반
class DatabaseConnection:
    def __enter__(self):
        self.conn = create_connection()
        return self.conn
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.conn.close()
        return False  # 예외 전파

# 데코레이터 기반
@contextmanager
def timer(name: str):
    start = time.time()
    try:
        yield
    finally:
        elapsed = time.time() - start
        print(f"{name}: {elapsed:.2f}s")

# 사용
with timer("processing"):
    do_something()
```

## Async/Await

```python
import asyncio
from typing import AsyncIterator

async def fetch_user(user_id: int) -> User:
    async with aiohttp.ClientSession() as session:
        async with session.get(f"/api/users/{user_id}") as response:
            data = await response.json()
            return User(**data)

# 병렬 실행
async def fetch_all_users(user_ids: list[int]) -> list[User]:
    tasks = [fetch_user(uid) for uid in user_ids]
    return await asyncio.gather(*tasks)

# Async generator
async def stream_data() -> AsyncIterator[bytes]:
    async with aiohttp.ClientSession() as session:
        async with session.get("/stream") as response:
            async for chunk in response.content.iter_chunked(1024):
                yield chunk
```

## Project Structure

```
my_project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py
│       ├── models/
│       ├── services/
│       └── utils/
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_*.py
├── pyproject.toml
└── README.md
```
