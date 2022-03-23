locals {
  #Appsvc Settings
  app_settings = {
    default_settings = sensitive({
      APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.INSIGHTS.instrumentation_key}"
      DOKCER_REGISTRY_SERVER_URL     = "${var.acr_name}.azurecr.io"
    }),
    linux_app_settings = sensitive({
      APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.INSIGHTS.instrumentation_key}"
      DOKCER_REGISTRY_SERVER_URL     = "${var.acr_name}.azurecr.io"
      WEBSITE_PULL_IMAGE_OVER_VNET   = "true"
      LINUX_SENSITIVE_VALUE          = "!!sensitive_value!!"
    })
  }
  linux_fx_version = "DOCKER|${var.acr_name}/${var.appsvc_name}:latest"

  ## ACR Firewall rules ##
  #Get all possible outbound IPs from VNET integrated App services and combine with allowed Axpo On Prem IP ranges from var.axpo_fw_ips
  allowed_ips = distinct(flatten(concat(azurerm_app_service.APPSVC.possible_outbound_ip_address_list, var.acr_custom_fw_rules)))

  acr_fw_rules = [
    {
      default_action = "Deny"
      ip_rules = [for i in local.allowed_ips : {
        action   = "Allow"
        ip_range = i
        }
      ]
      virtual_network_subnets = [
        {
          action    = "Allow"
          subnet_id = azurerm_subnet.SUBNETS["App-Service-Integration-Subnet"].id
        }
      ]
    }
  ]

}