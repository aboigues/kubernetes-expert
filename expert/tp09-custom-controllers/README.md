# TP09 - Custom Controllers et Operators

## 🎯 Objectifs pédagogiques

À la fin de ce TP, vous serez capable de :
- Comprendre le pattern Operator et son utilité
- Développer un custom controller avec kubebuilder
- Créer des CRDs (Custom Resource Definitions)
- Implémenter des boucles de réconciliation robustes
- Gérer les finalizers et le garbage collection
- Créer des webhooks d'admission et de validation
- Déployer et tester un operator complet

## 📚 Prérequis

- Cluster Kubernetes (1.25+)
- Go 1.21+ installé
- kubebuilder ou operator-sdk
- kubectl avec accès admin
- Git
- Docker ou Podman
- Compréhension de Go et des API Kubernetes

## ⏱️ Durée estimée

6-8 heures

## 📋 Partie 1 : Comprendre le Pattern Operator

### 1.1 - Concepts fondamentaux

**Qu'est-ce qu'un Operator ?**
Un Operator est une extension de Kubernetes qui utilise des custom resources pour gérer des applications et leurs composants de manière automatisée.

**Composants clés :**
- **CRD** : Définit le schéma de la custom resource
- **Controller** : Logique de réconciliation
- **Webhooks** : Validation et mutation des ressources

### 1.2 - Cas d'usage typiques

- Déploiement et gestion de bases de données (PostgreSQL, MongoDB)
- Configuration automatique d'applications complexes
- Gestion du cycle de vie (backup, restore, upgrade)
- Intégration avec des services externes
- Automatisation d'opérations complexes

## 📋 Partie 2 : Setup de l'environnement

### 2.1 - Installation de kubebuilder

```bash
# Installer kubebuilder
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder
sudo mv kubebuilder /usr/local/bin/

# Vérifier l'installation
kubebuilder version
```

### 2.2 - Créer un nouveau projet

```bash
# Créer le répertoire du projet
mkdir webapp-operator
cd webapp-operator

# Initialiser le projet
kubebuilder init --domain example.com --repo github.com/myorg/webapp-operator

# Examiner la structure
tree .
```

**Structure générée :**
```
.
├── Dockerfile
├── Makefile
├── PROJECT
├── README.md
├── cmd/
│   └── main.go
├── config/
│   ├── default/
│   ├── manager/
│   ├── prometheus/
│   └── rbac/
├── go.mod
├── go.sum
└── hack/
```

## 📋 Partie 3 : Créer une Custom Resource

### 3.1 - Définir l'API

**Scénario :** Créer un Operator pour gérer des applications web avec :
- Déploiement automatique
- Service et Ingress
- ConfigMap et Secret
- Autoscaling optionnel

```bash
# Créer l'API
kubebuilder create api \
  --group apps \
  --version v1alpha1 \
  --kind WebApp

# Répondre 'y' aux deux questions (Create Resource et Create Controller)
```

### 3.2 - Définir le schéma de la CRD

