#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

# List all virtual networks in the Azure subscription, extract the address prefixes of each VNet,
# select the last address prefix from the list, and format the output as JSON using jq
az network vnet list --query '[].addressSpace.addressPrefixes[] | [-1] | { vnet: @ }' --only-show-errors | jq
