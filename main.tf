# Terraform provider block
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}


}
# 1 - Create resource group
resource "azurerm_resource_group" "ikazure-rg" {
  name     = "keitazure-rg"
  location = "East us"
  tags = {
    environment = "dev"
  }
}
# 2 Deploy a virtual  network (vnet) 
resource "azurerm_virtual_network" "ikvnet" {
  name                = "ik-vnet"
  resource_group_name = azurerm_resource_group.ikazure-rg.name
  location            = azurerm_resource_group.ikazure-rg.location
  address_space       = ["10.123.0.0/16"]
  tags = {
    environment = "dev"
  }

}
# 3 Deploy subnet 
resource "azurerm_subnet" "ikazure-sb" {
  name                 = "ik-subnet1"
  resource_group_name  = azurerm_resource_group.ikazure-rg.name
  virtual_network_name = azurerm_virtual_network.ikvnet.name
  address_prefixes     = ["10.123.0.0/24"]


}
# 4 Deploy Network Security group (NSG)
resource "azurerm_network_security_group" "ikazure-nsg" {
  name                = "ik-nsg"
  location            = azurerm_resource_group.ikazure-rg.location
  resource_group_name = azurerm_resource_group.ikazure-rg.name
  tags = {
    environment = "dev"
  }

}
# 5 Create rules for Network security group
resource "azurerm_network_security_rule" "example" {
  name                        = "ikazure-nsgr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ikazure-rg.name
  network_security_group_name = azurerm_network_security_group.ikazure-nsg.name
}
# 6 Associate NSG to the subnet 
resource "azurerm_subnet_network_security_group_association" "ikazure-subassociat" {
  subnet_id                 = azurerm_subnet.ikazure-sb.id
  network_security_group_id = azurerm_network_security_group.ikazure-nsg.id
}
# 7 Generate a public ip add 
resource "azurerm_public_ip" "example" {
  name                    = "ikazure-ip"
  location                = azurerm_resource_group.ikazure-rg.location
  resource_group_name     = azurerm_resource_group.ikazure-rg.name
  allocation_method       = "Dynamic"
  

  tags = {
    environment = "dev"
  }
}
# 8  Network interface
resource "azurerm_network_interface" "ikazure-ni" {
  name                  = "ikazure-nic"
  location              = azurerm_resource_group.ikazure-rg.location
  resource_group_name   = azurerm_resource_group.ikazure-rg.name
  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.ikazure-sb.id
    public_ip_address_id = azurerm_public_ip.example.id

  }
  tags = {
    environment="dev"
  }


  
}
# 9 Create a VM for this network
resource "azurerm_linux_virtual_machine" "ikazure-vm" {
  name                = "ikazure-vm"
  resource_group_name = azurerm_resource_group.ikazure-rg.name
  location            = azurerm_resource_group.ikazure-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.ikazure-ni.id,
  ]
  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  
}