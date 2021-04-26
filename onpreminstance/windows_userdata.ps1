<powershell>
$index = Get-NetAdapter | Select-Object InterfaceAlias , InterfaceIndex
set-DnsClientServerAddress -InterfaceIndex $index.InterfaceIndex -ServerAddresses ("${dns1}","${dns2}")
</powershell>l>