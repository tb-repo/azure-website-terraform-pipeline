resource "azurerm_network_interface" "web" {
  name                = "tb-nic-web"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = {
    Name = "tb-nic-web"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "tb-vm-web"
  location                        = data.azurerm_resource_group.lab.location
  resource_group_name             = data.azurerm_resource_group.lab.name
  size                            = "Standard_B21s_v2"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.web.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /var/www/html/index.html
        content: |
          <!doctype html>
          <html><head><title>Thiagrajan Azure Terraform Lab</title></head>
          <body><h1>It works!</h1><p>Automation deployed with Terraform using Azure DevOps Pipeline.</p></body></html>
    runcmd:
      - [systemctl, enable, --now, nginx]
  CLOUD_INIT
  )

  tags = {
    Name = "tb-vm-web"
  }
}

data "azurerm_ssh_public_key" "web" {
  name                = "tb-vm-ssh-pvt-key"
  resource_group_name = "tb_rg"
}