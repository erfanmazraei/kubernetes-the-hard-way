#!/usr/bin/env bash


cat <<EOF > /etc/systemd/system/kube-scheduler.service
[Unit]
Description=kube-scheduler

[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/kube-scheduler \\
  --authentication-kubeconfig=/etc/kubernetes/configs/kube-scheduler.kubeconfig \\
  --authorization-kubeconfig=/etc/kubernetes/configs/kube-scheduler.kubeconfig \\
  --cert-dir=/etc/kubernetes/certs \\
  --client-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --kubeconfig=/etc/kubernetes/configs/kube-scheduler.kubeconfig \\
  --requestheader-client-ca-file=/etc/kubernetes/certs/kube-ca.crt \\
  --tls-cert-file=/etc/kubernetes/certs/kube-scheduler.crt \\
  --tls-private-key-file=/etc/kubernetes/certs/kube-scheduler.key \\
  --v=10

[Install]
WantedBy=multi-user.target
EOF
