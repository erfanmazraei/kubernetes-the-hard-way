#!/usr/bin/env bash

EXPIRATION="$(date -u --date '+3650 days' +'%Y-%m-%dT%H:%M:%SZ')"

cat <<EOF > bootstrap-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bootstrap-token-abc123
  namespace: kube-system
type: bootstrap.kubernetes.io/token
stringData:
  description: "Worker node bootstrap token"
  token-id: abc123
  token-secret: f78baa5b8d5a4bc598e741ffb2fe09e9
  expiration: ${EXPIRATION}
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"
  auth-extra-groups: system:bootstrappers:worker
EOF
