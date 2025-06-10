variable "base_name" {
  description = "Name of your base infrastructure."
  type        = string
  default     = "my-project"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.base_name))
    error_message = "The base_name must only contain lowercase letters, numbers, and dashes."
  }
}

variable "environment" {
  description = "Infrastructure environment name (e.g. development, staging, production)."
  type        = string
  default     = "development"
}

variable "talos_secrets_file" {
  description = "Name of the file that contains the Talos secrets generated with `talosctl gen secrets`"
  type        = string
  default     = "secrets.yaml"
}

variable "os_application_credential_id" {
  description = "Openstack application credentials ID"
  type        = string
}

variable "os_application_credential_secret" {
  description = "Openstack application credentials secret"
  type        = string
}

variable "os_auth_url" {
  description = "Openstack keystone url"
  type        = string
  default     = "https://dashboard.bws.burda.com:5000"
}

variable "os_public_network_name" {
  description = "Name of the Openstack public network"
  type        = string
  default     = "Public1"
}

variable "os_private_network_name" {
  description = "Name of the private network"
  type        = string
  default     = "private-network"
}

variable "kube_api_external_ip" {
  description = "External floating IP to expose Kubernetes API"
  type        = string
}

variable "kube_api_external_port" {
  description = "Port to expose Kubernetes API"
  type        = number
  default     = 6443
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.32.3"
}

variable "openstack_ccm_version" {
  description = "Openstack cloud controller mananger version"
  type        = string
  default     = "v1.32.0"
}

variable "image_name" {
  description = "Name of the Talos image in your BWS project"
  type        = string
  default     = "Talos"
}

variable "worker_instance_flavor" {
  description = "Instance flavor for worker nodes"
  type        = string
  default     = "BWS-T1-4-16"
}

variable "worker_volume_type" {
  description = "BWS volume type for worker nodes"
  type        = string
  default     = "ssd-10000-250"
}

variable "worker_volume_size" {
  description = "Size in GB of the disk of worker nodes"
  type        = number
  default     = 40
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "controlplane_instance_flavor" {
  description = "Instance flavor for controlplane nodes"
  type        = string
  default     = "BWS-T1-4-16"
}

variable "controlplane_volume_type" {
  description = "BWS volume type for controlplane nodes"
  type        = string
  default     = "ssd-10000-250"
}

variable "controlplane_volume_size" {
  description = "Size in GB of the disk of controlplane nodes"
  type        = number
  default     = 40
}

variable "controlplane_count" {
  description = "Number of controlplane nodes"
  type        = number
  default     = 3
}

variable "gitops_applications_repo_url" {
  description = "Url of Git repository for applications"
  type        = string
  default     = "https://github.com/valiton-k8s-blueprints/argocd.git"
}

variable "gitops_applications_repo_path" {
  description = "Path in Git repository for applications"
  type        = string
  default     = "bws-talos"
}


variable "gitops_applications_repo_revision" {
  description = "Git repository revision/branch/ref for applications"
  type        = string
  default     = "main"
}

variable "external_dns_domain_filters" {
  description = "Domains for external dns, e.g. ['example.com']"
  type        = string
}

variable "argocd_hostname" {
  description = "FQDN for ArgoCD"
  type        = string
}

variable "cert_manager_acme_registration_mail" {
  description = "E-Mail address to register with let's encrypt"
  type        = string
}

variable "cinder_csi_plugin_volume_type" {
  description = "Cinder csi plugin add-on configuration values"
  type        = string
  default     = "ssd-20000-350"
}
