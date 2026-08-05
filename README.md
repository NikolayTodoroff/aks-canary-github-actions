# aks-canary-github-actions-infra

A two-tier voting application deployed on Azure Kubernetes Service using a canary deployment strategy, GitHub Actions pipelines with OIDC authentication, and Helm for application packaging.

---

## Highlights

- AKS cluster with system and user node pools, Azure CNI Overlay networking, and Azure AD-integrated RBAC
- Canary deployment pattern implemented with two separate Helm releases sharing one Kubernetes Service via label selectors
- Readiness and liveness probes on both stable and canary tracks, ensuring pods only receive traffic once genuinely healthy
- GitHub Actions pipeline with OIDC authentication (no stored credentials), reusable workflows, and SHA-tagged images per commit
- Separate `setup-ingress` jobs install nginx-ingress as a dedicated cluster-level release before any app deployment — clean boundary between cluster infrastructure and application releases
- Terraform infrastructure workflow using the Validate → Plan → Apply pattern
- Horizontal Pod Autoscaler on the stable track only — canary replica count is always a deliberate human decision, never automated

---

## Repository Structure

```
aks-canary-github-actions-infra/
├── .github/
│   └── workflows/
│       ├── application.yml          
│       ├── reusable-deploy.yml     
│       ├── infrastructure.yml            
│       ├── reusable-infra.yml   
│       └── promote.yml              
├── app/
│   └── azure-vote/                  
├── helm/
│   └── voting-app/
│       ├── Chart.yaml
│       ├── values.yml
│       ├── values-dev.yml
│       ├── values-prod.yml
│       └── templates/
│           ├── stable-deployment.yml
│           ├── canary-deployment.yml
│           ├── service.yml
│           ├── ingress.yml
│           ├── redis-deployment.yml
│           ├── redis-pvc.yml
│           ├── redis-service.yml
│           ├── hpa.yml
│           ├── role.yml
│           ├── rolebinding.yml
│           ├── clusterrole.yml
│           ├── clusterrolebinding.yml
│           └── NOTES.txt
├── infra/
│   ├── main/
│   ├── modules/
│   │   ├── aks/
│   │   ├── container-registry/
│   │   └── monitoring/
│   └── env/
├── scripts/
│   ├── bootstrap.sh
│   └── assign-roles.ps1
└── README.md
```

---

## Canary Architecture

```
Internet
    → Azure Load Balancer (auto-provisioned, L4)
    → nginx Ingress Controller (L7, separate Helm release: ingress-nginx)
    → voting-app Service (selector: app=voting-app, matches ALL pods)
    → voting-app-stable pods (track=stable, N replicas)
    → voting-app-canary pods  (track=canary, 1 replica)
    → Redis Service (ClusterIP)
    → Redis Pod → Azure Disk (PVC)
```

The traffic split is achieved purely through replica count — no service mesh, no weighted routing rules. With 4 stable replicas and 1 canary replica, approximately 80% of traffic hits stable and 20% hits canary.

**Why two separate Helm releases:**
Each release owns exactly its own resources. `--wait` on `voting-app-stable` only watches stable pods. `--wait` on `voting-app-canary` only watches canary pods. No cross-track resource ownership means no Helm ownership conflicts, no orphaned resources from one track blocking the other, and no timeout caused by the other track's health state.

**Shared resources** (Redis, PVC, Service, Ingress) live in the `voting-app-stable` release only, guarded by `{{- if eq .Values.track "stable" }}` in their templates. The canary release contains only the canary Deployment.

---

## CI/CD Architecture

### Application Pipeline

```
build
  └── Docker build → push SHA tag to dev ACR + prod ACR
        ↓
setup-ingress-dev          setup-ingress-prod (if prod deploy requested)
  └── helm upgrade          └── helm upgrade
      ingress-nginx             ingress-nginx
        ↓                         ↓
deploy-dev                 deploy-prod-stable / deploy-prod-canary
  └── helm upgrade              └── helm upgrade
      voting-app-stable             voting-app-{track}
      (dev, SHA tag)                (prod, SHA tag, approval gate)
```

**Canary promotion** (`promote.yml`) — manually triggered, requires the canary's commit SHA as input. Calls the reusable deploy workflow with `deployment-track: stable`, updating the stable release to run the validated canary image.

