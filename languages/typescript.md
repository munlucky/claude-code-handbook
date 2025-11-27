# TypeScript

## Type Safety

- `any` 사용 금지, 불가피할 경우 `unknown` 사용 후 타입 가드
- `as` 타입 단언 최소화, 타입 가드 함수 선호
- strict 모드 필수 (`"strict": true`)
- `null`과 `undefined` 명시적 처리

```typescript
// ❌ Bad
const data = response as UserData;

// ✅ Good
function isUserData(data: unknown): data is UserData {
  return typeof data === 'object' && data !== null && 'id' in data;
}
if (isUserData(response)) {
  // response is UserData here
}
```

## Type Definitions

- 인터페이스: 객체 형태 정의, 확장 가능
- 타입: 유니온, 인터섹션, 유틸리티 타입
- 제네릭: 재사용 가능한 타입에 활용

```typescript
// 인터페이스 - 확장 가능한 객체
interface User {
  id: string;
  name: string;
}

// 타입 - 유니온, 유틸리티
type Status = 'pending' | 'success' | 'error';
type PartialUser = Partial<User>;

// 제네릭 - 재사용
type ApiResponse<T> = {
  data: T;
  error: string | null;
};
```

## Utility Types 활용

```typescript
// Partial - 모든 프로퍼티 optional
type UpdateUser = Partial<User>;

// Pick/Omit - 선택적 프로퍼티
type UserPreview = Pick<User, 'id' | 'name'>;
type UserWithoutPassword = Omit<User, 'password'>;

// Record - 키-값 매핑
type UserRoles = Record<string, Role>;

// ReturnType - 함수 반환 타입 추출
type QueryResult = ReturnType<typeof fetchUser>;
```

## Enum vs Union

```typescript
// ❌ Enum - 런타임 코드 생성, 트리쉐이킹 어려움
enum Status {
  Pending,
  Success,
}

// ✅ Union - 타입만 존재
type Status = 'pending' | 'success';

// ✅ const object - 런타임 값 필요시
const STATUS = {
  PENDING: 'pending',
  SUCCESS: 'success',
} as const;
type Status = typeof STATUS[keyof typeof STATUS];
```

## Async/Await

```typescript
// 에러 처리 패턴
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  
  if (!response.ok) {
    throw new ApiError(`Failed to fetch user: ${response.status}`);
  }
  
  return response.json();
}

// Result 패턴 (에러를 반환값으로)
type Result<T, E = Error> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

async function safetyFetch<T>(url: string): Promise<Result<T>> {
  try {
    const res = await fetch(url);
    const data = await res.json();
    return { ok: true, value: data };
  } catch (error) {
    return { ok: false, error: error as Error };
  }
}
```

## Null Handling

```typescript
// Optional chaining
const city = user?.address?.city;

// Nullish coalescing
const name = user.name ?? 'Anonymous';

// Non-null assertion (확실할 때만)
const element = document.getElementById('app')!;
```
