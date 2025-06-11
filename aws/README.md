# AWS EKS Blueprint for Development Environment

## Usage

These examples show the possible options:

1. **Base Module only**

    In this example, only the base setup is executed. It contains the VPC and the EKS CLuster.

2. **Base Module + Gitops EKS addons**

    In addition to the base module, this example installs all enabled Kubernetes plugins which are installed via the gitOps approach with Argo CD.

### Base Module only

```tf
variable "base_name" {
  type    = string
  default = "my-base"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "development"
}

locals {
  region      = var.region
  base_name   = var.base_name
  environment = var.environment
}

################################################################################
# required providers
################################################################################
provider "aws" {
  region = local.region
}

################################################################################
# modules
################################################################################
module "base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//aws/base?ref=main"
  region    = local.region
  base_name = local.base_name

  environment = local.environment

  single_nat_gateway = true
}
output "base" {
  value = module.base
}

```
### Base Module + Gitops EKS Addons

```tf
variable "base_name" {
  type    = string
  default = "my-base"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "development"
}

locals {
  region      = var.region
  base_name   = var.base_name
  environment = var.environment
}

################################################################################
# required providers
################################################################################
provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes {
    host                   = module.base.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.base.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.base.eks_cluster_name, "--region", local.region]
    }
  }
}

provider "kubernetes" {
  host                   = module.base.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.base.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.base.eks_cluster_name, "--region", local.region]
  }
}

################################################################################
# modules
################################################################################
module "base" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//aws/base?ref=main"
  region    = local.region
  base_name = local.base_name

  environment = local.environment
}
output "base" {
  value = module.base
}


module "gitops-eks-addons" {
  source = "git::https://github.com/valiton-k8s-blueprints/terraform.git//aws/bootstrapping/gitops-eks-addons?ref=main"

  environment = local.environment

  region = local.region

  vpc_id = module.base.vpc_id

  eks_cluster_name        = module.base.eks_cluster_name
  eks_cluster_endpoint    = module.base.eks_cluster_endpoint
  eks_cluster_version     = module.base.eks_cluster_version
  eks_oidc_provider_arn   = module.base.oidc_provider_arn
  eks_managed_node_groups = module.base.eks_managed_node_groups
}
output "gitops-eks-addons" {
  value = module.gitops-eks-addons
}


```
## Apply

You can provision it using the following commands:
```bash
terraform init
terraform plan
terraform apply --auto-approve
```

Once the terraform has been executed and the EKS cluster is being created, you can access the EKS cluster using the following commands: 

```bash
aws eks update-kubeconfig --name eks-development-example
```
