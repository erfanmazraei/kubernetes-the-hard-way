#!/usr/bin/env bash


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

# Now reboot the server.
reboot

# To enable kubernetes `kubectl port-forward` feature, we should install below packages.
apt install socat conntrack ipset


# Now install `crictl` which is a CLI tool for kubernetes to interact with OCI complaint runtimes.
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.1/crictl-v1.27.1-linux-amd64.tar.gz
tar -xvf crictl-v1.27.1-linux-amd64.tar.gz
mv crictl /usr/local/bin/
chown root: /usr/local/bin/crictl

# Install containerd as highlevel OCI runtime.
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
tar -xvf containerd-1.7.2-linux-amd64.tar.gz
mv bin/* /usr/local/bin/

# Install basic cni-plugins.
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
# Create cni dir. (This path MUST be `/opt/cni/bin`)
mkdir -p /opt/cni/bin/
tar -xvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/

# Enable and load overlay module.
modprobe overlay
echo overlay >> /etc/modules

# Create systemd service file for containerd.
vim svc-containerd.sh
./svc-containerd.sh

# Start containerd service.
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd


# write openssl-kubelet-worker-k8s-node1.conf config file for kubelet of k8s-node1.
vim openssl-kubelet-worker-k8s-node1.conf

# Generate certificate signing request for kubelet on k8s-node1.
openssl req -newkey rsa:2048 -nodes -keyout kube-worker-k8s-node1.key -subj "/CN=system:node:k8s-node1/O=system:nodes" -config openssl-kubelet-worker-k8s-node1.conf -out kube-worker-k8s-node1.csr
# Sign the certificate CSR of kubelet on k8s-node1 with the root CA.
openssl x509 -req -in kube-worker-k8s-node1.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile openssl-kubelet-worker-k8s-node1.conf -out kube-worker-k8s-node1.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-worker-k8s-node1.crt


## Create kubeconfig file for k8s-node1 user.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-worker-k8s-node1.kubeconfig
# Create k8s-node1 and its credentials in kubeconfig file.
kubectl config set-credentials system:node:k8s-node1 --client-certificate kube-worker-k8s-node1.crt --client-key kube-worker-k8s-node1.key --embed-certs --kubeconfig kube-worker-k8s-node1.kubeconfig
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user system:node:k8s-node1 --kubeconfig kube-worker-k8s-node1.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-worker-k8s-node1.kubeconfig
# Check content of kubeconfig file.
cat kube-worker-k8s-node1.kubeconfig


# Download and extract kubernetes server binary and move to `/usr/local/bin/`.
wget https://dl.k8s.io/v1.26.4/kubernetes-server-linux-amd64.tar.gz
tar -xvf kubernetes-server-linux-amd64.tar.gz
mv kubernetes/server/bin/{kube-proxy,kubelet} /usr/local/bin/

# Move required certs and files to k8s-node1 node.
scp kube-ca.crt kube-proxy.crt kube-proxy.key kube-proxy.kubeconfig kube-worker-k8s-node1.crt kube-worker-k8s-node1.key kube-worker-k8s-node1.kubeconfig root@k8s-node1:/root/

# Create required direcotories and their permissions.
mkdir -p /etc/kubernetes/certs
mkdir -p /etc/kubernetes/configs
mkdir -p /etc/kubernetes/manifests
# Move certs and keys and files to their folders.
mv ./*.crt ./*.key /etc/kubernetes/certs/
mv ./*.kubeconfig /etc/kubernetes/configs/
# Change ownership and permissions of files.
chown -R root: /etc/kubernetes/
chmod -R 600 /etc/kubernetes/

# Set required dns record of worker-k8s-node1 in controller nodes and worker-k8s-node1.
vim /etc/hosts


# Create `kubelet.yaml` config file for kubelet of worker-k8s-node1.
vim /etc/kubernetes/configs/kubelet.yaml
# Create systemd service file for kubelet of worker-k8s-node1.
vim svc-kubelet.sh
./svc-kubelet.sh

# Create `kube-proxy.yaml` config file for kube-proxy of worker-k8s-node1.
vim /etc/kubernetes/configs/kube-proxy.yaml
# Create systemd service file for kube-proxy of worker-k8s-node1.
vim svc-kube-proxy.sh
./svc-kube-proxy.sh


## Create network config files of cni.
mkdir -p /etc/cni/net.d/
# Create `10-bridge.conf` config file for cni.
vim /etc/cni/net.d/10-bridge.conf
# Create `99-loopback.conf` config file for cni.
vim /etc/cni/net.d/99-loopback.conf

# Enable and start kubelet and kube-proxy services.
systemctl daemon-reload
systemctl enable --now kubelet
systemctl enable --now kube-proxy

## Now the node has been registered to apiserver and is in ready state.
# the path of cni configs `/etc/cni` is actively monitored and if the configs move from there
# the node state will change to notReady and if it returned immediately it be Ready again.

## We forgot to install `runc` as our lowlevel oci runtime, so the pod didnot create because of this problem.
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
chmod +x runc.amd64
mv runc.amd64 /usr/local/bin/runc

# Now our nginx is ready and can be accessed from inside of cluster.
# but still we have lots of problems, for example if we run below command:
kubectl exec nginx-748c667d99-7npfw -- ip a
# error: unable to upgrade connection: Forbidden (user=system:kube-apiserver-to-kubelet, verb=create, resource=nodes, subresource=proxy)
# It show forbidden access, in next steps we go and solve other problems.
