terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    storage_account_name = "tbstateacc"
    container_name       = "tfstate"
    key                  = "azure-website-infrastructure.tfstate"
  }
}

provider "azurerm" {
  features {}
}