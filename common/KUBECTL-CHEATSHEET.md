# Kubectl Cheatsheet - Commandes Avancées

## 🎯 Configuration et Contextes

```bash
# Afficher la configuration actuelle
kubectl config view

# Lister les contextes
kubectl config get-contexts

# Changer de contexte
kubectl config use-context <context-name>

# Définir le namespace par défaut
kubectl config set-context --current --namespace=<namespace>

# Créer un nouveau contexte
kubectl config set-context dev --cluster=kubernetes --namespace=development --user=dev-user
```

## 🔍 Recherche et Filtrage

```bash
# Tous les pods avec un label spécifique
kubectl get pods -l app=nginx

# Pods avec plusieurs labels
kubectl get pods -l 'app=nginx,environment=production'

# Pods qui ne matchent PAS un label
kubectl get pods -l 'app!=nginx'

# Utiliser des field selectors
kubectl get pods --field-selector status.phase=Running

# Combiner labels et fields
kubectl get pods -l app=nginx --field-selector status.phase=Running

# Trier par timestamp de création
kubectl get pods --sort-by=.metadata.creationTimestamp

# Pods triés par nombre de restarts
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'

# Output custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP

# JSONPath queries
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

## 📊 Informations Détaillées

```bash
# Describe avec tous les events
kubectl describe pod <pod-name>

# Obtenir le YAML complet d'une ressource
kubectl get pod <pod-name> -o yaml

# Obtenir uniquement certains champs
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'

# Logs avec timestamps
kubectl logs <pod-name> --timestamps

# Logs des 100 dernières lignes
kubectl logs <pod-name> --tail=100

# Follow logs de tous les containers d'un pod
kubectl logs <pod-name> --all-containers --follow

# Logs d'un container spécifique
kubectl logs <pod-name> -c <container-name>

# Logs du container précédent (après restart)
kubectl logs <pod-name> --previous

# Logs depuis les dernières X heures
kubectl logs <pod-name> --since=2h
```

## 🚀 Exécution et Debug

```bash
# Exécuter une commande dans un pod
kubectl exec <pod-name> -- ls /app

# Shell interactif
kubectl exec -it <pod-name> -- /bin/bash

# Exécuter dans un container spécifique
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Copier des fichiers
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# Port forwarding
kubectl port-forward <pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80

# Pod de debug temporaire
kubectl run debug --rm -it --image=busybox --restart=Never -- sh

# Pod de debug réseau
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# Debug d'un pod existant (Kubernetes 1.23+)
kubectl debug <pod-name> -it --image=busybox

# Créer une copie d'un pod pour debug
kubectl debug <pod-name> -it --copy-to=<pod-name-debug> --container=debug-container --image=busybox
```

## 🔐 Sécurité et RBAC

```bash
# Vérifier si on peut faire une action
kubectl auth can-i create pods
kubectl auth can-i create pods --namespace=dev
kubectl auth can-i create pods --as=user@example.com
kubectl auth can-i create pods --as=system:serviceaccount:default:mysa

# Lister toutes les permissions d'un user
kubectl auth can-i --list --as=user@example.com

# Voir les rôles et bindings
kubectl get roles,rolebindings -A
kubectl get clusterroles,clusterrolebindings

# Qui peut faire une action
kubectl auth reconcile -f role.yaml --dry-run=client

# Créer un service account avec token
kubectl create serviceaccount my-sa
kubectl create token my-sa --duration=24h
```

## 📈 Monitoring et Métriques

```bash
# Ressources des nodes
kubectl top nodes

# Ressources des pods
kubectl top pods
kubectl top pods --all-namespaces
kubectl top pods --sort-by=memory
kubectl top pods --sort-by=cpu

# Métriques d'un pod spécifique
kubectl top pod <pod-name> --containers

# API server metrics
kubectl get --raw /metrics | grep apiserver

# Événements en temps réel
kubectl get events --watch
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector type=Warning
```

## 🔄 Mises à jour et Rollbacks

```bash
# Mettre à jour une image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>

# Rollout status
kubectl rollout status deployment/<deployment-name>

# Historique des rollouts
kubectl rollout history deployment/<deployment-name>

# Rollback
kubectl rollout undo deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name> --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>

# Restart deployment
kubectl rollout restart deployment/<deployment-name>
```

## 🎚️ Scale et Autoscaling

```bash
# Scale manuel
kubectl scale deployment/<deployment-name> --replicas=5

# Scale basé sur condition
kubectl scale --replicas=3 deployment/<deployment-name> --current-replicas=2

# Autoscale
kubectl autoscale deployment/<deployment-name> --min=2 --max=10 --cpu-percent=80

# Voir les HPA
kubectl get hpa
kubectl describe hpa <hpa-name>
```

## 🏷️ Labels et Annotations

```bash
# Ajouter un label
kubectl label pods <pod-name> environment=production

# Modifier un label existant
kubectl label pods <pod-name> environment=staging --overwrite

# Supprimer un label
kubectl label pods <pod-name> environment-

# Ajouter une annotation
kubectl annotate pods <pod-name> description="Web server"

# Supprimer une annotation
kubectl annotate pods <pod-name> description-

