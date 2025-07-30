# Demo Wordpress installation

## Disclaimer

This example uses Bitnami legacy container images (see https://github.com/bitnami/containers/issues/83267)
and is only an example. Do not use this example for production workloads.

## Introduction

This directory contains ArgoCD applications that will install 
Wordpress into your cluster.

Since we don't want to have secrets in this repo (or in any repo), we use
external secrets to create a random database and wordpress admin password.

You will need to change the `ingress.hostname` in `wordpress.yaml` to reflect
your setup.

## Installation

To install a demo wordpress apply the manifests here with kubectl:

```shell
# create the wordpress namespace and secrets
kubectl apply -f application-secrets.yaml

# install database
kubectl apply -f mariadb.yaml

# install worpdress
kubectl apply -f wordpress.yaml

# get wordpress admin password
kubectl -n wordpress get secret wordpress --template='{{ (index .data "wordpress-password") | base64decode }}'
```

After that open your browser and log into wordpress with "user" and the password.
