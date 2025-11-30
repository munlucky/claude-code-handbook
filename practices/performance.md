# Performance

## Database

### Query 최적화

```sql
-- 인덱스 활용
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- 복합 인덱스 순서 중요 (선택도 높은 것 먼저)
-- WHERE user_id = ? AND status = ? → (user_id, status)

-- EXPLAIN으로 쿼리 분석
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

### N+1 문제 해결

```typescript
// ❌ N+1 문제
const users = await User.findAll();
for (const user of users) {
  const orders = await Order.findAll({ where: { userId: user.id } });
  // N번 쿼리 추가 발생
}

// ✅ Eager loading
const users = await User.findAll({
  include: [{ model: Order }]
});

// ✅ DataLoader (GraphQL)
const orderLoader = new DataLoader(async (userIds) => {
  const orders = await Order.findAll({
    where: { userId: userIds }
  });
  return userIds.map(id => orders.filter(o => o.userId === id));
});
```

### Connection Pooling

```typescript
// PostgreSQL
const pool = new Pool({
  max: 20,              // 최대 연결 수
  min: 5,               // 최소 유지 연결
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  connectionLimit = 10
}
```

## Caching

### 캐싱 전략

```typescript
// Cache-aside (Lazy loading)
async function getUser(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);
  
  const user = await db.users.findUnique({ where: { id } });
  await redis.setex(`user:${id}`, 3600, JSON.stringify(user));
  return user;
}

// Write-through
async function updateUser(id: string, data: Partial<User>) {
  const user = await db.users.update({ where: { id }, data });
  await redis.setex(`user:${id}`, 3600, JSON.stringify(user));
  return user;
}

// Cache invalidation
async function deleteUser(id: string) {
  await db.users.delete({ where: { id } });
  await redis.del(`user:${id}`);
}
```

### HTTP Caching

```typescript
// Cache-Control 헤더
res.setHeader('Cache-Control', 'public, max-age=3600'); // 1시간
res.setHeader('Cache-Control', 'private, no-cache');    // 매번 재검증
res.setHeader('Cache-Control', 'no-store');             // 캐시 금지

// ETag
const etag = crypto.createHash('md5').update(JSON.stringify(data)).digest('hex');
res.setHeader('ETag', etag);

if (req.headers['if-none-match'] === etag) {
  return res.status(304).end();
}
```

## Frontend Performance

### Code Splitting

```typescript
// Next.js dynamic import
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Spinner />,
  ssr: false, // 클라이언트만
});

// React.lazy
const Dashboard = React.lazy(() => import('./Dashboard'));

<Suspense fallback={<Loading />}>
  <Dashboard />
</Suspense>
```

### Image Optimization

```tsx
// Next.js Image
import Image from 'next/image';

<Image
  src="/hero.jpg"
  width={800}
  height={400}
  priority          // LCP 이미지
  placeholder="blur"
  sizes="(max-width: 768px) 100vw, 50vw"
/>

// srcset 활용
<img
  src="image-800.jpg"
  srcSet="image-400.jpg 400w, image-800.jpg 800w, image-1200.jpg 1200w"
  sizes="(max-width: 400px) 400px, 800px"
/>
```

### Bundle Size

```bash
# 분석
npm run build -- --analyze
npx bundle-buddy

# Tree shaking 확인
import { debounce } from 'lodash';     # ❌ 전체 번들
import debounce from 'lodash/debounce'; # ✅ 필요한 것만
```

## API Performance

### Pagination

```typescript
// Offset pagination (단순, 큰 offset에서 느림)
const users = await db.users.findMany({
  skip: page * limit,
  take: limit,
});

// Cursor pagination (일관된 성능)
const users = await db.users.findMany({
  take: limit,
  cursor: lastId ? { id: lastId } : undefined,
  skip: lastId ? 1 : 0,
});
```

### Response Compression

```typescript
import compression from 'compression';

app.use(compression({
  threshold: 1024, // 1KB 이상만 압축
  filter: (req, res) => {
    if (req.headers['x-no-compression']) return false;
    return compression.filter(req, res);
  },
}));
```

### 병렬 처리

```typescript
// ❌ Sequential
const user = await getUser(id);
const orders = await getOrders(id);
const reviews = await getReviews(id);

// ✅ Parallel
const [user, orders, reviews] = await Promise.all([
  getUser(id),
  getOrders(id),
  getReviews(id),
]);
```

## 측정과 성능 예산
- 변경 전후 p50/p95/p99, 오류율을 APM/로그로 측정 (예: Datadog, New Relic)
- 프론트: Lighthouse로 LCP/FID/CLS, 번들 크기 측정
- 서버/API: 응답 시간/쿼리 시간/CPU/메모리/GC 지표 수집
- 성능 예산 예시: LCP < 2.5s, JS 번들 < 250KB(gzip), API p95 < 300ms
- 카나리/점진 배포로 개선 여부 검증 후 전체 반영

## Monitoring

### 핵심 메트릭

```typescript
// Response time
const start = Date.now();
// ... 작업
const duration = Date.now() - start;
metrics.histogram('api_duration', duration, { endpoint: req.path });

// Error rate
metrics.increment('api_errors', { endpoint: req.path, status: res.statusCode });

// Throughput
metrics.increment('api_requests', { endpoint: req.path });
```

### Profiling

```bash
# Node.js CPU profiling
node --prof app.js
node --prof-process isolate-*.log > profile.txt

# Memory
node --inspect app.js
# Chrome DevTools에서 Memory 탭

# 힙 스냅샷
process.memoryUsage();
```

## Checklist

- [ ] 쿼리에 적절한 인덱스
- [ ] N+1 쿼리 제거
- [ ] 자주 접근하는 데이터 캐싱
- [ ] 이미지 최적화 (WebP, lazy loading)
- [ ] 코드 스플리팅
- [ ] Gzip/Brotli 압축
- [ ] 병렬 처리 가능한 작업 Promise.all
- [ ] 페이지네이션 (대량 데이터)
- [ ] Connection pooling
- [ ] 성능 메트릭 모니터링