# Labelliser tous les pods d'un namespace
kubectl label pods --all environment=production -n <namespace>
```

## 🗑️ Suppression

```bash
# Supprimer avec grace period
kubectl delete pod <pod-name> --grace-period=30

# Force delete (attention!)
kubectl delete pod <pod-name> --force --grace-period=0

# Supprimer par label
kubectl delete pods -l app=nginx

# Supprimer toutes les ressources d'un namespace
kubectl delete all --all -n <namespace>

# Supprimer par fichier
kubectl delete -f <file.yaml>

# Dry run avant suppression
kubectl delete pod <pod-name> --dry-run=client
```

## 🔧 Patch et Edit

```bash
# Edit en ligne
kubectl edit deployment/<deployment-name>

# Patch JSON
kubectl patch deployment/<deployment-name> -p '{"spec":{"replicas":3}}'

# Patch strategic merge
kubectl patch deployment/<deployment-name> --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.20"}]}}}}'

# Patch JSON merge
kubectl patch deployment/<deployment-name> --type=merge -p '{"spec":{"replicas":5}}'

# Set resource requests/limits
kubectl set resources deployment/<deployment-name> -c=<container-name> --limits=cpu=200m,memory=512Mi --requests=cpu=100m,memory=256Mi

# Set environment variable
kubectl set env deployment/<deployment-name> APP_ENV=production

# Set service account
kubectl set serviceaccount deployment/<deployment-name> <sa-name>
```

## 🌐 Networking

```bash
# Voir les services et endpoints
kubectl get svc,ep

# Tester la résolution DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Voir les network policies
kubectl get networkpolicy
kubectl describe networkpolicy <policy-name>

# Voir les ingress
kubectl get ingress
kubectl describe ingress <ingress-name>
```

## 💾 Storage

```bash
# PersistentVolumes et Claims
kubectl get pv,pvc
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# StorageClasses
kubectl get storageclass
kubectl describe storageclass <sc-name>

# VolumeSnapshots (si supporté)
kubectl get volumesnapshots
kubectl get volumesnapshotclasses
```

## 🔬 Advanced Debugging

```bash
# Voir les API resources disponibles
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false

# Voir les API versions
kubectl api-versions

# Explain d'une resource
kubectl explain pod
kubectl explain pod.spec.containers
kubectl explain deployment.spec.strategy

# Validation d'un fichier sans l'appliquer
kubectl apply -f <file.yaml> --dry-run=client
kubectl apply -f <file.yaml> --dry-run=server

# Diff avant apply
kubectl diff -f <file.yaml>

# Voir les raw API calls
kubectl get pods -v=8

# Proxy vers l'API server
kubectl proxy --port=8080
# Puis: curl http://localhost:8080/api/v1/namespaces/default/pods

# Obtenir les certificats
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d

# Lister les resources sans RBAC permissions
kubectl get pods --as=system:serviceaccount:default:default
```

## 📦 Plugin et Extensions

```bash
# Installer krew (plugin manager)
kubectl krew install <plugin-name>

# Plugins utiles
kubectl krew install ctx      # Changer de contexte facilement
kubectl krew install ns       # Changer de namespace facilement
kubectl krew install tree     # Visualiser les owner references
kubectl krew install neat     # Nettoyer l'output YAML
kubectl krew install status   # Status détaillé des resources
kubectl krew install view-secret  # Décoder les secrets

# Utiliser un plugin
kubectl ctx                   # Voir et changer de contexte
kubectl ns                    # Voir et changer de namespace
kubectl tree deployment/<name>  # Voir l'arbre des ressources
```

## 🚨 Emergency Operations

```bash
# Cordon un node (ne plus scheduler de pods dessus)
kubectl cordon <node-name>

# Uncordon un node
kubectl uncordon <node-name>

# Drain un node (évacuer les pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Taint un node
kubectl taint nodes <node-name> key=value:NoSchedule

# Untaint un node
kubectl taint nodes <node-name> key:NoSchedule-

# Forcer la suppression d'un namespace bloqué
kubectl get namespace <namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
```

## 💡 Tips et Astuces

```bash
# Alias utiles dans .bashrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

# Autocomplétion
source <(kubectl completion bash)
complete -F __start_kubectl k

# Watch mode
watch kubectl get pods

# Ou avec kubectl
kubectl get pods --watch

# Output en couleur (avec bat ou moins)
kubectl get pods -o yaml | bat -l yaml

# Pretty print JSON
kubectl get pod <pod-name> -o json | jq .

# Compter les resources
kubectl get pods --no-headers | wc -l

# Obtenir toutes les images utilisées
kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Pods par node
kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name --all-namespaces

# Pods qui consomment le plus de CPU
kubectl top pods --all-namespaces | sort --reverse --key 3 --numeric | head -10
```

## 🎓 Scripts Utiles

### Get all resources in a namespace
```bash
#!/bin/bash
NAMESPACE=${1:-default}
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n $NAMESPACE
```

### Find pods not ready
```bash
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

### Resource usage summary
```bash
kubectl top nodes | awk 'NR>1 {cpu+=$3; mem+=$5} END {print "Total CPU:", cpu, "Total Memory:", mem}'
```

### Kill all pods in a namespace (attention!)
```bash
kubectl delete pods --all -n <namespace>
```

---

**Note :** Certaines commandes nécessitent des permissions spécifiques ou des features gates activées.
