# Guide de Progression Kubernetes Expert

## 🎯 Comment utiliser ce repository

Ce guide vous aide à naviguer à travers les TP selon votre niveau et vos objectifs.

## 📊 Évaluation de votre niveau

### Niveau Intermédiaire (pré-requis)
Vous devriez maîtriser :
- [ ] Création et gestion de Pods, Deployments, Services
- [ ] ConfigMaps et Secrets de base
- [ ] Networking de base (ClusterIP, NodePort, LoadBalancer)
- [ ] Volumes et PersistentVolumeClaims
- [ ] Namespaces et ResourceQuotas
- [ ] Commandes kubectl essentielles

**Si ces concepts ne sont pas clairs, commencez par des ressources de base avant ces TP.**

### Test de niveau Avancé
Essayez de répondre à ces questions :
1. Expliquez le rôle de chaque composant du control plane
2. Quelle est la différence entre un ClusterRole et un Role ?
3. Comment fonctionne un NetworkPolicy ?
4. Qu'est-ce qu'un StatefulSet et quand l'utiliser ?
5. Comment configurer un HPA avec des custom metrics ?

**Si vous pouvez répondre à 4/5 questions, vous êtes prêt pour le niveau Avancé.**

### Test de niveau Expert
Essayez de répondre à ces questions :
1. Comment fonctionne la boucle de réconciliation d'un controller ?
2. Expliquez le pattern Operator et ses use cases
3. Qu'est-ce qu'un admission webhook et comment l'implémenter ?
4. Comment optimiser les performances d'etcd en production ?
5. Décrivez une stratégie de disaster recovery multi-région

**Si vous pouvez répondre à 4/5 questions, vous êtes prêt pour le niveau Expert.**

## 🛤️ Parcours recommandés

### Parcours 1 : DevOps Engineer
**Objectif :** Déployer et maintenir des applications en production

**Progression suggérée :**
1. TP02 - Networking Avancé (4-5h)
2. TP03 - Sécurité et RBAC (4h)
3. TP05 - Observabilité (5h)
4. TP07 - GitOps avec ArgoCD/Flux (4h)
5. TP08 - CI/CD Kubernetes-Native (4h)
6. TP13 - Disaster Recovery (4h)
7. TP14 - Sécurité Expert (5h)
8. TP16 - Chaos Engineering (4h)

**Durée totale estimée :** 34-35 heures

### Parcours 2 : Platform Engineer
**Objectif :** Créer et maintenir une plateforme interne

**Progression suggérée :**
1. TP01 - Architecture Interne (3-4h)
2. TP03 - Sécurité et RBAC (4h)
3. TP06 - Autoscaling Avancé (3h)
4. TP09 - Custom Controllers (6-8h)
5. TP15 - Extension de l'API (6h)
6. TP18 - Platform Engineering (6h)
7. TP12 - Performance Tuning (5h)
8. TP17 - Cost Optimization (4h)

**Durée totale estimée :** 37-42 heures

### Parcours 3 : Site Reliability Engineer (SRE)
**Objectif :** Assurer la fiabilité et la performance

**Progression suggérée :**
1. TP01 - Architecture Interne (3-4h)
2. TP05 - Observabilité (5h)
3. TP06 - Autoscaling Avancé (3h)
4. TP10 - Service Mesh Istio (6h)
5. TP12 - Performance Tuning (5h)
6. TP13 - Disaster Recovery (4h)
7. TP16 - Chaos Engineering (4h)
8. TP11 - Multi-Cluster (5h)

**Durée totale estimée :** 35-36 heures

### Parcours 4 : Security Engineer
**Objectif :** Sécuriser un cluster et les applications

**Progression suggérée :**
1. TP01 - Architecture Interne (3-4h)
2. TP02 - Networking Avancé (4-5h)
3. TP03 - Sécurité et RBAC (4h)
4. TP14 - Sécurité Expert (5h)
5. TP09 - Custom Controllers (6-8h) *pour comprendre admission webhooks*
6. TP10 - Service Mesh Istio (6h) *pour mTLS et policies*

**Durée totale estimée :** 28-32 heures

### Parcours 5 : Complet (Architecte Kubernetes)
**Objectif :** Maîtriser tous les aspects de Kubernetes

**Progression suggérée (ordre optimal) :**

**Phase 1 - Fondations Avancées (16-18h)**
1. TP01 - Architecture Interne
2. TP02 - Networking Avancé
3. TP03 - Sécurité et RBAC
4. TP04 - Stockage Avancé

**Phase 2 - Opérations (16-17h)**
5. TP05 - Observabilité
6. TP06 - Autoscaling
7. TP07 - GitOps
8. TP08 - CI/CD

**Phase 3 - Expertise Technique (22-25h)**
9. TP09 - Custom Controllers
10. TP10 - Service Mesh
11. TP11 - Multi-Cluster
12. TP12 - Performance Tuning

**Phase 4 - Production Readiness (19h)**
13. TP13 - Disaster Recovery
14. TP14 - Sécurité Expert
15. TP16 - Chaos Engineering
16. TP17 - Cost Optimization

**Phase 5 - Platform (12h)**
17. TP15 - Extension de l'API
18. TP18 - Platform Engineering

**Durée totale estimée :** 85-91 heures (environ 3 mois à temps partiel)

## 📅 Planning de formation

### Format intensif (2 semaines à temps plein)
- **Semaine 1 :** TP01 à TP08 (niveau avancé)
- **Semaine 2 :** TP09 à TP18 (niveau expert, sélection)
- **Objectif :** Certification CKAD/CKA préparation

