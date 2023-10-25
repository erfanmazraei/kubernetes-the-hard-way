#!/usr/bin/env bash


## This setup has same actions like `node1.sh` except it will be bootstrap.

## We should do some system configs on worker nodes.
# disable all swap on worker node.
swapoff -a
# Edit `/etc/fstab` to comment swap section.
vim /etc/fstab

# Config cgroup and disable ipv6 on grub then update grub.
vim /etc/default/grub
# Edit this line -> GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0 ipv6.disable=1"
update-grub

# Enable and load br_netfilter module.
modprobe br_netfilter
echo br_netfilter >> /etc/modules

# Enable and load overlay module.
modprobe overlay
echo overlay >> /etc/modules

# Config kernel parameters for br_netfilter and ip_forward.
cat <<EOF > /etc/sysctl.d/10-kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF

# Reload all config of sysctl.
sysctl --system

# Config DNS in systemd config files.
vim /etc/systemd/resolved.conf
# Edit this line -> DNS=1.1.1.1
systemctl daemon-reload
systemctl restart systemd-resolved
# Check DNS with these commands.
systemd-resolve --status
# or
cat /etc/resolv.conf

# To enable kubernetes `kubectl port-forward` feature, we should install below packages.
apt install socat conntrack ipset

# Now reboot the server.
reboot

# Now install `crictl` which is a CLI tool for kubernetes to interact with OCI complaint runtimes.
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.1/crictl-v1.27.1-linux-amd64.tar.gz
tar -xvf crictl-v1.27.1-linux-amd64.tar.gz
mv crictl /usr/local/bin/
chown root: /usr/local/bin/crictl

