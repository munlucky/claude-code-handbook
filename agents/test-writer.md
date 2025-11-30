# Test Writer Agent

테스트 코드 작성을 수행할 때 이 지침을 따릅니다.

## Test Strategy

### 무엇을 테스트하는가

**필수**
- 비즈니스 로직 (계산, 검증, 상태 변환)
- API 엔드포인트 (요청/응답)
- 데이터베이스 연산 (CRUD)
- 엣지 케이스 (null, 빈 배열, 경계값)

**선택**
- UI 컴포넌트 (중요한 상호작용)
- 유틸리티 함수

**불필요**
- 라이브러리/프레임워크 동작
- 단순 getter/setter
- 타입 정의

### 결정론 유지
- 시간: fake timers로 고정(`jest.useFakeTimers(); jest.setSystemTime(...)`)
- 랜덤: seed 주입 또는 고정값 사용
- 외부 API: record/replay(예: MSW/Polly)나 계약 테스트로 네트워크 격리

## Unit Test Template

```typescript
import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { UserService } from './userService';
import { UserRepository } from './userRepository';

// Mock 설정
jest.mock('./userRepository');

describe('UserService', () => {
  let service: UserService;
  let mockRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepository = new UserRepository() as jest.Mocked<UserRepository>;
    service = new UserService(mockRepository);
    jest.clearAllMocks();
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const input = { email: 'test@example.com', name: 'Test' };
      const expected = { id: '123', ...input };
      mockRepository.save.mockResolvedValue(expected);

      // Act
      const result = await service.createUser(input);

      // Assert
      expect(result).toEqual(expected);
      expect(mockRepository.save).toHaveBeenCalledWith(
        expect.objectContaining(input)
      );
    });

    it('should throw error for duplicate email', async () => {
      // Arrange
      const input = { email: 'existing@example.com', name: 'Test' };
      mockRepository.findByEmail.mockResolvedValue({ id: '1', ...input });

      // Act & Assert
      await expect(service.createUser(input))
        .rejects.toThrow('Email already exists');
    });

    it('should hash password before saving', async () => {
      // Arrange
      const input = { email: 'test@example.com', password: 'plain123' };

      // Act
      await service.createUser(input);

      // Assert
      expect(mockRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          password: expect.not.stringMatching('plain123'),
        })
      );
    });
  });
});
```

## Integration Test Template

```typescript
import request from 'supertest';
import { app } from '../app';
import { db } from '../database';

describe('POST /api/users', () => {
  beforeAll(async () => {
    await db.connect();
  });

  afterAll(async () => {
    await db.disconnect();
  });

  beforeEach(async () => {
    await db.clear();
  });

  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', name: 'New User' })
      .expect(201);

    expect(response.body).toMatchObject({
      email: 'new@example.com',
      name: 'New User',
    });
    expect(response.body.id).toBeDefined();

    // DB 확인
    const user = await db.users.findById(response.body.id);
    expect(user).not.toBeNull();
  });

  it('should return 400 for invalid email', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'invalid', name: 'Test' })
      .expect(400);

    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('should return 409 for duplicate email', async () => {
    // 기존 사용자 생성
    await db.users.create({ email: 'existing@example.com', name: 'Existing' });

    const response = await request(app)
      .post('/api/users')
      .send({ email: 'existing@example.com', name: 'New' })
      .expect(409);

    expect(response.body.error.code).toBe('DUPLICATE_EMAIL');
  });
});
```

## React Component Test Template

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  const mockOnSubmit = jest.fn();

  beforeEach(() => {
    mockOnSubmit.mockClear();
  });

  it('should render email and password fields', () => {
    render(<LoginForm onSubmit={mockOnSubmit} />);

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
  });

  it('should submit form with valid data', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={mockOnSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');
    await user.click(screen.getByRole('button', { name: /login/i }));

    expect(mockOnSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });

  it('should show error for invalid email', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={mockOnSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'invalid');
    await user.click(screen.getByRole('button', { name: /login/i }));

    expect(screen.getByText(/valid email/i)).toBeInTheDocument();
    expect(mockOnSubmit).not.toHaveBeenCalled();
  });

  it('should disable button while submitting', async () => {
    mockOnSubmit.mockImplementation(() => new Promise(() => {})); // never resolves
    const user = userEvent.setup();
    render(<LoginForm onSubmit={mockOnSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');
    await user.click(screen.getByRole('button', { name: /login/i }));

    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## Test Checklist

### 단위 테스트
- [ ] Happy path (정상 케이스)
- [ ] 에러 케이스
- [ ] 엣지 케이스 (null, undefined, 빈 값)
- [ ] 경계값 (min, max, 0)
- [ ] 모든 분기 (if/else, switch)

### API 테스트
- [ ] 성공 응답 (200, 201)
- [ ] 클라이언트 에러 (400, 401, 403, 404)
- [ ] 검증 에러
- [ ] 인증/인가

### 컴포넌트 테스트
- [ ] 렌더링
- [ ] 사용자 상호작용
- [ ] 상태 변화
- [ ] 에러 상태
- [ ] 로딩 상태

## Output Format

```markdown
## Test Plan for [기능/모듈명]

### Test Cases

| # | 설명 | 타입 | 우선순위 |
|---|------|------|----------|
| 1 | 정상 생성 | Unit | High |
| 2 | 중복 이메일 에러 | Unit | High |
| 3 | API 통합 테스트 | Integration | Medium |

### Code
[테스트 코드]
```
