#!/bin/bash

# Claude Code Handbook - Module Combiner
# 여러 모듈을 조합하여 CLAUDE.md 파일을 생성합니다.
#
# 사용법:
#   ./scripts/combine.sh [options] <modules...>
#
# 예시:
#   ./scripts/combine.sh languages/typescript frameworks/nextjs practices/testing
#   ./scripts/combine.sh --output my-project/CLAUDE.md languages/typescript
#   ./scripts/combine.sh --no-base languages/python  # base 제외

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$ROOT_DIR/output"
OUTPUT_FILE="$OUTPUT_DIR/CLAUDE.md"
INCLUDE_BASE=true

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [options] <modules...>"
    echo ""
    echo "Options:"
    echo "  -o, --output <file>  출력 파일 경로 (기본: output/CLAUDE.md)"
    echo "  -n, --no-base        base 모듈 제외"
    echo "  -l, --list           사용 가능한 모듈 목록"
    echo "  -h, --help           도움말"
    echo ""
    echo "Examples:"
    echo "  $0 languages/typescript frameworks/nextjs"
    echo "  $0 --output ~/my-project/CLAUDE.md languages/python"
    echo "  $0 agents/code-review agents/debugger"
}

list_modules() {
    echo "Available modules:"
    echo ""
    echo "📦 Languages:"
    ls -1 "$ROOT_DIR/languages/" 2>/dev/null | sed 's/.md$//' | sed 's/^/  languages\//'
    echo ""
    echo "📦 Frameworks:"
    ls -1 "$ROOT_DIR/frameworks/" 2>/dev/null | sed 's/.md$//' | sed 's/^/  frameworks\//'
    echo ""
    echo "📦 Infra:"
    ls -1 "$ROOT_DIR/infra/" 2>/dev/null | sed 's/.md$//' | sed 's/^/  infra\//'
    echo ""
    echo "📦 Practices:"
    ls -1 "$ROOT_DIR/practices/" 2>/dev/null | sed 's/.md$//' | sed 's/^/  practices\//'
    echo ""
    echo "🤖 Agents:"
    ls -1 "$ROOT_DIR/agents/" 2>/dev/null | sed 's/.md$//' | sed 's/^/  agents\//'
    echo ""
    echo "🧰 Skills:"
    find "$ROOT_DIR/skills" -maxdepth 2 -type f -name "*.md" 2>/dev/null \
      | sed "s#$ROOT_DIR/##" | sed 's/.md$//'
}

resolve_module_path() {
    local module="$1"
    local path=""
    
    # .md 확장자 제거 (있으면)
    module="${module%.md}"

    # 전체 경로로 변환 (루트 기준)
    if [[ "$module" == languages/* ]] || [[ "$module" == frameworks/* ]] || \
       [[ "$module" == infra/* ]] || [[ "$module" == practices/* ]] || \
       [[ "$module" == agents/* ]] || [[ "$module" == skills/* ]]; then
        path="$ROOT_DIR/$module.md"
    else
        # 짧은 형식 시도 (예: typescript -> languages/typescript)
        for dir in languages frameworks infra practices agents; do
            if [[ -f "$ROOT_DIR/$dir/$module.md" ]]; then
                path="$ROOT_DIR/$dir/$module.md"
                break
            fi
        done
        # skills 하위에서 찾기
        if [[ -z "$path" ]]; then
            found_skill=$(find "$ROOT_DIR/skills" -maxdepth 2 -type f -name "${module}.md" | head -n 1)
            if [[ -n "$found_skill" ]]; then
                path="$found_skill"
            fi
        fi
    fi

    echo "$path"
}

# 인자 파싱
MODULES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -n|--no-base)
            INCLUDE_BASE=false
            shift
            ;;
        -l|--list)
            list_modules
            exit 0
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            MODULES+=("$1")
            shift
            ;;
    esac
done

# 모듈이 지정되지 않았으면 에러
if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No modules specified${NC}"
    print_usage
    exit 1
fi

# 출력 디렉토리 생성
mkdir -p "$(dirname "$OUTPUT_FILE")"

# 임시 파일
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# 헤더 추가
cat >> "$TEMP_FILE" << 'EOF'
# Project Instructions

이 문서는 Claude Code Handbook의 모듈을 조합하여 생성되었습니다.

---

EOF

# Base 모듈 추가
if [[ "$INCLUDE_BASE" == true ]]; then
    if [[ -f "$ROOT_DIR/base/CLAUDE.md" ]]; then
        echo -e "${GREEN}✓${NC} Adding: base/CLAUDE.md"
        cat "$ROOT_DIR/base/CLAUDE.md" >> "$TEMP_FILE"
        echo -e "\n---\n" >> "$TEMP_FILE"
    fi
fi

# 각 모듈 추가
for module in "${MODULES[@]}"; do
    path=$(resolve_module_path "$module")
    
    if [[ -z "$path" ]] || [[ ! -f "$path" ]]; then
        echo -e "${RED}✗${NC} Not found: $module"
        echo -e "  Use ${YELLOW}$0 --list${NC} to see available modules"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Adding: $module"
    cat "$path" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
done

# 최종 파일 생성
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}Generated:${NC} $OUTPUT_FILE"
echo -e "Lines: $(wc -l < "$OUTPUT_FILE")"
