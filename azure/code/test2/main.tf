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

# namings and tags
locals {

     prefix = "${local.application}-${local.environment}-${local.region_code}"

     # resource group names
     rg_network  = "${local.prefix}-rg-network"
     rg_compute  = "${local.prefix}-rg-compute"
     rg_security = "${local.prefix}-rg-security"

     # networking
     vnet_name       = "${local.prefix}-vnet"
     subnet_app      = "${local.prefix}-subnet-app"
     subnet_mgt      = "${local.prefix}-subnet-mgt"
     subnet_fwl      = "${local.prefix}-subnet-fwl"

     # NIC & Public IP
     nic_vm_app      = "${local.prefix}-nic-vm-app"
     nic_vm_mgt      = "${local.prefix}-nic-vm-mgt"
     pip_vm_mgt      = "${local.prefix}-pip-vm-mgt"

     # Virtual Machines
     vm_app_name     = "${local.prefix}-vm-app"
     vm_mgt_name     = "${local.prefix}-vm-mgt"

     # NSG names
     nsg_app         = "${local.prefix}-nsg-app"
     nsg_mgt         = "${local.prefix}-nsg-mgt"
     nsg_fwl         = "${local.prefix}-nsg-fwl"

     # common tags
     common_tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# resource groups
resource "azurerm_resource_group" "rg_network" {
     name     = "rg-network"
     location = local.region

     # tags = local.common_tags
}

resource "azurerm_resource_group" "rg_compute" {
     name     = "rg-compute"
     location = local.region

     # tags = local.common_tags
}

resource "azurerm_resource_group" "rg_security" {
     name     = "rg-security"
     location = local.region

     # tags = local.common_tags
}

# networking
resource "azurerm_virtual_network" "vnet" {
     name                = local.vnet_name
     location            = azurerm_resource_group.rg_network.location
     resource_group_name = azurerm_resource_group.rg_network.name
     address_space       = ["10.0.0.0/16"]

     tags = local.common_tags
}

resource "azurerm_subnet" "subnet_app" {
     name                 = local.subnet_app
     resource_group_name  = azurerm_resource_group.rg_network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_mgt" {
     name                 = local.subnet_mgt
     resource_group_name  = azurerm_resource_group.rg_network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet_fwl" {
     name                 = local.subnet_fwl
     resource_group_name  = azurerm_resource_group.rg_network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.3.0/24"]
}


# network interface cards and ip address
resource "azurerm_network_interface" "nic_vm_app" {
     name                = local.nic_vm_app
     location            = azurerm_resource_group.rg_network.location
     resource_group_name = azurerm_resource_group.rg_network.name

     ip_configuration {
     name                          = "ipconfig"
     subnet_id                     = azurerm_subnet.subnet_app.id
     private_ip_address_allocation = "Dynamic"
     }

     tags = local.common_tags
}

resource "azurerm_public_ip" "pip_vm_mgt" {
     name                = local.pip_vm_mgt
     location            = azurerm_resource_group.rg_network.location
     resource_group_name = azurerm_resource_group.rg_network.name

     allocation_method = "Static"
     sku               = "Standard"

     tags = local.common_tags
}

resource "azurerm_network_interface" "nic_vm_mgt" {
     name                = local.nic_vm_mgt
     location            = azurerm_resource_group.rg_network.location
     resource_group_name = azurerm_resource_group.rg_network.name

     ip_configuration {
     name                          = "ipconfig"
     subnet_id                     = azurerm_subnet.subnet_mgt.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = azurerm_public_ip.pip_vm_mgt.id
     }

     tags = local.common_tags
}

# virtual machines
resource "azurerm_linux_virtual_machine" "vm_app" {
     name                            = local.vm_app_name
     location                        = azurerm_resource_group.rg_compute.location
     resource_group_name             = azurerm_resource_group.rg_compute.name
     network_interface_ids           = [azurerm_network_interface.nic_vm_app.id]
     size                            = "Standard_B2ls_v2"
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
          name                 = "${local.vm_app_name}-osdisk"
          storage_account_type = "Standard_LRS"
          caching              = "ReadWrite"
          }

     tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "vm_mgt" {
     name                            = local.vm_mgt_name
     location                        = azurerm_resource_group.rg_compute.location
     resource_group_name             = azurerm_resource_group.rg_compute.name
     network_interface_ids           = [azurerm_network_interface.nic_vm_mgt.id]
     size                            = "Standard_B2ls_v2"
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
          name                 = "${local.vm_mgt_name}-osdisk"
          storage_account_type = "Standard_LRS"
          caching              = "ReadWrite"
          }

     tags = local.common_tags
}

# network security group and associations
resource "azurerm_network_security_group" "nsg_app" {
     name                = local.nsg_app
     location            = azurerm_resource_group.rg_security.location
     resource_group_name = azurerm_resource_group.rg_security.name

     security_rule {
     name                       = "SSH-From-MGT"
     priority                   = 100
     direction                  = "Inbound"
     access                     = "Allow"
     protocol                   = "Tcp"

     source_port_range          = "*"
     source_address_prefix      = azurerm_subnet.subnet_mgt.address_prefixes[0]

     destination_port_range     = "22"
     destination_address_prefix = "*"
     }

     tags = local.common_tags
}


resource "azurerm_network_security_group" "nsg_mgt" {
     name                = local.nsg_mgt
     location            = azurerm_resource_group.rg_security.location
     resource_group_name = azurerm_resource_group.rg_security.name

     security_rule {
     name                       = "SSH"
     priority                   = 100
     direction                  = "Inbound"
     access                     = "Allow"
     protocol                   = "Tcp"
     source_port_range          = "*"
     destination_port_range     = "22"
     source_address_prefix      = "*"
     destination_address_prefix = "*"
     }

     tags = local.common_tags
}

resource "azurerm_network_security_group" "nsg_fwl" {
     name                = local.nsg_fwl
     location            = azurerm_resource_group.rg_security.location
     resource_group_name = azurerm_resource_group.rg_security.name

     security_rule {
     name                       = "Deny-All"
     priority                   = 101
     direction                  = "Inbound"
     access                     = "Deny"
     protocol                   = "*"
     source_port_range          = "*"
     destination_port_range     = "*"
     source_address_prefix      = "*"
     destination_address_prefix = "*"
     }

     tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "assoc_app" {
     subnet_id                 = azurerm_subnet.subnet_app.id
     network_security_group_id = azurerm_network_security_group.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_mgt" {
     subnet_id                 = azurerm_subnet.subnet_mgt.id
     network_security_group_id = azurerm_network_security_group.nsg_mgt.id
}

resource "azurerm_subnet_network_security_group_association" "assoc_fwl" {
     subnet_id                 = azurerm_subnet.subnet_fwl.id
     network_security_group_id = azurerm_network_security_group.nsg_fwl.id
}
