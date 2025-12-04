# TP01 - Architecture Interne de Kubernetes

## 🎯 Objectifs pédagogiques

À la fin de ce TP, vous serez capable de :
- Comprendre l'architecture des composants du control plane
- Analyser le fonctionnement de etcd et sa structure de données
- Observer les communications entre les composants
- Débugger un cluster Kubernetes
- Identifier les points de défaillance et leur impact

## 📚 Prérequis

- Cluster Kubernetes fonctionnel (minikube, kind ou k3s)
- kubectl installé et configuré
- Accès SSH aux nodes (pour minikube/kind)
- crictl installé
- etcdctl installé

## ⏱️ Durée estimée

3-4 heures

## 📋 Partie 1 : Architecture du Control Plane

### 1.1 - Identifier les composants

```bash
# Lister tous les pods du control plane
kubectl get pods -n kube-system

# Observer les composants statiques
kubectl get pods -n kube-system -l tier=control-plane

# Examiner les logs de l'API server
kubectl logs -n kube-system kube-apiserver-<node-name>
```

**Questions :**
1. Quels sont les composants critiques du control plane ?
2. Combien d'instances de chaque composant avez-vous ?
3. Comment ces composants communiquent-ils entre eux ?

### 1.2 - Analyser l'API Server

```bash
# Voir la configuration de l'API server
kubectl get pod -n kube-system kube-apiserver-<node> -o yaml

# Identifier les flags de démarrage
kubectl describe pod -n kube-system kube-apiserver-<node>

# Tester l'API directement
kubectl proxy --port=8080 &
curl http://localhost:8080/api/v1/namespaces
```

**Exercice :**
- Identifiez le port d'écoute de l'API server
- Trouvez où sont stockés les certificats TLS
- Listez les API groups disponibles

### 1.3 - Observer le Scheduler

```bash
# Logs du scheduler
kubectl logs -n kube-system kube-scheduler-<node>

# Créer un pod avec des contraintes
kubectl apply -f pod-with-constraints.yaml

# Observer le scheduling
kubectl get events --sort-by='.lastTimestamp'
```

**Exercice :**
Créez un pod qui ne peut pas être schedulé et analysez pourquoi.

### 1.4 - Controller Manager

```bash
# Observer les controllers actifs
kubectl get pods -n kube-system | grep controller-manager

# Logs du controller manager
kubectl logs -n kube-system kube-controller-manager-<node>

# Lister les controllers
kubectl logs -n kube-system kube-controller-manager-<node> | grep "Starting"
```

**Questions :**
1. Combien de controllers sont actifs ?
2. Quel est le rôle du replication controller ?
3. Comment fonctionne le endpoint controller ?

## 📋 Partie 2 : Étude de etcd

### 2.1 - Connexion à etcd

```bash
# Pour minikube
minikube ssh
sudo su -

# Installer etcdctl si nécessaire
ETCD_VER=v3.5.9
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/

# Exporter les variables d'environnement
export ETCDCTL_API=3
export ETCDCTL_CACERT=/var/lib/minikube/certs/etcd/ca.crt
export ETCDCTL_CERT=/var/lib/minikube/certs/etcd/server.crt
export ETCDCTL_KEY=/var/lib/minikube/certs/etcd/server.key

# Vérifier la santé
etcdctl endpoint health
```

### 2.2 - Explorer les données

```bash
# Lister toutes les clés
etcdctl get / --prefix --keys-only

# Voir les namespaces
etcdctl get /registry/namespaces --prefix --keys-only

# Examiner un pod
etcdctl get /registry/pods/default/<pod-name>

# Compter les objets
etcdctl get /registry --prefix --keys-only | wc -l
```

**Exercice :**
1. Trouvez où sont stockés les secrets
2. Examinez la structure d'un deployment
3. Identifiez les données des ConfigMaps

### 2.3 - Backup et Restore de etcd

```bash
# Créer un backup
etcdctl snapshot save /tmp/etcd-backup.db

# Vérifier le backup
etcdctl snapshot status /tmp/etcd-backup.db

# Simuler une perte de données
kubectl delete namespace test-backup

# Restore (ATTENTION: en production, procédure plus complexe)
etcdctl snapshot restore /tmp/etcd-backup.db
```

