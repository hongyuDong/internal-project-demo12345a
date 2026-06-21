# 最小代码骨架说明

> 这是一个**参考实现**，不是完整业务代码。  
> 目的：让 Claude / 团队成员能看到模板 → 代码的映射关系。

---

## 📂 目录结构

```
src/
├── __init__.py
├── main.py                       # FastAPI 应用入口
├── api/
│   ├── __init__.py
│   └── v1/
│       ├── __init__.py
│       ├── auth.py                # 认证 API
│       ├── users.py               # 用户 API（骨架）
│       └── organizations.py       # 组织 API（骨架）
├── core/
│   ├── __init__.py
│   ├── config.py                 # 配置（pydantic-settings）
│   ├── security.py               # JWT + 认证依赖
│   └── cache.py                  # Redis 缓存层
└── models/
    ├── __init__.py
    └── user.py                    # User SQLAlchemy 模型

requirements.txt                  # Python 依赖
```

## 🚀 启动

```bash
# 1. 装依赖
uv venv
uv pip install -r requirements.txt

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env

# 3. 启动
uvicorn src.main:app --reload

# 4. 访问
# - API: http://localhost:8000
# - Swagger UI: http://localhost:8000/docs
# - ReDoc: http://localhost:8000/redoc
# - OpenAPI spec: http://localhost:8000/openapi.json
```

## ⚠️ 当前状态

这些文件都是 **骨架**，标有 `NotImplementedError("TODO: ...")` 的方法需要团队补全。

补全顺序建议：
1. ✅ `config.py` — 已实现（含 .env 支持）
2. ✅ `security.py` — 已实现 JWT 验证骨架
3. ✅ `cache.py` — 已实现 Redis 缓存
4. ✅ `models/user.py` — 已实现 SQLAlchemy 模型
5. ✅ `main.py` — 已实现应用入口
6. ✅ `api/v1/auth.py` — 已实现 me + logout
7. 🟡 `api/v1/users.py` — 骨架（需补全业务逻辑）
8. 🟡 `api/v1/organizations.py` — 骨架

## 📚 实现业务逻辑时

### 必读
- `docs/api/openapi.yaml` — 接口契约（不可偏离）
- `docs/domain/entities/user.md` — User 完整字段
- `docs/requirements/business-rules.md` — 业务规则
- `docs/architecture/adr/` — 架构决策

### 推荐流程
1. 读 OpenAPI 端点定义
2. 找对应 business-rules.md 的 BR-NNN
3. 用 skill `create-new-endpoint` 引导（如果装了）
4. 写业务逻辑 + 单元测试 + 集成测试
5. 更新 `docs/api/openapi.yaml`（如有偏离）
6. PR + review

### 测试

```bash
# 单元测试
pytest tests/unit/ -v

# 集成测试（需要 DB）
pytest tests/integration/ -v

# 覆盖率
pytest --cov=src --cov-report=html
```

## 🔧 替换指南（如果不用 FastAPI）

这个骨架演示的是 Python/FastAPI 栈。如果团队用：

| 团队栈 | 替换 |
|--------|------|
| Java/Spring Boot | `src/main.py` → `Application.java`，`requirements.txt` → `pom.xml` |
| Go | `src/main.py` → `cmd/server/main.go`，`requirements.txt` → `go.mod` |
| Node/NestJS | `src/main.ts` + `package.json` |

**核心契约不变**：
- OpenAPI 3.1 spec（`docs/api/openapi.yaml`）
- 业务规则（`docs/requirements/business-rules.md`）
- 架构决策（`docs/architecture/adr/`）
- 工作流程（`CLAUDE.md`）

## ⚠️ 不要做的事

- ❌ 不要把 .env 文件提交到 git
- ❌ 不要 hardcode 密钥到代码
- ❌ 不要忽略 PII 加密（BR-011）
- ❌ 不要绕过 audit log
- ❌ 不要跳过 RFC 7807 错误格式
- ❌ 不要写"我自己实现的版本"而不读 OpenAPI
