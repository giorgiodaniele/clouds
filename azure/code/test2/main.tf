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

resource "azurerm_resource_group" "rg-network" {
     name     = "rg-network"
     location = "norwayeast"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }

}


resource "azurerm_resource_group" "rg-compute" {
     name     = "rg-compute"
     location = "norwayeast"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }

}


resource "azurerm_resource_group" "rg-security" {
     name     = "rg-security"
     location = "norwayeast"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }

}

resource "azurerm_virtual_network" "vnet" {
     name                = "vnet"
     location            = azurerm_resource_group.rg-network.location
     resource_group_name = azurerm_resource_group.rg-network.name
     address_space       = ["10.0.0.0/16"]


     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }

}


resource "azurerm_subnet" "subnet-app" {
     name                 = "subnet-app"
     resource_group_name  = azurerm_resource_group.rg-network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet-mgt" {
     name                 = "subnet-mgt"
     resource_group_name  = azurerm_resource_group.rg-network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet-fwl" {
     name                 = "subnet-fwl"
     resource_group_name  = azurerm_resource_group.rg-network.name
     virtual_network_name = azurerm_virtual_network.vnet.name
     address_prefixes     = ["10.0.3.0/24"]
}

# create nic for vm-app (not have a public ip)
resource "azurerm_network_interface" "nic-vm-app" {
     name                = "nic-vm-app"
     location            = azurerm_resource_group.rg-network.location
     resource_group_name = azurerm_resource_group.rg-network.name

     ip_configuration {
     name                          = "ipconfig"
     subnet_id                     = azurerm_subnet.subnet-app.id
     private_ip_address_allocation = "Dynamic"
     # public_ip_address_id          = azurerm_public_ip.pip.id
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create ip address
resource "azurerm_public_ip" "pip-vm-mgt" {
     name                = "pip-vm-mgt"
     location            = azurerm_resource_group.rg-network.location
     resource_group_name = azurerm_resource_group.rg-network.name

     allocation_method = "Static"
     sku               = "Standard"

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create nic for vm-mgt (have a public ip)
resource "azurerm_network_interface" "nic-vm-mgt" {
     name                = "nic-vm-mgt"
     location            = azurerm_resource_group.rg-network.location
     resource_group_name = azurerm_resource_group.rg-network.name

     ip_configuration {
     name                          = "ipconfig"
     subnet_id                     = azurerm_subnet.subnet-mgt.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = azurerm_public_ip.pip-vm-mgt.id
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create virtual machine which is going to run the application
resource "azurerm_linux_virtual_machine" "vm-app" {
     name                            = "vm-app"
     location                        = azurerm_resource_group.rg-compute.location
     resource_group_name             = azurerm_resource_group.rg-compute.name
     network_interface_ids           = [azurerm_network_interface.nic-vm-app.id]
     size                            = "Standard_B2ls_v2"
     computer_name                   = "ubunut-mgt-vm"
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
     name                 = "osdisk-vm-app"
     storage_account_type = "Standard_LRS"
     caching              = "ReadWrite"
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create virtual machine which is going to be used for management
resource "azurerm_linux_virtual_machine" "vm-mgt" {
     name                            = "vm-mgt"
     location                        = azurerm_resource_group.rg-compute.location
     resource_group_name             = azurerm_resource_group.rg-compute.name
     network_interface_ids           = [azurerm_network_interface.nic-vm-mgt.id]
     size                            = "Standard_B2ls_v2"
     computer_name                   = "ubunut-mgt-vm"
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
     name                 = "osdisk-vm-mgt"
     storage_account_type = "Standard_LRS"
     caching              = "ReadWrite"
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}


# create nsg for subnet-app (no one can reach it)
resource "azurerm_network_security_group" "nsg-subnet-app" {
     name                = "nsg-subnet-app"
     location            = azurerm_resource_group.rg-security.location
     resource_group_name = azurerm_resource_group.rg-security.name

     # allow ssh traffic (just from subnet-mgt, which is "10.0.2.0/24")
     security_rule {
          name                       = "SSH"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "10.0.2.0/24"
          destination_address_prefix = "*"
     }

     # deny any inbound traffic over tcp
     security_rule {
          name                       = "Deny-TCP-Incoming-Internet-Traffic"
          priority                   = 101
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }

     # deny any inbound traffic over udp
     security_rule {
          name                       = "Deny-UDP-Incoming-Internet-Traffic"
          priority                   = 102
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Udp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create nsg for subnet-mgt
resource "azurerm_network_security_group" "nsg-subnet-mgt" {
     name                = "nsg-subnet-mgt"
     location            = azurerm_resource_group.rg-security.location
     resource_group_name = azurerm_resource_group.rg-security.name

     # allow ssh traffic
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


     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}

# create nsg for subnet-fwl
resource "azurerm_network_security_group" "nsg-subnet-fwl" {
     name                = "nsg-subnet-fwl"
     location            = azurerm_resource_group.rg-security.location
     resource_group_name = azurerm_resource_group.rg-security.name

     # deny any inbound traffic over tcp
     security_rule {
          name                       = "Deny-TCP-Incoming-Internet-Traffic"
          priority                   = 101
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }

     # deny any inbound traffic over udp
     security_rule {
          name                       = "Deny-UDP-Incoming-Internet-Traffic"
          priority                   = 102
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Udp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
     }

     tags = {
     environment = "${local.environment}"
     application = "${local.application}"
     team        = "${local.team}"
     }
}


# attach nsg to subnet-app
resource "azurerm_subnet_network_security_group_association" "nsg-bind-subnet-app" {
    subnet_id                 = azurerm_subnet.subnet-app.id
    network_security_group_id = azurerm_network_security_group.nsg-subnet-app.id
}
# attach nsg to subnet-mgt
resource "azurerm_subnet_network_security_group_association" "nsg-bind-subnet-mgt" {
    subnet_id                 = azurerm_subnet.subnet-mgt.id
    network_security_group_id = azurerm_network_security_group.nsg-subnet-mgt.id
}
# attach nsg to subnet-fwl
resource "azurerm_subnet_network_security_group_association" "nsg-bind-subnet-fwl" {
    subnet_id                 = azurerm_subnet.subnet-fwl.id
    network_security_group_id = azurerm_network_security_group.nsg-subnet-fwl.id
}