module "manage_github" {
  source = "../"
  github_organization            = var.github_organization
  self_runner_webhook_url        = var.self_runner_webhook_url
  github_repositories_list       = var.github_repositories_list
  GITHUB_APP_ID                  = var.GITHUB_APP_ID
  GITHUB_APP_INSTALLATION_ID     = var.GITHUB_APP_INSTALLATION_ID
  GITHUB_APP_PEM_FILE            = var.GITHUB_APP_PEM_FILE 
} 
