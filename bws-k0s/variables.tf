variable "base_name" {
  description = "Name of your base infrastructure. Will be used to prfix the names of your resources."
  type        = string
  default     = "my-project"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.base_name))
    error_message = "The base_name must only contain lowercase letters, numbers, and dashes."
  }
}

variable "environment" {
  description = "Infrastructure environment name (e.g. development, staging, production). You can deploy different addons version to different environments. cert-manager will use let's encrypt staging for all environments but production"
  type        = string
  default     = "development"
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

variable "keystone_auth_port" {
  description = "Port of keystone auth"
  type        = number
  default     = 30043
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.36.2"
}

variable "k0s_version" {
  description = "k0s version"
  type        = string
  default     = "v1.36.2+k0s.0"
}

variable "openstack_ccm_version" {
  description = "Openstack cloud controller mananger version"
  type        = string
  default     = "v1.36.0"
}

variable "image_name" {
  description = "Name of the image in your BWS project"
  type        = string
  default     = "Ubuntu 24.04"
}

variable "worker_instance_flavor" {
  description = "Instance flavor for worker nodes"
  type        = string
  default     = "BWS-T1-2-8"
}

variable "worker_volume_type" {
  description = "BWS volume type for worker nodes"
  type        = string
  default     = "ssd-3000-125"
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
  default     = "BWS-T1-2-8"
}

variable "controlplane_volume_type" {
  description = "BWS volume type for controlplane nodes"
  type        = string
  default     = "ssd-3000-125"
}

variable "controlplane_volume_size" {
  description = "Size in GB of the disk of controlplane nodes"
  type        = number
  default     = 40
}

variable "bastion_instance_flavor" {
  description = "Instance flavor for the bastion node"
  type        = string
  default     = "BWS-T1-2-4"
}

variable "bastion_volume_type" {
  description = "BWS volume type for bastion node"
  type        = string
  default     = "ssd-3000-125"
}

variable "bastion_volume_size" {
  description = "Size in GB of the disk of bastion node"
  type        = number
  default     = 10
}

variable "controlplane_count" {
  description = "Number of controlplane nodes"
  type        = number
  default     = 3
}

variable "gitops_applications_repo_url" {
  description = "Url of Git repository for applications"
  type        = string
}

variable "gitops_applications_repo_path" {
  description = "Path in Git repository for applications"
  type        = string
  default     = "bws-k0s"
}

variable "gitops_applications_repo_revision" {
  description = "Git repository revision/branch/ref for applications"
  type        = string
}

variable "dns_domain" {
  description = "Domain for external dns and gateway"
  type        = string
}

variable "external_dns_domains" {
  description = "Additional domains for external dns"
  type        = list(string)
  default     = []
}

variable "cert_manager_acme_registration_email" {
  description = "E-Mail address to register with let's encrypt"
  type        = string
}

variable "cinder_csi_plugin_volume_type" {
  description = "Cinder csi plugin add-on configuration values"
  type        = string
  default     = "ssd-3000-125"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}
