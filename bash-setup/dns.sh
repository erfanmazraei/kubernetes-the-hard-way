#!/usr/bin/env bash


# First we deploy simple manifests 'pod.yaml' and 'nginx.yaml'.
kubectl apply -f pod.yaml
kubectl apply -f nginx.yaml
# Then create service for nginx deployment from type 'ClusterIP'.
kubectl expose deployment nginx --port 80 --type ClusterIP

# If we go inside the container test we can see that we can't access nginx service or any other actions related to dns.
# it's because we don't have dns.
kubectl exec -it test -- sh
# ping 1.1.1.1
# PING 1.1.1.1 (1.1.1.1): 56 data bytes
# 64 bytes from 1.1.1.1: seq=0 ttl=59 time=0.956 ms
# 64 bytes from 1.1.1.1: seq=1 ttl=59 time=5.445 ms

# ping google.com
# ^C

#### NOTICE: Also if we manually ping the other pod ip we can see it's working but the service IP is not working
#### This is because the series resource only support 'TCP', 'UDP' and 'HTTP' protocols, not ICMP.
#### So we can't ping the service IP.

# pod IP:
# ping 10.200.51.17
# PING 10.200.51.17 (10.200.51.17): 56 data bytes
# 64 bytes from 10.200.51.17: seq=0 ttl=63 time=0.160 ms
# 64 bytes from 10.200.51.17: seq=1 ttl=63 time=0.110 ms

# service IP:
# ping 10.10.101.157
# PING 10.10.101.157 (10.10.101.157): 56 data bytes
# ^C
# --- 10.10.101.157 ping statistics ---


#### For installing coredns we can use 2 method: the manifest that is deprecated and helm chart.
#### first one is used in deep-dive and second is used on normal use cases.
# for first method we download manifest.
wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
mv coredns.yaml.sed coredns.yaml
# Change the 'coredns.yaml' file based our needs and apply the manifest.
vim coredns.yaml
kubectl apply -f coredns.yaml
# we see the pod is now up and running. now restart the kube-proxy on workers to changes take affect.
ssh root@k8s-node1 "sudo systemctl restart kube-proxy"
ssh root@k8s-node2 "sudo systemctl restart kube-proxy"
ssh root@k8s-node3 "sudo systemctl restart kube-proxy"

# Go to a pod and test if the dns is working.
kubectl exec -it test -- sh
# we see all the dns query are working now.
# ping google.com
# PING google.com (172.253.116.101): 56 data bytes
# 64 bytes from 172.253.116.101: seq=0 ttl=60 time=10.266 ms
# 64 bytes from 172.253.116.101: seq=1 ttl=60 time=16.386 ms

# nslookup nginx
# Server:		10.10.0.10
# Address:	10.10.0.10:53
# ** server can't find nginx.cluster.local: NXDOMAIN
# ** server can't find nginx.cluster.local: NXDOMAIN
# Name:	nginx.default.svc.cluster.local
# Address: 10.10.101.157

# The cni plugin of calico is not installled properly so we change to flannel for this moment.


# Config autocompletion of helm for bash.
helm completion bash > /etc/bash_completion.d/helm

#### For installing coredns with method 2 we use helm chart.
# Add the helm repo of coredns.
helm repo add coredns https://coredns.github.io/helm
wget https://raw.githubusercontent.com/coredns/helm/master/charts/coredns/values.yaml -O coredns-values.yaml
# Change the 'coredns-values.yaml' file based our needs and install the helm chart.
vim coredns-values.yaml
helm --namespace=kube-system install coredns coredns/coredns -f coredns-values.yaml
# kubectl get po -A
# NAMESPACE      NAME                               READY   STATUS    RESTARTS   AGE
# default        nginx-6c557cc74d-c6pqz             1/1     Running   0          118m
# default        nginx-6c557cc74d-wj5q2             1/1     Running   0          118m
# default        nginx-6c557cc74d-zb6jf             1/1     Running   0          118m
# default        test                               1/1     Running   0          118m
# kube-flannel   kube-flannel-ds-f2jq7              1/1     Running   0          119m
# kube-flannel   kube-flannel-ds-lw8t6              1/1     Running   0          119m
# kube-flannel   kube-flannel-ds-xmbfz              1/1     Running   0          119m
# kube-system    coredns-coredns-7d68c6d6f4-hnv5c   1/1     Running   0          13m
# kube-system    coredns-coredns-7d68c6d6f4-jbzgx   1/1     Running   0          13m

## Now we want change the config of the helm release. first list it.
helm -n kube-system ls
# NAME   	NAMESPACE  	REVISION	UPDATED                                  	STATUS  	CHART         	APP VERSION
# coredns	kube-system	1       	2023-08-04 23:12:31.846726534 +0330 +0330	deployed	coredns-1.24.3	1.10.1
## Get the values of the current release that is deployed.
helm -n kube-system get values coredns
# USER-SUPPLIED VALUES:
# affinity: {}
# autoscaler:
#   affinity: {}
#   configmap:
#     annotations: {}
#   .
#   .
#   .
#   clusterIP: 10.10.0.10
#   name: ""
# serviceAccount:
#   annotations: {}
#   create: false
#   name: ""
# serviceType: ClusterIP
# terminationGracePeriodSeconds: 30
# tolerations: []
# topologySpreadConstraints: []
# zoneFiles: []

## for upgrading the release with new config use below config.
helm -n kube-system upgrade -i coredns coredns/coredns -f coredns-values.yaml
# Release "coredns" has been upgraded. Happy Helming!

## We can see history of helm relese we deployed like below:
helm -n kube-system history coredns
# REVISION	UPDATED                 	STATUS         	CHART         	APP VERSION	DESCRIPTION
# 1       	Fri Aug  4 23:12:31 2023	superseded     	coredns-1.24.3	1.10.1     	Install complete
# 2       	Fri Aug  4 23:45:10 2023	pending-upgrade	coredns-1.24.3	1.10.1     	Preparing upgrade
# 3       	Fri Aug  4 23:57:22 2023	superseded     	coredns-1.24.3	1.10.1     	Rollback to 1
# 4       	Sat Aug  5 00:00:37 2023	deployed       	coredns-1.24.3	1.10.1     	Upgrade complete
