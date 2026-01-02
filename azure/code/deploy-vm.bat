@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

:: define variables 
SET loc=norwayeast
SET rg=rg-team0-ne
SET vnet=vnet-team0-ne
SET snet=snet-team0-ne
SET vm=vm-team0-ne
SET ip=pip-team0-ne
SET nic=nic-team0-ne
SET dns=vm-team0-ne
SET nsg=nsg-team0-ne

:: create resource group
CALL az group create --name "%rg%" --location "%loc%"
IF ERRORLEVEL 1 GOTO :error

:: create vnet
CALL az network vnet create --resource-group "%rg%" --name "%vnet%" --address-prefixes 10.0.0.0/16
IF ERRORLEVEL 1 GOTO :error

:: create snet
CALL az network vnet subnet create --resource-group "%rg%" --vnet-name "%vnet%" --name "%snet%" --address-prefixes 10.0.0.0/24
IF ERRORLEVEL 1 GOTO :error

:: create public ip
CALL az network public-ip create --resource-group "%rg%" --name "%ip%" --sku Standard --allocation-method Static --dns-name "%dns%"
IF ERRORLEVEL 1 GOTO :error

:: create nic
CALL az network nic create --resource-group "%rg%" --name "%nic%" --vnet-name "%vnet%" --subnet "%snet%" --public-ip-address "%ip%"
IF ERRORLEVEL 1 GOTO :error

::  create vm
CALL az vm create --resource-group "%rg%" --name "%vm%" --nics "%nic%" --image Ubuntu2204 --size Standard_B2ls_v2 --admin-username azureuser --generate-ssh-keys
IF ERRORLEVEL 1 GOTO :error

:: create network security group
CALL az network nsg create --resource-group "%rg%" --name "%nsg%"  --location "%loc%"
IF ERRORLEVEL 1 GOTO :error

:: allow tcp on port 22 (create network security group rule)
CALL az network nsg rule create --resource-group "%rg%" --nsg-name "%nsg%" --name Allow-SSH --priority 1000 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 22
IF ERRORLEVEL 1 GOTO :error

:: allow tcp on port 8080 (create network security group rule)
CALL az network nsg rule create --resource-group "%rg%" --nsg-name "%nsg%" --name Allow-HTTP --priority 1010 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 8080
IF ERRORLEVEL 1 GOTO :error

:: allow tcp on port 80 (create network security group rule)
CALL az network nsg rule create --resource-group "%rg%" --nsg-name "%nsg%" --name Allow-IANA-HTTP --priority 1020 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 80
IF ERRORLEVEL 1 GOTO :error

:: allow tcp on port 443 (create network security group rule)
CALL az network nsg rule create --resource-group "%rg%" --nsg-name "%nsg%" --name Allow-IANA-HTTPS --priority 1030 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 443
IF ERRORLEVEL 1 GOTO :error

:: attach rule to subnet
CALL az network vnet subnet update --resource-group "%rg%" --vnet-name "%vnet%" --name "%snet%" --network-security-group "%nsg%"
IF ERRORLEVEL 1 GOTO :error

echo Operazione completata con successo!
pause
exit /b 0

:error
echo Operazione non completata!
pause
exit /b 1



:: to start and stop vm
:: az vm stop  --resource-group rg-team0-ne --vm vm-team0-ne
:: az vm start --resource-group rg-team0-ne --vm vm-team0-ne

:: to destroy anything
:: az group delete --resource group rg-team0-ne