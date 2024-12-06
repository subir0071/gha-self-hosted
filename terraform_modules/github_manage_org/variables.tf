
variable "github_organization" {
  description = "GitHub organization or username"
  type        = string
}

variable "self_runner_webhook_url" {
  description = "webhook url for the receiver function/lambda"
  type = string
}

variable "github_repositories_list" {
  description = "List of Github repositories to be managed"
   type = list(object({
    name        = string
    description = string
    visibility  = string
   }))
   default = [ 
    {
      name        = "sample_repository"
      description = "This repository is default, override it in your ,tfvars file."
      visibility  = "private"
    }
  ]
}

variable "GITHUB_APP_ID" {
  description = "inject github app id from env variable"
  type = string
}

variable "GITHUB_APP_INSTALLATION_ID" {
  description = "inject github app installation id from env variable"
  type = string
}

variable "GITHUB_APP_PEM_FILE" {
  description = "inject github app private key file from env variable"
  type = string
}
