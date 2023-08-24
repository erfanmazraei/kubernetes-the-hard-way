#!/usr/bin/env bash

NODE_NAME=$(hostname -s)
NODE_IPADDR=$(ip -j -p a show enp0s7 | jq .[0].addr_info[0].local | sed 's/"//g')
NODE1_IP=172.86.96.248
NODE2_IP=172.86.96.247
NODE3_IP=172.86.96.250
NODE4_IP=172.86.96.251
NODE5_IP=172.86.96.249

cat <<EOF > /etc/systemd/system/etcd.service
[Unit]
Description=etcd

[Service]
Type=notify
User=etcd
Restart=on-failure
RestartSec=5s
LimitNOFILE=50000
TimeoutStartSec=0
ExecStart=/usr/local/bin/etcd \\
  --name $NODE_NAME \\
  --data-dir /var/lib/etcd \\
  --client-cert-auth \\
  --peer-client-cert-auth \\
  --cert-file /etc/etcd/certs/etcd-server.crt \\
  --key-file /etc/etcd/certs/etcd-server.key \\
  --trusted-ca-file /etc/etcd/certs/etcd-ca.crt \\
  --peer-cert-file /etc/etcd/certs/etcd-server.crt \\
  --peer-key-file /etc/etcd/certs/etcd-server.key \\
  --peer-trusted-ca-file /etc/etcd/certs/etcd-ca.crt \\
  --advertise-client-urls https://$NODE_IPADDR:2379 \\
  --listen-client-urls https://localhost:2379,https://$NODE_IPADDR:2379 \\
  --listen-peer-urls https://$NODE_IPADDR:2380 \\
  --initial-advertise-peer-urls https://$NODE_IPADDR:2380 \\
  --initial-cluster k8s-etc1=https://$NODE1_IP:2380,k8s-etc2=https://$NODE2_IP:2380,k8s-etc3=https://$NODE3_IP:2380,k8s-etc4=https://$NODE4_IP:2380,k8s-etc5=https://$NODE5_IP:2380
  --initial-cluster-token etcd-cluster \\
  --initial-cluster-state new

[Install]
WantedBy=multi-user.target
EOF
