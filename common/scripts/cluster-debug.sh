#!/bin/bash
################################################################################
# Script de debugging pour cluster Kubernetes
# Usage: ./cluster-debug.sh [namespace]
################################################################################

set -e

NAMESPACE=${1:-default}
OUTPUT_DIR="debug-output-$(date +%Y%m%d-%H%M%S)"

echo "🔍 Kubernetes Cluster Debug Script"
echo "=================================="
echo "Namespace: $NAMESPACE"
echo "Output directory: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# Fonction pour logger
log() {
    echo "[$(date +%H:%M:%S)] $1"
}

# Fonction pour exécuter et sauvegarder
run_and_save() {
    local cmd=$1
    local output_file=$2
    log "Running: $cmd"
    eval "$cmd" > "$OUTPUT_DIR/$output_file" 2>&1 || echo "Error running command" >> "$OUTPUT_DIR/$output_file"
}

log "Starting cluster diagnostics..."

# 1. Cluster Info
log "Collecting cluster information..."
run_and_save "kubectl cluster-info" "cluster-info.txt"
run_and_save "kubectl version" "version.txt"
run_and_save "kubectl get nodes -o wide" "nodes.txt"
run_and_save "kubectl top nodes" "nodes-resources.txt"

# 2. Namespace Resources
log "Collecting namespace resources..."
run_and_save "kubectl get all -n $NAMESPACE -o wide" "namespace-resources.txt"
run_and_save "kubectl get pvc,pv -n $NAMESPACE" "storage.txt"
run_and_save "kubectl get configmaps,secrets -n $NAMESPACE" "config-secrets.txt"
run_and_save "kubectl get networkpolicies -n $NAMESPACE" "network-policies.txt"

# 3. Pods Details
log "Collecting pod details..."
run_and_save "kubectl get pods -n $NAMESPACE -o wide" "pods.txt"
run_and_save "kubectl top pods -n $NAMESPACE" "pods-resources.txt"

# Describe tous les pods
kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | while read -r pod; do
    if [ -n "$pod" ]; then
        log "Describing pod: $pod"
        kubectl describe pod "$pod" -n "$NAMESPACE" > "$OUTPUT_DIR/pod-describe-$pod.txt" 2>&1

        # Logs du pod
        log "Getting logs for pod: $pod"
        kubectl logs "$pod" -n "$NAMESPACE" --tail=500 > "$OUTPUT_DIR/pod-logs-$pod.txt" 2>&1 || echo "No logs available" > "$OUTPUT_DIR/pod-logs-$pod.txt"

        # Previous logs si le pod a redémarré
        if kubectl logs "$pod" -n "$NAMESPACE" --previous > /dev/null 2>&1; then
            kubectl logs "$pod" -n "$NAMESPACE" --previous --tail=500 > "$OUTPUT_DIR/pod-logs-previous-$pod.txt" 2>&1
        fi
    fi
done

# 4. Events
log "Collecting events..."
run_and_save "kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'" "events.txt"

# 5. Services et Endpoints
log "Collecting services and endpoints..."
run_and_save "kubectl get services -n $NAMESPACE -o wide" "services.txt"
run_and_save "kubectl get endpoints -n $NAMESPACE" "endpoints.txt"

kubectl get services -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | while read -r svc; do
    if [ -n "$svc" ]; then
        kubectl describe service "$svc" -n "$NAMESPACE" > "$OUTPUT_DIR/service-describe-$svc.txt" 2>&1
    fi
done

# 6. Ingress
if kubectl get ingress -n "$NAMESPACE" > /dev/null 2>&1; then
    log "Collecting ingress..."
    run_and_save "kubectl get ingress -n $NAMESPACE -o wide" "ingress.txt"

    kubectl get ingress -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | while read -r ing; do
        if [ -n "$ing" ]; then
            kubectl describe ingress "$ing" -n "$NAMESPACE" > "$OUTPUT_DIR/ingress-describe-$ing.txt" 2>&1
        fi
    done
fi

