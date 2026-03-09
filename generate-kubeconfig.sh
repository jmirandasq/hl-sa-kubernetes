#!/bin/bash

set -e

SA_NAME=$1
NAMESPACE=${2:-default}
CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$CONTEXT\")].context.cluster}")
SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
CA_DATA=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.certificate-authority-data}")

OUTPUT_FILE="${SA_NAME}-kubeconfig.yaml"

echo "Generating token..."
TOKEN=$(kubectl create token $SA_NAME -n $NAMESPACE --duration=8760h)

echo "Creating kubeconfig..."

cat <<EOF > $OUTPUT_FILE
apiVersion: v1
kind: Config

clusters:
- name: $CLUSTER_NAME
  cluster:
    certificate-authority-data: $CA_DATA
    server: $SERVER

users:
- name: $SA_NAME
  user:
    token: $TOKEN

contexts:
- name: ${SA_NAME}-context
  context:
    cluster: $CLUSTER_NAME
    user: $SA_NAME
    namespace: $NAMESPACE

current-context: ${SA_NAME}-context
EOF

echo ""
echo "Kubeconfig generated:"
echo "$OUTPUT_FILE"
echo ""
echo "Test with:"
echo "KUBECONFIG=$OUTPUT_FILE kubectl get pods"