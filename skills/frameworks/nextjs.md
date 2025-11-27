# Next.js

## App Router (v13+)

### 파일 컨벤션

```
app/
├── layout.tsx          # Root layout
├── page.tsx            # Home page (/)
├── loading.tsx         # Loading UI
├── error.tsx           # Error boundary
├── not-found.tsx       # 404 page
├── globals.css
├── (auth)/             # Route group (URL에 미포함)
│   ├── login/page.tsx
│   └── signup/page.tsx
├── dashboard/
│   ├── layout.tsx      # Nested layout
│   ├── page.tsx
│   └── [id]/           # Dynamic route
│       └── page.tsx
└── api/
    └── users/
        └── route.ts    # API route
```

### Server vs Client Components

```tsx
// Server Component (기본값)
// - 데이터 페칭, DB 접근, 민감 정보 접근
// - async/await 직접 사용 가능
async function UserList() {
  const users = await db.users.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// Client Component
// - 상태, 이벤트 핸들러, 브라우저 API 필요시
'use client';

import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Data Fetching

```tsx
// Server Component에서 직접 fetch
async function Page() {
  // 자동으로 중복 제거, 캐싱
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 } // ISR: 1시간마다 재검증
  });
  
  return <div>{/* ... */}</div>;
}

// 캐시 옵션
fetch(url, { cache: 'force-cache' });  // 기본값, 캐시 사용
fetch(url, { cache: 'no-store' });     // 매 요청마다 새로 fetch
fetch(url, { next: { revalidate: 60 } }); // 60초 후 재검증

// Server Actions
'use server';

async function createUser(formData: FormData) {
  const name = formData.get('name');
  await db.users.create({ data: { name } });
  revalidatePath('/users');
}
```

### Metadata

```tsx
// Static metadata
export const metadata: Metadata = {
  title: 'My App',
  description: 'App description',
};

// Dynamic metadata
export async function generateMetadata({ params }): Promise<Metadata> {
  const product = await getProduct(params.id);
  return { title: product.name };
}
```

### Route Handlers (API Routes)

```tsx
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const users = await db.users.findMany();
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await db.users.create({ data: body });
  return NextResponse.json(user, { status: 201 });
}

// Dynamic route: app/api/users/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = await db.users.findUnique({ where: { id: params.id } });
  if (!user) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
  return NextResponse.json(user);
}
```

### Middleware

```tsx
// middleware.ts (root에 위치)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // 인증 체크
  const token = request.cookies.get('token');
  
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};
```

### Image & Font

```tsx
// Image 최적화
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={800}
  height={400}
  priority          // LCP 이미지에 사용
  placeholder="blur"
/>

// Font 최적화
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export default function RootLayout({ children }) {
  return (
    <html lang="ko" className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

### Environment Variables

```bash
# .env.local (git ignore)
DATABASE_URL=postgresql://...
NEXT_PUBLIC_API_URL=https://api.example.com  # 클라이언트 노출

# 사용
const dbUrl = process.env.DATABASE_URL;  // 서버만
const apiUrl = process.env.NEXT_PUBLIC_API_URL;  // 클라이언트도 가능
```
