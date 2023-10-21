#!/usr/bin/env bash


# Install binary of kube-controller-manager and kube-scheduler in `/usr/local/bin/`  ( in controller nodes )
install kubernetes/server/bin/kube-controller-manager /usr/local/bin/
install kubernetes/server/bin/kube-scheduler /usr/local/bin/

# Create systemd service file for kube-controller-manager.
vim svc-controller-manager.sh # you can see this file in this project and bash-setup directory
./svc-controller-manager.sh
# In the above config, we have option `--cluster-signing-cert-file`, `--cluster-signing-key-file`
# which are used to sign certificates requests that used in RBAC (also needed in node bootstrap) and need key of ca,
# so it's better to create a chain and use intermediate as ca not the main one.
for i in k8s-contorller1 k8s-contorller2 k8s-contorller3; do # this file  use from svc-controller-manager.sh
  scp kube-ca.key root@"${i}":/root/
done
mv ./*.key /etc/kubernetes/certs/
chown -R root: /etc/kubernetes/
chmod -R 600 /etc/kubernetes/

# Start apiserver service.
systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager

## Now the kube-controller-manger is up but can't work properly. we have below error on log.
## HTTP Trace: Dial to tcp:89.34.98.145:6443 failed: dial tcp 89.34.98.145:6443: i/o timeout
## This is because we have not configured the loadbalancer yet, so we go to the next step to setup them.


## Setup loadbalancer nodes.
apt install haproxy keepalived 
# Set required dns records of apiservers in loadbalancer nodes.
vim /etc/hosts

## Edit keepalived config files
# on node1 put keepalived-master.conf.
vim /etc/keepalived/keepalived.conf # you can see this file in this project and bash-setup directory
# on node1 put keepalived-backup.conf.
vim /etc/keepalived/keepalived.conf # you can see this file in this project and bash-setup directory
# on both node:
vim /etc/default/keepalived # you can see this file in this project and bash-setup directory

# Start keepalived service.
systemctl daemon-reload
systemctl enable --now keepalived
# now we  should see the VIP should seen in master node and HA works on failure states.

## Edit haproxy config files
# Create config file for load balancer.
vim /etc/haproxy/haproxy.cfg
haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl enable --now haproxy
systemctl restart haproxy

# Now we see in log of kube-controller-manger that the election is happened and on is master and others are locked.
# Now we can edit kube-admin.kubeconfig and set actual loadbalancer ip.
kubectl --kubeconfig kube-admin.kubeconfig get no
kubectl --kubeconfig kube-admin.kubeconfig get ns
kubectl --kubeconfig kube-admin.kubeconfig get cs


# Create systemd service file for kube-scheduler.
vim svc-scheduler.sh
./svc-scheduler.sh

# Start apiserver service.
systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler

# Now we see in log of kube-scheduler that the election is happened and on is master and others are locked.
kubectl --kubeconfig kube-admin.kubeconfig get cs
# Now our controller-plane components are ready.


# Now deploy a simple deployment.
# First we export `KUBECONFIG` env var to use it in kubectl commands.
export KUBECONFIG=kube-admin.kubeconfig
kubectl create deployment nginx --image nginx --replicas 1
# Warning  FailedScheduling  99s   default-scheduler  no nodes available to schedule pods
# It shows all the things are working fine and we have no worker nodes to schedule pods on them.
