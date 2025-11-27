# Claude Code Handbook

Claude Code에서 사용할 수 있는 재사용 가능한 지침(instructions), 스킬(skills), 에이전트(agents) 모음입니다.

## 구조

```
claude-code-handbook/
├── base/                 # 기본 지침 (항상 적용 권장)
├── skills/               # 재사용 가능한 기술 모듈
│   ├── languages/        # 프로그래밍 언어별
│   ├── frameworks/       # 프레임워크별
│   ├── infra/            # 인프라/DevOps
│   └── practices/        # 개발 프랙티스
├── agents/               # 특정 작업 수행용 에이전트 지침
├── prompts/              # 자주 쓰는 프롬프트 스니펫
├── examples/             # 조합 예시
└── scripts/              # 유틸리티 스크립트
```

## 사용법

### 1. 직접 복사

필요한 파일을 프로젝트의 `CLAUDE.md`에 복사합니다.

```bash
cp base/CLAUDE.md ~/my-project/CLAUDE.md
```

### 2. 모듈 조합

여러 모듈을 조합해서 사용합니다.

```bash
# 스크립트 사용
./scripts/combine.sh languages/typescript frameworks/nextjs practices/testing

# 결과물을 프로젝트에 복사
cp output/CLAUDE.md ~/my-project/CLAUDE.md
```

### 3. 심볼릭 링크

자주 사용하는 조합은 examples에서 링크합니다.

```bash
ln -s ~/claude-code-handbook/examples/fullstack-nextjs/CLAUDE.md ~/my-project/CLAUDE.md
```

## 모듈 목록

### Base
| 파일 | 설명 |
|------|------|
| `base/CLAUDE.md` | 코딩 스타일, 커뮤니케이션 기본 규칙 |
| `base/conventions.md` | 네이밍, 포맷팅 컨벤션 |

### Skills - Languages
| 파일 | 설명 |
|------|------|
| `languages/typescript.md` | TypeScript 모범 사례 |
| `languages/python.md` | Python 스타일 가이드 |
| `languages/go.md` | Go 언어 컨벤션 |

### Skills - Frameworks
| 파일 | 설명 |
|------|------|
| `frameworks/nextjs.md` | Next.js App Router 패턴 |
| `frameworks/fastapi.md` | FastAPI 구조화 가이드 |
| `frameworks/express.md` | Express.js 패턴 |

### Skills - Infra
| 파일 | 설명 |
|------|------|
| `skills/infra/kubernetes.md` | K8s 매니페스트 작성 |
| `skills/infra/aws.md` | AWS 서비스 패턴 |
| `skills/infra/docker.md` | Dockerfile 최적화 |
| `skills/infra/terraform.md` | Terraform 모듈 작성 |

### Skills - Practices
| 파일 | 설명 |
|------|------|
| `practices/testing.md` | 테스트 전략 |
| `practices/security.md` | 보안 체크리스트 |
| `practices/performance.md` | 성능 최적화 |

### Agents
| 파일 | 설명 |
|------|------|
| `agents/code-review.md` | PR 코드 리뷰 |
| `agents/refactor.md` | 리팩토링 전문 |
| `agents/debugger.md` | 디버깅/트러블슈팅 |
| `agents/docs-writer.md` | 문서화 |
| `agents/test-writer.md` | 테스트 코드 작성 |
| `agents/migration.md` | 마이그레이션 작업 |

## 커스터마이징

각 파일은 독립적으로 동작하도록 설계되었습니다. 필요에 따라:

1. 그대로 사용
2. 일부 수정해서 사용
3. 여러 모듈 조합해서 사용
4. 자신만의 모듈 추가

## 기여

PR 환영합니다. 새로운 스킬이나 에이전트 추가 시 기존 포맷을 따라주세요.

## License

MIT License
