#!/bin/bash
# Script to create Ansible vault file

VAULT_FILE="group_vars/all/vault.yml"

echo "Creating Ansible vault file for passwords..."
echo ""

# Check if vault file already exists
if [ -f "$VAULT_FILE" ] && [ -s "$VAULT_FILE" ]; then
    echo "Vault file already exists: $VAULT_FILE"
    read -p "Do you want to recreate it? (y/N): " RECREATE
    if [ "$RECREATE" != "y" ] && [ "$RECREATE" != "Y" ]; then
        echo "Keeping existing vault file."
        exit 0
    fi
fi

echo "You'll be prompted to create a vault password."
echo "This password will be used to encrypt the vault file."
echo "Remember this password - you'll need it when running playbooks!"
echo ""
read -sp "Enter vault password: " VAULT_PASS
echo ""
read -sp "Confirm vault password: " VAULT_PASS_CONFIRM
echo ""

if [ "$VAULT_PASS" != "$VAULT_PASS_CONFIRM" ]; then
    echo "Error: Passwords don't match!"
    exit 1
fi

echo ""
echo "Now enter the actual passwords for your VMs:"
read -sp "Enter Windows/Linux admin password (same as Terraform): " ADMIN_PASS
echo ""
read -sp "Enter MSSQL SA password: " MSSQL_SA_PASS
echo ""

# Create temporary plaintext file
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
vault_admin_password: "$ADMIN_PASS"
vault_mssql_sa_password: "$MSSQL_SA_PASS"
EOF

# Encrypt the file using ansible-vault
echo "$VAULT_PASS" | ansible-vault encrypt "$TEMP_FILE" --output "$VAULT_FILE" --vault-password-file=-

# Clean up
rm -f "$TEMP_FILE"

echo ""
echo "Vault file created successfully: $VAULT_FILE"
echo ""
echo "To use the vault when running playbooks:"
echo "  ansible-playbook site.yml --ask-vault-pass"
echo ""
echo "To edit the vault:"
echo "  ansible-vault edit group_vars/all/vault.yml"
echo ""

