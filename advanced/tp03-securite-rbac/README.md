# TP03 - Sécurité et RBAC Avancé

## 🎯 Objectifs pédagogiques

À la fin de ce TP, vous serez capable de :
- Concevoir et implémenter une architecture RBAC complète
- Mettre en place Pod Security Standards (PSS)
- Utiliser OPA/Gatekeeper pour des policies avancées
- Sécuriser les secrets avec des solutions externes
- Auditer et améliorer la sécurité d'un cluster

## 📚 Prérequis

- Cluster Kubernetes (1.25+)
- kubectl avec droits admin
- Helm 3
- Compréhension des concepts de sécurité de base

## ⏱️ Durée estimée

4-5 heures

## 📋 Partie 1 : RBAC Approfondi

### 1.1 - Architecture RBAC multi-tenants

**Scénario :** Vous devez configurer l'accès pour 3 équipes :
- **dev-team** : Accès complet à leur namespace, lecture seule sur staging
- **ops-team** : Accès cluster-wide pour monitoring, pas de modifications
- **admin-team** : Accès complet avec restrictions sur certaines opérations sensibles

```bash
# Créer les namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
kubectl create namespace monitoring
```

### 1.2 - Créer les ServiceAccounts

```yaml
# serviceaccounts.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-sa
  namespace: dev
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ops-sa
  namespace: monitoring
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-sa
  namespace: kube-system
```

### 1.3 - Définir les Roles et ClusterRoles

```yaml
# dev-team-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-full-access
  namespace: dev
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
# Lecture seule sur staging
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-readonly-staging
  namespace: staging
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "jobs", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
---
# ops-team-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ops-monitoring
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
- nonResourceURLs: ["/metrics", "/healthz"]
  verbs: ["get"]
---
# admin-restricted-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admin-restricted
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
# Interdire la modification de certaines ressources sensibles
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["critical-secret", "tls-cert"]
  verbs: ["delete", "update"]
```

### 1.4 - Créer les RoleBindings

```yaml
# rolebindings.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-team-binding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: dev-sa
  namespace: dev
- kind: Group
  name: dev-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: dev-full-access
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-readonly-staging-binding
  namespace: staging
subjects:
- kind: Group
  name: dev-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: dev-readonly-staging
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ops-monitoring-binding
subjects:
- kind: ServiceAccount
  name: ops-sa
  namespace: monitoring
- kind: Group
  name: ops-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: ops-monitoring
  apiGroup: rbac.authorization.k8s.io
```

### 1.5 - Tester les permissions

```bash
# Tester avec dev-sa
kubectl auth can-i create pods --namespace=dev --as=system:serviceaccount:dev:dev-sa
# Devrait retourner "yes"

kubectl auth can-i delete deployments --namespace=staging --as=system:serviceaccount:dev:dev-sa
# Devrait retourner "no"

# Tester avec ops-sa
kubectl auth can-i get pods --all-namespaces --as=system:serviceaccount:monitoring:ops-sa
# Devrait retourner "yes"

kubectl auth can-i delete pods --namespace=production --as=system:serviceaccount:monitoring:ops-sa
# Devrait retourner "no"

# Audit des permissions
kubectl auth can-i --list --as=system:serviceaccount:dev:dev-sa -n dev
```

## 📋 Partie 2 : Pod Security Standards

### 2.1 - Comprendre les niveaux PSS

Les trois niveaux :
- **Privileged** : Sans restrictions
- **Baseline** : Minimalement restrictif
- **Restricted** : Hautement restrictif (production)

### 2.2 - Configurer PSS au niveau namespace

```bash
# Appliquer le niveau restricted en mode enforce
kubectl label namespace dev \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Baseline pour staging
kubectl label namespace staging \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Privileged pour kube-system (nécessaire)
kubectl label namespace kube-system \
  pod-security.kubernetes.io/enforce=privileged
```

### 2.3 - Tester les restrictions

```yaml
# pod-non-compliant.yaml - Devrait être rejeté
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true  # NON PERMIS en mode restricted
```

```bash
kubectl apply -f pod-non-compliant.yaml
# Devrait être rejeté
```

```yaml
# pod-compliant.yaml - Devrait être accepté
apiVersion: v1
kind: Pod
metadata:
  name: compliant
  namespace: dev
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
```

## 📋 Partie 3 : OPA Gatekeeper

### 3.1 - Installation de Gatekeeper

```bash
# Installer via Helm
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --name-template=gatekeeper \
  --namespace gatekeeper-system --create-namespace

# Vérifier l'installation
kubectl get pods -n gatekeeper-system
```

### 3.2 - Créer des ConstraintTemplates

```yaml
# constraint-template-required-labels.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Les labels obligatoires sont manquants: %v", [missing])
        }
```

```yaml
# constraint-template-allowed-repos.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sallowedrepos

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          satisfied := [good | repo = input.parameters.repos[_]
                              good = startswith(container.image, repo)]
          not any(satisfied)
          msg := sprintf("Image '%v' provient d'un registry non autorisé", [container.image])
        }
```

### 3.3 - Appliquer les Constraints

```yaml
# constraint-labels-prod.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-labels-prod
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet"]
    namespaces:
      - production
  parameters:
    labels:
      - "app"
      - "environment"
      - "team"
      - "cost-center"
```

