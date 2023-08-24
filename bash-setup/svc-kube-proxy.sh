#!/usr/bin/env bash


cat <<EOF > /etc/systemd/system/kube-proxy.service
[Unit]
Description=kube-proxy

[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/etc/kubernetes/configs/kube-proxy.yaml \\
  --v=10

[Install]
WantedBy=multi-user.target
EOF
