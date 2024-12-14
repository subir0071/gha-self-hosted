variable "resource_group_name" {
    type    = string
    default = "terraformbackend"
}

variable "location" {
    type    = string
    default = "eastus2"
}


variable "storage_account_name" {
    type    = string
    default = "ghrunnerterraformbackend"
}

variable "storage_account_tier" {
    type    = string
    default = "Standard"
}

variable "storage_account_replication_type" {
    type    = string
    default = "LRS"
}


variable "storage_container_name" {
    type    = string
    default = "terraformbackend"
}

variable "container_access_type" {
    type    = string
    default = "blob"
}

