# TP16 - Chaos Engineering sur Kubernetes

## 🎯 Objectifs pédagogiques

À la fin de ce TP, vous serez capable de :
- Comprendre les principes du chaos engineering
- Déployer et configurer Chaos Mesh
- Créer des expériences de chaos variées
- Analyser la résilience des applications
- Automatiser les tests de chaos
- Intégrer le chaos engineering dans le cycle CI/CD

## 📚 Prérequis

- Cluster Kubernetes (1.24+)
- Helm 3
- kubectl avec accès admin
- Application de test déployée
- Prometheus et Grafana pour l'observabilité
- Compréhension des concepts de résilience

## ⏱️ Durée estimée

4-5 heures

## 📋 Partie 1 : Principes du Chaos Engineering

### 1.1 - Les 4 principes fondamentaux

1. **Hypothèse sur l'état stable** : Définir des métriques qui indiquent un comportement normal
2. **Varier les événements du monde réel** : Simuler des pannes réalistes
3. **Expérimenter en production** : Tests les plus significatifs en conditions réelles
4. **Automatiser les expériences** : Exécution continue et systématique

### 1.2 - Types de chaos

- **Pod Chaos** : Tuer des pods, les redémarrer
- **Network Chaos** : Latence, perte de paquets, partitions réseau
- **IO Chaos** : Erreurs disque, latence I/O
- **Stress Chaos** : Stress CPU, mémoire
- **Time Chaos** : Décalage temporel
- **Kernel Chaos** : Erreurs système

### 1.3 - Méthodologie

1. Définir l'état stable (SLIs/SLOs)
2. Émettre des hypothèses
3. Concevoir l'expérience
4. Exécuter de manière contrôlée
5. Observer et mesurer
6. Analyser les résultats
7. Améliorer et itérer

## 📋 Partie 2 : Installation de Chaos Mesh

### 2.1 - Installation via Helm

```bash
# Ajouter le repo Helm
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Créer le namespace
kubectl create namespace chaos-mesh

# Installer Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock \
  --set dashboard.create=true

# Vérifier l'installation
kubectl get pods -n chaos-mesh
kubectl get crd | grep chaos-mesh
```

### 2.2 - Accéder au Dashboard

```bash
# Port-forward vers le dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333

# Ouvrir http://localhost:2333 dans le navigateur

# Créer un token pour l'authentification
kubectl create token -n chaos-mesh chaos-dashboard
```

### 2.3 - Installation des outils CLI

```bash
# Installer chaoctl
curl -sSL https://mirrors.chaos-mesh.org/latest/install.sh | bash

# Vérifier
chaoctl version
```

## 📋 Partie 3 : Application de Test

### 3.1 - Déployer une application microservices

```yaml
# test-app.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: chaos-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: chaos-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: chaos-test
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: chaos-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: hashicorp/http-echo
        args:
        - "-text=Backend Response"
        ports:
        - containerPort: 5678
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: chaos-test
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: chaos-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: database
        image: redis:alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: chaos-test
spec:
  selector:
    app: database
  ports:
  - port: 6379
    targetPort: 6379
```

```bash
kubectl apply -f test-app.yaml
kubectl get pods -n chaos-test -w
```

### 3.2 - Générateur de charge

```yaml
# load-generator.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
  namespace: chaos-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-generator
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: load-generator
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            wget -q -O- http://frontend.chaos-test.svc.cluster.local
            sleep 0.5
          done
```

```bash
kubectl apply -f load-generator.yaml
```

## 📋 Partie 4 : Expériences de Pod Chaos

### 4.1 - Pod Kill Experiment

```yaml
# podchaos-kill.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-frontend
  namespace: chaos-test
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: frontend
  duration: "30s"
  scheduler:
    cron: "@every 2m"
```

**Hypothèse** : L'application doit rester disponible malgré la perte d'un pod frontend.

```bash
# Appliquer l'expérience
kubectl apply -f podchaos-kill.yaml

# Observer les pods
kubectl get pods -n chaos-test -w

# Vérifier les métriques
# - Latence des requêtes
# - Taux d'erreur
# - Nombre de pods disponibles

# Arrêter l'expérience
kubectl delete podchaos pod-kill-frontend -n chaos-test
```

