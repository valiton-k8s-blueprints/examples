locals {
  kubernetes_endpoint         = "https://${var.kube_api_external_ip}:${var.kube_api_external_port}"
  ca_crt                      = file(var.ca_crt_file)
  ca_key                      = file(var.ca_key_file)
  client_crt                  = file(var.client_crt_file)
  client_key                  = file(var.client_key_file)
  external_dns_domain_filters = jsonencode(concat([var.dns_domain], var.external_dns_domains))
}

provider "openstack" {
  auth_url                      = var.os_auth_url
  application_credential_id     = var.os_application_credential_id
  application_credential_secret = var.os_application_credential_secret
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_endpoint
    cluster_ca_certificate = local.ca_crt
    client_certificate     = local.client_crt
    client_key             = local.client_key
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_endpoint
  cluster_ca_certificate = local.ca_crt
  client_certificate     = local.client_crt
  client_key             = local.client_key
}

data "openstack_identity_auth_scope_v3" "user" {
  name         = "user"
  set_token_id = true
}

module "bws-base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/base?ref=feature/k0s"

  base_name                        = var.base_name
  os_auth_url                      = var.os_auth_url
  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  os_region_name                   = var.os_region_name
  os_user_name                     = data.openstack_identity_auth_scope_v3.user.user_name
  os_public_network_name           = var.os_public_network_name
  os_private_network_name          = var.os_private_network_name
  os_token                         = data.openstack_identity_auth_scope_v3.user.token_id

  kubernetes_version     = var.kubernetes_version
  kube_api_external_ip   = var.kube_api_external_ip
  kube_api_external_port = var.kube_api_external_port
  keystone_auth_port     = var.keystone_auth_port

  controlplane_count           = var.controlplane_count
  controlplane_volume_size     = var.controlplane_volume_size
  controlplane_volume_type     = var.controlplane_volume_type
  controlplane_instance_flavor = var.controlplane_instance_flavor

  worker_count           = var.worker_count
  worker_volume_size     = var.worker_volume_size
  worker_volume_type     = var.worker_volume_type
  worker_instance_flavor = var.worker_instance_flavor

  bastion_volume_size     = var.bastion_volume_size
  bastion_volume_type     = var.bastion_volume_type
  bastion_instance_flavor = var.bastion_instance_flavor

  image_name = var.image_name

  ssh_public_key = var.ssh_public_key

  pod_security_exemptions_namespaces = []

  k8s_distribution = "kubeone"

  availability_zone = var.availability_zone

  min_dynamic_workers = var.min_dynamic_workers
  max_dynamic_workers = var.max_dynamic_workers

  ca_crt = local.ca_crt
  ca_key = local.ca_key

  cinder_csi_plugin_volume_type = var.cinder_csi_plugin_volume_type
}

module "bws-bootstrap" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/bootstrap?ref=feature/k0s"

  depends_on = [module.bws-base.cluster_health, module.bws-base]

  base_name   = var.base_name
  environment = var.environment

  gitops_applications_repo_revision = var.gitops_applications_repo_revision
  gitops_applications_repo_url      = var.gitops_applications_repo_url
  gitops_applications_repo_path     = var.gitops_applications_repo_path

  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret

  destroy_timeout = 120

  metadata_annotations = {
    openstack_auth_url = var.os_auth_url

    dns_domain                           = var.dns_domain
    external_dns_domain_filters          = local.external_dns_domain_filters
    external_dns_txt_owner_id            = var.base_name
    cert_manager_acme_registration_email = var.cert_manager_acme_registration_email
  }
}
