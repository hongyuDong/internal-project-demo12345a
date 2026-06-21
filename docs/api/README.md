# API 文档 (internal-user-service)

> OpenAPI 3.1 规范 + 文档索引

---

## 📄 规范文件

| 文件 | 格式 | 大小 | 用途 |
|------|------|------|------|
| `openapi.yaml` | YAML | 30 KB | 主规范（Claude Code / 编辑器友好）|
| `openapi.json` | JSON | 转换自 YAML | 工具链（Swagger UI / 代码生成）|
| `changelog.md` | Markdown | - | API 变更日志 |

## 🚀 快速开始

### 浏览器查看（Swagger UI）

```bash
# Docker 启动 Swagger UI
docker run -p 8080:8080 \
  -e SWAGGER_JSON=/api/openapi.json \
  -v $(pwd)/docs/api:/api \
  swaggerapi/swagger-ui
# 访问 http://localhost:8080
```

### VS Code 预览

装 [OpenAPI (Swagger) Editor](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi) 扩展，打开 `openapi.yaml` 即可预览。

### 生成代码

```bash
# Python 客户端
npx @openapitools/openapi-generator-cli generate \
  -i docs/api/openapi.yaml \
  -g python \
  -o ./client/python

# TypeScript 客户端
npx @openapitools/openapi-generator-cli generate \
  -i docs/api/openapi.yaml \
  -g typescript-axios \
  -o ./client/typescript

# FastAPI 服务端（基于 Pydantic）
npx @openapitools/openapi-generator-cli generate \
  -i docs/api/openapi.yaml \
  -g python-fastapi \
  -o ./server/skeleton
```

## 📊 端点统计

| Tag | 端点数 | 描述 |
|-----|--------|------|
| Health | 2 | /healthz, /readyz |
| Auth | 2 | /v1/auth/* |
| Users | 9 | 用户 CRUD + 状态 + 批量 |
| Organizations | 5 | 组织 CRUD + 关系 |
| Roles | 2 | 角色管理 |
| Permissions | 2 | 权限查询 + 检查 |
| Jobs | 1 | 异步任务 |
| **总计** | **23** | (含 webhooks) |

## 🔐 认证

```bash
# 1. SSO 登录获取 token
# 浏览器访问 https://sso.company.com/login

# 2. 调用 API
curl -H "Authorization: Bearer $TOKEN" \
     https://user.company.com/v1/users/me
```

## 🚦 限流

- **每个用户**：1000 次/分钟（BR-018）
- **超额**：返回 429 + `Retry-After`
- **Admin**：不受限

## 📜 业务规则引用

每个端点的 `x-business-rules` 字段标识关联的 BR-NNN。

详见 `docs/requirements/business-rules.md`。

## 📅 维护

- **修改规范**: 编辑 `openapi.yaml`
- **校验**: `python3 -c "import yaml; yaml.safe_load(open('docs/api/openapi.yaml'))"`
- **同步**: PR 时自动跑 lint + 校验
- **变更记录**: 写入 `changelog.md`

## 🤖 Claude / AI 使用

Claude 在写代码前**必须**读 `openapi.yaml`：

```
$ read docs/api/openapi.yaml
```

任何代码改动必须符合：
- ✅ Path 一致
- ✅ Method 一致
- ✅ Request schema 匹配
- ✅ Response schema 匹配
- ✅ Error codes 匹配

不一致 → 必须先改 spec，再改代码。

## 📚 相关文档

- 业务规则: `docs/requirements/business-rules.md`
- 数据流: `docs/architecture/data-flow.md`
- 架构总览: `docs/architecture/overview.md`
- ADR: `docs/architecture/adr/`
