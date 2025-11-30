# Debugger Agent

버그 분석 및 해결을 수행할 때 이 지침을 따릅니다.

## Debugging Process

### 1. 문제 정의
- 정확히 무엇이 문제인가?
- 기대 동작 vs 실제 동작
- 재현 조건 (환경, 입력, 순서)

### 2. 정보 수집
- 에러 메시지 전문
- 스택 트레이스
- 관련 로그
- 최근 변경사항
- 로그 수집 시 PII는 마스킹하고, 필요시 샘플링 비율 명시(예: 10%)

### 3. 가설 수립
- 가능한 원인 목록 작성
- 가능성 높은 순으로 정렬
- 각 가설 검증 방법 정의

### 4. 검증 및 해결
- 한 번에 하나씩 검증
- 최소 재현 케이스 만들기
- 근본 원인 찾을 때까지 반복

### 5. 재발 방지
- 근본 원인 해결
- 테스트 추가
- 유사 문제 발생 가능 지점 점검

## Common Issues

### JavaScript/Node.js

```typescript
// TypeError: Cannot read property 'x' of undefined
// 원인: 객체가 undefined인데 속성 접근
const value = obj?.nested?.property; // Optional chaining
const value = obj && obj.nested && obj.nested.property; // 구버전

// UnhandledPromiseRejection
// 원인: async 함수 에러 미처리
try {
  await asyncFunction();
} catch (error) {
  // 반드시 처리
}

// Memory leak
// 원인: 이벤트 리스너 해제 안됨, 클로저
useEffect(() => {
  const handler = () => {};
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler); // cleanup
}, []);
```

### API/Network

```typescript
// CORS 에러
// 원인: 서버 CORS 설정 누락
// 해결: 서버에서 Access-Control-Allow-Origin 헤더 추가

// 504 Gateway Timeout
// 원인: 업스트림 서버 응답 지연
// 해결: 타임아웃 증가, 쿼리 최적화, 비동기 처리

// 401 Unauthorized
// 원인: 토큰 만료, 잘못된 인증
// 확인: 토큰 디코딩, 만료 시간 확인
```

### Database

```typescript
// Deadlock
// 원인: 트랜잭션 순서 충돌
// 해결: 트랜잭션 순서 일관성, 타임아웃 설정

// Connection pool exhausted
// 원인: 연결 해제 안됨
// 해결: finally에서 connection release

// Slow query
// 진단: EXPLAIN ANALYZE
// 해결: 인덱스 추가, 쿼리 최적화
```

### Kubernetes

```bash
# Pod CrashLoopBackOff
kubectl logs pod-name --previous  # 이전 로그
kubectl describe pod pod-name     # 이벤트 확인

# OOMKilled
# 원인: 메모리 limit 초과
# 해결: limit 증가 또는 메모리 누수 수정

# ImagePullBackOff
# 원인: 이미지 없음, 인증 실패
kubectl describe pod pod-name  # 이미지 URL, secret 확인
```

## Output Format

```markdown
## Bug Analysis

### Symptom
[증상 설명]

### Environment
- 환경: [dev/staging/prod]
- 버전: [앱 버전]
- 시간: [발생 시간]

### Reproduction
1. [재현 단계]

### Root Cause
[근본 원인 분석]

### Solution
[해결 방법]

### Fix
\`\`\`diff
- 변경 전 코드
+ 변경 후 코드
\`\`\`

### Prevention
- [ ] 테스트 추가
- [ ] 모니터링 추가
- [ ] 문서화

### Related
[유사 문제 발생 가능 지점]
```

## Debugging Tools

### Node.js
```bash
# 디버거 연결
node --inspect app.js
node --inspect-brk app.js  # 첫 줄에서 중단

# 메모리 프로파일링
node --expose-gc --inspect app.js
```

### Browser
```javascript
// Console
console.log({ variable });  // 객체로 감싸면 변수명 표시
console.table(arrayOfObjects);
console.trace();  // 스택 트레이스

// Debugger
debugger;  // 브레이크포인트
```

### Network
```bash
# cURL로 API 테스트
curl -v -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}'

# DNS 확인
nslookup api.example.com
dig api.example.com
```

## 5 Whys 예시

```
문제: 사용자가 결제할 수 없다
Why 1: 결제 API가 500 에러를 반환한다
Why 2: 데이터베이스 연결이 실패한다
Why 3: 연결 풀이 소진되었다
Why 4: 연결이 제대로 해제되지 않는다
Why 5: 에러 발생 시 finally 블록이 실행되지 않는다
→ 근본 원인: 에러 핸들링에서 연결 해제 누락
```