## 📋 Partie 3 : Communications entre composants

### 3.1 - Observer le flux de création d'un Pod

```bash
# Activer le verbosity
kubectl apply -f test-pod.yaml -v=8

# Observer les events
kubectl get events -w &

# Créer un pod
kubectl run debug-pod --image=nginx

# Analyser les logs
kubectl logs -n kube-system kube-apiserver-<node> | grep debug-pod
kubectl logs -n kube-system kube-scheduler-<node> | grep debug-pod
kubectl logs -n kube-system kube-controller-manager-<node> | grep debug-pod
```

**Questions :**
1. Quel composant reçoit la requête en premier ?
2. Comment le scheduler est-il notifié ?
3. Quel est le rôle du kubelet dans ce processus ?

### 3.2 - Watch API

```bash
# Observer les changements en temps réel
kubectl get pods -w &

# Utiliser l'API directement
curl -v http://localhost:8080/api/v1/namespaces/default/pods?watch=true
```

## 📋 Partie 4 : Debugging avancé

### 4.1 - Utiliser crictl

```bash
# Lister les containers via CRI
crictl ps

# Inspecter un container
crictl inspect <container-id>

# Logs via crictl
crictl logs <container-id>

# Stats des containers
crictl stats
```

### 4.2 - Analyser les problèmes de réseau

```bash
# Vérifier les endpoints
kubectl get endpoints

# Tester la résolution DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Examiner les iptables
# (sur le node)
sudo iptables-save | grep <service-name>
```

### 4.3 - Performance du Control Plane

```bash
# Métriques de l'API server
kubectl get --raw /metrics | grep apiserver_request_duration

# Métriques de etcd
kubectl get --raw /metrics | grep etcd_

# Latency de l'API
kubectl get pods --v=6 2>&1 | grep "Request duration"
```

## 📋 Partie 5 : Scénarios de défaillance

### 5.1 - Simuler une panne de l'API Server

```bash
# Arrêter l'API server (minikube)
minikube ssh
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# Observer l'impact
kubectl get pods  # Doit échouer

# Restaurer
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

**Questions :**
- Que se passe-t-il pour les pods en cours d'exécution ?
- Les services sont-ils affectés ?
- Combien de temps pour la récupération ?

### 5.2 - Panne du Scheduler

```bash
# Désactiver le scheduler
kubectl scale deployment kube-scheduler -n kube-system --replicas=0

# Tenter de créer un pod
kubectl run test --image=nginx

# Observer
kubectl get pods
kubectl describe pod test
```

### 5.3 - Panne de etcd

```bash
# ATTENTION: Très destructif, uniquement en environnement de test
# Simuler une corruption
# Observer la récupération automatique ou restaurer depuis backup
```

## 🎓 Exercices avancés

### Exercice 1 : Audit complet
Créez un script qui génère un rapport complet sur :
- L'état de santé de tous les composants
- Les métriques de performance
- Les alertes potentielles

### Exercice 2 : Custom Scheduler
Comprenez comment fonctionnent les schedulers et préparez-vous au TP15 sur les custom schedulers.

### Exercice 3 : Monitoring du Control Plane
Configurez Prometheus pour monitorer les métriques du control plane.

## 🔍 Points clés à retenir

1. **API Server** : Point d'entrée unique, tous les composants communiquent via lui
2. **etcd** : Source de vérité, critique pour le cluster
3. **Scheduler** : Décisions d'affectation basées sur les ressources et contraintes
4. **Controller Manager** : Boucles de réconciliation pour maintenir l'état désiré
5. **Kubelet** : Agent sur chaque node, interface avec le container runtime

## 📚 Ressources complémentaires

- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [etcd Documentation](https://etcd.io/docs/)
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Debugging Kubernetes](https://kubernetes.io/docs/tasks/debug/)

## ✅ Validation

Vous avez terminé ce TP si vous pouvez :
- [ ] Expliquer le rôle de chaque composant du control plane
- [ ] Naviguer dans etcd et comprendre la structure des données
- [ ] Tracer le flux de création d'une ressource
- [ ] Debugger des problèmes au niveau du control plane
- [ ] Simuler et résoudre des pannes de composants

## 🚀 Prochaine étape

TP02 - Networking Avancé et CNI
