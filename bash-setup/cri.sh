#!/usr/bin/env bash


# the hierarchy of runtime is like this: k8s -> runtime(containerd) -> runc -> container
# the runtime section could be changed to something else like more detail (containerd + shim) or another thing like CRI-O.
# conttainerd has 'ctr' that is a CLI tool for containerd. we can use it for running container with fromat like runc.
ctr i pull quay.io/bedrock/nginx:alpine3.17-slim
ctr i ls
ctr run quay.io/bedrock/nginx:alpine3.17-slim test
ctr c ls
ctr c rm test


# Now install cri-o in node3.
wget https://storage.googleapis.com/cri-o/artifacts/cri-o.amd64.v1.26.4.tar.gz
tar -xvf cri-o.amd64.v1.26.4.tar.gz
install cri-o/bin/crio /usr/local/bin/
install cri-o/bin/pinns /usr/local/bin/
install cri-o/bin/conmon /usr/local/bin/

mkdir -p /var/lib/crio
mkdir -p /etc/crio
mkdir -p /etc/containers

## Create config file and other needed files for crio.
# This config defines crio use cgroupfs for driver instead of systemd.
cat <<EOF > /etc/crio/crio.conf
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"
EOF

# This config defines any image from diffrent registries can be pulled.
cat <<EOF > /etc/containers/policy.json
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ]
}
EOF

# This config defines crio should search on which registries for unqualified images.
cat <<EOF > /etc/containers/registries.conf
unqualified-search-registries = ["docker.io"]
EOF

# Create systemd service file for crio.
vim svc-crio.sh
./svc-crio.sh

# Start crio service.
systemctl daemon-reload
systemctl enable --now crio


# Now it's time to change kubelet to use crio, if it's needed to change 'cgroupDriver' on 'kubelet.yaml' file.
# In this scenario we change crio to use 'cgroupfs' so it's not needed to change 'kubelet.yaml' file.
# We should only change the service file of kubelet to use crio as runtime.
vim /etc/systemd/system/kubelet.service
# change this line:
# --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
# to this line:
# --container-runtime-endpoint=unix:///var/run/crio/crio.sock \\

systemctl daemon-reload
systemctl restart kubelet

## Now we see that the runtime of node is changed to crio.
kubectl get no -o wide
# NAME        STATUS   ROLES    AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION         CONTAINER-RUNTIME
# k8s-node1   Ready    <none>   2d20h   v1.26.4   195.206.171.57   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-10-cloud-amd64   containerd://1.7.2
# k8s-node2   Ready    <none>   2d20h   v1.26.4   195.206.171.50   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-10-cloud-amd64   containerd://1.7.2
# k8s-node3   Ready    <none>   2d20h   v1.26.4   195.206.171.56   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-10-cloud-amd64   cri-o://1.26.4


# Now create simple pod on k8s-node3.
vim pod.yaml
kubectl apply -f pod.yaml

######
# The above config works fine, but in kube-deep-dive course after some debugging it end of with this config for solving problem.
cat <<EOF > /etc/crio/crio.conf
[crio.image]
default_transport = "docker://"

[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"
EOF

cat <<EOF > /etc/containers/registries.conf
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
insecure = false
blocked = false
location = "registry-1.docker.io"
EOF
# It seems the above config is extra.
######


## Now we try to exec on container or port-forwarding to it.
kubectl port-forward test 8080:80
# error: error upgrading connection: unable to upgrade connection: Forbidden (user=system:kube-apiserver-to-kubelet, verb=create, resource=nodes, subresource=proxy)
kubectl exec test -- nginx -v
# error: unable to upgrade connection: Forbidden (user=system:kube-apiserver-to-kubelet, verb=create, resource=nodes, subresource=proxy)

## This error is because apiserver need to connect kubelet for specific action like exec, port-farwarding, etc.
## We generate a cert for this purpose but it's not allowed now, because we don't have any rbac for it.
## To solve this issue we need to build clusterRole and clusterRoleBinding for the 'system:kube-apiserver-to-kubelet' user.
vim apiserver-to-kubelet.yaml
kubectl apply -f apiserver-to-kubelet.yaml
# clusterrole.rbac.authorization.k8s.io/system:kube-apiserver-to-kubelet created
# clusterrolebinding.rbac.authorization.k8s.io/system:kube-apiserver created

## Now we can exec on container or port-forwarding to it.
kubectl port-forward test 8888:80
# Forwarding from 127.0.0.1:8888 -> 80
# Forwarding from [::1]:8888 -> 80
kubectl exec test -- nginx -v
# nginx version: nginx/1.25.1

###### NOTE: 'NOMINATED NODE' means when a pod is primitive to a node(because of resource or other thing.), it's usually nominated to that node.
###### NOTE: 'READINESS GATES' means when a pod is not ready, it's add extra condition to pod prob to define when pod is ready. for example depend on cloud provider load-balancer is ready or not.
