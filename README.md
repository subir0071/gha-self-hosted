# 🛠️ Azure Self-Hosted GitHub Actions Runner (Serverless & Containerized)

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
- A GitHub Personal Access Token (PAT)
- Docker + GitHub Container Registry or Azure Container Registry

---

## 🚀 Deployment Steps

1. **Provision Azure Resources**
   - Resource Group
   - Storage Account with Queue
   - Key Vault
   - Azure Container Registry
   - Azure Functions (with two triggers)

2. **Configure GitHub Webhook**
   - Point it to the HTTP-triggered Azure Function endpoint.
   - Use a GitHub PAT stored securely in Azure Key Vault.

3. **Build & Push Runner Image**
   ```bash
   docker build -t <your-registry>/gh-runner:latest .
   docker push <your-registry>/gh-runner:latest
   ```

4. **Configure Azure Function**
   - Grant access to ACR and Key Vault.
   - Set up environment variables for Function app.

5. **Test Workflow**
   - Trigger a GitHub Action job.
   - Monitor Azure Function logs and container activity.

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

## 📁 Diagram

> Architecture diagram source is available in [draw.io XML format](./diagram.drawio).

---

## 📄 License

MIT License
