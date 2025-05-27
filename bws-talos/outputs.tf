output "talosconfig" {
  description = "Talos client configuration"
  value       = module.bws-talos-base.talosconfig
  sensitive   = true
}

output "worker_machine_configuration" {
  description = "Machine Configuration for worker nodes"
  value       = module.bws-talos-base.worker_machine_configuration
  sensitive   = true
}

output "controlplane_machine_configuration" {
  description = "Machine Configuration for controlplane nodes"
  value       = module.bws-talos-base.controlplane_machine_configuration
  sensitive   = true
}

output "x_download_kubeconfig" {
  description = "Get kubeconfig of cluster"
  value       = <<-EOT
    tofu output -raw talosconfig > talosconfig
    talosctl --talosconfig ./talosconfig --nodes ${module.bws-talos-base.controlplane_nodes[0]} kubeconfig
    EOT
}

output "x_access_argocd" {
  description = "ArgoCD Access"
  value       = <<-EOT
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
    EOT
}
