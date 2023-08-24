#!/usr/bin/env bash


cat <<EOF > /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=kube-controller-manager

[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --authentication-kubeconfig=/etc/kubernetes/configs/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/etc/kubernetes/configs/kube-controller-manager.kubeconfig \\
  --cert-dir=/etc/kubernetes/certs \\
  --client-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=cluster.local \\
  --cluster-signing-cert-file=/etc/kubernetes/certs/kube-ca.crt \\
  --cluster-signing-key-file=/etc/kubernetes/certs/kube-ca.key \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kubeconfig=/etc/kubernetes/configs/kube-controller-manager.kubeconfig \\
  --node-cidr-mask-size=24 \\
  --requestheader-client-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --root-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --service-account-private-key-file=/etc/kubernetes/certs/service-account.key \\
  --service-cluster-ip-range=10.10.0.0/16 \\
  --tls-cert-file=/etc/kubernetes/certs/kube-controller-manager.crt \\
  --tls-private-key-file=/etc/kubernetes/certs/kube-controller-manager.key \\
  --use-service-account-credentials=true \\
  --v=10

[Install]
WantedBy=multi-user.target
EOF
