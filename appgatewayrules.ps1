# Get existing Application Gateway config
$appgw = Get-AzApplicationGateway `
    -ResourceGroupName $resGroupName `
    -Name $appgwName

    $sinkpool = New-AzApplicationGatewayBackendAddressPool -Name "sinkpool"


$listener = Get-AzApplicationGatewayHttpListener `
    -Name "apim-api-listener" `
    -ApplicationGateway $appgw

$sinkpool = Get-AzApplicationGatewayBackendAddressPool `
    -ApplicationGateway $appgw `
    -Name "sinkpool"

$pool = Get-AzApplicationGatewayBackendAddressPool `
    -ApplicationGateway $appgw `
    -Name "apimbackend"

$poolSettings = Get-AzApplicationGatewayBackendHttpSettings `
    -ApplicationGateway $appgw `
    -Name "apim-api-poolsetting"

$pathRule = New-AzApplicationGatewayPathRuleConfig `
    -Name "external" `
    -Paths "/external/*" `
    -BackendAddressPool $pool `
    -BackendHttpSettings $poolSettings

$appgw = Add-AzApplicationGatewayUrlPathMapConfig `
    -ApplicationGateway $appgw `
    -Name "external-urlpathmapconfig" `
    -PathRules $pathRule `
    -DefaultBackendAddressPool $sinkpool `
    -DefaultBackendHttpSettings $poolSettings

$appgw = Set-AzApplicationGateway `
    -ApplicationGateway $appgw

$pathmap = Get-AzApplicationGatewayUrlPathMapConfig `
    -ApplicationGateway $appgw `
    -Name "external-urlpathmapconfig"

$appgw = Add-AzApplicationGatewayRequestRoutingRule `
    -ApplicationGateway $appgw `
    -Name "apim-api-external-rule" `
    -RuleType PathBasedRouting `
    -HttpListener $listener `
    -BackendAddressPool $Pool `
    -BackendHttpSettings $poolSettings `
    -UrlPathMap $pathMap