```go
// api/v1alpha1/webapp_types.go
package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebAppSpec définit l'état désiré de WebApp
type WebAppSpec struct {
	// Image du container à déployer
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern=`^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*:[a-z0-9]+([._-][a-z0-9]+)*$`
	Image string `json:"image"`

	// Nombre de replicas
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=100
	// +kubebuilder:default=1
	Replicas *int32 `json:"replicas,omitempty"`

	// Port exposé par l'application
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=65535
	// +kubebuilder:default=8080
	Port *int32 `json:"port,omitempty"`

	// Variables d'environnement
	// +optional
	Env []EnvVar `json:"env,omitempty"`

	// Configuration de l'Ingress
	// +optional
	Ingress *IngressConfig `json:"ingress,omitempty"`

	// Configuration de l'autoscaling
	// +optional
	Autoscaling *AutoscalingConfig `json:"autoscaling,omitempty"`

	// Resources (CPU/Memory)
	// +optional
	Resources *ResourceRequirements `json:"resources,omitempty"`
}

type EnvVar struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type IngressConfig struct {
	// Activer l'Ingress
	Enabled bool `json:"enabled"`

	// Hostname pour l'Ingress
	Host string `json:"host,omitempty"`

	// TLS configuration
	TLS bool `json:"tls,omitempty"`

	// Annotations supplémentaires
	Annotations map[string]string `json:"annotations,omitempty"`
}

type AutoscalingConfig struct {
	// Activer l'HPA
	Enabled bool `json:"enabled"`

	// Nombre minimum de replicas
	// +kubebuilder:validation:Minimum=1
	MinReplicas *int32 `json:"minReplicas,omitempty"`

	// Nombre maximum de replicas
	// +kubebuilder:validation:Minimum=1
	MaxReplicas *int32 `json:"maxReplicas,omitempty"`

	// Target CPU utilization (%)
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=100
	TargetCPUUtilization *int32 `json:"targetCPUUtilization,omitempty"`
}

type ResourceRequirements struct {
	Limits   ResourceList `json:"limits,omitempty"`
	Requests ResourceList `json:"requests,omitempty"`
}

type ResourceList struct {
	CPU    string `json:"cpu,omitempty"`
	Memory string `json:"memory,omitempty"`
}

// WebAppStatus définit l'état observé de WebApp
type WebAppStatus struct {
	// Phase actuelle de l'application
	// +kubebuilder:validation:Enum=Pending;Creating;Running;Failed;Updating
	Phase string `json:"phase,omitempty"`

	// Conditions représentent l'état de différents aspects
	Conditions []metav1.Condition `json:"conditions,omitempty"`

	// Nombre de replicas disponibles
	AvailableReplicas int32 `json:"availableReplicas,omitempty"`

	// URL d'accès (si Ingress activé)
	URL string `json:"url,omitempty"`

	// Dernière mise à jour
	LastUpdateTime *metav1.Time `json:"lastUpdateTime,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:subresource:scale:specpath=.spec.replicas,statuspath=.status.availableReplicas
// +kubebuilder:printcolumn:name="Image",type=string,JSONPath=`.spec.image`
// +kubebuilder:printcolumn:name="Replicas",type=integer,JSONPath=`.spec.replicas`
// +kubebuilder:printcolumn:name="Available",type=integer,JSONPath=`.status.availableReplicas`
// +kubebuilder:printcolumn:name="Phase",type=string,JSONPath=`.status.phase`
// +kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`

// WebApp est le schéma de l'API pour la ressource WebApp
type WebApp struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   WebAppSpec   `json:"spec,omitempty"`
	Status WebAppStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// WebAppList contient une liste de WebApp
type WebAppList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []WebApp `json:"items"`
}

func init() {
	SchemeBuilder.Register(&WebApp{}, &WebAppList{})
}
```

### 3.3 - Générer les manifests

```bash
# Générer le code et les CRDs
make generate
make manifests

# Examiner la CRD générée
cat config/crd/bases/apps.example.com_webapps.yaml
```

## 📋 Partie 4 : Implémenter le Controller

### 4.1 - Logique de réconciliation

```go
// internal/controller/webapp_controller.go
package controller

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	appsv1alpha1 "github.com/myorg/webapp-operator/api/v1alpha1"
)

const (
	webappFinalizer = "apps.example.com/finalizer"
)

// WebAppReconciler réconcilie un objet WebApp
type WebAppReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=apps.example.com,resources=webapps,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=apps.example.com,resources=webapps/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=apps.example.com,resources=webapps/finalizers,verbs=update
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=networking.k8s.io,resources=ingresses,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=autoscaling,resources=horizontalpodautoscalers,verbs=get;list;watch;create;update;patch;delete

