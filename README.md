# 🏃‍♂️ Azure Self-Hosted GitHub Actions Runner (Serverless & Containerized)

[![Azure](https://img.shields.io/badge/Azure-Functions-blue?logo=microsoft-azure)](https://azure.microsoft.com/en-us/services/functions/)
[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-black?logo=github)](https://github.com/features/actions)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-purple?logo=terraform)](https://terraform.io)
[![Docker](https://img.shields.io/badge/Docker-Container-blue?logo=docker)](https://docker.com)
[![Python](https://img.shields.io/badge/Python-3.11-green?logo=python)](https://python.org)

A **scalable, cost-efficient, and secure** solution for running self-hosted GitHub Actions runners on-demand using Azure's serverless and containerization services. This project eliminates the need for persistent VMs while providing ephemeral, scalable runner infrastructure.

---

## 🏗️ Architecture Overview

<p align="center">
  <img src="design_diagram.png" alt="Architecture Diagram" width="600"/>
</p>

### Component Flow:
```mermaid
graph TD
    A[GitHub Webhook] --> B[Azure Receiver Function]
    B --> C[Azure Storage Queue]
    C --> D[Azure Controller Function]
    D --> E[Azure Key Vault]
    D --> F[Azure Container Registry]
    D --> G[Azure Container Instance]
    E --> G
    F --> G
    G --> H[GitHub Runner]
```

### Architecture Components:

| Component | Purpose | Technology |
|-----------|---------|------------|
| **🎣 Receiver Function** | Handles GitHub webhook events and queues jobs | Azure Functions (HTTP Trigger) |
| **📬 Storage Queue** | Buffers and decouples job requests | Azure Storage Queue |
| **🎛️ Controller Function** | Provisions container instances for runners | Azure Functions (Queue Trigger) |
| **🐳 Container Instances** | Runs ephemeral GitHub Actions runners | Azure Container Instances (ACI) |
| **🔐 Key Vault** | Securely stores GitHub App credentials and ACR credentials | Azure Key Vault |
| **📦 Container Registry** | Hosts custom runner container images | Azure Container Registry (ACR) |
| **🧹 Cleanup Function** | Automatically removes terminated containers | Azure Functions (Timer Trigger) |

---

## ✨ Key Features

- **🚀 Serverless & Event-Driven**: Fully serverless architecture with automatic scaling
- **💰 Cost-Efficient**: Pay only for actual compute usage, no idle resources
- **🔒 Security-First**: GitHub App authentication, managed identities, and Key Vault integration
- **⚡ Auto-Scaling**: Handles parallel jobs with queue-based load balancing
- **🧹 Self-Cleaning**: Automatic cleanup of terminated containers
- **🐳 Containerized**: Custom Docker images for consistent runner environments
- **🌍 Multi-Environment**: Terraform-based infrastructure with environment separation
- **📊 Observable**: Application Insights integration for monitoring and logging

---

## 📋 Prerequisites

Before deploying this solution, ensure you have:

### Required Tools
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version)
- [Terraform](https://terraform.io/downloads) (>= 1.0)
- [Docker](https://docker.com/get-started) (for building runner images)
- [Git](https://git-scm.com/downloads)

### Azure Resources
- **Azure Subscription** with appropriate permissions
- **Resource Group** creation permissions
- **Service Principal** or **User-Assigned Managed Identity** for GitHub Actions

### GitHub Requirements
- **GitHub Organization** (personal accounts not supported for organization runners)
- **GitHub App** configured for the organization with the following permissions:
  - Repository permissions: `Actions: Write`, `Metadata: Read`
  - Organization permissions: `Self-hosted runners: Write`
- **Organization Admin** access to install the GitHub App

---

## 🚀 Quick Start Guide

### Step 1: Clone and Setup

```bash
git clone https://github.com/subir0071/gha-self-hosted.git
cd gha-self-hosted
```

### Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Azure Service Principal Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `abcdef12-3456-7890-abcd-ef1234567890` |
| `TF_VAR_GITHUB_APP_ID` | GitHub App ID | `123456` |
| `TF_VAR_GITHUB_APP_INSTALLATION_ID` | GitHub App Installation ID | `12345678` |
| `TF_VAR_GITHUB_APP_CLIENTID` | GitHub App Client ID | `Iv1.a1b2c3d4e5f6g7h8` |
| `TF_VAR_GITHUB_APP_PEM_FILE` | GitHub App Private Key (PEM format) | `-----BEGIN RSA PRIVATE KEY-----...` |

### Step 3: Deploy Infrastructure

Execute the GitHub Actions workflows in this order:

1. **Create Terraform Backend**:
   ```bash
   # Run via GitHub Actions
   gh workflow run create_azure_remote_backend.yml
   ```

2. **Deploy Azure Infrastructure**:
   ```bash
   # Run via GitHub Actions
   gh workflow run deploy_azure_infra.yml
   ```

3. **Deploy Functions and Images**:
   ```bash
   # Deploy all components
   gh workflow run deploy_receiver_function.yml
   gh workflow run build_deploy_controller_function.yml
   gh workflow run build_deploy_images.yml
   ```

### Step 4: Configure GitHub Organization

After successful deployment:

1. **Get the Receiver Function URL** from Azure Portal or Terraform outputs
2. **Configure Organization Webhook**:
   - Go to your GitHub Organization → Settings → Webhooks
   - Add webhook with the Receiver Function URL
   - Select "Workflow jobs" events
   - Set content type to "application/json"

### Step 5: Test Your Setup

Create a test workflow in your repository:

```yaml
# .github/workflows/test-runner.yml
name: Test Self-Hosted Runner

on: [workflow_dispatch]

jobs:
  test:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - name: Test Runner
        run: |
          echo "🎉 Running on self-hosted Azure runner!"
          echo "Runner: $(hostname)"
          echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
```

---

## 📁 Project Structure

```
gha-self-hosted/
├── 📁 .github/workflows/           # GitHub Actions deployment workflows
│   ├── build_deploy_controller_function.yml
│   ├── build_deploy_images.yml
│   ├── create_azure_remote_backend.yml
│   ├── deploy_azure_infra.yml
│   └── deploy_receiver_function.yml
├── 📁 create-azure-infra/          # Main Terraform infrastructure
│   ├── main.tf                     # Azure resources definition
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── dev.tfvars                  # Environment-specific values
│   └── dev-backend.config          # Terraform backend configuration
├── 📁 create-remote-state/         # Terraform backend setup
├── 📁 github-runner-receiver-function/  # HTTP trigger function
│   ├── function_app.py             # Webhook receiver logic
│   ├── requirements.txt            # Python dependencies
│   └── host.json                   # Function configuration
├── 📁 github-runner-controller-function/ # Queue trigger function
│   ├── function_app.py             # Container provisioning logic
│   ├── requirements.txt            # Python dependencies
│   └── host.json                   # Function configuration
├── 📁 github-runner-cleanup-function/   # Timer trigger function
│   ├── function_app.py             # Cleanup logic
│   ├── requirements.txt            # Python dependencies
│   └── host.json                   # Function configuration
├── 📁 github-runner-images/        # Docker container definitions
│   ├── docker-compose.yml          # Multi-stage build configuration
│   ├── context/
│   │   ├── Dockerfile.base         # Base Ubuntu image with tools
│   │   ├── Dockerfile.runner       # GitHub Actions runner image
│   │   └── script/
│   │       ├── app.sh              # Runner registration script
│   │       └── generate_jwt.py     # GitHub App JWT generation
├── 📁 terraform_modules/           # Reusable Terraform modules
│   └── github_manage_org/          # GitHub organization management
└── 📄 design_diagram.png           # Architecture diagram
```

---

## ⚙️ Configuration

### Environment Variables

The solution uses environment-specific configuration through Azure Function App Settings:

#### Receiver Function Settings:
- `QUEUE_NAME`: Azure Storage Queue name for job buffering
- `storageAccountConnectionString`: Connection string for Azure Storage

#### Controller Function Settings:
- `AZURE_CONTAINER_REGISTRY`: ACR name for pulling runner images
- `AZURE_KV_NAME`: Key Vault name for credential retrieval
- `GH_ORG_NAME`: GitHub organization name
- `AZURE_SUBSCRIPTION_ID`: Target subscription for ACI deployment
- `AZURE_RESOURCE_GROUP`: Resource group for ACI instances

#### Cleanup Function Settings:
- `AZURE_SUBSCRIPTION_ID`: Subscription for container monitoring
- `AZURE_RESOURCE_GROUP`: Resource group to monitor

### Terraform Variables

Customize deployment through `dev.tfvars`:

```hcl
project             = "myproject"      # Project name prefix
env                 = "dev"            # Environment identifier
location            = "eastus2"        # Azure region
acr_sku             = "Basic"          # Container Registry SKU
kv_sku_name         = "standard"       # Key Vault SKU
GITHUB_ORG_NAME     = "my-org"        # GitHub organization
```

---

## 🔍 Monitoring & Troubleshooting

### Application Insights Integration

All functions are integrated with Azure Application Insights for comprehensive monitoring:

- **📊 Performance Metrics**: Function execution times, success rates
- **🐛 Error Tracking**: Detailed exception logging and stack traces  
- **📈 Custom Metrics**: Container creation counts, queue depths
- **🔍 Distributed Tracing**: End-to-end request tracking

### Common Issues and Solutions

#### 1. Container Creation Failures
```bash
# Check controller function logs
az logs show --resource-group myproject-dev-rg \
  --resource myproject-dev-controller-function-app

# Verify Key Vault permissions
az role assignment list --assignee <function-principal-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv-name>
```

#### 2. GitHub Webhook Issues
```bash
# Test receiver function directly
curl -X POST https://myproject-dev-receiver-function-app.azurewebsites.net/api/receiver_function \
  -H "Content-Type: application/json" \
  -d '{"action":"queued","workflow_job":{"id":"test-123","labels":["self-hosted","linux"]}}'
```

#### 3. Runner Registration Problems
- Verify GitHub App permissions and installation
- Check organization webhook configuration  
- Validate GitHub App credentials in Key Vault

### Health Checks

Monitor system health through Azure Portal or CLI:

```bash
# Function app status
az functionapp show --name myproject-dev-controller-function-app \
  --resource-group myproject-dev-rg --query "state"

# Queue depth monitoring
az storage queue show --name myproject-dev-queue \
  --account-name myprojectdev --query "metadata"

# Container instance status
az container list --resource-group myproject-dev-rg \
  --query "[].{Name:name,State:instanceView.state}" --output table
```

---

## 🛡️ Security Best Practices

### Authentication & Authorization
- **✅ Managed Identity**: Functions use system-assigned managed identities
- **✅ RBAC**: Least-privilege access with Azure role assignments
- **✅ GitHub App**: Secure authentication instead of personal access tokens
- **✅ Key Vault**: Encrypted storage for sensitive credentials

### Network Security
- **🔒 HTTPS Only**: All functions enforce HTTPS communication
- **🌐 Function Keys**: HTTP triggers protected with function-level keys
- **🔐 Private Endpoints**: Configure for production environments

### Secrets Management
```bash
# Rotate GitHub App private key
az keyvault secret set --vault-name myproject-dev-kv \
  --name myproject-dev-kv-gh-pemfile \
  --value @new-private-key.pem

# Update ACR credentials
az keyvault secret set --vault-name myproject-dev-kv \
  --name myproject-dev-kv-acr-pass \
  --value $(az acr credential show --name myprojectdevacr --query "passwords[0].value" -o tsv)
```

---

## 🔄 CI/CD Pipeline

The project includes comprehensive GitHub Actions workflows for automated deployment:

### Workflow Dependencies
```mermaid
graph TD
    A[create_azure_remote_backend.yml] --> B[deploy_azure_infra.yml]
    B --> C[deploy_receiver_function.yml]
    B --> D[build_deploy_controller_function.yml]
    B --> E[build_deploy_images.yml]
    C --> F[Configure GitHub Webhook]
    D --> F
    E --> F
```

### Manual Deployment
For development or troubleshooting:

```bash
# Deploy individual components
cd github-runner-controller-function
zip -r ../controller-function.zip . -x "*.git*" "*/__pycache__/*" "*.pyc"
az functionapp deployment source config-zip \
  --resource-group myproject-dev-rg \
  --name myproject-dev-controller-function-app \
  --src controller-function.zip
```

---

## 🧹 Maintenance

### Regular Tasks

1. **Update Dependencies**: Regularly update Azure Function Python packages
2. **Rotate Secrets**: Implement automatic GitHub App credential rotation
3. **Monitor Costs**: Set up Azure Cost Management alerts
4. **Update Runner Images**: Keep container images updated with latest tools

### Cleanup Operations

```bash
# Manual cleanup of old containers
az container list --resource-group myproject-dev-rg \
  --query "[?instanceView.state=='Terminated'].name" -o tsv | \
  xargs -I {} az container delete --name {} --resource-group myproject-dev-rg --yes

# Remove old container images
az acr repository list --name myprojectdevacr --output tsv | \
  xargs -I {} az acr repository delete --name myprojectdevacr --repository {} --yes
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Setup local development environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r github-runner-controller-function/requirements.txt

# Install development tools
pip install pytest black flake8 mypy
```

### Running Tests
```bash
# Run unit tests
pytest tests/

# Code formatting
black github-runner-*-function/

# Type checking
mypy github-runner-*-function/
```

---

## 📚 Additional Resources

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps)
- [Azure Container Instances Documentation](https://docs.microsoft.com/en-us/azure/container-instances/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙋‍♂️ Support

For questions, issues, or contributions:

- **📋 Issues**: [GitHub Issues](https://github.com/subir0071/gha-self-hosted/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/subir0071/gha-self-hosted/discussions)
- **📧 Email**: [Open an issue](https://github.com/subir0071/gha-self-hosted/issues/new) for private inquiries

---

<p align="center">
  <strong>Built with ❤️ for the DevOps community</strong>
</p>
