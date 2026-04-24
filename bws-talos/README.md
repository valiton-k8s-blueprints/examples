# Example configuration for BWS (Openstack)

This is an example configuration to provision a Talos Linux cluster on BWS (Openstack).

## Quick start

### Prerequisites

1. Get access to a BWS project.
2. Create a floating IP to access the cluster:
   
   Manually create a Floating-IP: https://dashboard.bws.burda.com/network/floatingip
   
   Button "Allocate IP"
   
   Select "Network"
   
   Select "Owned Subnet"
   
   Leave "Floating IP Address" empty
   
   Button "OK"
. 
4. Create application credentials to authenticate to BWS.

   Remember to select the desired project after Login.

   Go to https://dashboard.bws.burda.com/user/application-credentials
   or click your account icon (top-right in the web-UI) => "User Center" => "Application Credentials"

   Button "Create Application Credentials"

   Roles needed: "load-balancer_member", "member"

5. Download the Talos Linux image and upload it to BWS. Name it 'Talos' (this is the default for this configuration).
5. Get `talosctl` (see https://www.talos.dev/v1.10/introduction/quickstart/).
6. Create your cluster secrets:
    ```shell
    talosctl gen secrets
    ```
7. Fork the argocd repo (https://github.com/valiton-k8s-blueprints/argocd).

### Configure the configuration 

Create a `terraform.tfvars` file with your application credentials:

```terraform
base_name                            = "test-cluster"
environment                          = "development"
os_project_name                      = "<your project>"
os_application_credential_id         = "********* REDACTED *********"
os_application_credential_secret     = "********* REDACTED *********"
kube_api_external_ip                 = "<your floating ip>"
external_dns_domain_filters          = "['<your-project>.bws.burda.com']"
cert_manager_acme_registration_email = "<your email>"
gitops_applications_repo_url         = "<your applications repo>"
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
## get talosconfig
tofu output -raw talosconfig > talosconfig

## get kubeconfig (will be added to the default file in ~/.kube/config)
talosctl --talosconfig ./talosconfig --nodes 10.x.x.x kubeconfig

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


