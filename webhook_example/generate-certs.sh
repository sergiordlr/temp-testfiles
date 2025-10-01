#!/bin/bash

SERVICE_NAME="unschedulable-webhook-service"
NAMESPACE="default"
SECRET_NAME="unschedulable-webhook-certs"
BASE_DIR="."
CONFIG_FILE="${BASE_DIR}/mutatingwebhookconfiguration.yaml"
CA_CERT_FILE="${BASE_DIR}/ca.crt"
WEBHOOK_CERTS_YAML="${BASE_DIR}/webhook-certs.yaml"

# Create a temporary OpenSSL config file for SANs
cat <<EOF > ${BASE_DIR}/server.cnf
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${SERVICE_NAME}
DNS.2 = ${SERVICE_NAME}.${NAMESPACE}
DNS.3 = ${SERVICE_NAME}.${NAMESPACE}.svc
DNS.4 = ${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local
EOF

# Generate CA key and certificate
echo "Generating CA key and certificate..."
openssl genrsa -out "${BASE_DIR}/ca.key" 2048
openssl req -new -x509 -key "${BASE_DIR}/ca.key" -out "${CA_CERT_FILE}" -days 3650 -subj "/CN=Admission Controller CA" -addext "subjectAltName = DNS:${SERVICE_NAME}.${NAMESPACE}.svc"

# Generate server key and certificate request with SANs
echo "Generating server key and certificate request with SANs..."
openssl genrsa -out "${BASE_DIR}/webhook.key" 2048
openssl req -new -key "${BASE_DIR}/webhook.key" -out "${BASE_DIR}/webhook.csr" -subj "/CN=${SERVICE_NAME}.${NAMESPACE}.svc" -config ${BASE_DIR}/server.cnf

# Sign server certificate with CA, including SANs
echo "Signing server certificate with CA, including SANs..."
openssl x509 -req -in "${BASE_DIR}/webhook.csr" -CA "${CA_CERT_FILE}" -CAkey "${BASE_DIR}/ca.key" -CAcreateserial -out "${BASE_DIR}/webhook.crt" -days 3650 -extfile ${BASE_DIR}/server.cnf -extensions v3_req

# Create Kubernetes Secret
echo "Creating Kubernetes Secret ${SECRET_NAME}..."
kubectl create secret tls ${SECRET_NAME} \
  --cert="${BASE_DIR}/webhook.crt" \
  --key="${BASE_DIR}/webhook.key" \
  --namespace=${NAMESPACE} --dry-run=client -o yaml > "${WEBHOOK_CERTS_YAML}"

# Update MutatingWebhookConfiguration with CA Bundle using Python script
echo "Updating ${CONFIG_FILE} with CA Bundle using Python script..."
python "${BASE_DIR}/update_webhook_config.py"

# Clean up generated cert files and temporary config
echo "Cleaning up generated cert files and temporary config..."
rm "${BASE_DIR}/ca.key" "${CA_CERT_FILE}" "${BASE_DIR}/webhook.key" "${BASE_DIR}/webhook.csr" "${BASE_DIR}/webhook.crt" "${BASE_DIR}/server.cnf"

echo "Certificate generation and Secret creation complete."
echo "Apply webhook-certs.yaml and then mutatingwebhookconfiguration.yaml to your cluster."