### 4.2 - Pod Failure (sans suppression)

```yaml
# podchaos-failure.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-backend
  namespace: chaos-test
spec:
  action: pod-failure
  mode: fixed
  value: "1"
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  duration: "2m"
```

Cette expérience rend le pod indisponible sans le supprimer, simulant un freeze.

### 4.3 - Container Kill

```yaml
# podchaos-container-kill.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: container-kill
  namespace: chaos-test
spec:
  action: container-kill
  mode: one
  containerNames:
    - backend
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  duration: "1m"
  scheduler:
    cron: "@every 5m"
```

## 📋 Partie 5 : Network Chaos

### 5.1 - Latence réseau

```yaml
# networkchaos-delay.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay
  namespace: chaos-test
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  delay:
    latency: "500ms"
    correlation: "25"
    jitter: "100ms"
  duration: "5m"
  direction: to
  target:
    mode: all
    selector:
      namespaces:
        - chaos-test
      labelSelectors:
        app: frontend
```

**Hypothèse** : L'application doit gérer une latence réseau élevée avec des timeouts appropriés.

```bash
kubectl apply -f networkchaos-delay.yaml

# Mesurer la latence
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -n chaos-test -- \
  sh -c 'for i in $(seq 1 10); do time curl -s http://backend > /dev/null; done'
```

### 5.2 - Perte de paquets

```yaml
# networkchaos-loss.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-loss
  namespace: chaos-test
spec:
  action: loss
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  loss:
    loss: "25"
    correlation: "25"
  duration: "3m"
```

### 5.3 - Partition réseau

```yaml
# networkchaos-partition.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-partition
  namespace: chaos-test
spec:
  action: partition
  mode: all
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: database
  direction: both
  duration: "2m"
  target:
    mode: all
    selector:
      namespaces:
        - chaos-test
      labelSelectors:
        app: backend
```

**Hypothèse** : L'application doit détecter la perte de connexion à la DB et gérer gracieusement.

### 5.4 - Bandwidth limitation

```yaml
# networkchaos-bandwidth.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: bandwidth-limit
  namespace: chaos-test
spec:
  action: bandwidth
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: frontend
  bandwidth:
    rate: "1mbps"
    limit: 20000
    buffer: 10000
  duration: "3m"
```

## 📋 Partie 6 : Stress Chaos

### 6.1 - Stress CPU

```yaml
# stresschaos-cpu.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: stress-cpu
  namespace: chaos-test
spec:
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  stressors:
    cpu:
      workers: 2
      load: 80
  duration: "3m"
```

**Hypothèse** : Le HPA doit scale automatiquement sous charge CPU élevée.

### 6.2 - Stress mémoire

```yaml
# stresschaos-memory.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: stress-memory
  namespace: chaos-test
spec:
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: backend
  stressors:
    memory:
      workers: 1
      size: "512MB"
  duration: "2m"
```

### 6.3 - Combined stress

```yaml
# stresschaos-combined.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: stress-combined
  namespace: chaos-test
spec:
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: frontend
  stressors:
    cpu:
      workers: 1
      load: 50
    memory:
      workers: 1
      size: "256MB"
  duration: "5m"
```

## 📋 Partie 7 : IO Chaos

### 7.1 - Latence I/O

```yaml
# iochaos-latency.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: io-latency
  namespace: chaos-test
spec:
  action: latency
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: database
  volumePath: /data
  path: "/data/**/*"
  delay: "500ms"
  percent: 50
  duration: "3m"
```

### 7.2 - Erreurs I/O

```yaml
# iochaos-errno.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: io-errno
  namespace: chaos-test
spec:
  action: errno
  mode: one
  selector:
    namespaces:
      - chaos-test
    labelSelectors:
      app: database
  volumePath: /data
  path: "/data/**/*"
  errno: 5  # EIO (Input/output error)
  percent: 10
  duration: "2m"
```

## 📋 Partie 8 : Workflows et Scenarios Complexes

### 8.1 - Workflow séquentiel

