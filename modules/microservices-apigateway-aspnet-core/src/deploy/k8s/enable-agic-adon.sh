#!/bin/bash

# Color theming
if [ -f ~/clouddrive/aspnet-learn/setup/theme.sh ]
then
  . <(cat ~/clouddrive/aspnet-learn/setup/theme.sh)
fi

pushd ~/clouddrive/aspnet-learn/src/deploy/k8s > /dev/null

echo
echo "Enable AGIC add on"
echo "============================"

if [ -f ~/clouddrive/aspnet-learn/create-aks-exports.txt ]; then  
  eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)
fi

if [ -f ~/clouddrive/aspnet-learn/create-application-gateway-exports.txt ]; then
  eval $(cat ~/clouddrive/aspnet-learn/create-application-gateway-exports.txt)
fi

if [ -z "$ESHOP_RG" ]  || [ -z "$ESHOP_AKSNAME" ] || [ -z "$ESHOP_APPGATEWAY" ] || [ -z "$ESHOP_APPGATEWAYRG" ] || [ -z "$ESHOP_APPVNET" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_RG..: $ESHOP_RG"
    echo "- ESHOP_AKSNAME: $ESHOP_AKSNAME"
    echo "- ESHOP_APPGATEWAY............: $ESHOP_APPGATEWAY"
    echo "- ESHOP_APPGATEWAYRG..........: $ESHOP_APPGATEWAYRG"
    echo "- ESHOP_APPVNET..........: $ESHOP_APPVNET"
    exit 1
fi

appgwId=$(az network application-gateway show -n $ESHOP_APPGATEWAY -g $ESHOP_RG -o tsv --query "id") 
az aks enable-addons -n $ESHOP_AKSNAME -g $ESHOP_RG -a ingress-appgw --appgw-id $appgwId


echo
echo "Peer the AKS and APP Gateway virtual networks together"
echo "============================"

nodeResourceGroup=$(az aks show -n $ESHOP_AKSNAME -g $ESHOP_RG -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")

aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")
az network vnet peering create -n AppGWtoAKSVnetPeering -g $ESHOP_RG --vnet-name $ESHOP_APPVNET --remote-vnet $aksVnetId --allow-vnet-access

appGWVnetId=$(az network vnet show -n $ESHOP_APPVNET -g $ESHOP_RG -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

echo
echo "AGIC enabled in your existing cluster"
echo "============================"

popd > /dev/null