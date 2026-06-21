# 压测方案

> 性能验证 + 容量规划依据

---

## 1. 目标

| 指标 | 目标 |
|------|------|
| **稳态 QPS** | 5000 |
| **峰值 QPS** | 10000（2x 稳态） |
| **P99 延迟** | < 300ms |
| **错误率** | < 0.1% |
| **CPU 使用率** | < 70% |
| **DB 连接** | < 80 / 100 |

---

## 2. 工具

### 主工具: Locust

```python
# tests/performance/locustfile.py
from locust import HttpUser, task, between
import random


class UserServiceUser(HttpUser):
    wait_time = between(0.1, 0.5)
    
    def on_start(self):
        # 模拟登录获取 JWT
        self.token = self.login()
    
    def login(self):
        # SSO 模拟（测试环境）
        response = self.client.post(
            "/v1/auth/test-login",
            json={"email": f"loadtest{random.randint(1, 1000)}@test.com"},
        )
        return response.json()["token"]
    
    @task(10)
    def get_my_profile(self):
        self.client.get(
            "/v1/users/me",
            headers={"Authorization": f"Bearer {self.token}"},
        )
    
    @task(5)
    def list_users(self):
        self.client.get(
            "/v1/users?limit=50",
            headers={"Authorization": f"Bearer {self.token}"},
        )
    
    @task(2)
    def get_my_permissions(self):
        self.client.get(
            "/v1/users/me/permissions",
            headers={"Authorization": f"Bearer {self.token}"},
        )
    
    @task(1)
    def update_profile(self):
        self.client.patch(
            "/v1/users/me",
            json={"name": f"Updated {random.randint(1, 10000)}"},
            headers={
                "Authorization": f"Bearer {self.token}",
                "Idempotency-Key": str(uuid4()),
            },
        )
```

### 运行

```bash
# 安装
pip install locust

# 启动 Web UI
locust -f tests/performance/locustfile.py --host=https://user.staging.company.com

# 命令行模式
locust -f tests/performance/locustfile.py \
  --host=https://user.staging.company.com \
  --users 1000 \
  --spawn-rate 100 \
  --run-time 10m \
  --headless \
  --html report.html
```

---

## 3. 压测场景

### 3.1 稳态压测（Staging）

| 参数 | 值 |
|------|-----|
| 用户数 | 1000 并发 |
| 持续时间 | 30 分钟 |
| 目标 | 验证日常负载 |

### 3.2 峰值压测（Staging）

| 参数 | 值 |
|------|-----|
| 用户数 | 3000 并发 |
| 持续时间 | 15 分钟 |
| 目标 | 验证峰值处理 |

### 3.3 极限压测（Staging 夜间）

| 参数 | 值 |
|------|-----|
| 用户数 | 5000+ 并发 |
| 持续时间 | 5 分钟 |
| 目标 | 找出瓶颈 |

### 3.4 长时间稳定性（Staging）

| 参数 | 值 |
|------|-----|
| 用户数 | 500 并发 |
| 持续时间 | 24 小时 |
| 目标 | 查内存泄漏 |

### 3.5 故障注入（Staging）

- DB 节点 kill 1 个
- Redis 重启
- 网络延迟 100ms
- 1000 RPS 突发

---

## 4. 监控指标（压测时重点看）

### 应用层

| 指标 | 目标 | 告警 |
|------|------|------|
| P50 延迟 | < 50ms | - |
| P99 延迟 | < 300ms | > 500ms |
| 错误率 | < 0.1% | > 1% |
| QPS | 满足目标 | - |

### 系统层

| 指标 | 目标 |
|------|------|
| CPU | < 70% |
| 内存 | < 80% |
| 网络 I/O | < 100 MB/s |
| 磁盘 I/O | < 1000 IOPS |

### 数据库

| 指标 | 目标 |
|------|------|
| 连接数 | < 80 / 100 |
| 慢查询 | < 10 / min |
| 复制延迟 | < 1s |
| 锁等待 | < 5s |

### Redis

| 指标 | 目标 |
|------|------|
| 命中率 | > 90% |
| 内存 | < 70% |
| 延迟 | < 1ms |

### Kafka

