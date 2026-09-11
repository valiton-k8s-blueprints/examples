locals {
  kubernetes_endpoint         = "https://${var.kube_api_external_ip}:${var.kube_api_external_port}"
  talos_secrets               = yamldecode(file(var.talos_secrets_file))
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
    token                  = data.openstack_identity_auth_scope_v3.user.token_id
    cluster_ca_certificate = base64decode(local.talos_secrets.certs.k8s.crt)
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_endpoint
  token                  = data.openstack_identity_auth_scope_v3.user.token_id
  cluster_ca_certificate = base64decode(local.talos_secrets.certs.k8s.crt)
}

data "openstack_identity_auth_scope_v3" "user" {
  name         = "user"
  set_token_id = true
}

module "bws-base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/base?ref=v1.1.1"

  base_name                        = var.base_name
  os_auth_url                      = var.os_auth_url
  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  os_user_name                     = data.openstack_identity_auth_scope_v3.user.user_name
  os_public_network_name           = var.os_public_network_name
  os_private_network_name          = var.os_private_network_name
  os_token                         = data.openstack_identity_auth_scope_v3.user.token_id

  kubernetes_version     = var.kubernetes_version
  openstack_ccm_version  = var.openstack_ccm_version
  kube_api_external_ip   = var.kube_api_external_ip
  kube_api_external_port = var.kube_api_external_port
  keystone_auth_port     = var.keystone_auth_port
  talos_secrets          = local.talos_secrets

  controlplane_count           = var.controlplane_count
  controlplane_volume_size     = var.controlplane_volume_size
  controlplane_volume_type     = var.controlplane_volume_type
  controlplane_instance_flavor = var.controlplane_instance_flavor

  worker_count           = var.worker_count
  worker_volume_size     = var.worker_volume_size
  worker_volume_type     = var.worker_volume_type
  worker_instance_flavor = var.worker_instance_flavor

  image_name = var.image_name

  pod_security_exemptions_namespaces = ["kube-prometheus-stack", "cinder-csi-plugin"]

  k8s_distribution = "talos"
}

module "bws-bootstrap" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/bootstrap?ref=v1.1.1"

  depends_on = [module.bws-base.cluster_health]

  base_name   = var.base_name
  environment = var.environment

  gitops_applications_repo_revision = var.gitops_applications_repo_revision
  gitops_applications_repo_url      = var.gitops_applications_repo_url
  gitops_applications_repo_path     = var.gitops_applications_repo_path

  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  dynamic_worker_cloud_init        = module.bws-base.worker_machine_configuration

  destroy_timeout = 120

  metadata_annotations = {
    openstack_ccm_version = var.openstack_ccm_version

    openstack_auth_url            = var.os_auth_url
    openstack_subnet_id           = module.bws-base.os_private_network_subnet_id
    openstack_floating_network_id = module.bws-base.os_public_network_id

    dns_domain                           = var.dns_domain
    cinder_csi_plugin_volume_type        = var.cinder_csi_plugin_volume_type
    external_dns_domain_filters          = local.external_dns_domain_filters
    external_dns_txt_owner_id            = var.base_name
    cert_manager_acme_registration_email = var.cert_manager_acme_registration_email

    dynamic_worker_pool         = "${var.base_name}-pool1"
    dynamic_worker_flavor_name  = var.worker_instance_flavor
    dynamic_worker_image_name   = var.image_name
    dynamic_worker_network_name = module.bws-base.os_private_network_name
    dynamic_worker_disk_size    = var.worker_volume_size
    dynamic_worker_subnet_name  = module.bws-base.os_private_network_subnet_name
  }
}
