provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}
 #vnet config
  resource "azurerm_virtual_network" "demo" {
    name                = "demo-network"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.demo.location
    resource_group_name = azurerm_resource_group.demo.name
  }
  
  resource "azurerm_subnet" "demo" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.demo.name
    virtual_network_name = azurerm_virtual_network.demo.name
    address_prefixes     = ["10.0.2.0/24"]
  }
  
  resource "azurerm_network_interface" "demo" {
    count               = var.vm_count
    name                = "demo-nic-${count.index}"
    location            = azurerm_resource_group.demo.location
    resource_group_name = azurerm_resource_group.demo.name
  
    ip_configuration {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.demo.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.public_ip["${count.index}"].id
    }
  }
  #security Group config
  resource "azurerm_network_security_group" "nsg" {
    name                = "ssh_nsg"
    location            = azurerm_resource_group.demo.location
    resource_group_name = azurerm_resource_group.demo.name
  
    security_rule {
      name                       = "allow_ssh_sg"
      priority                   = 100 
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
  
  resource "azurerm_network_interface_security_group_association" "association" {
    count = var.vm_count
    network_interface_id      = azurerm_network_interface.demo[count.index].id
    network_security_group_id = azurerm_network_security_group.nsg.id
  }
  #ip config
  resource "azurerm_public_ip" "public_ip" {
    count               = var.vm_count
    name                = "vm_public_ip-${count.index}"
    resource_group_name = azurerm_resource_group.demo.name
    location            = azurerm_resource_group.demo.location
    allocation_method   = "Dynamic"
  }
  #vm config
  resource "azurerm_resource_group" "demo" {
    name     = "demo-resources"
    location = "Central India"
  }
  
  resource "azurerm_linux_virtual_machine" "demo" {
    count               = var.vm_count
    name                = "demo-machine-${count.index}"
    resource_group_name = azurerm_resource_group.demo.name
    location            = azurerm_resource_group.demo.location
    size                = "Standard_B1s"
    admin_username      = "adminuser"
    admin_password      = "Pass@123456pass"
    disable_password_authentication = false
    network_interface_ids = [
      azurerm_network_interface.demo["${count.index}"].id,
    ]
      os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }
  
    source_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    }
    }
