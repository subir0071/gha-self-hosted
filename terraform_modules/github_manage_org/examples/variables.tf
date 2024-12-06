
variable "github_organization" {
  description = "GitHub organization or username"
  type        = string
}

# This variab;e should get injected via TF_VAR as it is dependent on the function that 
# listens to this webhook
variable "self_runner_webhook_url" {
  description = "webhook url for the receiver function/lambda"
  type = string
  default = "https://change_it_to_correct_receiver_function_or_lambda_url"
}

variable "github_repositories_list" {
  description = "List of Github repositories to be managed"
   type = list(object({
    name        = string
    description = string
    visibility  = string
   }))
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
