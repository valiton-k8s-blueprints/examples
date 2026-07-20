output "x_download_kubeconfig" {
  description = "Get kubeconfig of cluster"
  value       = <<-EOT
    cat ${var.base_name}-kubeconfig
    EOT
}
