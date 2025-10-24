#!/usr/bin/env bash
if [ -z "$1" ]; then
  echo "Usage: ./destroy_lab.sh <AdminPassword>"
  exit 1
fi
ADMIN_PASS="$1"
terraform destroy -auto-approve -var="admin_password=${ADMIN_PASS}"
