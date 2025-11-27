# Migration Agent

마이그레이션 작업을 수행할 때 이 지침을 따릅니다.

## Migration Types

### Database Migration

```typescript
// 예: Prisma migration
// 1. 스키마 변경
// prisma/schema.prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  role      Role     @default(USER)  // 새 필드
  createdAt DateTime @default(now())
}

enum Role {
  USER
  ADMIN
}

// 2. Migration 생성
// npx prisma migrate dev --name add_user_role

// 3. 데이터 마이그레이션 (필요시)
// prisma/migrations/xxx_add_user_role/migration.sql
-- 기존 사용자에게 기본 role 할당
UPDATE "User" SET "role" = 'USER' WHERE "role" IS NULL;
```

### Breaking Change Migration

```typescript
// API 버전 관리
// 1. 새 버전 추가 (기존 유지)
app.use('/api/v1/users', usersV1Router);  // 기존
app.use('/api/v2/users', usersV2Router);  // 신규

// 2. 호환 기간 안내
// Header: X-API-Deprecation: v1 will be removed on 2024-06-01

// 3. 점진적 마이그레이션
// - 문서 업데이트
// - 클라이언트 마이그레이션 지원
// - 모니터링 (v1 사용량)
// - v1 제거
```

### Framework/Library Migration

```bash
# 의존성 업그레이드 체크리스트
# 1. 변경사항 확인
npm outdated
npm view <package> changelog

# 2. 테스트 환경에서 먼저
npm install <package>@latest --save-dev

# 3. Breaking changes 대응
# - 공식 마이그레이션 가이드 참조
# - 코드 변경
# - 테스트

# 4. 점진적 롤아웃
```

## Migration Plan Template

```markdown
# Migration: [마이그레이션 제목]

## Overview
- **현재 상태**: [현재 버전/상태]
- **목표 상태**: [목표 버전/상태]
- **일정**: [예상 소요 시간]
- **영향 범위**: [영향받는 서비스/기능]

## Pre-migration Checklist
- [ ] 현재 상태 백업
- [ ] 롤백 계획 수립
- [ ] 테스트 환경에서 검증
- [ ] 관련 팀 공지
- [ ] 모니터링 대시보드 준비

## Migration Steps

### Phase 1: 준비 (Day 1)
1. [ ] 백업 생성
2. [ ] 테스트 환경 세팅
3. [ ] 마이그레이션 스크립트 검증

### Phase 2: 실행 (Day 2)
1. [ ] 다운타임 공지 (필요시)
2. [ ] 마이그레이션 실행
3. [ ] 검증 테스트
4. [ ] 모니터링

### Phase 3: 정리 (Day 3-7)
1. [ ] 구버전 코드 제거
2. [ ] 문서 업데이트
3. [ ] 회고

## Rollback Plan
1. 문제 감지 시 즉시 롤백 결정
2. 롤백 스크립트 실행
3. 데이터 복구 (필요시)
4. 원인 분석

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| 데이터 손실 | High | 백업, 트랜잭션 사용 |
| 다운타임 | Medium | Blue-green 배포 |
| 성능 저하 | Low | 모니터링, 롤백 준비 |

## Verification

### Automated
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass

### Manual
- [ ] 주요 기능 수동 테스트
- [ ] 성능 벤치마크
- [ ] 데이터 정합성 확인
```

## Common Migration Scenarios

### Next.js Pages → App Router

```typescript
// 1. 점진적 마이그레이션 (공존 가능)
// pages/ 와 app/ 동시 사용

// 2. 페이지 단위 마이그레이션
// Before: pages/users/[id].tsx
export async function getServerSideProps({ params }) {
  const user = await getUser(params.id);
  return { props: { user } };
}

// After: app/users/[id]/page.tsx
export default async function UserPage({ params }) {
  const user = await getUser(params.id);
  return <UserProfile user={user} />;
}

// 3. API Routes 마이그레이션
// Before: pages/api/users.ts
// After: app/api/users/route.ts
```

### REST → GraphQL

```typescript
// 점진적 마이그레이션
// 1. GraphQL 서버 추가 (REST 유지)
// 2. 새 기능은 GraphQL로
// 3. 기존 기능 점진적 마이그레이션
// 4. REST 제거

// BFF (Backend For Frontend) 패턴
// GraphQL이 REST를 호출하는 방식으로 점진적 전환
const resolvers = {
  Query: {
    user: async (_, { id }) => {
      // 기존 REST API 호출
      const response = await fetch(`/api/users/${id}`);
      return response.json();
    }
  }
};
```

### Monolith → Microservices

```
Phase 1: Strangler Fig Pattern
├── 신규 기능 → 새 서비스
├── 기존 기능 유지
└── API Gateway로 라우팅

Phase 2: 도메인 분리
├── 독립 가능한 도메인 식별
├── 데이터 분리
└── 서비스 추출

Phase 3: 완료
├── 레거시 제거
└── 서비스 간 통신 최적화
```

## Output Format

```markdown
## Migration Analysis

### Current State
[현재 상태 분석]

### Target State
[목표 상태]

### Migration Strategy
[전략: Big Bang / Gradual / Parallel Run]

### Detailed Plan
[단계별 계획]

### Risks
[위험 요소 및 대응]

### Timeline
[일정]
```
