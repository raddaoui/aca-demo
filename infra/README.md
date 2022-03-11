# deploy Azure container app using an ARM deployment
 
        params="containerappName=aca-printenv-app location=eastus environment_name=aca-env acr_password=xxxyyy"
        az deployment group create \
           --resource-group aca-rg \
           --template-file aca_deployment.json\
           --parameters $params