### Infrastructure Pipeline (`terraform.yml`)

```
Validate → Plan → Apply
```

Parameterized by `environment` (dev/prod) and `terraform_action` (plan/apply). Uses the same Validate → Plan → Apply separation, translated to GitHub Actions syntax.

---

## Key Design Decisions

- **Separate Helm releases for stable and canary.** Stable and canary are deployed as independent Helm releases rather than a single release. This gives each deployment its own lifecycle and ownership boundary, preventing `helm upgrade --wait` from being blocked by resources belonging to the other track and allowing each release to be upgraded or rolled back independently.

- **Dedicated ingress controller release.** The NGINX Ingress Controller is cluster infrastructure, not part of the application. It is installed once as its own `ingress-nginx` Helm release by dedicated pipeline jobs rather than as a dependency of the application chart. This avoids Helm ownership conflicts and gives the ingress controller an independent lifecycle.

- **Immutable image versioning with Git commit SHAs.** Every container image is tagged with `github.sha`, providing a unique, immutable version for every build. Using immutable tags eliminates stale image issues caused by Kubernetes node caching and makes every deployment fully traceable to a specific commit.

- **Horizontal Pod Autoscaler only for the stable release.** The stable deployment scales automatically under production load, while the canary deployment always runs with an explicitly defined replica count. This ensures that traffic exposure to a new version remains a deliberate deployment decision rather than being increased automatically by the HPA.

- **Readiness probes before serving traffic.** Pods are added to the Service endpoint list only after passing their readiness probe. This prevents traffic from reaching containers that have started but are still initializing, reducing failed requests during rollouts and canary deployments.

- **OIDC-based authentication throughout.** GitHub Actions authenticates to Azure using OpenID Connect (OIDC) workload identity federation instead of stored credentials. This removes long-lived secrets from the CI/CD pipeline while following Microsoft's recommended authentication model for GitHub Actions.

---

## Canary Deployment Lifecycle

```
1. Push to main
   └── build image, push to both ACRs with SHA tag

2. Auto-deploy to dev (stable track)
   └── validate the image works

3. Manual trigger: deploy-prod-stable
   └── establish baseline on prod (approval gate)

4. Manual trigger: deploy-prod-canary
   └── new image deployed alongside stable (approval gate)
   └── ~20% of traffic hits canary

5. Observe — Container Insights, error rates, latency

6. Manual trigger: promote.yml with canary's SHA
   └── stable release updated to run the validated image
   └── promotion is always a deliberate human decision

7. Rollback if needed:
   kubectl scale deployment voting-app-canary -n voting --replicas=0
   (all traffic immediately returns to stable)
```

---

## Security

| Mechanism | Purpose |
|---|---|
| Workload Identity Federation (OIDC) | Pipeline authentication — no stored secrets |
| Kubelet managed identity + AcrPull | Credential-free image pulls from ACR |
| Azure Kubernetes Service RBAC Cluster Admin | Pipeline data-plane access to Kubernetes API |
| Azure Kubernetes Service Cluster Admin Role | Pipeline management-plane credential retrieval |
| Azure AD-integrated cluster RBAC | kubectl access via AAD group membership, no static kubeconfig credentials |
| `imagePullPolicy: Always` | Prevents stale cached images on nodes |

---

## Technologies

- **Terraform** — AKS cluster, ACR, networking, monitoring
- **GitHub Actions** — multi-job pipeline, reusable workflows, OIDC auth, environment approval gates
- **Helm** — application packaging, separate releases per track, per-environment values
- **Azure Kubernetes Service** — managed Kubernetes, system+user node pools, Azure CNI Overlay, AAD-integrated RBAC
- **Azure Container Registry** — per-environment registries, kubelet managed identity pulls
- **nginx Ingress Controller** — Layer 7 routing, single external entry point, dedicated cluster release
- **Horizontal Pod Autoscaler** — CPU-based scaling on stable track only
- **Python/Flask** — voting app frontend
- **Redis** — vote persistence, PVC-backed Azure Disk
- **Azure Monitor** — Log Analytics, Container Insights, metric alerts
- **TFLint + Checkov** — Terraform static analysis and security scanning

---