# Install containerd as highlevel OCI runtime.
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
tar -xvf containerd-1.7.2-linux-amd64.tar.gz
mv bin/* /usr/local/bin/

## We forgot to install `runc` as our lowlevel oci runtime, so the pod didnot create because of this problem.
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
chmod +x runc.amd64
mv runc.amd64 /usr/local/bin/runc

# Install basic cni-plugins.
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
# Create cni dir. (This path MUST be `/opt/cni/bin`)
mkdir -p /opt/cni/bin/
tar -xvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/

## Create network config files of cni.
mkdir -p /etc/cni/net.d/
# Create `99-loopback.conf` config file for cni.
vim /etc/cni/net.d/99-loopback.conf
## The above config provide lo interface inside container and is required for node state be ready.

# Create systemd service file for containerd.
vim svc-containerd.sh
./svc-containerd.sh

# Start containerd service.
systemctl daemon-reload
systemctl enable --now containerd

# Set required dns record of worker-k8s-node2 in controller nodes and worker-k8s-node2.
vim /etc/hosts

# Download and extract kubernetes server binary and move to `/usr/local/bin/`.
wget https://dl.k8s.io/v1.26.4/kubernetes-server-linux-amd64.tar.gz
tar -xvf kubernetes-server-linux-amd64.tar.gz
mv kubernetes/server/bin/{kube-proxy,kubelet} /usr/local/bin/

# Create required direcotories and their permissions.
mkdir -p /etc/kubernetes/certs
mkdir -p /etc/kubernetes/configs
mkdir -p /etc/kubernetes/manifests

# Move required certs and files to k8s-node2 node.
scp kube-ca.crt kube-proxy.crt kube-proxy.key kube-proxy.kubeconfig root@k8s-node2:/root/

# Move certs and keys and files to their folders.
mv ./*.crt ./*.key /etc/kubernetes/certs/
mv ./*.kubeconfig /etc/kubernetes/configs/

# Create `kube-proxy.yaml` config file for kube-proxy of worker-k8s-node2.
vim /etc/kubernetes/configs/kube-proxy.yaml
# Create systemd service file for kube-proxy of worker-k8s-node2.
vim svc-kube-proxy.sh
./svc-kube-proxy.sh

# Enable and start kube-proxy services.
systemctl daemon-reload
systemctl enable --now kube-proxy
# The kube-proxy is running and the only error is that it can not connect to kubelet.


## Run this on workerstation node you access apiserver and previously generated certs on it.
# Create `bootstrap-token.yaml` file for create token of bootstraping.
vim script-bootstrap-token.sh
./script-bootstrap-token.sh
# NOTICE: the token-id should be 6 char string and token-secret should be 16 char string.
# Now apply the `bootstrap-token.yaml` file and check if the token is generated.
kubectl apply -f bootstrap-token.yaml
kubectl get secrets -n kube-system
# It looks like this:
# NAME                     TYPE                            DATA   AGE
# bootstrap-token-abc123   bootstrap.kubernetes.io/token   7      19s


# Now create required rbac role binding for bootstrap worker.
vim bootstrap-allow-create-csr.yaml
vim bootstrap-allow-auto-approve-csr.yaml
vim bootstrap-allow-auto-renew-certificate.yaml
kubectl apply -f bootstrap-allow-create-csr.yaml
kubectl apply -f bootstrap-allow-auto-approve-csr.yaml
kubectl apply -f bootstrap-allow-auto-renew-certificate.yaml
# the above rbac role binding and cluster roles are based on these two commands, you can find more detail by running them.
kubectl get clusterroles.rbac.authorization.k8s.io
kubectl get clusterrolebindings.rbac.authorization.k8s.io


## Create kubeconfig file for bootstrap nodes.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-bootstrap.kubeconfig
# Create bootstrap-token and its credentials in kubeconfig file.
kubectl config set-credentials bootstrap-token --token abc123.f78baa5b8d5a4bc5 --kubeconfig kube-bootstrap.kubeconfig # --token tkenid.secret
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user bootstrap-token --kubeconfig kube-bootstrap.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-bootstrap.kubeconfig
# Check content of kubeconfig file.
cat kube-bootstrap.kubeconfig

# Move required bootstrap.kubeconfig bootstrap node.
scp kube-bootstrap.kubeconfig root@k8s-node2:/root/

# Move bootstrap.kubeconfig to its folder.
mv ./*.kubeconfig /etc/kubernetes/configs/
# Change ownership and permissions of files.
chown -R root: /etc/kubernetes/
chmod -R 600 /etc/kubernetes/


# Create `kubelet.yaml` config file for kubelet of worker-k8s-node2.
# this file in repository is named kubelet-bootstrap.yaml.
vim /etc/kubernetes/configs/kubelet.yaml
# Create systemd service file for kubelet of worker-k8s-node2.
vim svc-kubelet-bootstrap.sh
./svc-kubelet-bootstrap.sh

# Enable and start kubelet service.
systemctl daemon-reload
systemctl enable --now kubelet


# When kubelet start successfully and send csr request to apiserver, we should approve it there.
kubectl get csr
# NAME        AGE     SIGNERNAME                                    REQUESTOR                 REQUESTEDDURATION   CONDITION
# csr-gq57d   3m12s   kubernetes.io/kubelet-serving                 system:node:k8s-node2     <none>              Pending
# csr-vj64d   3m26s   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abc123   <none>              Approved,Issued
kubectl certificate approve csr-gq57d
# certificatesigningrequest.certificates.k8s.io/csr-gq57d approved
kubectl get csr
# NAME        AGE     SIGNERNAME                                    REQUESTOR                 REQUESTEDDURATION   CONDITION
# csr-gq57d   6m21s   kubernetes.io/kubelet-serving                 system:node:k8s-node2     <none>              Approved,Issued
# csr-vj64d   6m35s   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abc123   <none>              Approved,Issued

## now the node should be in ready state.


## leases are part of k8s api and are used to track the state of a node.
# the kube-node-lease namespace don't have any pod in it but has workers leases in it.
kubectl -n kube-node-lease get leases.coordination.k8s.io
# NAME        HOLDER      AGE
# k8s-node1   k8s-node1   2d5h
# k8s-node2   k8s-node2   18m
kubectl -n kube-system get leases.coordination.k8s.io # you can see kube-controller-manager leader
# NAME                                        HOLDER                                                                           AGE
# kube-apiserver-d4ftos6jtdwdvmqptijaf7bv5u   kube-apiserver-d4ftos6jtdwdvmqptijaf7bv5u_0a1fccbc-fa62-4093-b337-f33707313d4a   5d5h
# kube-apiserver-mjrw33vzr3t6zn3di523isazie   kube-apiserver-mjrw33vzr3t6zn3di523isazie_de4d1367-0925-47ec-a68d-e25221ac2ca8   5d5h
# kube-apiserver-xso55ndwqvp6ekjiob2p7dleka   kube-apiserver-xso55ndwqvp6ekjiob2p7dleka_f400581e-6b20-4e90-96b5-a514af71181f   5d5h
# kube-controller-manager                     k8s-contorller3_dd70b72d-8baf-477d-9f91-3f1b73916fef                             4d14h
# kube-scheduler                              k8s-contorller1_554e506b-bb73-48a6-a847-ae35e91e8b62                             3d12h


# We can create deployment with 3 replica with below command.
kubectl create deployment nginx-new --image nginx:alpine --replicas 3
# It shows that on the nodes that don't have bridge or cni, it stuck in network creating state.
kubectl get po -o wide
# NAME                         READY   STATUS              RESTARTS        AGE     IP            NODE        NOMINATED NODE   READINESS GATES
# nginx-748c667d99-7npfw       1/1     Running             1 (5h30m ago)   3d12h   10.200.0.92   k8s-node1   <none>           <none>
# nginx-new-577c47dc65-fwsfk   0/1     ContainerCreating   0               3m28s   <none>        k8s-node2   <none>           <none>
# nginx-new-577c47dc65-j4ndz   1/1     Running             0               3m28s   10.200.0.93   k8s-node1   <none>           <none>
# nginx-new-577c47dc65-zct8r   0/1     ContainerCreating   0               3m28s   <none>        k8s-node3   <none>           <none>
