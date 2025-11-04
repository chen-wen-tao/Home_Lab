#!/bin/bash
# Quick script to test Linux SSH connection

echo "Testing SSH connection to Linux host..."
echo ""

# Check if vault file exists and has content
VAULT_FILE="group_vars/all/vault.yml"
if [ -f "$VAULT_FILE" ] && [ -s "$VAULT_FILE" ]; then
    echo "Vault file found. Using vault..."
    echo ""
    ansible linux -m ping --ask-vault-pass
else
    echo "No vault file found or vault is empty."
    echo "Please provide the Linux admin password:"
    read -sp "Enter Linux admin password: " PASSWORD
    echo ""
    echo ""
    echo "Testing with provided password..."
    ansible linux -m ping -e "ansible_password=$PASSWORD" -e "vault_admin_password=$PASSWORD" -e "ansible_become_password=$PASSWORD"
fi


