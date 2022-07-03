# 0. Preliminaries
#
# - Databricks verbose audit logs is enabled and propagated to log analytics workspace
# - See readme.md in git repo

# 1. Set variables
#
$SUB='<<your subscription id>>'
$EMAIL='<<your email address>>'
$LAW_RG='<<your resource group with Log Workspace analytics>>'
$LAW_NAME='<<your Log Workspace Analytics name>>'
$ALERT_GROUP_NAME='dbr_exf_detection_ag'
$ALERT_RULE_NAME='dbr_exf_detection_alert'

# 2. Log in
#
az login
az account set --subscription $SUB

# 3. Create Action Group
#
az monitor action-group create -n $ALERT_GROUP_NAME -g $LAW_RG --action email rebremer $EMAIL
$action_id=$(az monitor action-group show -n $ALERT_GROUP_NAME -g $LAW_RG | ConvertFrom-Json).id

# 4. Read Kusto detection file, escape special characters
#
Set-Location deployment
$kusto_script = Get-Content "..\detection\databricksnotebook.kusto" -Raw
$kusto_script = $kusto_script -replace "`r`n", "\n"
$kusto_script = $kusto_script -replace '"', '\"'

# 5. Add Kusto file to ARM template (passing as parameters fails due to special characters)
#
$arm_data = Get-Content "arm_dbr_exf_script.json.template" -Raw
$arm_data = $arm_data -replace "{dbr_exf_script}", $kusto_script
$arm_data | Out-File -encoding ASCII arm_dbr_exf_script.json

# 6. Create Alert rule using ARM template
#
$law_id="/subscriptions/$SUB/resourcegroups/$LAW_RG/providers/microsoft.operationalinsights/workspaces/$LAW_NAME"
az deployment group create --name AlertDeploymentv4 --resource-group $LAW_RG --template-file arm_dbr_exf_script.json --parameters scheduledqueryrules_dbr_data_exfiltration_name=$alert_rule_name actionGroups_test_dbrdataexf_ag_externalid=$action_id workspaces_test_storlogging_law_externalid=$law_id