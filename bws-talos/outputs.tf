output "talosconfig" {
  description = "Talos client configuration"
  value       = module.bws-base.talosconfig
  sensitive   = true
}

output "worker_machine_configuration" {
  description = "Machine Configuration for worker nodes"
  value       = module.bws-base.worker_machine_configuration
  sensitive   = true
}

output "controlplane_machine_configuration" {
  description = "Machine Configuration for controlplane nodes"
  value       = module.bws-base.controlplane_machine_configuration
  sensitive   = true
}

output "x_download_kubeconfig" {
  description = "Get kubeconfig of cluster"
  value       = <<-EOT
    tofu output -raw talosconfig > talosconfig
    talosctl --talosconfig ./talosconfig --nodes ${module.bws-base.controlplane_nodes[0]} kubeconfig
    EOT
}
