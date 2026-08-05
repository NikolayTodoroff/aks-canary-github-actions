set -e

ENV=$1
LOCATION=$2
APP_NAME="akscanary"

if [ -z "$ENV" ] || [ -z "$LOCATION" ]; then
  echo "Usage: ./scripts/bootstrap.sh <environment> <location>"
  exit 1
fi

echo "Creating bootstrap infrastructure for: $ENV"

az group create \
  --name "rg-tfstate-${ENV}" \
  --location "${LOCATION}"

az storage account create \
  --name "st${APP_NAME}${ENV}" \
  --resource-group "rg-tfstate-${ENV}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name "st${APP_NAME}${ENV}"

echo "Bootstrap complete for ${ENV}"
echo "Storage account: st${APP_NAME}${ENV}"
echo "Resource group:  rg-tfstate-${ENV}"