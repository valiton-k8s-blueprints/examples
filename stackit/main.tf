variable "base_name" {
  type    = string
  default = "my-base"
}
variable "region" {
  type    = string
  default = "eu01"
}
variable "environment" {
  type    = string
  default = "development"
}
variable "availability_zones" {
  type    = list(string)
  default = ["eu01-1", "eu01-2"]
}
variable "extensions_dns_zones" {
  type    = list(string)
  default = ["my-project.runs.onstackit.cloud"]
}

variable "cert_manager_default_cert_domain_list" { 
  type    = list(string)
  default = ["poc.my-project.runs.onstackit.cloud", "*.poc.my-project.runs.onstackit.cloud"]
}

variable "project_id" {
  type = string
}
variable "use_secrets_manager" {
  type    = bool
  default = true
}


################################################################################
# required providers
################################################################################
provider "stackit" {
  default_region = var.region
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).users[0].user["client-certificate-data"])
    client_key             = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).users[0].user["client-key-data"])
    cluster_ca_certificate = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).clusters[0].cluster["certificate-authority-data"])
  }
}

provider "kubernetes" {
  host                   = yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).users[0].user["client-certificate-data"])
  client_key             = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(stackit_ske_kubeconfig.managed_cluster.kube_config).clusters[0].cluster["certificate-authority-data"])
}

provider "vault" {
  address          = "https://prod.sm.eu01.stackit.cloud"
  skip_child_token = true

  auth_login_userpass {
    username = stackit_secretsmanager_user.sm_user[0].username
    password = stackit_secretsmanager_user.sm_user[0].password
  }
}

################################################################################
# modules
################################################################################
module "base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//stackit/base?ref=main"

  availability_zones      = var.availability_zones
  project_id              = var.project_id
  base_name               = var.base_name
  extensions_dns_zones    = var.extensions_dns_zones
  base_node_pool_max_size = 10
}
output "base" {
  value = module.base
}

resource "stackit_ske_kubeconfig" "managed_cluster" {
  project_id   = var.project_id
  cluster_name = module.base.cluster_name
  refresh      = true
}

resource "stackit_secretsmanager_instance" "sm_instance" {
  count = var.use_secrets_manager ? 1 : 0

  project_id = var.project_id
  name       = module.base.cluster_name
}

resource "stackit_secretsmanager_user" "sm_user" {
  count = var.use_secrets_manager ? 1 : 0

  project_id    = var.project_id
  instance_id   = stackit_secretsmanager_instance.sm_instance[count.index].instance_id
  description   = "sm user"
  write_enabled = true
}

module "gitops-ske-addons" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//stackit/bootstrapping/gitops-ske-addons?ref=main"

  environment = var.environment

  region = var.region

  project_id = var.project_id

  ske_cluster_name        = module.base.cluster_name
  ske_cluster_id          = module.base.cluster_id
  ske_egress_adress_range = module.base.cluster_egress_address_range
  ske_cluster_version     = module.base.cluster_kubernetes_version_used
  ske_nodepools           = module.base.cluster_nodepools

  cert_manager_acme_registration_email       = "test@example.com" # please replace this with a valid e-mail.
  cert_manager_default_cert_domain_list      = var.cert_manager_default_cert_domain_list
  cert_manager_stackit_service_account_email = "cert-manager-example@sa.stackit.cloud" # The service account must already exist and have dns.admin or dns.editor permissions.

  external_secrets_stackit_secrets_manager_config = {
    sm_user        = length(stackit_secretsmanager_user.sm_user) > 0 ? stackit_secretsmanager_user.sm_user[0].username : null
    sm_password    = length(stackit_secretsmanager_user.sm_user) > 0 ? stackit_secretsmanager_user.sm_user[0].password : null
    sm_instance_id = length(stackit_secretsmanager_instance.sm_instance[0].instance_id) > 0 ? stackit_secretsmanager_instance.sm_instance[0].instance_id : null
  }

  addons = {
    enable_ingress_nginx                            = true
    enable_cert_manager                             = true
    enable_cert_manager_default_cert                = true
    enable_external_secrets                         = true
    enable_external_secrets_stackit_secrets_manager = true
    enable_kube_prometheus_stack                    = true
  }

}
output "gitops-ske-addons" {
  value = module.gitops-ske-addons.ske_gitops_bridge_metadata
}
