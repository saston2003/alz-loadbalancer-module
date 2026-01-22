# Install IIS on both Skynet VMs using count
resource "azurerm_virtual_machine_extension" "iis" {
  count                = 2
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; New-NetFirewallRule -DisplayName 'Allow HTTP' -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow; New-NetFirewallRule -DisplayName 'Allow HTTPS' -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value '<html><body style=font-family:Arial;text-align:center;padding:50px><h1>Skynet${format("%02d", count.index + 1)}</h1><p>Load Balanced Web Server</p><p>IIS is running successfully!</p></body></html>'\""
  })

  tags = var.tags
}