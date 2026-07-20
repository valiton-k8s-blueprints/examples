terraform {
  required_version = ">= 1.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.4.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.0"
    }
  }
}
