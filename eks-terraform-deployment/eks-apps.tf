# =====================================================================
# Kubernetes Provider Configuration
# =====================================================================
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# =====================================================================
# Deploy Kubernetes Applications from Manifests
# =====================================================================

resource "kubernetes_manifest" "namespace" {
  provider = kubernetes
  manifest = yamldecode(file("${path.module}/../eks-apps/namespace.yaml"))
}

resource "kubernetes_manifest" "api_deployment" {
  provider = kubernetes
  manifest = yamldecode(file("${path.module}/../eks-apps/api-deployment.yaml"))

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "nginx_deployment" {
  provider = kubernetes
  manifest = yamldecode(file("${path.module}/../eks-apps/nginx-deployment.yaml"))

  depends_on = [kubernetes_manifest.namespace]
}
