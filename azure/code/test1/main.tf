terraform {
  required_version = ">= 0.14"
  required_providers {
     azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 3.1.0"
     }
  }
}

provider "azurerm" {
  features {}
}

locals {
     region      = "norwayeast"
     region_code = "noe"
     team        = "team-1"
     environment = "prod"
     application = "kafka"
}

# create a new resource group
resource "azurerm_resource_group" "rg" {
     name     = "rg-${local.application}-${local.environment}-${local.region_code}"
     location = "norwayeast"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }

}

# create virtual network
resource "azurerm_virtual_network" "vnet" {
     name                = "vnet-${local.application}-${local.environment}-${local.region_code}"
     location            = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name
     address_space       = ["10.0.0.0/16"]


     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create subnet
resource "azurerm_subnet" "snet" {
     name                 = "snet-${local.application}-${local.environment}-${local.region_code}"
     resource_group_name  = azurerm_resource_group.rg.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.2.0/24"]
}


# create public ip
resource "azurerm_public_ip" "pip" {
     name                = "pip-${local.application}-${local.environment}-${local.region_code}"
     location            = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name

     allocation_method = "Static"
     sku               = "Standard"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create nsg and rule
resource "azurerm_network_security_group" "nsg" {
     name                = "nsg-${local.application}-${local.environment}-${local.region_code}"
     location            = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name

     # allow http traffic
     security_rule {
          name                       = "HTTP"
          priority                   = 1001
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }

     # allow ssh traffic
     security_rule {
          name                       = "SSH"
          priority                   = 1002
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }


     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}


# create network interface card
resource "azurerm_network_interface" "nic" {
     name                = "nic-${local.application}-${local.environment}-${local.region_code}"
     location            = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name

     ip_configuration {
     name                          = "ipconfig"
     subnet_id                     = azurerm_subnet.snet.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = azurerm_public_ip.pip.id
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}


# associate nsg to nic
resource "azurerm_network_interface_security_group_association" "nsg-bind" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
     name                            = "vm-${local.application}-${local.environment}-${local.region_code}"
     location                        = azurerm_resource_group.rg.location
     resource_group_name             = azurerm_resource_group.rg.name
     network_interface_ids           = [azurerm_network_interface.nic.id]
     size                            = "Standard_B2ls_v2"
     computer_name                   = "ubuntuvm"
     admin_username                  = "azureuser"
     admin_password                  = "Password1234!"
     disable_password_authentication = false

     source_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
     }

     os_disk {
     name                 = "osdisk-${local.application}-${local.environment}-${local.region_code}"
     storage_account_type = "Standard_LRS"
     caching              = "ReadWrite"
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}


# In questo scenario, la VM può trafficare con qualsiasi indirizzo IP pubblico;
# tuttavia, solo le connessioni sulla porta 22 e sulla porta 8080 sono consentite
# Questo consente di installare del software (scaricare pacchetti da interent)
# ed esporre servizi sulla porta 8080, accessibili a tutti