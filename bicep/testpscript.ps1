$LOCATION = "westeurope"
$BICEP_FILE="main.bicep"

# delete a deployment
az deployment sub  delete  --name testasedeployment

# deploy the bicep file directly

az deployment sub  create --name testapim1   --template-file $BICEP_FILE   --parameters localparam.json --location $LOCATION -o json
