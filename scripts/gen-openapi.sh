#!/bin/bash
# ============================================================
#  OpenAPI 代码生成脚本
#  从 docs/api/openapi.yaml 生成 Pydantic 模型 + 客户端
# ============================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
SPEC="$PROJECT_DIR/docs/api/openapi.yaml"
OUT_DIR="$PROJECT_DIR/generated"
LANG="${1:-python}"

echo "============================================================"
echo "  OpenAPI 代码生成器"
echo "  Spec: $SPEC"
echo "  Output: $OUT_DIR"
echo "  Language: $LANG"
echo "============================================================"
echo

# 检查 spec 存在
if [ ! -f "$SPEC" ]; then
    echo "❌ Spec not found: $SPEC"
    exit 1
fi

# 检查 Node.js
if ! command -v npm &> /dev/null; then
    echo "❌ npm not installed (needed for openapi-generator-cli)"
    echo "   Install: https://nodejs.org"
    exit 1
fi

# 检查 openapi-generator-cli
if ! command -v openapi-generator-cli &> /dev/null && ! npx --no-install @openapitools/openapi-generator-cli --version &> /dev/null; then
    echo "📦 Installing openapi-generator-cli..."
    npm install -g @openapitools/openapi-generator-cli
fi

mkdir -p "$OUT_DIR"

# 生成
echo "🔨 Generating $LANG code..."
case "$LANG" in
    python)
        npx @openapitools/openapi-generator-cli generate \
            -i "$SPEC" \
            -g python \
            -o "$OUT_DIR/python" \
            --additional-properties=packageName=user_service_client,projectName=user-service-client \
            --skip-validate-spec 2>&1 | tail -5
        echo "✅ Python client: $OUT_DIR/python"
        ;;
    python-fastapi)
        # 生成 Pydantic 模型 + FastAPI 路由骨架
        npx @openapitools/openapi-generator-cli generate \
            -i "$SPEC" \
            -g python-fastapi \
            -o "$OUT_DIR/python-fastapi" \
            --additional-properties=packageName=user_service \
            --skip-validate-spec 2>&1 | tail -5
        echo "✅ FastAPI skeleton: $OUT_DIR/python-fastapi"
        ;;
    typescript)
        npx @openapitools/openapi-generator-cli generate \
            -i "$SPEC" \
            -g typescript-axios \
            -o "$OUT_DIR/typescript" \
            --skip-validate-spec 2>&1 | tail -5
        echo "✅ TypeScript client: $OUT_DIR/typescript"
        ;;
    go)
        npx @openapitools/openapi-generator-cli generate \
            -i "$SPEC" \
            -g go \
            -o "$OUT_DIR/go" \
            --skip-validate-spec 2>&1 | tail -5
        echo "✅ Go client: $OUT_DIR/go"
        ;;
    *)
        echo "❌ Unknown language: $LANG"
        echo "   Supported: python, python-fastapi, typescript, go"
        exit 1
        ;;
esac

echo
echo "============================================================"
echo "  [OK] 生成完成"
echo "============================================================"
echo
echo "下一步:"
case "$LANG" in
    python*)
        echo "  cd $OUT_DIR/$LANG && pip install -e ."
        echo "  from user_service_client import ApiClient"
        ;;
    typescript)
        echo "  cd $OUT_DIR/typescript && npm install"
        ;;
    go)
        echo "  cd $OUT_DIR/go && go mod tidy"
        ;;
esac
