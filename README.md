Azure container apps example
===============================


Deployment steps:
------------------


Clone Repo and move into it:

	git clone git@github.com:raddaoui/aca-demo.git
	cd aca-demo

Deploy infrastructure:

	bash infra/create_demo_infra.sh


LOG Analytics query example
------------------------------

To view logs through the Azure portal, hop on to the log analytic workspace and run this query:

	ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'aca-printenv-app' | project ContainerAppName_s, Log_s, TimeGenerated | take 100


Build application image
------------------------

Build image using ACR tasks:

	ACR_NAME="{ACR registry name}"
	IMAGE_NAME="printenv"
	IMAGE_TAG="v1"
	RESOURCE_GROUP="{ACR resource group}"
	az login # authenticate if you're not
	az acr build --registry $ACR_NAME -g $RESOURCE_GROUP --image $IMAGE_NAME:$IMAGE_TAG .


Build using docker:

	docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG .
	docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG

