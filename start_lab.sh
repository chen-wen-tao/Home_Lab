#!/usr/bin/env bash
if [ -z "$1" ]; then
  echo "Usage: ./start_lab.sh <AdminPassword> [allowed_cidr]"
  exit 1
fi
ADMIN_PASS="$1"
ALLOWED="${2:-REPLACE_ME/32}"
terraform init
terraform apply -auto-approve -var="admin_password=${ADMIN_PASS}" -var="allowed_ip=${ALLOWED}"
terraform output
