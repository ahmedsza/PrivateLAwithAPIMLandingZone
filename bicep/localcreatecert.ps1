$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\localmachine\my -dnsname www.contoso.com
$password = ConvertTo-SecureString -String "Azure123456!" -Force -AsPlainText
Get-ChildItem -Path ("Cert:\LocalMachine\my\" + $cert.Thumbprint) | Export-PfxCertificate -FilePath appgw.pfx -Password $password