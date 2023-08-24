#!/usr/bin/env bash


# Generate root CA self-singed certificates for etcd.
openssl req -newkey rsa:2048 -nodes -keyout etcd-ca.key -x509 -subj "/CN=etcd-ca" -days 3650 -out etcd-ca.crt
# See the details of the certificates.
openssl x509 -text -noout -in etcd-ca.crt


# write openssl-etcd-server.conf config file for etcd-server.
vim openssl-etcd-server.conf

# Generate certificate signing request for etcd-serer.
openssl req -newkey rsa:2048 -nodes -keyout etcd-server.key -subj "/CN=etcd-server" -config openssl-etcd-server.conf -out etcd-server.csr
# Sign the certificate CSR of etcd-server with the root CA.
openssl x509 -req -in etcd-server.csr -CA etcd-ca.crt -CAkey etcd-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile openssl-etcd-server.conf -out etcd-server.crt
# See the details of the certificates.
openssl x509 -text -noout -in etcd-ca.crt

# Generate certificate signing request for etcd-admin.
openssl req -newkey rsa:2048 -nodes -keyout etcd-admin.key -subj "/CN=admin" -out etcd-admin.csr
# Sign the certificate CSR of etcd-admin with the root CA.
openssl x509 -req -in etcd-admin.csr -CA etcd-ca.crt -CAkey etcd-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile openssl-etcd-server.conf -out etcd-admin.crt
# See the details of the certificates.
openssl x509 -text -noout -in etcd-admin.crt


# Move etcd-ca.crt etcd-server.key etcd-server.crt to etcd nodes.
for i in k8s-etc1 k8s-etc2 k8s-etc3 k8s-etc4 k8s-etc5; do
  scp etcd-ca.crt etcd-server.key etcd-server.crt root@"${i}":/root/
done


## Execute this commands on etcd nodes.
useradd -Mrs /usr/sbin/nologin etcd
mkdir -p /etc/etcd/certs
mkdir -p /var/lib/etcd
chown -R etcd: /etc/etcd/
chown -R etcd: /var/lib/etcd/
chmod 750 /etc/etcd/
chmod 700 /var/lib/etcd/
# Move certs and keys to certs folder.
mv etcd-* /etc/etcd/certs/
# Change ownership and permissions of certs.
chown etcd: /etc/etcd/certs/*
chmod 640 /etc/etcd/certs/*


# Download and extract etcd binary and move to `/usr/local/bin/`.
wget https://github.com/etcd-io/etcd/releases/download/v3.5.8/etcd-v3.5.8-linux-amd64.tar.gz
tar -xzvf etcd-v3.5.8-linux-amd64.tar.gz
mv etcd-v3.5.8-linux-amd64/etcd* /usr/local/bin/

# Create systemd service file for etcd.
apt install -y jq
vim svc-etcd.sh
./svc-etcd.sh

# Start etcd service.
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd


# To see tables of cluster members list.
ETCDCTL_API=3 ./etcdctl --cacert etcd-ca.crt --cert etcd-admin.crt --key etcd-admin.key --endpoints='https://172.86.96.248:2379,https://172.86.96.247:2379,https://172.86.96.250:2379,https://172.86.96.251:2379,https://172.86.96.249:2379' -w table member list
# To see tables of cluster endpoint status and which node is leader.
ETCDCTL_API=3 ./etcdctl --cacert etcd-ca.crt --cert etcd-admin.crt --key etcd-admin.key --endpoints='https://172.86.96.248:2379,https://172.86.96.247:2379,https://172.86.96.250:2379,https://172.86.96.251:2379,https://172.86.96.249:2379' -w table endpoint status
# To check the performance and memory usage of cluster.
ETCDCTL_API=3 etcdctl --cacert /etc/etcd/certs/etcd-ca.crt --cert etcd-admin.crt --key etcd-admin.key --endpoints='https://172.86.96.248:2379,https://172.86.96.247:2379,https://172.86.96.250:2379,https://172.86.96.251:2379,https://172.86.96.249:2379' -w table check perf
ETCDCTL_API=3 etcdctl --cacert /etc/etcd/certs/etcd-ca.crt --cert etcd-admin.crt --key etcd-admin.key --endpoints='https://172.86.96.248:2379,https://172.86.96.247:2379,https://172.86.96.250:2379,https://172.86.96.251:2379,https://172.86.96.249:2379' -w table check datascale --insecure-skip-tls-verify


# some related links:
# https://www.golinuxcloud.com/openssl-create-certificate-chain-linux/
# https://www.openssl.org/docs/man1.0.2/man5/x509v3_config.html
# https://docs.oracle.com/javame/8.0/api/satsa_extensions_api/com/oracle/crypto/cert/X509Certificate.KeyUsage.html

# NOTE: about adding new node to etcd cluster see E1-2 `01:22:45` from deep dive video.

# NOTE: about backup from kubernetes Velero is good choice. https://velero.io/