| 指标 | 目标 |
|------|------|
| 消费 lag | < 1min |
| Producer 延迟 | < 10ms |

---

## 5. 容量规划

### 当前容量

| 资源 | 当前使用 | 上限 | 余量 |
|------|----------|------|------|
| 应用 pod CPU | 30% (3 pod) | 100% | 3.3x |
| 应用 pod 内存 | 45% | 100% | 2.2x |
| DB 连接 | 50 / 100 | 100 | 2x |
| Redis 内存 | 60% | 100% | 1.6x |

### 增长预测

| 指标 | 2026 | 2027 | 2028 |
|------|------|------|------|
| 用户数 | 5000 万 | 5500 万 | 6000 万 |
| QPS | 5000 | 6000 | 7000 |
| 数据量 | 2 TB | 2.5 TB | 3 TB |
| DB 连接需求 | 80 | 100 | 120 |

### 扩容时间表

| 时间 | 行动 |
|------|------|
| 2026 Q4 | 应用 pod 从 3 → 6 |
| 2027 Q2 | DB 从 8 核 → 16 核 |
| 2027 Q4 | Redis 从 32GB → 64GB |
| 2028 Q2 | DB 拆分（读写分离） |

---

## 6. 性能回归

### CI 强制

每次 PR：
- 跑性能基线测试（同等条件下）
- P99 延迟不能比 main 高 > 10%
- 错误率不能高 > 50%

### 工具

- `tests/performance/regression.py`
- 比较 baseline vs current
- 写入 `performance-regression.json`
- CI 失败如果超过阈值

---

## 7. 调优 checklist

压测后常见问题 + 调优：

| 问题 | 调优 |
|------|------|
| P99 高 | 检查 DB 慢查询、加缓存、调整 HPA |
| 错误率高 | 看 Sentry，常见：超时、连接池 |
| DB 连接耗尽 | 调高 pgbouncer pool_size |
| Redis 内存满 | 加内存、调 eviction policy |
| Kafka lag | 增加 consumer 并发 |

---

## 8. 报告模板

每次压测后输出：

```markdown
## 压测报告 - YYYY-MM-DD

### 场景
稳态压测，1000 并发，30 分钟

### 结果

| 指标 | 目标 | 实测 | 状态 |
|------|------|------|------|
| QPS | 5000 | 5234 | ✅ |
| P99 延迟 | < 300ms | 245ms | ✅ |
| 错误率 | < 0.1% | 0.02% | ✅ |
| CPU | < 70% | 55% | ✅ |

### 瓶颈

- 应用层：CPU 在 60% 时 P99 已经到 200ms，建议扩容到 6 pod
- DB：连接数到 75，剩余 25

### 行动项

- [ ] HPA 阈值从 60% 调到 50%
- [ ] DB 连接池从 80 调到 100

### 下次压测

- 加入 30% 流量来自 mobile
```

---

## 9. 工具脚本

`scripts/load-test.sh`：

```bash
#!/bin/bash
set -e

ENV=${1:-staging}
DURATION=${2:-10m}
USERS=${3:-1000}

echo "🚀 压测开始: env=$ENV duration=$DURATION users=$USERS"

# 1. 备份 baseline
cp tests/performance/baseline.json tests/performance/baseline.bak.json

# 2. 跑压测
locust -f tests/performance/locustfile.py \
  --host="https://user.$ENV.company.com" \
  --users "$USERS" \
  --spawn-rate 100 \
  --run-time "$DURATION" \
  --headless \
  --html "report-$ENV-$(date +%Y%m%d-%H%M).html" \
  --csv "metrics-$ENV-$(date +%Y%m%d-%H%M)"

# 3. 对比 baseline
python tests/performance/compare.py \
  --current "metrics-$ENV-$(date +%Y%m%d-%H%M)_stats.csv" \
  --baseline tests/performance/baseline.json

# 4. 发送报告
mail -s "压测报告 $ENV" sre-team@company.com < "report-$ENV-*.html"
```

---

## 10. 相关

- [HPA 配置](../architecture/deployment.md#23-hpa)
- [容量规划](../architecture/deployment.md#7-容量规划)
- [性能突降 Runbook](../runbook/performance-degradation.md)
