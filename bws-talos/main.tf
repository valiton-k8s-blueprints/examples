locals {
  kubernetes_endpoint = "https://${var.kube_api_external_ip}:${var.kube_api_external_port}"
  talos_secrets       = yamldecode(file(var.talos_secrets_file))
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

module "bws-talos-bootstrap-config" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws-talos/bootstrap-config?ref=main"

  addons = var.addons
}

module "bws-talos-base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws-talos/base?ref=main"

  base_name                        = var.base_name
  os_auth_url                      = var.os_auth_url
  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  os_user_name                     = data.openstack_identity_auth_scope_v3.user.user_name
  os_public_network_name           = var.os_public_network_name
  os_private_network_name          = var.os_private_network_name

  kubernetes_version     = var.kubernetes_version
  openstack_ccm_version  = var.openstack_ccm_version
  kube_api_external_ip   = var.kube_api_external_ip
  kube_api_external_port = var.kube_api_external_port
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

  pod_security_exemptions_namespaces = module.bws-talos-bootstrap-config.pod_security_exemptions_namespaces
}

module "bws-talos-bootstrap" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//bws-talos/bootstrap?ref=main"

  depends_on = [module.bws-talos-base.talos_cluster_health]

  base_name          = var.base_name
  environment        = var.environment
  kubernetes_version = var.kubernetes_version
  addons             = module.bws-talos-bootstrap-config.addons

  gitops_applications_repo_revision = var.gitops_applications_repo_revision
  gitops_applications_repo_url      = var.gitops_applications_repo_url

  os_auth_url                      = var.os_auth_url
  os_application_credential_id     = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  os_private_network_subnet_id     = module.bws-talos-base.os_private_network_subnet_id
  os_public_network_id             = module.bws-talos-base.os_public_network_id

  destroy_timeout = 120

  kube_prometheus_stack = {
    namespace = module.bws-talos-bootstrap-config.kube_prometheus_stack_namespace
  }

  cinder_csi_plugin = {
    namespace = module.bws-talos-bootstrap-config.cinder_csi_plugin_namespace
  }

  external_dns = {
    domain_filters = var.external_dns_domain_filters
    policy         = "sync"
  }

  cert_manager = {
    acme = {
      registration_email = var.cert_manager_acme_registration_mail
    }
  }

  ingress_nginx = {
    ingressclass = {
      name    = "ingress-nginx"
      default = "true"
    }
  }

  argocd = {
    hostname = var.argocd_hostname
  }
}
