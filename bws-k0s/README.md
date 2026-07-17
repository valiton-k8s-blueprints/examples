# Example configuration for BWS (Openstack)

This is an example configuration to provision a k0s cluster on BWS (Openstack).

## Quick start

### Prerequisites

1. Get access to a BWS project.
2. Create a floating IP to access the cluster.
3. Create application credentials to authenticate to BWS.
4.  Get `k0sctl` (see https://github.com/k0sproject/k0sctl?tab=readme-ov-file#installation)
5. Fork the argocd repo (https://github.com/valiton-k8s-blueprints/argocd).
6. Configure SSH: to setup the machines, we access them with ssh. This is done with a bastion host, but to spare
   another floating IP, we access the bastion host through a load balancer. This load balancer has a default timeout
   of 50 seconds so the ssh connection will die if a command on the server takes longer. To prevent that, you can
   configure your ssh client to send keepalive messages every 30 seconds. Add the following to your `~/.ssh/config`:

   ```
   Host *
        ServerAliveInterval 30
        ServerAliveCountMax 2
   ```

### Private GitOps repositories

If you fork the argocd repository to a private repository, you have to configure credentials for ArgoCD. For Gitlab you can
create a deploy token and add a secret to your cluster, e.g. by updating your configuration with the following snippet:

```hcl
resource "kubernetes_namespace_v1" "argocd" {
  depends_on = [module.bws_base.cluster_health, module.bws_base]

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret_v1" "argocd_repo_secret" {
  depends_on = [kubernetes_namespace_v1.argocd]

  metadata {
    name      = "gitlab-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    url      = "<your applications repo>"
    type     = "git"
    password = var.gitlab_repo_password
    username = var.gitlab_repo_username
  }
}
```

### Minimal configuration

Create a `terraform.tfvars` file with your application credentials:

```terraform
base_name                            = "test-cluster"
environment                          = "development"
os_application_credential_id         = "<your application credential id>"
os_application_credential_secret     = "<your application credential secret>"
kube_api_external_ip                 = "<your floating ip>"
dns_domain                           = "<your-project>.bws.burda.com"
cert_manager_acme_registration_email = "<your email>"
gitops_applications_repo_url         = "<your applications repo>"
ssh_public_key                       = "<your ssh public key>"
```

Init Opentofu

```shell
tofu init
```

and plan/apply

```shell
tofu apply
```

After a couple of minutes, your cluster should be up and running. Follow the instructions of the terraform 
output to get your kubeconfig. Check the state of the applications with

```shell
kubectl -n argocd get applications
```

When all applications are synced and healthy, you can deploy your workloads or our example workload.

# Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.17.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.38.0 |
| <a name="requirement_openstack"></a> [openstack](#requirement\_openstack) | 3.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.9.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.11.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.14.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | 3.4.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bws-base"></a> [bws-base](#module\_bws-base) | git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/base | feature/k0s |
| <a name="module_bws-bootstrap"></a> [bws-bootstrap](#module\_bws-bootstrap) | git::https://github.com/valiton-k8s-blueprints/terraform.git//bws/bootstrap | feature/k0s |

## Resources

| Name | Type |
| ---- | ---- |
| [openstack_identity_auth_scope_v3.user](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/3.4.0/docs/data-sources/identity_auth_scope_v3) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | Name of your base infrastructure. Will be used to prfix the names of your resources. | `string` | `"my-project"` | no |
| <a name="input_bastion_instance_flavor"></a> [bastion\_instance\_flavor](#input\_bastion\_instance\_flavor) | Instance flavor for the bastion node | `string` | `"BWS-T1-2-4"` | no |
| <a name="input_bastion_volume_size"></a> [bastion\_volume\_size](#input\_bastion\_volume\_size) | Size in GB of the disk of bastion node | `number` | `10` | no |
| <a name="input_bastion_volume_type"></a> [bastion\_volume\_type](#input\_bastion\_volume\_type) | BWS volume type for bastion node | `string` | `"ssd-3000-125"` | no |
| <a name="input_cert_manager_acme_registration_email"></a> [cert\_manager\_acme\_registration\_email](#input\_cert\_manager\_acme\_registration\_email) | E-Mail address to register with let's encrypt | `string` | n/a | yes |
| <a name="input_cinder_csi_plugin_volume_type"></a> [cinder\_csi\_plugin\_volume\_type](#input\_cinder\_csi\_plugin\_volume\_type) | Cinder csi plugin add-on configuration values | `string` | `"ssd-3000-125"` | no |
| <a name="input_controlplane_count"></a> [controlplane\_count](#input\_controlplane\_count) | Number of controlplane nodes | `number` | `3` | no |
| <a name="input_controlplane_instance_flavor"></a> [controlplane\_instance\_flavor](#input\_controlplane\_instance\_flavor) | Instance flavor for controlplane nodes | `string` | `"BWS-T1-2-8"` | no |
| <a name="input_controlplane_volume_size"></a> [controlplane\_volume\_size](#input\_controlplane\_volume\_size) | Size in GB of the disk of controlplane nodes | `number` | `40` | no |
| <a name="input_controlplane_volume_type"></a> [controlplane\_volume\_type](#input\_controlplane\_volume\_type) | BWS volume type for controlplane nodes | `string` | `"ssd-3000-125"` | no |
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | Domain for external dns and gateway | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Infrastructure environment name (e.g. development, staging, production). You can deploy different addons version to different environments. cert-manager will use let's encrypt staging for all environments but production | `string` | `"development"` | no |
| <a name="input_external_dns_domains"></a> [external\_dns\_domains](#input\_external\_dns\_domains) | Additional domains for external dns | `list(string)` | `[]` | no |
| <a name="input_gitops_applications_repo_path"></a> [gitops\_applications\_repo\_path](#input\_gitops\_applications\_repo\_path) | Path in Git repository for applications | `string` | `"bws-k0s"` | no |
| <a name="input_gitops_applications_repo_revision"></a> [gitops\_applications\_repo\_revision](#input\_gitops\_applications\_repo\_revision) | Git repository revision/branch/ref for applications | `string` | n/a | yes |
| <a name="input_gitops_applications_repo_url"></a> [gitops\_applications\_repo\_url](#input\_gitops\_applications\_repo\_url) | Url of Git repository for applications | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Name of the image in your BWS project | `string` | `"Ubuntu 24.04"` | no |
| <a name="input_k0s_version"></a> [k0s\_version](#input\_k0s\_version) | k0s version | `string` | `"v1.36.2+k0s.0"` | no |
| <a name="input_keystone_auth_port"></a> [keystone\_auth\_port](#input\_keystone\_auth\_port) | Port of keystone auth | `number` | `30043` | no |
| <a name="input_kube_api_external_ip"></a> [kube\_api\_external\_ip](#input\_kube\_api\_external\_ip) | External floating IP to expose Kubernetes API | `string` | n/a | yes |
| <a name="input_kube_api_external_port"></a> [kube\_api\_external\_port](#input\_kube\_api\_external\_port) | Port to expose Kubernetes API | `number` | `6443` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version | `string` | `"v1.36.2"` | no |
| <a name="input_openstack_ccm_version"></a> [openstack\_ccm\_version](#input\_openstack\_ccm\_version) | Openstack cloud controller mananger version | `string` | `"v1.36.0"` | no |
| <a name="input_os_application_credential_id"></a> [os\_application\_credential\_id](#input\_os\_application\_credential\_id) | Openstack application credentials ID | `string` | n/a | yes |
| <a name="input_os_application_credential_secret"></a> [os\_application\_credential\_secret](#input\_os\_application\_credential\_secret) | Openstack application credentials secret | `string` | n/a | yes |
| <a name="input_os_auth_url"></a> [os\_auth\_url](#input\_os\_auth\_url) | Openstack keystone url | `string` | `"https://dashboard.bws.burda.com:5000"` | no |
| <a name="input_os_private_network_name"></a> [os\_private\_network\_name](#input\_os\_private\_network\_name) | Name of the private network | `string` | `"private-network"` | no |
| <a name="input_os_public_network_name"></a> [os\_public\_network\_name](#input\_os\_public\_network\_name) | Name of the Openstack public network | `string` | `"Public1"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key | `string` | n/a | yes |
| <a name="input_worker_count"></a> [worker\_count](#input\_worker\_count) | Number of worker nodes | `number` | `2` | no |
| <a name="input_worker_instance_flavor"></a> [worker\_instance\_flavor](#input\_worker\_instance\_flavor) | Instance flavor for worker nodes | `string` | `"BWS-T1-2-8"` | no |
| <a name="input_worker_volume_size"></a> [worker\_volume\_size](#input\_worker\_volume\_size) | Size in GB of the disk of worker nodes | `number` | `40` | no |
| <a name="input_worker_volume_type"></a> [worker\_volume\_type](#input\_worker\_volume\_type) | BWS volume type for worker nodes | `string` | `"ssd-3000-125"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_x_download_kubeconfig"></a> [x\_download\_kubeconfig](#output\_x\_download\_kubeconfig) | Get kubeconfig of cluster |
<!-- END_TF_DOCS -->
