#!/bin/bash

RED='\033[0;31m'
LBLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

while getopts 'h:r:n:t:' OPTION; do
  case "$OPTION" in
    h)
      echo "You have supplied the -h option."
      echo "script usage: update-db-tags.sh [-h] [-r resource-group] [-n name of db] [-t db tag value]"
      echo -e "Available Resource Groups:\n train-rg-cbdb\n prod-rg-cbdb" 
      echo "Availability depends on selected Azure Subscription" >&2
      exit 1
      ;;
    r)
      rvalue="$OPTARG"
      echo -e "[DEBUG] ${LBLUE}The resource group provided is $OPTARG${NC}"
      ;;
    n)
      nvalue="$OPTARG"
      echo -e "[DEBUG] ${LBLUE}The database name provided is $OPTARG${NC}"
      ;;
    t)
      tvalue="$OPTARG"
      echo -e "[DEBUG] ${LBLUE}The db tag value provided equals $OPTARG${NC}"
      ;;
    ?)
      echo "script usage: update-db-tags.sh [-h] [-r resource-group] [-n name of db] [-t db tag value]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"


if [[ -z $rvalue ]];
  then
  echo -e "[ERROR] ${RED}Missing resource group argument${NC}" >&2
  exit 1

elif [[ -z $nvalue ]];
  then
  echo -e "[ERROR] ${RED}Missing database name argument${NC}" >&2
  exit 1

elif [[ -z $tvalue ]];
  then
  echo -e "[ERROR] ${RED}Missing desired db tag value argument${NC}" >&2
  exit 1

else
  #Checking if jq is installed, because its needed to parse the azure return
  command -v jq >/dev/null 2>&1 || { echo "jq is required to parse the azure return, but it's not installed.  Aborting." >&2; exit 1; }
  
  ## Populating the tag variables
  cbdbtag="cbdb=$tvalue"
  tempenvtag=$(az mysql flexible-server show --resource-group $rvalue --name $nvalue --query "{tags:tags.env}")
  envval=$(echo "$tempenvtag" | jq -r '.tags')
  envtag="env=$(envval)"
  echo -e "[DEBUG] ${LBLUE}The env tag value retrieved is $envval${NC}"

fi

if [[ -z $tempenvtag ]];
  then
  echo -e "[ERROR] ${RED}Empty azure env tag query response${NC}" >&2
  exit 1

elif [[ -z $envtag ]];
  then
  echo -e "[ERROR] ${RED}Empty json parser return${NC}" >&2
  exit 1

else
  echo -e "[INFO] This script will update the db tag to ${GREEN}$tvalue${NC} on database ${GREEN}$nvalue${NC} in resource group ${GREEN}$rvalue${NC}\n[INFO] The current env tag retrieved is ${GREEN}$envtag${NC}"

  az mysql flexible-server update --resource-group $rvalue --name $nvalue --tags $cbdbtag $envtag


  echo -e "[INFO] ${LBLUE}List of databases in resource group $rname${NC}"
  az mysql flexible-server list --resource-group $rvalue --query "[].{Name:name, cbdb:tags.cbdb, state:state, sku:sku.name, FQDN:fullyQualifiedDomainName}" --output table

fi
