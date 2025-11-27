# Security

## Authentication

### Password Handling

```typescript
// ❌ Never
const password = "plaintext";
const hash = md5(password);

// ✅ Always use bcrypt/argon2
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

### JWT

```typescript
import jwt from 'jsonwebtoken';

const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

function generateTokens(userId: string) {
  const accessToken = jwt.sign(
    { sub: userId, type: 'access' },
    process.env.JWT_SECRET!,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );
  
  const refreshToken = jwt.sign(
    { sub: userId, type: 'refresh' },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );
  
  return { accessToken, refreshToken };
}

// Refresh token rotation
async function refreshAccessToken(refreshToken: string) {
  const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET!);
  
  // Invalidate old refresh token (store in DB/Redis)
  await invalidateRefreshToken(refreshToken);
  
  // Issue new tokens
  return generateTokens(payload.sub);
}
```

## Input Validation

### SQL Injection 방지

```typescript
// ❌ Never - SQL Injection 취약
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// ✅ Parameterized queries
const user = await db.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ✅ ORM 사용
const user = await prisma.user.findUnique({
  where: { id: userId }
});
```

### XSS 방지

```typescript
// React: 자동 이스케이프
<div>{userInput}</div>  // Safe

// ❌ 위험: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// 필요시 sanitize
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### Request Validation

```typescript
// Zod 사용
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
});

// 미들웨어
function validate<T>(schema: z.ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ errors: result.error.issues });
    }
    req.body = result.data;
    next();
  };
}
```

## HTTPS & Headers

```typescript
// Helmet.js
import helmet from 'helmet';

app.use(helmet());

// 수동 설정
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  next();
});
```

## CORS

```typescript
import cors from 'cors';

// 개발용 (위험)
app.use(cors());

// 프로덕션
app.use(cors({
  origin: ['https://myapp.com', 'https://admin.myapp.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400, // preflight 캐시 24시간
}));
```

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// 전역 rate limit
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // IP당 100 요청
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false,
});

// 로그인 rate limit (더 엄격)
const loginLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1시간
  max: 5, // 5회 시도
  skipSuccessfulRequests: true,
});

app.use('/api', limiter);
app.use('/api/auth/login', loginLimiter);
```

## Secrets Management

```typescript
// ❌ Never
const API_KEY = "sk-1234567890";

// ✅ Environment variables
const API_KEY = process.env.API_KEY;

// ✅ Secrets manager (AWS)
import { SecretsManager } from '@aws-sdk/client-secrets-manager';

const secrets = await secretsManager.getSecretValue({
  SecretId: 'my-app/prod'
});

// .env 파일 (개발용)
// .env는 반드시 .gitignore에 추가
```

## Logging Security

```typescript
// ❌ 민감 정보 로깅 금지
logger.info('User login', { password: req.body.password });
logger.info(`Processing card ${cardNumber}`);

// ✅ 마스킹 처리
function maskSensitive(obj: any): any {
  const sensitiveKeys = ['password', 'token', 'secret', 'card'];
  // ... 마스킹 로직
}

logger.info('User login', { email: user.email, ip: req.ip });
```

## Checklist

### 인증/인가
- [ ] 비밀번호 bcrypt/argon2로 해싱
- [ ] JWT 만료 시간 설정
- [ ] Refresh token rotation
- [ ] 권한 검사 (authorization)

### 입력 검증
- [ ] 모든 입력값 검증/sanitize
- [ ] SQL injection 방지 (parameterized query)
- [ ] XSS 방지 (output encoding)

### 통신
- [ ] HTTPS 강제
- [ ] 보안 헤더 설정
- [ ] CORS 적절히 설정

### 인프라
- [ ] Rate limiting
- [ ] Secrets 환경변수/secrets manager
- [ ] 민감 정보 로깅 금지
- [ ] 에러 메시지에 내부 정보 노출 금지