func (r *WebAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)
	log.Info("Reconciling WebApp", "namespace", req.Namespace, "name", req.Name)

	// Récupérer l'instance WebApp
	webapp := &appsv1alpha1.WebApp{}
	err := r.Get(ctx, req.NamespacedName, webapp)
	if err != nil {
		if errors.IsNotFound(err) {
			log.Info("WebApp resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		log.Error(err, "Failed to get WebApp")
		return ctrl.Result{}, err
	}

	// Gérer la suppression avec finalizers
	if webapp.ObjectMeta.DeletionTimestamp != nil {
		if controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
			// Nettoyage des ressources
			if err := r.cleanupResources(ctx, webapp); err != nil {
				return ctrl.Result{}, err
			}

			// Supprimer le finalizer
			controllerutil.RemoveFinalizer(webapp, webappFinalizer)
			err := r.Update(ctx, webapp)
			if err != nil {
				return ctrl.Result{}, err
			}
		}
		return ctrl.Result{}, nil
	}

	// Ajouter le finalizer s'il n'existe pas
	if !controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
		controllerutil.AddFinalizer(webapp, webappFinalizer)
		err = r.Update(ctx, webapp)
		if err != nil {
			return ctrl.Result{}, err
		}
	}

	// Mettre à jour le statut en "Creating"
	if webapp.Status.Phase == "" {
		webapp.Status.Phase = "Creating"
		if err := r.Status().Update(ctx, webapp); err != nil {
			log.Error(err, "Failed to update WebApp status")
			return ctrl.Result{}, err
		}
	}

	// Créer ou mettre à jour le Deployment
	if err := r.reconcileDeployment(ctx, webapp); err != nil {
		log.Error(err, "Failed to reconcile Deployment")
		r.updateStatus(ctx, webapp, "Failed", err.Error())
		return ctrl.Result{}, err
	}

	// Créer ou mettre à jour le Service
	if err := r.reconcileService(ctx, webapp); err != nil {
		log.Error(err, "Failed to reconcile Service")
		r.updateStatus(ctx, webapp, "Failed", err.Error())
		return ctrl.Result{}, err
	}

	// Créer ou mettre à jour l'Ingress si activé
	if webapp.Spec.Ingress != nil && webapp.Spec.Ingress.Enabled {
		if err := r.reconcileIngress(ctx, webapp); err != nil {
			log.Error(err, "Failed to reconcile Ingress")
			return ctrl.Result{}, err
		}
	}

	// Créer ou mettre à jour l'HPA si activé
	if webapp.Spec.Autoscaling != nil && webapp.Spec.Autoscaling.Enabled {
		if err := r.reconcileHPA(ctx, webapp); err != nil {
			log.Error(err, "Failed to reconcile HPA")
			return ctrl.Result{}, err
		}
	}

	// Mettre à jour le statut final
	if err := r.updateFinalStatus(ctx, webapp); err != nil {
		return ctrl.Result{}, err
	}

	return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
}

func (r *WebAppReconciler) reconcileDeployment(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	deployment := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{Name: webapp.Name, Namespace: webapp.Namespace}, deployment)

	labels := map[string]string{
		"app":        webapp.Name,
		"managed-by": "webapp-operator",
	}

	replicas := int32(1)
	if webapp.Spec.Replicas != nil {
		replicas = *webapp.Spec.Replicas
	}

	port := int32(8080)
	if webapp.Spec.Port != nil {
		port = *webapp.Spec.Port
	}

	// Construire les variables d'environnement
	envVars := []corev1.EnvVar{}
	for _, env := range webapp.Spec.Env {
		envVars = append(envVars, corev1.EnvVar{
			Name:  env.Name,
			Value: env.Value,
		})
	}

	// Définir le Deployment désiré
	desiredDeployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      webapp.Name,
			Namespace: webapp.Namespace,
			Labels:    labels,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  webapp.Name,
							Image: webapp.Spec.Image,
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: port,
									Name:          "http",
								},
							},
							Env: envVars,
						},
					},
				},
			},
		},
	}

	// Ajouter les resources si spécifiées
	if webapp.Spec.Resources != nil {
		resources := corev1.ResourceRequirements{}
		if webapp.Spec.Resources.Requests.CPU != "" || webapp.Spec.Resources.Requests.Memory != "" {
			resources.Requests = corev1.ResourceList{}
			if webapp.Spec.Resources.Requests.CPU != "" {
				resources.Requests[corev1.ResourceCPU] = *resource.NewQuantity(webapp.Spec.Resources.Requests.CPU, resource.DecimalSI)
			}
			if webapp.Spec.Resources.Requests.Memory != "" {
				resources.Requests[corev1.ResourceMemory] = *resource.NewQuantity(webapp.Spec.Resources.Requests.Memory, resource.BinarySI)
			}
		}
		// Similar pour Limits...
		desiredDeployment.Spec.Template.Spec.Containers[0].Resources = resources
	}

	// Définir WebApp comme owner du Deployment
	if err := controllerutil.SetControllerReference(webapp, desiredDeployment, r.Scheme); err != nil {
		return err
	}

	if errors.IsNotFound(err) {
		// Créer le Deployment
		return r.Create(ctx, desiredDeployment)
	} else if err != nil {
		return err
	}

	// Mettre à jour le Deployment existant
	deployment.Spec = desiredDeployment.Spec
	return r.Update(ctx, deployment)
}

