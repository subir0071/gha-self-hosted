# 🛠️ Azure Self-Hosted GitHub Actions Runner (Serverless & Containerized) [WIP]

This project provides a scalable, cost-efficient way to run **self-hosted GitHub Actions runners** on-demand using **Azure Container Instances (ACI)**, **Azure Functions**, and **Azure Storage Queues**.

---

## 📐 Architecture Overview

```plaintext
GitHub Webhook → Azure Function (HTTP Trigger)
                         ↓
               Azure Storage Queue
                         ↓
         Azure Function (Queue Trigger)
              ↙                     ↘
   Azure Key Vault         Azure Container Registry
                         ↓
           Azure Container Instance (Runner)
```

## 📁 Diagram

> <img src="design_diagram.png" width="300" />

```
(A) Azure Receiver Function      (1) Webhook received by Azure Receiver Function
(B) Azure Queue Storage          (2) Message sent to Azure Queue
(C) Azure Controller Function    (3) Azure controller function is triggered on message
(D) Azure Container Instance     (4) Create Azure Container Instance 
(E) Azure Key Vault              
(F) Azure Container Registry 
```
---

- **GitHub Webhook**: Sends workflow job events to Azure.
- **Azure Functions**: 
  - HTTP trigger listens to GitHub events and queues jobs.
  - Queue trigger spins up ACI runners from queue messages.
- **Azure Storage Queue**: Buffers job requests.
- **ACI**: Spins up temporary runners using a custom image.
- **Azure Key Vault**: Secures GitHub PATs and secrets.
- **ACR**: Stores the runner container image.

---

## ⚙️ Features

- 🧠 Serverless and event-driven.
- 💸 Cost-efficient (pays only per use).
- 🔐 Secrets secured via Key Vault.
- 🚀 Supports parallel jobs and scale-out via queues.

---

## 📦 Prerequisites

- Azure Subscription
- GitHub Repository with Admin Access
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- A GitHub Organization with Github App configured
- Docker + Azure Container Registry

---

## 🚀 Deployment Steps

1. **Provision Azure Resources**
   - Setup Terraform Backend in Azure 
     - Execute Action Workflow `create_azure_remote_backend.yml`
   - Setup GHA Infrastructure in Azure
     - Execute Action Workflow `deploy_azure_infra.yml`
   - Deploy Receiver Function
     - Execute Action Workflow `deploy_receiver_function.yml`
   - Deploy Controller Function
     - Execute Action Function `deploy_controller_function.yml`
   - Deploy container images specific to runner
     - Execute Action Workflow `build_deploy_images.yml`

---

## 🧪 Sample GitHub Workflow

```yaml
name: Example CI

on: [push]

jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@v4
      - name: Run a build script
        run: echo "Build started on a self-hosted Azure runner"
```

---

## 🔒 Security Considerations

- Use **Managed Identity** for Functions to access Key Vault.
- Limit scope of GitHub PAT (e.g., `repo`, `actions:write`).
- Use network restrictions on Function and ACI where possible.

---

## 📊 Monitoring & Logging

- Use **Application Insights** for Function logging.
- Monitor Container Instance logs via Azure Portal or CLI.
- Set up alerts on failures or scaling thresholds.

---

## 📄 License

MIT License
