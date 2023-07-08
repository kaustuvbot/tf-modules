# AWS Infrastructure Runbook v0

This runbook covers the alerts defined in the monitoring module. Each section describes the alarm, what it means, how to investigate, and common remediation steps.

---

## EKS Alarms

### `eks-cpu-high`

**Condition**: Average node CPU utilization > 80% for 3 consecutive 5-minute periods.

**What it means**: Worker nodes are under sustained CPU pressure. This is not a single spike — it has persisted for 15+ minutes.

**Investigation**:
```bash
# Check node-level CPU
kubectl top nodes

# Check which pods are consuming CPU
kubectl top pods -A --sort-by=cpu | head -20

# Check for runaway pods
kubectl get pods -A | grep -v Running
```

**Common causes**:
- Sudden traffic spike — check if HPA has scaled up
- Runaway process in a pod — inspect container logs
- Cluster autoscaler hasn't reacted yet — check autoscaler logs

**Remediation**:
1. If traffic-driven: verify HPA is configured and scaling
2. If a single pod: `kubectl delete pod <pod> -n <namespace>` to force restart
3. If sustained: add a new node group or increase `max_size`

---

### `eks-memory-high`

**Condition**: Average node memory utilization > 80% for 3 consecutive 5-minute periods.

**Investigation**:
```bash
kubectl top nodes
kubectl top pods -A --sort-by=memory | head -20

# Check for OOMKilled pods
kubectl get pods -A -o json | jq '.items[] | select(.status.containerStatuses[]?.lastState.terminated.reason == "OOMKilled") | .metadata.name'
```

**Common causes**:
- Missing memory limits on pods — pods will consume all available memory
- Memory leak in application
- JVM heap not bounded

**Remediation**:
1. Set `resources.limits.memory` on pods without limits
2. If OOMKilled: increase memory limit or fix the memory leak
3. If cluster-wide: scale up node group

---

### `eks-node-not-ready`

**Condition**: One or more nodes report NotReady for 2 consecutive periods. Missing data is treated as breaching.

**This is a high-priority alert** — NotReady nodes mean pods may be evicted.

**Investigation**:
```bash
# Find NotReady nodes
kubectl get nodes | grep NotReady

# Check node conditions
kubectl describe node <node-name> | grep -A 10 Conditions

# Check node events
kubectl get events --field-selector involvedObject.name=<node-name>
```

**Common causes**:
- EC2 instance health issue — check EC2 console
- kubelet crashed — check system logs on the node
- Network plugin failure (VPC CNI issue)
- Disk pressure

**Remediation**:
1. If EC2 instance is unhealthy: terminate it — ASG will replace it
2. If disk pressure: check for large log files, increase EBS volume size
3. If VPC CNI: `kubectl rollout restart daemonset aws-node -n kube-system`

---

### `eks-pod-restarts`

**Condition**: More than 10 pod restarts in a 5-minute period, for 2 of 3 consecutive periods.

**Investigation**:
```bash
# Find crash-looping pods
kubectl get pods -A | grep CrashLoopBackOff

# Check restart counts
kubectl get pods -A -o wide | awk '$5 > 5 {print}'

# Check logs for crashing pod
kubectl logs <pod> -n <namespace> --previous
```

**Common causes**:
- Application bug causing panic/crash
- Missing configuration (env vars, secrets, configmaps)
- Readiness/liveness probe misconfiguration
- OOMKilled (check memory alarm too)

**Remediation**:
1. Check `kubectl describe pod <pod>` for last exit code and reason
2. Review previous logs for error messages
3. Temporarily increase `restartPolicy` delay by patching deployment

---

### `eks-node-health` (Composite)

**Condition**: Fires when:
- A node is NotReady, **OR**
- Both CPU AND memory are high simultaneously

**What it means**: The cluster is in a degraded state. Either nodes are failing or the cluster is resource-saturated.

**Action**: Check both `eks-node-not-ready` and `eks-cpu-high`/`eks-memory-high` runbooks above. Treat this as a P1 incident.

---

## Notification Channels

Alarms are delivered via:
- **SNS topic**: `{project}-{environment}-alerts`
- **Slack** (if configured): `#alerts` channel
- **Email** (if configured): subscribed addresses

To add a new notification channel, update `alarm_email_addresses` or `slack_webhook_url` in the monitoring module inputs.

---

## Adjusting Thresholds

Default thresholds are conservative for production. To adjust:

```hcl
module "monitoring" {
  # ...
  alarm_cpu_threshold          = 90   # default: 80
  alarm_memory_threshold       = 85   # default: 80
  alarm_pod_restart_threshold  = 20   # default: 10
  alarm_evaluation_periods     = 5    # default: 3
  alarm_period                 = 60   # default: 300 (5 min)
}
```

Lower `alarm_period` for faster detection (at higher CloudWatch cost). Increase `alarm_evaluation_periods` to reduce false positives.
