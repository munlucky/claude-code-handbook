# Testing

## 테스트 피라미드

```
       /\
      /  \      E2E (적게)
     /----\     
    /      \    Integration (중간)
   /--------\   
  /          \  Unit (많이)
 /______________\
```

## Unit Test

### 좋은 테스트의 특징

- Fast: 빠르게 실행
- Isolated: 다른 테스트에 영향 없음
- Repeatable: 항상 같은 결과
- Self-validating: 성공/실패 명확
- Timely: 코드 작성과 함께

### 네이밍 컨벤션

```typescript
// describe: 테스트 대상
// it/test: 행동 설명
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', () => {});
    it('should throw error when email is invalid', () => {});
    it('should hash password before saving', () => {});
  });
});
```

### AAA 패턴

```typescript
it('should calculate total with discount', () => {
  // Arrange - 준비
  const cart = new Cart();
  cart.addItem({ price: 100, quantity: 2 });
  const discount = 0.1;

  // Act - 실행
  const total = cart.calculateTotal(discount);

  // Assert - 검증
  expect(total).toBe(180);
});
```

### Mocking

```typescript
// Jest mock
jest.mock('./emailService');

// 특정 메서드만 mock
const sendEmail = jest.spyOn(emailService, 'send').mockResolvedValue(true);

// 호출 검증
expect(sendEmail).toHaveBeenCalledWith({
  to: 'user@example.com',
  subject: 'Welcome',
});
expect(sendEmail).toHaveBeenCalledTimes(1);

// Mock 초기화
beforeEach(() => {
  jest.clearAllMocks();
});
```

### 비동기 테스트

```typescript
// async/await
it('should fetch user data', async () => {
  const user = await userService.findById('123');
  expect(user.name).toBe('John');
});

// Promise rejection
it('should throw on not found', async () => {
  await expect(userService.findById('invalid'))
    .rejects.toThrow('User not found');
});

// Timeout
it('should complete within time', async () => {
  const result = await slowOperation();
  expect(result).toBeDefined();
}, 10000); // 10초 타임아웃
```

## Integration Test

```typescript
// API 테스트 (supertest)
import request from 'supertest';
import app from '../app';

describe('POST /api/users', () => {
  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'John', email: 'john@example.com' })
      .expect(201);

    expect(response.body).toMatchObject({
      name: 'John',
      email: 'john@example.com',
    });
    expect(response.body.id).toBeDefined();
  });

  it('should return 400 for invalid email', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'John', email: 'invalid' })
      .expect(400);

    expect(response.body.error).toContain('email');
  });
});
```

### 데이터베이스 테스트

```typescript
// 테스트 DB 설정
beforeAll(async () => {
  await db.connect(process.env.TEST_DATABASE_URL);
});

afterAll(async () => {
  await db.disconnect();
});

// 각 테스트 전 데이터 초기화
beforeEach(async () => {
  await db.truncateAll();
  await db.seed(); // 테스트 데이터 삽입
});

// 트랜잭션으로 롤백 (빠름)
beforeEach(async () => {
  await db.beginTransaction();
});

afterEach(async () => {
  await db.rollback();
});
```

## E2E Test

```typescript
// Playwright 예시
import { test, expect } from '@playwright/test';

test.describe('User Authentication', () => {
  test('should login successfully', async ({ page }) => {
    await page.goto('/login');
    
    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Welcome');
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/login');
    
    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'wrong');
    await page.click('button[type="submit"]');
    
    await expect(page.locator('.error')).toBeVisible();
  });
});
```

## Test Coverage

```json
// jest.config.js
{
  "collectCoverageFrom": [
    "src/**/*.{ts,tsx}",
    "!src/**/*.d.ts",
    "!src/**/index.ts"
  ],
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80,
      "statements": 80
    }
  }
}
```

## 테스트 작성 가이드

### 결정론적 테스트 만들기
- 시간: `jest.useFakeTimers(); jest.setSystemTime(new Date('2024-01-01'))`
- 랜덤: `seedrandom('test');` 혹은 고정 seed를 주입
- 네트워크/외부 API: record-replay(VCR/Mock Service Worker)로 격리
- DB: 각 테스트를 트랜잭션으로 감싸고 `BEGIN` → 테스트 → `ROLLBACK`

### 무엇을 테스트할까

- 비즈니스 로직 (계산, 검증, 변환)
- 엣지 케이스 (빈 값, 경계값, 에러)
- 외부 의존성과의 상호작용

### 테스트하지 말 것

- 라이브러리/프레임워크 코드
- 단순 getter/setter
- 구현 세부사항 (내부 메서드 호출 순서 등)

### 테스트 더블

| 종류 | 용도 |
|------|------|
| Stub | 미리 정해진 값 반환 |
| Mock | 호출 여부/방식 검증 |
| Spy | 실제 구현 + 호출 기록 |
| Fake | 단순화된 실제 구현 (In-memory DB) |
