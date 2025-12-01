#!/bin/bash
# Create Kubernetes secrets for E-Ren app
# Run this BEFORE helm install
#
# Usage:
#   export DATABASE_URL="postgresql://..."
#   export SECRET_KEY_BASE="$(openssl rand -hex 64)"
#   export SENDGRID="..."
#   export DATADOG_API_KEY="..."
#   ./create-secrets.sh

set -e

# Check if required env vars are set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set"
  exit 1
fi

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "ERROR: SECRET_KEY_BASE is not set"
  echo "Generate one with: openssl rand -hex 64"
  exit 1
fi

if [ -z "$SENDGRID" ]; then
  echo "ERROR: SENDGRID is not set"
  exit 1
fi

if [ -z "$DATADOG_API_KEY" ]; then
  echo "ERROR: DATADOG_API_KEY is not set"
  exit 1
fi

echo "Creating e-ren-secrets..."
kubectl create secret generic e-ren-secrets \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  --from-literal=SENDGRID="$SENDGRID" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating datadog-secret..."
kubectl create secret generic datadog-secret \
  --from-literal=api-key="$DATADOG_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Done! Secrets created."
echo ""
echo "Now run:"
echo "  helm install e-ren ."
