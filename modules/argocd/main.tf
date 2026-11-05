resource "helm_release" "argocd_bootstrap" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/argocd-bootstrap-values.yaml")
  ]
}