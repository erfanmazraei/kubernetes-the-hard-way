#!/usr/bin/env bash

NODE_NAME=$(hostname -s)
NODE_IPADDR=$(ip -j -p a show enp0s7 | jq .[0].addr_info[0].local | sed 's/"//g')
NODE1_IP=172.86.96.248
NODE2_IP=172.86.96.247
NODE3_IP=172.86.96.250
NODE4_IP=172.86.96.251
NODE5_IP=172.86.96.249

cat <<EOF > /etc/systemd/system/kube-apiserver.service
[Unit]
Description=kube-apiserver

[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=$NODE_IPADDR \\
  --allow-privileged=true \\
  --audit-log-compress=true \\
  --audit-log-maxage=90 \\
  --audit-log-maxbackup=10 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/kube-audit.log \\
  --authorization-mode=Node,RBAC \\
  --cert-dir=/etc/kubernetes/certs \\
  --client-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --enable-admission-plugins=NodeRestriction \\
  --enable-bootstrap-token-auth=true \\
  --encryption-provider-config=/etc/kubernetes/configs/encryption-config.yaml \\
  --encryption-provider-config-automatic-reload=true \\
  --etcd-cafile=/etc/kubernetes/certs/etcd-ca.crt \\
  --etcd-certfile=/etc/kubernetes/certs/etcd-kube-apiserver.crt \\
  --etcd-keyfile=/etc/kubernetes/certs/etcd-kube-apiserver.key \\
  --etcd-servers=https://$NODE1_IP:2379,https://$NODE2_IP:2379,https://$NODE3_IP:2379,https://$NODE4_IP:2379,https://$NODE5_IP:2379 \\
  --kubelet-certificate-authority=/etc/kubernetes/certs/kube-ca.crt \\
  --kubelet-client-certificate=/etc/kubernetes/certs/kube-apiserver-to-kubelet.crt \\
  --kubelet-client-key=/etc/kubernetes/certs/kube-apiserver-to-kubelet.key \\
  --runtime-config="api/all=true" \\
  --service-account-issuer=kube-apiserver \\
  --service-account-key-file=/etc/kubernetes/certs/service-account.crt \\
  --service-account-signing-key-file=/etc/kubernetes/certs/service-account.key \\
  --service-cluster-ip-range=10.10.0.0/16 \\
  --tls-cert-file=/etc/kubernetes/certs/kube-apiserver.crt \\
  --tls-private-key-file=/etc/kubernetes/certs/kube-apiserver.key \\
  --tls-min-version=VersionTLS12 \\
  --v=10

[Install]
WantedBy=multi-user.target
EOF
