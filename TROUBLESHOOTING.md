# Troubleshooting Guide

## Azure CLI Errors

### Error: `AttributeError: Attribute disks does not exist`

This error occurs when Azure CLI has incompatible dependencies, particularly with beta versions of `azure-mgmt-resource`.

**Solution:**
1. Update Azure CLI:
   ```bash
   az upgrade
   ```

2. If that doesn't work, reinstall Azure CLI:
   ```bash
   # Remove existing installation
   pip3 uninstall azure-cli
   
   # Reinstall
   pip3 install --upgrade azure-cli
   ```

3. Or use the official installer:
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

### Error: `'NoneType' object is not callable`

This is related to the Azure CLI SDK compatibility issue. Follow the same steps as above to update/reinstall Azure CLI.

### Error: `ReadOnlyDisabledSubscription`

Your Azure subscription is disabled and marked as read-only. You cannot create resources until it's re-enabled.

**Solution:**
1. Check subscription status in Azure Portal
2. Contact Azure support if needed
3. Or switch to a different subscription:
   ```bash
   az account list --output table
   az account set --subscription <subscription-id>
   ```

### Error: Resource group creation fails

This can be due to:
1. Subscription is disabled (see above)
2. Azure CLI compatibility issues (update Azure CLI)
3. Insufficient permissions

**Solution:**
- Check your permissions: `az role assignment list --assignee $(az account show --query user.name -o tsv)`
- Try updating Azure CLI
- Verify subscription is enabled

## Script Improvements

The `deploy_lab_complete.sh` script has been updated to:
- Check subscription status before attempting to create resources
- Detect Azure CLI compatibility issues
- Provide helpful error messages
- Handle errors gracefully with exit codes

## Terraform Errors

### Error: `A resource with the ID "..." already exists - to be managed via Terraform this resource needs to be imported`

This error occurs when you're trying to create a resource that already exists in Azure but isn't in Terraform's state file.

**Solution - Import the existing resource:**

1. **Quick method for resource groups:**
   ```bash
   ./terraform_manage.sh import-rg lab-complete-rg
   ```

2. **Manual import method:**
   ```bash
   cd terraform
   terraform import azurerm_resource_group.lab /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME
   ```

3. **To find the resource ID:**
   ```bash
   az group show --name lab-complete-rg --query id -o tsv
   ```

4. **After importing, verify with:**
   ```bash
   ./terraform_manage.sh plan
   ```

**Alternative - Use a different resource group name:**

If you don't want to import the existing resource group, you can change the name:
```bash
cd terraform
terraform apply -var="resource_group_name=lab-new-rg" -var="admin_password=YourPassword" -auto-approve
```

### Error: `ReadOnlyDisabledSubscription` when subscription shows as "Enabled"

This happens when your subscription appears enabled but is still in read-only mode. Common causes:

1. **Subscription was recently re-enabled** - Takes 5-10 minutes for write permissions to propagate
2. **Spending limit reached** - Free/trial subscriptions have spending limits
3. **Regional restrictions** - Some regions may be restricted
4. **API propagation delay** - Azure services need time to sync

**Solutions:**

1. **Wait and retry** (most common fix):
   ```bash
   # Wait 5-10 minutes, then try again
   ./terraform_manage.sh apply YourPassword
   ```

2. **Check Azure Portal**:
   - Go to Azure Portal → Subscriptions → Your subscription
   - Check for spending limits or restrictions
   - Remove spending limit if active
   - Check subscription status

3. **Test write access manually**:
   ```bash
   az group create --name test-rg-$(date +%s) --location westus2
   # If this works, subscription is writable
   ```

4. **Check for regional issues**:
   ```bash
   # Try a different region
   cd terraform
   terraform apply -var="location=East US" -var="admin_password=YourPassword"
   ```

5. **Contact Azure Support** if issue persists after waiting

## Best Practices

1. Always check Azure CLI version: `az --version`
2. Keep Azure CLI updated: `az upgrade`
3. Verify subscription status before deployment
4. Use Terraform for more reliable deployments (see `terraform_manage.sh`)
5. Import existing resources before managing them with Terraform

