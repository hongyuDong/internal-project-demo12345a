# RB-004: Kafka 消费积压

> **等级**: 🟡 P1（持续 > 30 分钟 → 🔴 P0）  
> **典型触发**: consumer lag > 100K 或 > 5 分钟

---

## 🚨 立即确认

```bash
# 1. 看 lag
kubectl exec -it kafka-0 -n user-service-prod -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --all-groups

# 2. 看具体 topic
kubectl exec -it kafka-0 -n user-service-prod -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group user-service-notifier
```

---

## 🛠 常见原因 + 修复

### A. Consumer 慢 / 卡住

```bash
# 1. 看 consumer pod 状态
kubectl get pods -n user-service-prod -l app=user-service-consumer

# 2. 看 consumer 日志
kubectl logs -n user-service-prod -l app=user-service-consumer --tail=200 | grep -i error

# 3. 重启 consumer
kubectl rollout restart deployment/user-service-consumer -n user-service-prod
```

### B. Producer 突发流量

```bash
# 1. 看 producer 速率
kubectl exec -it kafka-0 -n user-service-prod -- \
  kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic user.created

# 2. 增加 consumer 并发
kubectl scale deployment/user-service-consumer -n user-service-prod --replicas=10
```

### C. 下游服务慢（如 audit-service 故障）

```bash
# 1. 看下游状态
curl -s https://audit.company.com/healthz

# 2. 临时跳过（不推荐）
# 改 audit-service 客户端配置，重试 3 次后丢弃
```

### D. Topic 分区不足

```bash
# 1. 增加分区（最多一次 2x）
kubectl exec -it kafka-0 -n user-service-prod -- \
  kafka-topics.sh --bootstrap-server localhost:9092 \
  --alter --topic user.created --partitions 24
```

---

## 📊 恢复验证

- Lag 持续下降到 < 1K
- Consumer 速率 > Producer 速率
- 下游服务告警消失

---

## 🛡 长期改进

- HPA：lag > 100K 自动扩容 consumer
- 死信队列：3 次重试失败进 DLQ
- 多 consumer group 隔离：notifier / audit / sync 各自独立
