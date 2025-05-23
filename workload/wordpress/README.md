Demo Wordpress installation
===========================

This directory contains ArgoCD applications that will install 
Wordpress into your cluster.

Since we don't want to have secrets in this repo (or in any repo), we use
a [secret generator](https://github.com/mittwald/kubernetes-secret-generator) 
to create a random database and wordpress admin password.

You will need to change the `ingress.hostname` in `wordpress.yaml` to reflect
your setup.

To install a demo wordpress apply the manifests here with kubectl:

```shell
# create the wordpress namespace and an empty secret
kubectl apply -f secret.yaml

# install secret generator
kubectl apply -f secret-generator.yaml

# install database
kubectl apply -f mariadb.yaml

# install worpdress
kubectl apply -f wordpress.yaml

# get wordpress admin password
kubectl -n wordpress get secret wordpress --template='{{ (index .data "wordpress-password") | base64decode }}'
```

After that open your browser and log into wordpress with "user" and the password.
