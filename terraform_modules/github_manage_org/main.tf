resource "github_repository" "create_repo" {
    for_each    = { for repo in var.github_repositories_list : repo.name => repo }

    name        = each.value.name
    description = each.value.description
    visibility  = each.value.visibility
}

resource "github_organization_webhook" "create_trigger_webhook" {
  configuration {
    url          = var.self_runner_webhook_url
    content_type = "json"
    insecure_ssl = false
  }
  active = false
  events = ["workflow_job"]
}

resource "github_actions_runner_group" "self_hosted_runner_group" {
  name                    = "self-hosted-runner-group"
  visibility              = "all"
  allows_public_repositories = false
}

