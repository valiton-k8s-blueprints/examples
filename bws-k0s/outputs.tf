output "x_download_kubeconfig" {
  description = "Get kubeconfig of cluster"
  value       = <<-EOT
  k0sctl kubeconfig --config k0s.yaml
EOT
}