# 7. RBAC
log "Collecting RBAC info..."
run_and_save "kubectl get serviceaccounts -n $NAMESPACE" "serviceaccounts.txt"
run_and_save "kubectl get roles,rolebindings -n $NAMESPACE" "rbac.txt"

# 8. Control Plane (si accessible)
log "Collecting control plane info..."
run_and_save "kubectl get pods -n kube-system" "control-plane-pods.txt"
run_and_save "kubectl get componentstatuses" "component-status.txt"

# 9. Resource Quotas et Limits
log "Collecting quotas and limits..."
run_and_save "kubectl get resourcequotas -n $NAMESPACE" "resource-quotas.txt"
run_and_save "kubectl get limitranges -n $NAMESPACE" "limit-ranges.txt"

# 10. Custom Resources (CRDs)
log "Collecting CRDs..."
run_and_save "kubectl get crd" "crds.txt"

# 11. Networking Debug
log "Running network diagnostics..."
cat > "$OUTPUT_DIR/network-test.sh" << 'EOF'
#!/bin/bash
# Ce script peut être exécuté dans un pod de debug
# kubectl run debug --rm -it --image=nicolaka/netshoot -- /bin/bash

echo "DNS Resolution Test:"
nslookup kubernetes.default

echo -e "\nService connectivity test:"
curl -v telnet://kubernetes.default:443

echo -e "\nDNS Configuration:"
cat /etc/resolv.conf
EOF
chmod +x "$OUTPUT_DIR/network-test.sh"

# 12. Summary Report
log "Generating summary report..."
cat > "$OUTPUT_DIR/SUMMARY.md" << EOF
# Kubernetes Cluster Debug Report

**Date:** $(date)
**Namespace:** $NAMESPACE
**Cluster:** $(kubectl config current-context)

## Quick Stats

### Nodes
\`\`\`
$(kubectl get nodes --no-headers | wc -l) nodes
$(kubectl get nodes --no-headers | grep Ready | wc -l) ready
\`\`\`

### Pods in $NAMESPACE
\`\`\`
$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l) total pods
$(kubectl get pods -n "$NAMESPACE" --no-headers | grep Running | wc -l) running
$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -E 'Error|CrashLoopBackOff|ImagePullBackOff' | wc -l) in error state
\`\`\`

### Recent Events
\`\`\`
$(kubectl get events -n "$NAMESPACE" --field-selector type=Warning --no-headers | head -5)
\`\`\`

## Files Generated

- cluster-info.txt: Cluster information
- pods.txt: All pods in namespace
- events.txt: All events sorted by time
- pod-describe-*.txt: Detailed pod descriptions
- pod-logs-*.txt: Pod logs
- services.txt: All services
- ...

## Recommended Actions

1. Check pod-describe-*.txt files for pods in error state
2. Review events.txt for warnings and errors
3. Check pod-logs-*.txt for application errors
4. Verify resources with pods-resources.txt
5. Check network policies if connectivity issues

## Common Issues Checklist

- [ ] Pods stuck in Pending: Check resource availability and node selectors
- [ ] Pods in CrashLoopBackOff: Check logs and liveness probes
- [ ] ImagePullBackOff: Verify image name and registry access
- [ ] Service not accessible: Check endpoints and network policies
- [ ] High resource usage: Check pods-resources.txt

EOF

log "Debug information collected successfully!"
log "Output directory: $OUTPUT_DIR"
log ""
log "📊 Quick summary:"
echo "Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo "Pods in $NAMESPACE: $(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)"
echo "Pods Running: $(kubectl get pods -n "$NAMESPACE" --no-headers | grep Running | wc -l)"
echo "Pods in Error: $(kubectl get pods -n "$NAMESPACE" --no-headers | grep -E 'Error|CrashLoopBackOff|ImagePullBackOff' | wc -l)"
echo ""
log "Review $OUTPUT_DIR/SUMMARY.md for a detailed report"
log "✅ Done!"

# Créer une archive
log "Creating archive..."
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
log "Archive created: $OUTPUT_DIR.tar.gz"
