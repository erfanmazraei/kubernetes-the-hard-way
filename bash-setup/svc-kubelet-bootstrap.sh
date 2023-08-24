#!/usr/bin/env bash


cat <<EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet
After=containerd.service
Requires=containerd.service

[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/kubelet \\
  --config=/etc/kubernetes/configs/kubelet.yaml \\
  --bootstrap-kubeconfig=/etc/kubernetes/configs/kube-bootstrap.kubeconfig \\
  --cert-dir=/etc/kubernetes/certs \\
  --kubeconfig=/etc/kubernetes/configs/kube-worker-k8s-node2.kubeconfig \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --v=10

[Install]
WantedBy=multi-user.target
EOF
