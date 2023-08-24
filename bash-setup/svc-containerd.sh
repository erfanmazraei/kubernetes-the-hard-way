#!/usr/bin/env bash


cat <<EOF > /etc/systemd/system/containerd.service
[Unit]
Description=containerd
After=network.target local-fs.target

[Service]
Type=notify
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5s
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