func (r *WebAppReconciler) reconcileService(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	service := &corev1.Service{}
	err := r.Get(ctx, types.NamespacedName{Name: webapp.Name, Namespace: webapp.Namespace}, service)

	labels := map[string]string{
		"app":        webapp.Name,
		"managed-by": "webapp-operator",
	}

	port := int32(8080)
	if webapp.Spec.Port != nil {
		port = *webapp.Spec.Port
	}

	desiredService := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      webapp.Name,
			Namespace: webapp.Namespace,
			Labels:    labels,
		},
		Spec: corev1.ServiceSpec{
			Selector: labels,
			Ports: []corev1.ServicePort{
				{
					Port:       80,
					TargetPort: intstr.FromInt(int(port)),
					Name:       "http",
				},
			},
			Type: corev1.ServiceTypeClusterIP,
		},
	}

	if err := controllerutil.SetControllerReference(webapp, desiredService, r.Scheme); err != nil {
		return err
	}

	if errors.IsNotFound(err) {
		return r.Create(ctx, desiredService)
	} else if err != nil {
		return err
	}

	service.Spec = desiredService.Spec
	return r.Update(ctx, service)
}

func (r *WebAppReconciler) reconcileIngress(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	// Implementation similaire pour Ingress
	// ... (code omis pour la brièveté)
	return nil
}

func (r *WebAppReconciler) reconcileHPA(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	// Implementation similaire pour HPA
	// ... (code omis pour la brièveté)
	return nil
}

func (r *WebAppReconciler) updateFinalStatus(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	// Récupérer le deployment pour obtenir le nombre de replicas
	deployment := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{Name: webapp.Name, Namespace: webapp.Namespace}, deployment)
	if err != nil {
		return err
	}

	webapp.Status.AvailableReplicas = deployment.Status.AvailableReplicas
	webapp.Status.Phase = "Running"

	if webapp.Spec.Ingress != nil && webapp.Spec.Ingress.Enabled {
		webapp.Status.URL = fmt.Sprintf("http://%s", webapp.Spec.Ingress.Host)
		if webapp.Spec.Ingress.TLS {
			webapp.Status.URL = fmt.Sprintf("https://%s", webapp.Spec.Ingress.Host)
		}
	}

	now := metav1.Now()
	webapp.Status.LastUpdateTime = &now

	return r.Status().Update(ctx, webapp)
}

func (r *WebAppReconciler) updateStatus(ctx context.Context, webapp *appsv1alpha1.WebApp, phase, message string) {
	webapp.Status.Phase = phase
	r.Status().Update(ctx, webapp)
}

func (r *WebAppReconciler) cleanupResources(ctx context.Context, webapp *appsv1alpha1.WebApp) error {
	// Cleanup personnalisé si nécessaire
	// Les ressources avec OwnerReference seront automatiquement supprimées
	return nil
}