```yaml
# workflow-sequential.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: sequential-chaos
  namespace: chaos-test
spec:
  entry: the-entry
  templates:
    - name: the-entry
      templateType: Serial
      deadline: 10m
      children:
        - pod-kill
        - network-delay
        - stress-test

    - name: pod-kill
      templateType: PodChaos
      deadline: 2m
      podChaos:
        action: pod-kill
        mode: one
        selector:
          namespaces:
            - chaos-test
          labelSelectors:
            app: frontend

    - name: network-delay
      templateType: NetworkChaos
      deadline: 3m
      networkChaos:
        action: delay
        mode: one
        selector:
          namespaces:
            - chaos-test
          labelSelectors:
            app: backend
        delay:
          latency: "300ms"

    - name: stress-test
      templateType: StressChaos
      deadline: 3m
      stressChaos:
        mode: one
        selector:
          namespaces:
            - chaos-test
          labelSelectors:
            app: backend
        stressors:
          cpu:
            workers: 2
            load: 70
```

### 8.2 - Workflow parallèle

```yaml
# workflow-parallel.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: parallel-chaos
  namespace: chaos-test
spec:
  entry: the-entry
  templates:
    - name: the-entry
      templateType: Parallel
      deadline: 5m
      children:
        - pod-chaos
        - network-chaos
        - stress-chaos

    - name: pod-chaos
      templateType: PodChaos
      deadline: 5m
      podChaos:
        action: pod-failure
        mode: one
        selector:
          namespaces:
            - chaos-test
          labelSelectors:
            app: frontend

    - name: network-chaos
      templateType: NetworkChaos
      deadline: 5m
      networkChaos:
        action: delay
        mode: all
        selector:
          namespaces:
            - chaos-test
        delay:
          latency: "200ms"

    - name: stress-chaos
      templateType: StressChaos
      deadline: 5m
      stressChaos:
        mode: all
        selector:
          namespaces:
            - chaos-test
        stressors:
          cpu:
            workers: 1
            load: 50
```

### 8.3 - Workflow conditionnel

```yaml
# workflow-conditional.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: conditional-chaos
  namespace: chaos-test
spec:
  entry: entry
  templates:
    - name: entry
      templateType: Serial
      children:
        - initial-chaos
        - conditional-branch

    - name: initial-chaos
      templateType: PodChaos
      deadline: 1m
      podChaos:
        action: pod-kill
        mode: one
        selector:
          namespaces:
            - chaos-test

    - name: conditional-branch
      templateType: Conditional
      children:
        - mild-chaos
        - severe-chaos
      conditionalBranches:
        - target: mild-chaos
          expression: "status.experiment.phase == 'Running'"
        - target: severe-chaos
          expression: "status.experiment.phase == 'Failed'"
```

## 📋 Partie 9 : Monitoring et Observabilité

### 9.1 - Métriques avec Prometheus

```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: chaos-mesh
  namespace: chaos-mesh
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: chaos-daemon
  endpoints:
  - port: http
    interval: 30s
```

**Requêtes Prometheus utiles :**

```promql
# Taux d'erreur HTTP
rate(http_requests_total{status=~"5.."}[5m])

# Latence P99
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Pods disponibles
kube_deployment_status_replicas_available

# Taux de restart
rate(kube_pod_container_status_restarts_total[5m])
```

### 9.2 - Dashboard Grafana

Créer un dashboard avec les panels suivants :
- Nombre d'expériences actives
- Taux de succès/échec des expériences
- Métriques d'application (latence, erreurs, throughput)
- Resource utilization (CPU, mémoire, réseau)
- Pod status et restarts

### 9.3 - Alertes

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: chaos-alerts
  namespace: monitoring
