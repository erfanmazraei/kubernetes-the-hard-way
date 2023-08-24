#!/usr/bin/env bash

# For install flannel we should downlad the manifest file and apply it.
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# network pulgins installation is done by copy the config files to their folders on `/etc/cni/net.d/` and `/opt/cni/bin/`.
# this is achieved by daemon sets that deploy on the cluster and copy required file to their folders.

# Another problem is that is first place we don't have any cni, so as wee see the container stuck in createing state.
# so how we can deploy cni as container? the answer is we should use `hostNetwork: true`.
# in this way we can deploy cni with host network and don't required any cni to be installed on the cluster.

# deploy simple deployment is 2 state with and without `hostNetwork: true`.
# with out `hostNetwork: true` the pod stuck in createing state.
vim nginx.yaml
kubectl apply -f nginx.yaml

# with `hostNetwork: true` the pod is running.
vim nginx-hostNetwork.yaml
kubectl apply -f nginx-hostNetwork.yaml

# Also the service resource is not related to cni and it's working with kube-proxy.
# so with haveing cni we can expose the port with service resource.
kubectl expose deployment nginx --port 80 --type NodePort
# Now the service is created and we can access it with node ip and node port.
kubectl get svc
# NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
# kubernetes   ClusterIP   10.10.0.1     <none>        443/TCP        5d13h
# nginx        NodePort    10.10.159.2   <none>        80:30673/TCP   8s
kubectl get po -o wide
# NAME                     READY   STATUS    RESTARTS   AGE     IP               NODE        NOMINATED NODE   READINESS GATES
# nginx-86476778f9-lbhpj   1/1     Running   0          3m16s   195.206.171.56   k8s-node3   <none>           <none>
# nginx-86476778f9-mrgxt   1/1     Running   0          3m16s   195.206.171.57   k8s-node1   <none>           <none>
# nginx-86476778f9-nkhfq   1/1     Running   0          3m16s   195.206.171.50   k8s-node2   <none>           <none>
## It shows that in the case of `hostNetwork: true` the pod is running with IP of node.
## we can curl it on any ip of nodes with exposed port and see nginx page.

# Now we want to install the flannel, First we should change the configMap in the file to match our pod CIDR.
vim kube-flannel.yml
kubectl apply -f kube-flannel.yml
# now a damonset inside kube-flannel namespace is created and it's running on all nodes.

# Now we can deploy nginx with out `hostNetwork: true` and it's working. it takes ip in pod CIDR range.
kubectl apply -f nginx.yaml
kubectl get po -o wide
# NAME                     READY   STATUS    RESTARTS   AGE     IP            NODE        NOMINATED NODE   READINESS GATES
# nginx-6c557cc74d-bnjkc   1/1     Running   0          63s     10.200.0.33   k8s-node1   <none>           <none>
# nginx-6c557cc74d-m7hxm   1/1     Running   0          9m56s   10.200.2.2    k8s-node3   <none>           <none>
# nginx-6c557cc74d-wh529   1/1     Running   0          9m56s   10.200.1.2    k8s-node2   <none>           <none>


## live migration from flannel to calico. https://docs.tigera.io/calico/latest/getting-started/kubernetes/flannel/migration-from-flannel
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/flannel-migration/calico.yaml

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/flannel-migration/migration-job.yaml


## Now trying to install cni calico on fresh k8s.
# to delete flannel you can change run this.
kubectl delete -f kube-flannel.yml

# no install CRD of calico.
wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# then download the other file. this file has configuration we need to chage based on our cluster.
wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

# install calicoctl as po on kubernetes.
wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calicoctl.yaml
kubectl apply -f calicoctl.yaml


## NOTE: For changing the cni to other cni the important thing is to change the cni config file on `/etc/cni/net.d/`.
# we need to delete the old config in this direcotry and replace it with new one. other parts are like other resources we have in k8s.
# this change doesen't have any impact on running containers and is important for new containers.
# changing cni on running containers has impact when creating them again and make them don't see the old cni containers on other hosts. pay attention to this.


## There is some topics about optmise the k8s cluster etcd on episode 4_2 of k8s from the hard way.
