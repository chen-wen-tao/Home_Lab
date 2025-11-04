#!/bin/bash
# Quick script to test WinRM connection

echo "Testing WinRM connection to Windows client..."
echo ""

# Check if vault file exists and has content
VAULT_FILE="group_vars/all/vault.yml"
if [ -f "$VAULT_FILE" ] && [ -s "$VAULT_FILE" ]; then
    echo "Vault file found. Using vault..."
    echo ""
    ansible windows -m win_ping --ask-vault-pass
else
    echo "No vault file found or vault is empty."
    echo "Please provide the Windows admin password:"
    read -sp "Enter Windows admin password: " PASSWORD
    echo ""
    echo ""
    echo "Testing with provided password..."
    ansible windows -m win_ping -e "ansible_password=$PASSWORD" -e "vault_admin_password=$PASSWORD"
fi

