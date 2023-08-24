#!/usr/bin/env bash

# Add helm repo for metallb, update repo and install metallb.
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb -n metallb-system --create-namespace

# Then we apply the manifest of ip pool and interface to listen on for metallb.
vim metallb.yaml
kubectl apply -f metallb.yaml


# Add helm repo for ingress-nginx, update repo and install ingress-nginx.
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

## Now we can check the service of ingress-nginx get it's external ip and test it. we can see the nginx page is up on external ip.
kubectl -n ingress-nginx get svc
# NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
# ingress-nginx-controller             LoadBalancer   10.10.17.170    195.206.181.239   80:30002/TCP,443:31012/TCP   6m
# ingress-nginx-controller-admission   ClusterIP      10.10.254.252   <none>            443/TCP                      6m
