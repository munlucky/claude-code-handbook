# Full-stack Next.js Project Instructions

이 문서는 다음 모듈의 조합입니다:
- base/CLAUDE.md
- languages/typescript.md
- frameworks/nextjs.md
- practices/testing.md

---

## Base Instructions

- 한국어로 응답
- 변경사항은 이유와 함께 설명
- 불확실한 부분은 명시적으로 질문
- 코드 변경 시 변경된 부분만 보여주기

## Code Style

- TypeScript strict 모드
- `any` 사용 금지
- 함수는 단일 책임
- 에러 핸들링 명시적으로

## Next.js Conventions

- App Router 사용
- Server Components 기본, 필요시만 'use client'
- Server Actions로 폼 처리
- 이미지는 next/image 사용

## File Structure

```
app/
├── (auth)/
│   ├── login/page.tsx
│   └── signup/page.tsx
├── dashboard/
│   ├── layout.tsx
│   └── page.tsx
├── api/
│   └── [route]/route.ts
├── layout.tsx
├── page.tsx
└── globals.css
components/
├── ui/           # 재사용 UI 컴포넌트
└── features/     # 기능별 컴포넌트
lib/
├── db.ts
├── auth.ts
└── utils.ts
```

## Data Fetching

```tsx
// Server Component에서 직접 fetch
async function Page() {
  const data = await fetch('...', {
    next: { revalidate: 3600 }
  });
  return <Component data={data} />;
}
```

## API Routes

```tsx
// app/api/users/route.ts
export async function GET(request: NextRequest) {
  const data = await db.users.findMany();
  return NextResponse.json(data);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  // validation
  const user = await db.users.create({ data: body });
  return NextResponse.json(user, { status: 201 });
}
```

## Testing

- Unit: 비즈니스 로직
- Integration: API routes
- E2E: 핵심 사용자 흐름 (Playwright 권장, 이미 Cypress가 있으면 유지 후 점진 전환)
- E2E 선택 가이드: 멀티브라우저/비주얼 회귀 필요 → Playwright, 기존 Cypress 자산 재사용 필요 → Cypress 유지, 신규면 Playwright 기본

```typescript
// __tests__/api/users.test.ts
describe('POST /api/users', () => {
  it('should create user', async () => {
    const response = await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify({ email: 'test@example.com' }),
    });
    expect(response.status).toBe(201);
  });
});
```

## Git Commits

- `feat:` 새 기능
- `fix:` 버그 수정
- `refactor:` 리팩토링
- `test:` 테스트
- `docs:` 문서
