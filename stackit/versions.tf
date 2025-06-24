terraform {
  required_version = ">= 1"
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "~> 0.55.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1, <3.0.0"
    }
  }
}
