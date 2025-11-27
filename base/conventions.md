# Conventions

## Naming

### 변수/함수
- camelCase: JavaScript/TypeScript
- snake_case: Python, Rust
- 불리언: `is`, `has`, `should`, `can` 접두사
- 이벤트 핸들러: `handle` + 동사 (예: `handleClick`, `handleSubmit`)

### 파일/디렉토리
- 컴포넌트: PascalCase (`UserProfile.tsx`)
- 유틸리티: camelCase 또는 kebab-case (`formatDate.ts`, `string-utils.ts`)
- 상수 파일: SCREAMING_SNAKE_CASE (`API_ENDPOINTS.ts`)
- 테스트: `*.test.ts`, `*.spec.ts`

### 약어 규칙
- 널리 알려진 약어만 사용 (예: URL, API, ID)
- 약어도 camelCase 규칙 적용 (`userId` not `userID`)

## Formatting

### 들여쓰기
- 2 spaces: JavaScript, TypeScript, JSON, YAML
- 4 spaces: Python

### 최대 줄 길이
- 코드: 100자
- 주석/문서: 80자

### Import 순서
1. 외부 라이브러리
2. 내부 절대 경로
3. 상대 경로
4. 타입 import (TypeScript)

각 그룹 사이 빈 줄

## Documentation

### 주석
- 복잡한 비즈니스 로직에만 주석
- TODO: `// TODO: 설명 (@담당자)`
- FIXME: `// FIXME: 설명`
- 임시 코드: `// HACK: 이유 설명`

### JSDoc/Docstring
- 공개 API에는 필수
- 파라미터와 리턴 타입 명시
- 예제 코드 포함 권장

## Error Handling

### 에러 메시지
- 사용자에게 보여줄 메시지와 로깅용 메시지 분리
- 컨텍스트 정보 포함 (어떤 작업 중, 어떤 값으로 인해)
- 해결 방법 힌트 제공

### 에러 타입
- 예상 가능한 에러: 명시적 처리
- 예상 불가 에러: 상위로 전파, 글로벌 핸들러에서 처리