### Format temps partiel (3 mois)
- **1 TP par semaine**
- **4-6h d'étude par semaine**
- **Pratique et approfondissement**

### Format modulaire (selon besoins)
Choisissez les TP selon vos objectifs professionnels immédiats.

## 🎯 Objectifs par certification

### CKA (Certified Kubernetes Administrator)
**TP essentiels :**
- TP01 - Architecture Interne
- TP02 - Networking Avancé
- TP03 - Sécurité et RBAC
- TP04 - Stockage Avancé
- TP13 - Disaster Recovery

### CKAD (Certified Kubernetes Application Developer)
**TP essentiels :**
- TP02 - Networking Avancé (NetworkPolicies)
- TP03 - Sécurité (RBAC, SecurityContext)
- TP05 - Observabilité
- TP07 - GitOps
- TP08 - CI/CD

### CKS (Certified Kubernetes Security Specialist)
**TP essentiels :**
- TP01 - Architecture Interne
- TP02 - Networking (NetworkPolicies)
- TP03 - Sécurité et RBAC
- TP14 - Sécurité Expert
- TP09 - Custom Controllers (admission webhooks)

## 💡 Conseils de progression

### 1. Préparation
- Installez tous les outils nécessaires avant de commencer
- Configurez un cluster de test (minikube, kind, ou k3s)
- Ayez un environnement de développement confortable

### 2. Pendant les TP
- **Ne pas copier-coller aveuglément** : Comprenez chaque commande
- **Prenez des notes** : Documentez ce que vous apprenez
- **Expérimentez** : Testez des variantes, cassez des choses
- **Utilisez la documentation** : Habituez-vous à chercher dans docs.kubernetes.io

### 3. Après chaque TP
- **Faites tous les exercices avancés** : Pas seulement la partie guidée
- **Créez votre propre projet** : Appliquez les concepts appris
- **Partagez** : Expliquez à quelqu'un ou écrivez un article
- **Nettoyez votre cluster** : Repartez sur une base saine

### 4. Validation des acquis
Chaque TP a une checklist de validation. Ne passez au suivant que si vous avez coché tous les items.

## 🔧 Setup de l'environnement

### Option 1 : Local avec kind
```bash
# Installer kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Créer un cluster
kind create cluster --name k8s-expert
```

### Option 2 : Local avec minikube
```bash
# Installer minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Démarrer
minikube start --cpus=4 --memory=8192 --driver=docker
```

### Option 3 : Cloud (recommandé pour TP experts)
- **GKE** : Google Kubernetes Engine (crédits gratuits)
- **EKS** : Amazon Elastic Kubernetes Service
- **AKS** : Azure Kubernetes Service
- **Civo** : Clusters Kubernetes économiques

### Outils essentiels
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k9s (optionnel mais recommandé)
curl -sS https://webinstall.dev/k9s | bash

# kubectx et kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

## 📈 Suivi de progression

Créez un fichier `progression.md` personnel :

```markdown
# Ma Progression Kubernetes Expert

## Objectif
[Votre objectif : certification, promotion, projet, etc.]

## TP Complétés

### Niveau Avancé
- [ ] TP01 - Architecture Interne - Date: ___ - Notes: ___
- [ ] TP02 - Networking - Date: ___ - Notes: ___
- [ ] TP03 - Sécurité RBAC - Date: ___ - Notes: ___
...

### Niveau Expert
- [ ] TP09 - Custom Controllers - Date: ___ - Notes: ___
...

## Projets personnels
- [ ] Projet 1: ___
- [ ] Projet 2: ___

## Difficultés rencontrées
- ...

## Learnings clés
- ...
```

## 🤝 Communauté et support

- **Questions :** Ouvrez une issue sur GitHub
- **Discussions :** Utilisez les Discussions GitHub
- **Contributions :** PRs bienvenues !
- **Slack Kubernetes :** kubernetes.slack.com

## 📚 Ressources complémentaires

### Documentation officielle
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

### Livres recommandés
- "Kubernetes in Action" par Marko Lukša
- "Programming Kubernetes" par Michael Hausenblas
- "Kubernetes Patterns" par Bilgin Ibryam

### Blogs et articles
- [Kubernetes Blog](https://kubernetes.io/blog/)
- [CNCF Blog](https://www.cncf.io/blog/)
- [Learnk8s](https://learnk8s.io/blog)

### Vidéos et talks
- [KubeCon talks](https://www.youtube.com/c/cloudnativefdn)
- [TGI Kubernetes](https://www.youtube.com/watch?v=9YYeE-bMWv8&list=PL7bmigfV0EqQzxcNpmcdTJ9eFRPBe-iZa)

## 🎖️ Certifications

Après avoir complété les TP appropriés :

1. **CKA** : kubernetes.io/training/certification/cka/
2. **CKAD** : kubernetes.io/training/certification/ckad/
3. **CKS** : kubernetes.io/training/certification/cks/

## ✨ Prochaines étapes après les TP

1. **Contribuer à l'open source**
   - Kubernetes
   - Projets CNCF
   - Operators community

2. **Construire votre portfolio**
   - GitHub avec vos projets
   - Blog technique
   - Talks/présentations

3. **Partager vos connaissances**
   - Mentoring
   - Writing
   - Speaking

---

**Bonne chance dans votre parcours d'apprentissage ! 🚀**
