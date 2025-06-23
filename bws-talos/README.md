Example configuration for BWS (Openstack)
=========================================

Quick start
-----------

Get `talosctl` (see https://www.talos.dev/v1.10/introduction/quickstart/) and create your cluster secrets:

```shell
talosctl gen secrets
```

Fork the argocd repo (https://github.com/valiton-k8s-blueprints/argocd). 

Create a `terraform.tfvars` file with you application credentials:

```terraform
base_name                            = "test-cluster"
os_application_credential_id         = "********* REDACTED *********"
os_application_credential_secret     = "********* REDACTED *********"
kube_api_external_ip                 = "193.x.x.x"
external_dns_domain_filters          = "['<your-project>.bws.burda.com']"
argocd_hostname                      = "argocd.<your-project>.bws.burda.com"
cert_manager_acme_registration_email = "<your email>"
gitops_applications_repo_url         = "<your applications repo>"
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