// SetupWithManager configure le controller avec le Manager
func (r *WebAppReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&appsv1alpha1.WebApp{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Owns(&networkingv1.Ingress{}).
		Owns(&autoscalingv2.HorizontalPodAutoscaler{}).
		Complete(r)
}
```

## 📋 Partie 5 : Webhooks de validation

### 5.1 - Créer un validating webhook

```bash
kubebuilder create webhook \
  --group apps \
  --version v1alpha1 \
  --kind WebApp \
  --defaulting \
  --programmatic-validation
```

### 5.2 - Implémenter la validation

```go
// api/v1alpha1/webapp_webhook.go
package v1alpha1

import (
	"fmt"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

var webapplog = logf.Log.WithName("webapp-resource")

func (r *WebApp) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

// +kubebuilder:webhook:path=/mutate-apps-example-com-v1alpha1-webapp,mutating=true,failurePolicy=fail,groups=apps.example.com,resources=webapps,verbs=create;update,versions=v1alpha1,name=mwebapp.kb.io,sideEffects=None,admissionReviewVersions=v1

var _ webhook.Defaulter = &WebApp{}

// Default implémente webhook.Defaulter
func (r *WebApp) Default() {
	webapplog.Info("default", "name", r.Name)

	// Valeurs par défaut
	if r.Spec.Replicas == nil {
		replicas := int32(1)
		r.Spec.Replicas = &replicas
	}

	if r.Spec.Port == nil {
		port := int32(8080)
		r.Spec.Port = &port
	}

	if r.Spec.Autoscaling != nil && r.Spec.Autoscaling.Enabled {
		if r.Spec.Autoscaling.MinReplicas == nil {
			minReplicas := int32(1)
			r.Spec.Autoscaling.MinReplicas = &minReplicas
		}
		if r.Spec.Autoscaling.MaxReplicas == nil {
			maxReplicas := int32(10)
			r.Spec.Autoscaling.MaxReplicas = &maxReplicas
		}
		if r.Spec.Autoscaling.TargetCPUUtilization == nil {
			cpu := int32(80)
			r.Spec.Autoscaling.TargetCPUUtilization = &cpu
		}
	}
}

// +kubebuilder:webhook:path=/validate-apps-example-com-v1alpha1-webapp,mutating=false,failurePolicy=fail,groups=apps.example.com,resources=webapps,verbs=create;update,versions=v1alpha1,name=vwebapp.kb.io,sideEffects=None,admissionReviewVersions=v1

var _ webhook.Validator = &WebApp{}

// ValidateCreate implémente webhook.Validator
func (r *WebApp) ValidateCreate() (admission.Warnings, error) {
	webapplog.Info("validate create", "name", r.Name)
	return nil, r.validateWebApp()
}

// ValidateUpdate implémente webhook.Validator
func (r *WebApp) ValidateUpdate(old runtime.Object) (admission.Warnings, error) {
	webapplog.Info("validate update", "name", r.Name)
	return nil, r.validateWebApp()
}

// ValidateDelete implémente webhook.Validator
func (r *WebApp) ValidateDelete() (admission.Warnings, error) {
	webapplog.Info("validate delete", "name", r.Name)
	return nil, nil
}

func (r *WebApp) validateWebApp() error {
	// Validation de l'image
	if r.Spec.Image == "" {
		return fmt.Errorf("image is required")
	}

	// Validation autoscaling
	if r.Spec.Autoscaling != nil && r.Spec.Autoscaling.Enabled {
		if r.Spec.Autoscaling.MinReplicas != nil && r.Spec.Autoscaling.MaxReplicas != nil {
			if *r.Spec.Autoscaling.MinReplicas > *r.Spec.Autoscaling.MaxReplicas {
				return fmt.Errorf("minReplicas cannot be greater than maxReplicas")
			}
		}
	}

	// Validation Ingress
	if r.Spec.Ingress != nil && r.Spec.Ingress.Enabled {
		if r.Spec.Ingress.Host == "" {
			return fmt.Errorf("ingress host is required when ingress is enabled")
		}
	}

	return nil
}
```

## 📋 Partie 6 : Déploiement et Tests

### 6.1 - Construire et déployer

```bash
# Installer les CRDs
make install

# Lancer le controller localement pour les tests
make run

# Dans un autre terminal, tester
kubectl apply -f config/samples/
```

### 6.2 - Créer une instance de test

```yaml
# config/samples/apps_v1alpha1_webapp.yaml
apiVersion: apps.example.com/v1alpha1
kind: WebApp
metadata:
  name: webapp-sample
  namespace: default
spec:
  image: nginx:1.25
  replicas: 3
  port: 80
  env:
    - name: ENV
      value: production
  ingress:
    enabled: true
    host: webapp.example.com
    tls: true
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilization: 70
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

```bash
# Appliquer la ressource
kubectl apply -f config/samples/apps_v1alpha1_webapp.yaml

# Observer la réconciliation
kubectl get webapp
kubectl describe webapp webapp-sample

# Vérifier les ressources créées
kubectl get deployment,service,ingress,hpa
```

### 6.3 - Construire l'image Docker

```bash
# Construire l'image
make docker-build IMG=myregistry/webapp-operator:v1.0.0

# Push l'image
make docker-push IMG=myregistry/webapp-operator:v1.0.0

# Déployer dans le cluster
make deploy IMG=myregistry/webapp-operator:v1.0.0
```

### 6.4 - Vérifier le déploiement

```bash
# Vérifier le controller
kubectl get pods -n webapp-operator-system

# Voir les logs
kubectl logs -n webapp-operator-system deployment/webapp-operator-controller-manager

# Tester les webhooks
kubectl apply -f - <<EOF
apiVersion: apps.example.com/v1alpha1
kind: WebApp
metadata:
  name: invalid-webapp
spec:
  image: ""  # Devrait être rejeté
EOF
```

## 🎓 Exercices avancés

### Exercice 1 : Ajout de fonctionnalités
Étendre le controller pour supporter :
- Backup automatique avec CronJobs
- Health checks configurables
- InitContainers
- Sidecar containers

### Exercice 2 : Observabilité
Ajouter :
- Métriques Prometheus custom
- Events Kubernetes détaillés
- Logging structuré avec différents niveaux

### Exercice 3 : Tests
Implémenter :
- Unit tests pour le controller
- Integration tests avec envtest
- E2E tests dans un cluster réel

### Exercice 4 : Opérations avancées
Implémenter :
- Rolling updates avec stratégies custom
- Blue-green deployments
- Canary releases
- Rollback automatique en cas d'erreur

## 🔍 Points clés à retenir

1. **Boucle de réconciliation** : Idempotente et robuste
2. **Finalizers** : Cleanup proper des ressources
3. **OwnerReferences** : Gestion automatique du lifecycle
4. **Webhooks** : Validation et mutation avant persistence
5. **Status** : Toujours refléter l'état réel
6. **RBAC** : Permissions minimales nécessaires

## 📚 Ressources complémentaires

- [Kubebuilder Book](https://book.kubebuilder.io/)
- [Operator SDK](https://sdk.operatorframework.io/)
- [Kubernetes API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Controller Runtime](https://github.com/kubernetes-sigs/controller-runtime)
- [Operator Best Practices](https://sdk.operatorframework.io/docs/best-practices/)

## ✅ Validation

- [ ] CRD créée avec validation schema
- [ ] Controller implémenté avec réconciliation complète
- [ ] Webhooks de validation et mutation fonctionnels
- [ ] Finalizers implémentés correctement
- [ ] Tests unitaires et d'intégration écrits
- [ ] Operator déployé et fonctionnel dans un cluster
- [ ] Documentation complète du CRD

## 🚀 Prochaine étape

TP10 - Service Mesh Avancé (Istio)
