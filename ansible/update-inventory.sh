#!/bin/bash
# Script to update Ansible inventory with Terraform outputs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORY_FILE="$SCRIPT_DIR/inventory/hosts.yml"

echo "Updating Ansible inventory from Terraform outputs..."

cd "$PROJECT_ROOT/terraform"

# Check if Terraform has been initialized
if [ ! -f "terraform.tfstate" ] && [ ! -f "terraform.tfstate.backup" ]; then
    echo "Error: Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get IP addresses from Terraform outputs
CLIENT_IP=$(terraform output -raw client_private_ip 2>/dev/null || echo "")
LINUX_IP=$(terraform output -raw linux_private_ip 2>/dev/null || echo "")

if [ -z "$CLIENT_IP" ] || [ -z "$LINUX_IP" ]; then
    echo "Warning: Could not retrieve all IP addresses from Terraform outputs."
    echo "Please run 'terraform output' to see available outputs."
    echo ""
    echo "You can manually update $INVENTORY_FILE with the correct IP addresses."
    exit 1
fi

echo "Found IP addresses:"
echo "  Client (Windows): $CLIENT_IP"
echo "  Linux: $LINUX_IP"
echo ""

# Create backup
cp "$INVENTORY_FILE" "$INVENTORY_FILE.backup"

# Use Python for reliable updates
python3 << EOF
import re

with open("$INVENTORY_FILE", 'r') as f:
    content = f.read()

# Replace Windows client IP (in windows section)
content = re.sub(
    r'(ansible_host: )10\.10\.2\.0.*# Update with actual IP from terraform output',
    r'\1' + '$CLIENT_IP',
    content,
    count=1
)

# Replace Linux IP (in linux section) - second occurrence
matches = list(re.finditer(r'ansible_host: 10\.10\.2\.0.*# Update with actual IP from terraform output', content))
if len(matches) >= 2:
    # Replace the second occurrence (Linux)
    pos = matches[1].start()
    content = content[:pos] + "ansible_host: $LINUX_IP" + content[matches[1].end():]
elif len(matches) == 1:
    # Only one match found, replace it (should be Linux)
    content = re.sub(
        r'ansible_host: 10\.10\.2\.0.*# Update with actual IP from terraform output',
        r'ansible_host: $LINUX_IP',
        content
    )

with open("$INVENTORY_FILE", 'w') as f:
    f.write(content)
EOF

echo "Inventory file updated successfully!"
echo "Backup saved to: $INVENTORY_FILE.backup"
echo ""
echo "You can now run Ansible playbooks:"
echo "  cd ansible"
echo "  ansible-playbook site.yml"

