#!/usr/bin/env bash


# Generate root CA self-singed certificates for kubernetes.
openssl req -newkey rsa:2048 -nodes -keyout kube-ca.key -x509 -subj "/CN=kubernetes-ca" -days 3650 -out kube-ca.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-ca.crt

# Generate certificate signing request for kube-admin.
openssl req -newkey rsa:2048 -nodes -keyout kube-admin.key -subj "/CN=admin/O=system:masters" -out kube-admin.csr
# Sign the certificate CSR of kube-admin with the root CA.
openssl x509 -req -in kube-admin.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -out kube-admin.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-admin.crt

# Generate certificate signing request for kube-proxy.
openssl req -newkey rsa:2048 -nodes -keyout kube-proxy.key -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr
# Sign the certificate CSR of kube-proxy with the root CA.
openssl x509 -req -in kube-proxy.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -out kube-proxy.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-proxy.crt

# Generate certificate signing request for kube-controller-manager.
openssl req -newkey rsa:2048 -nodes -keyout kube-controller-manager.key -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr
# Sign the certificate CSR of kube-controller-manager with the root CA.
openssl x509 -req -in kube-controller-manager.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -out kube-controller-manager.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-controller-manager.crt

# Generate certificate signing request for kube-scheduler.
openssl req -newkey rsa:2048 -nodes -keyout kube-scheduler.key -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr
# Sign the certificate CSR of kube-scheduler with the root CA.
openssl x509 -req -in kube-scheduler.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -out kube-scheduler.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-scheduler.crt


# write openssl-kube-apiserver.conf config file for apiserver.
vim openssl-kube-apiserver.conf

# Generate certificate signing request for kube-apiserver.
openssl req -newkey rsa:2048 -nodes -keyout kube-apiserver.key -subj "/CN=kube-apiserver" -config openssl-kube-apiserver.conf -out kube-apiserver.csr
# Sign the certificate CSR of kube-apiserver with the root CA.
openssl x509 -req -in kube-apiserver.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile openssl-kube-apiserver.conf -out kube-apiserver.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-apiserver.crt


# write openssl-kube-apiserver-to-kubelet.conf config file for kube-apiserver-to-kubelet connection.
vim openssl-kube-apiserver-to-kubelet.conf

# Generate certificate signing request for kube-apiserver-to-kubelet.
openssl req -newkey rsa:2048 -nodes -keyout kube-apiserver-to-kubelet.key -subj "/CN=system:kube-apiserver-to-kubelet/O=system:kube-apiserver-to-kubelet" -config openssl-kube-apiserver-to-kubelet.conf -out kube-apiserver-to-kubelet.csr
# Sign the certificate CSR of kube-apiserver-to-kubelet with the root CA.
openssl x509 -req -in kube-apiserver-to-kubelet.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile openssl-kube-apiserver-to-kubelet.conf -out kube-apiserver-to-kubelet.crt
# See the details of the certificates.
openssl x509 -text -noout -in kube-apiserver-to-kubelet.crt


# Generate certificate signing request for service-account.
openssl req -newkey rsa:2048 -nodes -keyout service-account.key -subj "/CN=service-accounts" -out service-account.csr
# Sign the certificate CSR of kube-scheduler with the root CA.
openssl x509 -req -in service-account.csr -CA kube-ca.crt -CAkey kube-ca.key -CAcreateserial -days 3650 -out service-account.crt
# See the details of the certificates.
openssl x509 -text -noout -in service-account.crt

# Generate certificate signing request for etcd-kube-apiserver to connect apiserver to etcd.
openssl req -newkey rsa:2048 -nodes -keyout etcd-kube-apiserver.key -subj "/CN=kube-apiserver" -out etcd-kube-apiserver.csr
# Sign the certificate CSR of etcd-kube-apiserver with the root CA.
openssl x509 -req -in etcd-kube-apiserver.csr -CA etcd-ca.crt -CAkey etcd-ca.key -CAcreateserial -days 3650 -out etcd-kube-apiserver.crt
# See the details of the certificates.
openssl x509 -text -noout -in etcd-kube-apiserver.crt


# Config autocompletion of kubectl for bash.
kubectl completion bash > /etc/bash_completion.d/kubectl

## Create kubeconfig file for admin user.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-admin.kubeconfig
# Create admin and its credentials in kubeconfig file.
kubectl config set-credentials admin --client-certificate kube-admin.crt --client-key kube-admin.key --embed-certs --kubeconfig kube-admin.kubeconfig
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user admin --kubeconfig kube-admin.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-admin.kubeconfig
# Check content of kubeconfig file.
cat kube-admin.kubeconfig

## Create kubeconfig file for kube-controller-manager user.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-controller-manager.kubeconfig
# Create kube-controller-manager and its credentials in kubeconfig file.
kubectl config set-credentials system:kube-controller-manager --client-certificate kube-controller-manager.crt --client-key kube-controller-manager.key --embed-certs --kubeconfig kube-controller-manager.kubeconfig
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user system:kube-controller-manager --kubeconfig kube-controller-manager.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-controller-manager.kubeconfig
# Check content of kubeconfig file.
cat kube-controller-manager.kubeconfig