```yaml
# constraint-allowed-repos.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: prod-allowed-repos
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - production
  parameters:
    repos:
      - "registry.company.com/"
      - "gcr.io/company-project/"
```

### 3.4 - Tester les policies

```bash
# Appliquer les templates et constraints
kubectl apply -f constraint-template-required-labels.yaml
kubectl apply -f constraint-template-allowed-repos.yaml
kubectl apply -f constraint-labels-prod.yaml
kubectl apply -f constraint-allowed-repos.yaml

# Tester un deployment non conforme
kubectl create deployment test --image=nginx --namespace=production
# Devrait être rejeté

# Tester avec les labels requis
kubectl create deployment test \
  --image=registry.company.com/nginx \
  --namespace=production
kubectl label deployment test -n production \
  app=test environment=prod team=platform cost-center=eng-001
```

## 📋 Partie 4 : Gestion sécurisée des Secrets

### 4.1 - Sealed Secrets

```bash
# Installer Sealed Secrets
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system

# Installer kubeseal CLI
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

```bash
# Créer un secret scellé
kubectl create secret generic mysecret \
  --from-literal=password=SuperSecretPassword123 \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > mysealedsecret.yaml

# Le fichier peut maintenant être commité dans git
cat mysealedsecret.yaml

# Appliquer le sealed secret
kubectl apply -f mysealedsecret.yaml

# Vérifier qu'il a été déchiffré
kubectl get secret mysecret -o yaml
```

### 4.2 - Integration avec HashiCorp Vault

```bash
# Installer Vault via Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set "server.dev.enabled=true"

# Configurer Vault
kubectl exec -it vault-0 -n vault -- /bin/sh

# Dans le pod Vault
vault secrets enable -path=secret kv-v2
vault kv put secret/database/config username="db-admin" password="SuperSecret123"

# Configurer Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

# Créer une policy
vault policy write myapp-policy - <<EOF
path "secret/data/database/config" {
  capabilities = ["read"]
}
EOF

# Créer un role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp-sa \
  bound_service_account_namespaces=dev \
  policies=myapp-policy \
  ttl=24h
```

```yaml
# deployment-with-vault.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: dev
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/database/config"
    spec:
      serviceAccountName: myapp-sa
      containers:
      - name: app
        image: nginx
        env:
        - name: DB_USERNAME
          value: /vault/secrets/database
```

## 📋 Partie 5 : Audit et Monitoring de Sécurité

### 5.1 - Activer l'Audit Log

```yaml
# audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log des accès aux secrets
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["secrets"]

  # Log des modifications RBAC
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
    resources:
    - group: "rbac.authorization.k8s.io"

  # Log des exec/attach sur pods
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/exec", "pods/attach"]

  # Ignorer les health checks
  - level: None
    nonResourceURLs:
    - "/healthz*"
    - "/metrics"
```

### 5.2 - Scanner les vulnérabilités avec Trivy

```bash
# Installer Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scanner une image
trivy image nginx:latest

# Scanner toutes les images du cluster
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u | xargs -I {} trivy image {}

# Installer Trivy Operator pour scanning automatique
helm repo add aquasecurity https://aquasecurity.github.io/helm-charts/
helm install trivy-operator aquasecurity/trivy-operator \
  --namespace trivy-system --create-namespace
```

### 5.3 - Audit avec kube-bench

```bash
# Installer kube-bench
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Voir les résultats
kubectl logs job/kube-bench

# Analyser les recommandations
kubectl logs job/kube-bench | grep "\[FAIL\]"
```

## 🎓 Exercices avancés

### Exercice 1 : Mise en place complète
Créez une architecture de sécurité complète pour un cluster multi-tenant avec :
- RBAC granulaire par équipe
- PSS configuré par environnement
- 5 policies Gatekeeper custom
- Sealed Secrets ou Vault
- Audit logging activé

### Exercice 2 : Policy OPA custom
Créez une policy Gatekeeper qui :
- Interdit les containers en mode privileged
- Force l'utilisation de resource limits
- Vérifie que les images ont des tags sémantiques (pas :latest)
- Assure que tous les services en production ont un NetworkPolicy

### Exercice 3 : Rotation des secrets
Implémentez un système de rotation automatique des secrets avec Vault ou External Secrets Operator.

## 🔍 Points clés à retenir

1. **RBAC** : Principe du moindre privilège, audit régulier
2. **PSS** : Toujours utiliser "restricted" en production
3. **OPA/Gatekeeper** : Valider les configurations avant déploiement
4. **Secrets** : Ne jamais les stocker en clair, utiliser des solutions dédiées
5. **Audit** : Monitoring et alertes sur les actions sensibles

## 📚 Ressources complémentaires

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [HashiCorp Vault](https://www.vaultproject.io/docs/platform/k8s)

## ✅ Validation

- [ ] Architecture RBAC multi-tenant fonctionnelle
- [ ] PSS configuré et testé sur tous les namespaces
- [ ] 3+ policies Gatekeeper actives
- [ ] Solution de gestion des secrets implémentée
- [ ] Audit logging activé et testé
- [ ] Scan de sécurité automatique en place

## 🚀 Prochaine étape

TP04 - Stockage Avancé et StatefulSets
