terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure the GitHub Provider
# Pass the environment variables GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID & GITHUB_APP_PEM_FILE 
# Get the relevant values from the created github app
provider "github" {
    owner = var.github_organization
    app_auth {
      id = var.GITHUB_APP_ID
      installation_id = var.GITHUB_APP_INSTALLATION_ID
      pem_file = var.GITHUB_APP_PEM_FILE
    }
}
