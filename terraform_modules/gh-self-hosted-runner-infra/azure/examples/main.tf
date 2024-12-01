module "gh-self-hosted-infra-azure" {
    source = "../"

    # Pass variables to the module
    env                 = var.env
    project             = var.project
    location            = var.location
    acr_admin_enabled   = var.acr_admin_enabled
    acr_sku             = var.acr_sku
    GITHUB_APP_CLIENTID = var.GITHUB_APP_CLIENTID
    GITHUB_APP_ID       = var.GITHUB_APP_ID
    GITHUB_APP_INSTALLATION_ID = var.GITHUB_APP_INSTALLATION_ID
    GITHUB_APP_PEM_FILE = var.GITHUB_APP_PEM_FILE
    kv_sku_name = var.kv_sku_name
}