spec:
  groups:
  - name: chaos-experiments
    interval: 30s
    rules:
    - alert: HighErrorRateDuringChaos
      expr: |
        rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected during chaos experiment"

    - alert: ApplicationDownDuringChaos
      expr: |
        up{job="my-app"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Application is down during chaos experiment"
```

## 📋 Partie 10 : Automatisation et CI/CD

### 10.1 - Chaos Tests dans CI/CD

```yaml
# .github/workflows/chaos-tests.yaml
name: Chaos Engineering Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Tous les jours à 2h du matin
  workflow_dispatch:

jobs:
  chaos-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3

      - name: Setup cluster connection
        run: |
          echo "${{ secrets.KUBECONFIG }}" > kubeconfig
          export KUBECONFIG=kubeconfig

      - name: Deploy application
        run: |
          kubectl apply -f manifests/
          kubectl wait --for=condition=ready pod -l app=myapp --timeout=300s

      - name: Run chaos experiments
        run: |
          kubectl apply -f chaos-experiments/
          sleep 300  # Durée des expériences

      - name: Check application health
        run: |
          ./scripts/health-check.sh

      - name: Collect metrics
        run: |
          ./scripts/collect-metrics.sh

      - name: Cleanup
        if: always()
        run: |
          kubectl delete -f chaos-experiments/
```

### 10.2 - Script de validation automatique

```bash
#!/bin/bash
# scripts/chaos-validation.sh

set -e

NAMESPACE="chaos-test"
CHAOS_DURATION="5m"

echo "Starting chaos engineering validation..."

# 1. Baseline metrics
echo "Collecting baseline metrics..."
kubectl top pods -n $NAMESPACE > baseline-metrics.txt

# 2. Run chaos experiment
echo "Applying chaos experiment..."
kubectl apply -f chaos-experiments/pod-kill.yaml

# 3. Monitor during chaos
echo "Monitoring application during chaos..."
for i in {1..10}; do
    HEALTHY=$(kubectl get pods -n $NAMESPACE -l app=frontend --field-selector=status.phase=Running --no-headers | wc -l)
    echo "Healthy pods: $HEALTHY"

    if [ $HEALTHY -lt 2 ]; then
        echo "ERROR: Not enough healthy pods"
        exit 1
    fi

    sleep 30
done

# 4. Cleanup
echo "Cleaning up chaos experiment..."
kubectl delete -f chaos-experiments/pod-kill.yaml

# 5. Verify recovery
echo "Verifying application recovery..."
sleep 60

FINAL_HEALTHY=$(kubectl get pods -n $NAMESPACE -l app=frontend --field-selector=status.phase=Running --no-headers | wc -l)
EXPECTED=3

if [ $FINAL_HEALTHY -eq $EXPECTED ]; then
    echo "SUCCESS: Application recovered successfully"
    exit 0
else
    echo "FAILURE: Application did not recover properly"
    exit 1
fi
```

## 🎓 Exercices avancés

### Exercice 1 : Game Day complet
Organisez un Game Day avec :
- Scénarios de panne réalistes
- Équipe d'intervention
- Documentation des incidents
- Post-mortem et amélioration

### Exercice 2 : Chaos Dashboard personnalisé
Créez un dashboard qui affiche :
- État en temps réel des expériences
- Impact sur les SLIs
- Historique des expériences
- Recommandations d'amélioration

### Exercice 3 : Chaos Policy Engine
Développez un système qui :
- Évalue la criticité des services
- Détermine les expériences appropriées
- Applique progressivement le chaos
- Rollback automatique si SLO breach

## 🔍 Points clés à retenir

1. **Commencer petit** : Tests simples puis progressivement plus complexes
2. **Observer d'abord** : Comprendre le comportement normal avant d'introduire le chaos
3. **Automatiser** : Intégrer dans le cycle de développement
4. **Apprendre** : Chaque expérience doit mener à des améliorations
5. **Sécurité** : Toujours avoir un kill switch et des limites

## 📚 Ressources complémentaires

- [Chaos Mesh Documentation](https://chaos-mesh.org/docs/)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Google SRE Book - Testing for Reliability](https://sre.google/sre-book/testing-reliability/)
- [Chaos Engineering by Netflix](https://netflixtechblog.com/chaos-engineering-upgraded-878d341f15fa)

## ✅ Validation

- [ ] Chaos Mesh installé et configuré
- [ ] 5+ types d'expériences testées
- [ ] Workflows complexes implémentés
- [ ] Monitoring et alerting configurés
- [ ] Automation dans CI/CD
- [ ] Documentation des learnings
- [ ] Plan d'amélioration de la résilience

## 🚀 Prochaine étape

TP17 - Cost Optimization et FinOps
