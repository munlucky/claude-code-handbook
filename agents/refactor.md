# Refactor Agent

코드 리팩토링 작업을 수행할 때 이 지침을 따릅니다.

## Principles

### 1. 동작 유지
- 리팩토링은 외부 동작을 변경하지 않음
- 기능 변경과 리팩토링은 분리된 커밋으로

### 2. 점진적 변경
- 한 번에 하나의 리팩토링만
- 각 단계에서 테스트 통과 확인
- 큰 변경은 여러 작은 PR로 분할

### 3. 테스트 필수
- 리팩토링 전 테스트 커버리지 확인
- 테스트 없으면 먼저 테스트 추가

```typescript
// 테스트가 없을 때 최소 스텁 예시 (Jest)
describe('MyService', () => {
  it('should keep behavior', () => {
    // TODO: 현재 동작 검증 코드 추가
    expect(true).toBe(true);
  });
});
```

## Common Refactoring Patterns

### Extract Function

```typescript
// Before
function processOrder(order: Order) {
  // 가격 계산 로직 (10줄)
  let total = 0;
  for (const item of order.items) {
    total += item.price * item.quantity;
  }
  if (order.coupon) {
    total *= (1 - order.coupon.discount);
  }
  // 배송 로직 (10줄)
  // ...
}

// After
function processOrder(order: Order) {
  const total = calculateTotal(order);
  const shipping = calculateShipping(order);
  // ...
}

function calculateTotal(order: Order): number {
  const subtotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity, 0
  );
  return order.coupon 
    ? subtotal * (1 - order.coupon.discount)
    : subtotal;
}
```

### Replace Conditional with Polymorphism

```typescript
// Before
function getSpeed(vehicle: Vehicle) {
  switch (vehicle.type) {
    case 'car': return vehicle.enginePower * 0.5;
    case 'bicycle': return vehicle.gearRatio * 10;
    case 'airplane': return vehicle.thrust * 2;
  }
}

// After
interface Vehicle {
  getSpeed(): number;
}

class Car implements Vehicle {
  getSpeed() { return this.enginePower * 0.5; }
}

class Bicycle implements Vehicle {
  getSpeed() { return this.gearRatio * 10; }
}
```

### Introduce Parameter Object

```typescript
// Before
function createUser(
  name: string,
  email: string,
  age: number,
  city: string,
  country: string
) { }

// After
interface CreateUserInput {
  name: string;
  email: string;
  age: number;
  address: {
    city: string;
    country: string;
  };
}

function createUser(input: CreateUserInput) { }
```

### Replace Magic Numbers

```typescript
// Before
if (user.age >= 18) { }
setTimeout(callback, 86400000);

// After
const LEGAL_AGE = 18;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;

if (user.age >= LEGAL_AGE) { }
setTimeout(callback, ONE_DAY_MS);
```

### Simplify Conditionals

```typescript
// Before
function getPaymentMethod(user: User) {
  if (user.subscription) {
    if (user.subscription.type === 'premium') {
      if (user.subscription.paymentMethod) {
        return user.subscription.paymentMethod;
      }
    }
  }
  return 'default';
}

// After - Guard clauses
function getPaymentMethod(user: User) {
  if (!user.subscription) return 'default';
  if (user.subscription.type !== 'premium') return 'default';
  if (!user.subscription.paymentMethod) return 'default';
  
  return user.subscription.paymentMethod;
}
```

## Output Format

```markdown
## Refactoring Plan

### Goal
[리팩토링 목적]

### Steps
1. [첫 번째 변경]
   - 영향 범위: [파일 목록]
   - 위험도: Low/Medium/High
   
2. [두 번째 변경]
   ...

### Before/After
[주요 변경 코드 비교]

### Testing
- [ ] 기존 테스트 통과
- [ ] 새 테스트 추가 (필요시)

### Rollback Plan
[문제 발생 시 복구 방법]
```

## Checklist Before Refactoring

- [ ] 리팩토링 목적이 명확한가?
- [ ] 테스트 커버리지 충분한가?
- [ ] 영향 범위 파악했는가?
- [ ] 다른 작업과 분리 가능한가?
- [ ] 팀에 공유했는가? (큰 변경의 경우)

## When NOT to Refactor

- 시간 압박이 심할 때
- 테스트가 없고 추가할 시간도 없을 때
- 곧 교체/삭제될 코드
- 이해하지 못한 코드 (먼저 이해하기)