## Create kubeconfig file for kube-scheduler user.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-scheduler.kubeconfig
# Create kube-scheduler and its credentials in kubeconfig file.
kubectl config set-credentials system:kube-scheduler --client-certificate kube-scheduler.crt --client-key kube-scheduler.key --embed-certs --kubeconfig kube-scheduler.kubeconfig
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user system:kube-scheduler --kubeconfig kube-scheduler.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-scheduler.kubeconfig
# Check content of kubeconfig file.
cat kube-scheduler.kubeconfig

## Create kubeconfig file for kube-proxy user.
# Set cluster and ca certificate in kubeconfig file.(the server address is the address of loadbalancer)
kubectl config set-cluster cluster.local --certificate-authority=kube-ca.crt --embed-certs --server https://89.34.98.145:6443 --kubeconfig kube-proxy.kubeconfig
# Create kube-proxy and its credentials in kubeconfig file.
kubectl config set-credentials system:kube-proxy --client-certificate kube-proxy.crt --client-key kube-proxy.key --embed-certs --kubeconfig kube-proxy.kubeconfig
# Create context `default` and it's required cluster and user in kubeconfig file.
kubectl config set-context default --cluster cluster.local --user system:kube-proxy --kubeconfig kube-proxy.kubeconfig
# Set current context to use `default` in kubeconfig file.
kubectl config use-context default --kubeconfig kube-proxy.kubeconfig
# Check content of kubeconfig file.
cat kube-proxy.kubeconfig


## Create encryption-config.yaml file to encrypt secrets at first and store them encrypted on etcd.
vim encryption-config.yaml
# Generate random secret and put it on `secret` field of encryption-config.yaml.
head -c 32 /dev/urandom | base64


## Execute this commands on apiserver nodes.
# Download and extract kubernetes server binary and move to `/usr/local/bin/`.
wget https://dl.k8s.io/v1.26.4/kubernetes-server-linux-amd64.tar.gz
tar -xzvf kubernetes-server-linux-amd64.tar.gz
mv kubernetes/server/bin/kube-apiserver /usr/local/bin/

# Move required certs and files to control-plane nodes.
for i in k8s-contorller1 k8s-contorller2 k8s-contorller3; do
  scp kube-ca.crt encryption-config.yaml etcd-ca.crt etcd-kube-apiserver.crt etcd-kube-apiserver.key kube-apiserver-to-kubelet.crt kube-apiserver-to-kubelet.key kube-apiserver.crt kube-apiserver.key kube-controller-manager.crt kube-controller-manager.key kube-controller-manager.kubeconfig kube-scheduler.crt kube-scheduler.key kube-scheduler.kubeconfig service-account.crt service-account.key root@"${i}":/root/
done

# Create required direcotories and their permissions.
mkdir -p /etc/kubernetes/certs
mkdir -p /etc/kubernetes/configs
mkdir -p /etc/kubernetes/manifests
# Move certs and keys and files to their folders.
mv ./*.crt ./*.key /etc/kubernetes/certs/
mv ./*.kubeconfig ./cencryption-config.yaml /etc/kubernetes/configs/
# Change ownership and permissions of files.
chown -R root: /etc/kubernetes/
chmod -R 600 /etc/kubernetes/

# Create systemd service file for apiserver.
apt install -y jq
vim svc-apiserver.sh
./svc-apiserver.sh

# Start apiserver service.
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver


# Because we don't setup loadbalancer yet, we edit kube-admin.kubeconfig server section
# from loadbalancer to first apiserver node so we can connect to apiserver.
vim kube-admin.kubeconfig

## Run these command to check apiserver is functional.
# We don't have any node but connection is established.
kubectl --kubeconfig kube-admin.kubeconfig get no
# Check namespace.
kubectl --kubeconfig kube-admin.kubeconfig get ns
# Check component status.
kubectl --kubeconfig kube-admin.kubeconfig get cs

# To test we run simple container.
kubectl --kubeconfig kube-admin.kubeconfig run test --image nginx
# Error from server (Forbidden): pods "test" is forbidden: error looking up service account default/default: serviceaccount "default" not found
# the above error shows we don't have any service account.

# Temporary we create default service account and then run container again.
kubectl --kubeconfig kube-admin.kubeconfig create sa default
kubectl --kubeconfig kube-admin.kubeconfig run test --image nginx

# Check pod and shows it is in pending status because we don't have any
# scheduler, controller-manager or worker node.
kubectl --kubeconfig kube-admin.kubeconfig get po # pending

# Delete extra things created for test.
kubectl --kubeconfig kube-admin.kubeconfig delete po test
kubectl --kubeconfig kube-admin.kubeconfig delete sa default
