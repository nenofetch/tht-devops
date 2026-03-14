# Resource Group Azure
resource "azurerm_resource_group" "rg" {
  name = "${var.instance_name}-rg"
  location = var.region
}

# Virtual Network Azure
resource "azurerm_virtual_network" "vnet" {
  name    = "${var.instance_name}-vnet"
  address_space   = [var.vcn_cidr]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}


# Security list: allow inbound 22 (SSH), 80 (HTTP), and 9100 (Node Exporter) and Outbound
# Network Security Group
resource "azurerm_network_security_group" "web" {
  name = "${var.instance_name}-nsg"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

# SSH Inbound Rules
resource "azurerm_network_security_rule" "ssh" {
   name                        = "SSH"
   priority                    = 100
   direction                   = "Inbound"
   access                      = "Allow"
   protocol                    = "Tcp"

   source_port_range           = "*"
   destination_port_range      = "22"

   source_address_prefix       = "*"
   destination_address_prefix  = "*"

   resource_group_name         = azurerm_resource_group.rg.name
   network_security_group_name = azurerm_network_security_group.web.name
}

# HTTP Inbound Rules
resource "azurerm_network_security_rule" "http" {
   name                        = "HTTP"
   priority                    = 200
   direction                   = "Inbound"
   access                      = "Allow"
   protocol                    = "Tcp"

   source_port_range           = "*"
   destination_port_range      = "80"

   source_address_prefix       = "*"
   destination_address_prefix  = "*"

   resource_group_name         = azurerm_resource_group.rg.name
   network_security_group_name = azurerm_network_security_group.web.name
}

# Node Exporter Inbound Rules
resource "azurerm_network_security_rule" "node_exporter" {
   name                        = "NodeExporter"
   priority                    = 300
   direction                   = "Inbound"
   access                      = "Allow"
   protocol                    = "Tcp"

   source_port_range           = "*"
   destination_port_range      = "9100"

   source_address_prefix       = "*"
   destination_address_prefix  = "*"

   resource_group_name         = azurerm_resource_group.rg.name
   network_security_group_name = azurerm_network_security_group.web.name
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name = "${var.instance_name}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.subnet_cidr]
}

# Compute Instance Public IP and Network Interface
resource "azurerm_public_ip" "vm" {
  name = "${var.instance_name}-ip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Standard"
  allocation_method = "Static"
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.instance_name}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_linux_virtual_machine" "web" {
 name = var.instance_name
 resource_group_name = azurerm_resource_group.rg.name
 location = azurerm_resource_group.rg.location
 size = "Standard_D2als_v6"

 admin_username = "azureuser"
 network_interface_ids = [
   azurerm_network_interface.vm.id
 ]

 admin_ssh_key {
   username = "azureuser"
   public_key = var.ssh_public_key
 }

 os_disk {
   caching = "ReadWrite"
   storage_account_type = "Standard_LRS"
 }

 source_image_reference {
   publisher = "Canonical"
   offer = "0001-com-ubuntu-server-jammy"
   sku = "22_04-lts-gen2"
   version = "latest"
 }
 custom_data = base64encode(file("cloud-init.sh"))
}
