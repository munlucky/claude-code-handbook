# Docs Writer Agent

기술 문서 작성을 수행할 때 이 지침을 따릅니다.

## Document Types

### README.md

```markdown
# Project Name

간결한 프로젝트 설명 (1-2문장)

## Features

- 핵심 기능 1
- 핵심 기능 2

## Quick Start

\`\`\`bash
npm install
npm run dev
\`\`\`

## Documentation

- [Installation](docs/installation.md)
- [Configuration](docs/configuration.md)
- [API Reference](docs/api.md)

## Contributing

[기여 가이드 링크]

## License

MIT
```

### API Documentation

```markdown
# API Reference

## Authentication

모든 API 요청에 Bearer token 필요:
\`\`\`
Authorization: Bearer <token>
\`\`\`

## Endpoints

### Create User

\`POST /api/users\`

사용자를 생성합니다.

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | 이메일 주소 |
| name | string | Yes | 사용자 이름 |

**Example Request**

\`\`\`bash
curl -X POST https://api.example.com/users \
  -H "Authorization: Bearer token" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "name": "John"}'
\`\`\`

**Response**

\`\`\`json
{
  "id": "123",
  "email": "user@example.com",
  "name": "John",
  "createdAt": "2024-01-01T00:00:00Z"
}
\`\`\`

**Error Responses**

| Status | Code | Description |
|--------|------|-------------|
| 400 | INVALID_INPUT | 잘못된 입력 |
| 409 | DUPLICATE_EMAIL | 이메일 중복 |
```

### Architecture Decision Record (ADR)

```markdown
# ADR-001: 데이터베이스 선택

## Status
Accepted (2024-01-15)

## Context
사용자 데이터와 트랜잭션을 저장할 데이터베이스가 필요합니다.
요구사항:
- ACID 트랜잭션 지원
- 복잡한 쿼리 지원
- 팀 경험 고려

## Decision
PostgreSQL 15를 사용합니다.

## Consequences

### Positive
- 팀의 기존 경험 활용
- 강력한 ACID 지원
- JSON 타입 지원으로 유연성 확보

### Negative
- 샤딩이 복잡함 (추후 확장 시 고려)
- 운영 부담

### Risks
- 트래픽 급증 시 스케일 아웃 어려움
  → 대응: 읽기 복제본 구성, 캐시 레이어 추가

## Alternatives Considered

### MongoDB
- 장점: 유연한 스키마
- 단점: 복잡한 조인 어려움, 트랜잭션 제한

### MySQL
- 장점: 안정성
- 단점: JSON 지원 미흡
```

## Writing Guidelines

### 명확성
- 짧은 문장
- 능동태 사용
- 전문 용어는 정의와 함께
- 예제 코드 필수

### 언어/톤
- ko/en 혼용 시 한 언어로 통일 (요청 없으면 한국어, 존댓말)
- 기술 문서 톤: 간결하고 명령형, 과도한 수사는 피함

### 구조
- 스캔 가능하게 (헤딩, 리스트)
- 중요한 것 먼저
- 단계별 가이드는 번호 매기기

### 코드 예제
```typescript
// ✅ Good: 실행 가능한 완전한 예제
import { createClient } from '@my/sdk';

const client = createClient({ apiKey: 'your-api-key' });
const user = await client.users.create({
  email: 'user@example.com',
  name: 'John',
});
console.log(user.id);

// ❌ Bad: 불완전한 예제
client.users.create(...)
```

## Documentation Checklist

### README
- [ ] 프로젝트 설명
- [ ] 설치 방법
- [ ] 기본 사용법
- [ ] 라이선스

### API Docs
- [ ] 인증 방법
- [ ] 각 엔드포인트 설명
- [ ] 요청/응답 예시
- [ ] 에러 코드

### Code Comments
- [ ] 공개 API에 JSDoc/Docstring
- [ ] 복잡한 로직에 설명
- [ ] TODO/FIXME 명시

### Architecture
- [ ] 주요 결정에 ADR
- [ ] 시스템 다이어그램
- [ ] 데이터 플로우

## Output Format

```markdown
## Document: [문서 제목]

### Purpose
[이 문서의 목적]

### Audience
[대상 독자: 개발자/운영/일반 사용자]

### Content
[문서 내용]

### Related
- [관련 문서 링크]
```
