# Docker

## Dockerfile Best Practices

### Multi-stage Build

```dockerfile
# Node.js 예시
FROM node:20-alpine AS base

# 의존성 설치
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

# 빌드
FROM base AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# 프로덕션 이미지
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# 보안: non-root 유저
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

### Python 예시

```dockerfile
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# 의존성 설치
FROM base AS deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 프로덕션
FROM base AS runner

RUN useradd --create-home appuser
USER appuser

COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --chown=appuser:appuser . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## .dockerignore

```
# Git
.git
.gitignore

# Dependencies
node_modules
__pycache__
*.pyc
.venv

# Build outputs
.next
dist
build

# IDE
.vscode
.idea

# Tests
coverage
.pytest_cache

# Environment
.env
.env.local
*.env

# Docker
Dockerfile*
docker-compose*

# Misc
*.log
*.md
!README.md
```

## Docker Compose

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: runner
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 최적화 팁

### Layer Caching

```dockerfile
# ❌ Bad - 코드 변경 시 npm install 다시 실행
COPY . .
RUN npm install

# ✅ Good - package.json만 변경 시에만 재설치
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
```

### 이미지 크기 줄이기

```dockerfile
# alpine 사용
FROM node:20-alpine

# 불필요한 파일 제거
RUN npm ci --only=production && \
    npm cache clean --force

# .dockerignore 활용으로 빌드 컨텍스트 최소화
```

### 보안

```dockerfile
# Non-root 유저
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# 읽기 전용 파일시스템 (런타임)
# docker run --read-only

# 최신 베이스 이미지 사용
FROM node:20-alpine  # 태그 명시

# Secrets (빌드 시)
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

## Useful Commands

```bash
# 빌드
docker build -t my-app:latest .
docker build --target builder -t my-app:builder .  # 특정 stage
docker build --no-cache -t my-app:latest .  # 캐시 무시

# 실행
docker run -d --name my-app -p 3000:3000 my-app:latest
docker run --rm -it my-app:latest /bin/sh  # 디버깅

# 정리
docker system prune -af  # 미사용 리소스 모두 삭제
docker image prune -af   # 미사용 이미지 삭제

# 로그
docker logs -f my-app
docker logs --since 1h my-app

# 디버깅
docker exec -it my-app /bin/sh
docker inspect my-app
docker stats

# 이미지 분석
docker history my-app:latest
docker images --filter "dangling=true"
```
