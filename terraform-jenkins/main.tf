terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "self-rg" {
  name     = "${var.env_name}-resources"
  location = "West Europe"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "self-vn" {
  name                = "${var.env_name}-network"
  location            = azurerm_resource_group.self-rg.location
  resource_group_name = azurerm_resource_group.self-rg.name
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "self-subnet" {
  name                 = "${var.env_name}-subnet"
  resource_group_name  = azurerm_resource_group.self-rg.name
  virtual_network_name = azurerm_virtual_network.self-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "self-sg" {
  name                = "${var.env_name}-sg"
  location            = azurerm_resource_group.self-rg.location
  resource_group_name = azurerm_resource_group.self-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "self-dev-rule" {
  name                        = "${var.env_name}-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.self-rg.name
  network_security_group_name = azurerm_network_security_group.self-sg.name
}

resource "azurerm_subnet_network_security_group_association" "self-sga" {
  subnet_id                 = azurerm_subnet.self-subnet.id
  network_security_group_id = azurerm_network_security_group.self-sg.id
}

resource "azurerm_public_ip" "self-ip" {
  name                = "${var.env_name}-ip"
  location            = azurerm_resource_group.self-rg.location
  resource_group_name = azurerm_resource_group.self-rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "self-nic" {
  name                = "${var.env_name}-nic"
  location            = azurerm_resource_group.self-rg.location
  resource_group_name = azurerm_resource_group.self-rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.self-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.self-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "self-vm" {
  name                = "${var.env_name}-vm"
  resource_group_name = azurerm_resource_group.self-rg.name
  location            = azurerm_resource_group.self-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.self-nic.id,
  ]

  custom_data = base64encode("${data.template_file.init.rendered}")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azure.pub")
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_key_vault" "jenkins" {
  name                = "${var.key_vault_name}"
  resource_group_name = "${var.key_vault_rg}"
}

data "azurerm_key_vault_secret" "jenkins-username" {
  name         = "${var.key_vault_username_field_name}"
  key_vault_id = data.azurerm_key_vault.jenkins.id
}

data "azurerm_key_vault_secret" "jenkins-password" {
  name         = "${var.key_vault_password_field_name}"
  key_vault_id = data.azurerm_key_vault.jenkins.id
}

data "azurerm_public_ip" "self-ip-data" {
  name                = azurerm_public_ip.self-ip.name
  resource_group_name = azurerm_resource_group.self-rg.name
}

data "template_file" "init" {
  template = "${file("customdata.tpl.j2")}"
  vars = {
    username = "${data.azurerm_key_vault_secret.jenkins-username.value}",
    password = "${data.azurerm_key_vault_secret.jenkins-password.value}"
  }
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.self-vm.name}: ${data.azurerm_public_ip.self-ip-data.ip_address}"
}

output "jenkins_username" {
  value = "${data.azurerm_key_vault_secret.jenkins-username.value}"
  sensitive = true
}

output "jenkins_password" {
  value = "${data.azurerm_key_vault_secret.jenkins-password.value}"
  sensitive = true
}
