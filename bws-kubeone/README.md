# Example configuration for BWS (Openstack)

This is an example configuration to provision a kubeone cluster on BWS (Openstack).

## Quick start

### Prerequisites

1. Get access to a BWS project.

   Remember to select the desired project after logging in to the dashboard.

2. Create a floating IP to access the cluster:

   Manually create a Floating-IP: https://dashboard.bws.burda.com/network/floatingip

   Button "Allocate IP"

   Select "Network"

   Select "Owned Subnet"

   Leave "Floating IP Address" empty

   Button "OK"
 
4. Create application credentials to authenticate to BWS.

   Go to https://dashboard.bws.burda.com/user/application-credentials
   or click your account icon (top-right in the web-UI) => "User Center" => "Application Credentials"

   Button "Create Application Credentials"

   Roles needed: "load-balancer_member", "member"

4. Get `kubeone` (see https://docs.kubermatic.com/kubeone/v1.13/getting-kubeone/).
5. Create a CA, certifiactes and keys:
   ```shell
   cd ca
   tofu init
   tofu apply
   ```
6. Fork the argocd repo (https://github.com/valiton-k8s-blueprints/argocd). 
7. Configure SSH: to setup the machines, we access them with ssh. This is done with a bastion host, but to spare 
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
gitops_applications_repo_revision    = "<your repos branch>"
ssh_public_key                       = "<your ssh public key>"
```


### Init Opentofu

```shell
tofu init
```


### Plan/apply

Be sure to unset all env variables starting with "OS_", because some of them override our terraform configuration,
especially OS_CLOUD, despite the official documentation stating otherwise ( https://registry.terraform.io/providers/terraform-provider-openstack/openstack/3.0.0/docs ).

```shell
tofu apply
```

After a couple of minutes, your cluster should be up and running. Follow the instructions of the terraform 
output to get your kubeconfig. Check the state of the applications with:

```shell
kubectl -n argocd get applications
```

When all applications are synced and healthy, you can deploy your workloads or our example workload.

A couple of hints for manual commands are ouput, e.g.:

```plain
## get kubeconfig
## kubeone creates a file <cluster-name>-kubeconfig

echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
```


### Access ArgoCD web-UI

```shell
kubectl -n argocd port-forward svc/argo-cd-argocd-server 8081:80
```

http://localhost:8081


### Destroy

```shell
tofu destroy
```

NOTE: Any provisioned persistent volumes in Kubernetes will not be deleted. You have to delete them manually afterwards. ( https://dashboard.bws.burda.com/storage/volume )


# Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_ct"></a> [ct](#requirement\_ct) | 0.14.0 |
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
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Name of the availability zone | `string` | `"az1"` | no |
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | Name of your base infrastructure. Will be used to prfix the names of your resources. | `string` | `"my-project"` | no |
| <a name="input_bastion_instance_flavor"></a> [bastion\_instance\_flavor](#input\_bastion\_instance\_flavor) | Instance flavor for the bastion node | `string` | `"BWS-T1-2-4"` | no |
| <a name="input_bastion_volume_size"></a> [bastion\_volume\_size](#input\_bastion\_volume\_size) | Size in GB of the disk of bastion node | `number` | `10` | no |
| <a name="input_bastion_volume_type"></a> [bastion\_volume\_type](#input\_bastion\_volume\_type) | BWS volume type for bastion node | `string` | `"ssd-3000-125"` | no |
| <a name="input_ca_crt_file"></a> [ca\_crt\_file](#input\_ca\_crt\_file) | Filename of CA certificate for the cluster | `string` | `"ca/ca.crt"` | no |
| <a name="input_ca_key_file"></a> [ca\_key\_file](#input\_ca\_key\_file) | Filename of CA key for the cluster | `string` | `"ca/ca.key"` | no |
| <a name="input_cert_manager_acme_registration_email"></a> [cert\_manager\_acme\_registration\_email](#input\_cert\_manager\_acme\_registration\_email) | E-Mail address to register with let's encrypt | `string` | n/a | yes |
| <a name="input_cinder_csi_plugin_volume_type"></a> [cinder\_csi\_plugin\_volume\_type](#input\_cinder\_csi\_plugin\_volume\_type) | Cinder csi plugin add-on configuration values | `string` | `"ssd-3000-125"` | no |
| <a name="input_client_crt_file"></a> [client\_crt\_file](#input\_client\_crt\_file) | Filename of client certificate to use to connect to the cluster | `string` | `"ca/client.crt"` | no |
| <a name="input_client_key_file"></a> [client\_key\_file](#input\_client\_key\_file) | Filename of client key to use to connect to the cluster | `string` | `"ca/client.key"` | no |
| <a name="input_controlplane_count"></a> [controlplane\_count](#input\_controlplane\_count) | Number of controlplane nodes | `number` | `3` | no |
| <a name="input_controlplane_instance_flavor"></a> [controlplane\_instance\_flavor](#input\_controlplane\_instance\_flavor) | Instance flavor for controlplane nodes | `string` | `"BWS-T1-2-8"` | no |
| <a name="input_controlplane_volume_size"></a> [controlplane\_volume\_size](#input\_controlplane\_volume\_size) | Size in GB of the disk of controlplane nodes | `number` | `40` | no |
| <a name="input_controlplane_volume_type"></a> [controlplane\_volume\_type](#input\_controlplane\_volume\_type) | BWS volume type for controlplane nodes | `string` | `"ssd-3000-125"` | no |
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | Domain for external dns and gateway | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Infrastructure environment name (e.g. development, staging, production). You can deploy different addons version to different environments. cert-manager will use let's encrypt staging for all environments but production | `string` | `"development"` | no |
| <a name="input_external_dns_domains"></a> [external\_dns\_domains](#input\_external\_dns\_domains) | Additional domains for external dns | `list(string)` | `[]` | no |
| <a name="input_gitops_applications_repo_path"></a> [gitops\_applications\_repo\_path](#input\_gitops\_applications\_repo\_path) | Path in Git repository for applications | `string` | `"bws-kubeone"` | no |
| <a name="input_gitops_applications_repo_revision"></a> [gitops\_applications\_repo\_revision](#input\_gitops\_applications\_repo\_revision) | Git repository revision/branch/ref for applications | `string` | n/a | yes |
| <a name="input_gitops_applications_repo_url"></a> [gitops\_applications\_repo\_url](#input\_gitops\_applications\_repo\_url) | Url of Git repository for applications | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Name of the image in your BWS project | `string` | `"Ubuntu 24.04"` | no |
| <a name="input_keystone_auth_port"></a> [keystone\_auth\_port](#input\_keystone\_auth\_port) | Port of keystone auth | `number` | `30043` | no |
| <a name="input_kube_api_external_ip"></a> [kube\_api\_external\_ip](#input\_kube\_api\_external\_ip) | External floating IP to expose Kubernetes API | `string` | n/a | yes |
| <a name="input_kube_api_external_port"></a> [kube\_api\_external\_port](#input\_kube\_api\_external\_port) | Port to expose Kubernetes API | `number` | `6443` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version | `string` | `"v1.35.6"` | no |
| <a name="input_max_dynamic_workers"></a> [max\_dynamic\_workers](#input\_max\_dynamic\_workers) | Maximum number of dynamic workers | `number` | `3` | no |
| <a name="input_min_dynamic_workers"></a> [min\_dynamic\_workers](#input\_min\_dynamic\_workers) | Minimum number of dynamic workers | `number` | `1` | no |
| <a name="input_os_application_credential_id"></a> [os\_application\_credential\_id](#input\_os\_application\_credential\_id) | Openstack application credentials ID | `string` | n/a | yes |
| <a name="input_os_application_credential_secret"></a> [os\_application\_credential\_secret](#input\_os\_application\_credential\_secret) | Openstack application credentials secret | `string` | n/a | yes |
| <a name="input_os_auth_url"></a> [os\_auth\_url](#input\_os\_auth\_url) | Openstack keystone url | `string` | `"https://dashboard.bws.burda.com:5000"` | no |
| <a name="input_os_private_network_name"></a> [os\_private\_network\_name](#input\_os\_private\_network\_name) | Name of the private network | `string` | `"private-network"` | no |
| <a name="input_os_public_network_name"></a> [os\_public\_network\_name](#input\_os\_public\_network\_name) | Name of the Openstack public network | `string` | `"Public1"` | no |
| <a name="input_os_region_name"></a> [os\_region\_name](#input\_os\_region\_name) | Openstack region name | `string` | `"DE-OFG"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key | `string` | n/a | yes |
| <a name="input_worker_count"></a> [worker\_count](#input\_worker\_count) | Number of worker nodes | `number` | `1` | no |
| <a name="input_worker_instance_flavor"></a> [worker\_instance\_flavor](#input\_worker\_instance\_flavor) | Instance flavor for worker nodes | `string` | `"BWS-T1-2-8"` | no |
| <a name="input_worker_volume_size"></a> [worker\_volume\_size](#input\_worker\_volume\_size) | Size in GB of the disk of worker nodes | `number` | `40` | no |
| <a name="input_worker_volume_type"></a> [worker\_volume\_type](#input\_worker\_volume\_type) | BWS volume type for worker nodes | `string` | `"ssd-3000-125"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_x_download_kubeconfig"></a> [x\_download\_kubeconfig](#output\_x\_download\_kubeconfig) | Get kubeconfig of cluster |
<!-- END_TF_DOCS -->
