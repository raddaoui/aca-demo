SUBSCRIPTION="2d29908b-9e1b-407e-8678-73678dbc8a62"
RESOURCE_GROUP="aca-rg"
LOCATION="eastus"
LOG_ANALYTICS_WORKSPACE="aca-logs"
CONTAINERAPPS_ENVIRONMENT="aca-env"
CONTAINERAPP_NAME="aca-printenv-app"
ACR_NAME="alaacr270"
IMAGE_NAME="printenv"
IMAGE_TAG="v1"

# Create resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Create ACR
az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku premium --admin-enabled
ACR_SERVER=$(az acr show -n $ACR_NAME --query loginServer -o tsv) # assumes ACR Admin Account is enabled
ACR_UNAME=$(az acr credential show -n $ACR_NAME --query="username" -o tsv)
ACR_PASSWD=$(az acr credential show -n $ACR_NAME --query="passwords[0].value" -o tsv)

# Create a new Log Analytics workspace with the following command:
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_WORKSPACE

# retrieve the Log Analytics Client ID and client secret.
LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_WORKSPACE --out tsv`
LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=`az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_WORKSPACE --out tsv`

# create Azure Container Apps environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET \
  --location "$LOCATION"

# build Application image using ACR tasks
az acr build --registry $ACR_NAME -g $RESOURCE_GROUP --image $IMAGE_NAME:$IMAGE_TAG .

# Create container app
az containerapp create \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG \
  --registry-login-server $ACR_SERVER \
  --registry-username $ACR_UNAME \
  --registry-password $ACR_PASSWD \
  --secrets my-app-secret=supersensitivesecret \
  --environment-variables HTTP_PORT=80 \
  --cpu 0.5 --memory 1.0Gi \
  --target-port 80 \
  --ingress 'external' \
  --query configuration.ingress.fqdn
  #--min-replicas 1 \
  #--max-replicas 10 \

<<'###'
# Create service principle for github actions continious deployment
az ad sp create-for-rbac  \
	--name api://$CONTAINERAPP_NAME \
	--role "contributor" \
	--scopes /subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP  \
	--sdk-auth


CLIENT_ID=$(az ad sp show --id api://$CONTAINERAPP_NAME --query appId --output tsv)
TENANT_ID=$(az ad sp show --id api://$CONTAINERAPP_NAME --query appOwnerTenantId --output tsv)
CLIENT_SECRET=$(az ad sp credential reset --name api://$CONTAINERAPP_NAME --query "password" -o tsv)


GITHUB_OWNER="raddaoui"
GITHUB_REPO="aca-demo"
BRANCH_NAME="master"
GITHUB_PAT=""
# add github action CD integration
az containerapp github-action add \
  --repo-url "https://github.com/$GITHUB_OWNER/$GITHUB_REPO" \
  --docker-file-path "./dockerfile" \
  --branch $BRANCH_NAME \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --registry-url $ACR_SERVER \
  --registry-username $ACR_UNAME \
  --registry-password $ACR_PASSWD \
  --service-principal-client-id $CLIENT_ID \
  --service-principal-client-secret $CLIENT_SECRET \
  --service-principal-tenant-id $TENANT_ID \
  --token $GITHUB_PAT
  --login-with-github

# update container app to create a new revision
IMAGE_TAG="v2"
az containerapp create \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG \
###