#! /bin/bash

######################################################################
#                                                                    #
# This script is meant to remediate extension issues by uninstalling #
# and reinstalling the omsagentforlinux extension.                   #
#                                                                    #
#                         IMPORTANT!!!!                              #
# You must log into the azure cli prior to running the script and    #
# use the command "az account set -s "<subscription ID>" to change   #
# to the correct subscription of the VM. If this is not done, Then   #
# the script will not be able to gather environment variables.       #
#                                                                    #
######################################################################

echo " "
echo "#############################################"
echo "#  Note: You must perform an az login and   #"
echo "# an az account set prior to running script #"
echo "#                                           #"
echo "#     If you have completed these steps,    #"
echo "#             Please continue.              #"
echo "#############################################"
echo " "

echo -n "What is the name of the VM? "
read '-i ':

hostname=${REPLY}

read -r -p "You have entered ${REPLY}, Is this correct? [y/N] " response
case "$response" in
                    [yY][eE][sS]|[yY])
        echo " "
        echo "##########################################"
        echo "# Gathering data required for next steps #"
        echo "#    This task may take a few minutes    #"
        echo "##########################################"
        echo " "
# Grab all Variables
                # This command grabs the Resource Group name
resourcegroup=$(az vm list --show-details | grep ${REPLY} | grep -i "rg" | awk -F "/" '{print $5; exit}')
                echo "Resource Group:"
                echo "          $resourcegroup"
                #This command grabs the Log Analytics Name
loganalytics=$(az monitor log-analytics workspace list --resource-group $resourcegroup | grep "id" | awk -F',' '{gsub(/"/, "", $1);print $1}' | awk //'{print $2}' | awk -F "/" '{print $9; exit}')
                echo "Log Analytics Workspace:"
                echo "          $loganalytics"
                # This command grabs the workspace ID. Need to figure out how to get the resource group and workspace name added first before running this
workspaceid=$(az monitor log-analytics workspace show -g $resourcegroup --workspace-name $loganalytics | grep "customerId" | awk -F',' '{gsub(/"/, "", $1);print $1}' | awk //'{print $2}')
                echo "Workspace ID:"
                echo "          $workspaceid"

                # This command grabs the primary shared key from the log analytics workspace
primarykey=$(az monitor log-analytics workspace get-shared-keys --resource-group $resourcegroup --workspace-name $loganalytics | grep primarySharedKey | awk -F',' '{gsub(/"/, "", $1);print $1}' | awk //'{print $2}')
                echo "Primary Key:"
                echo "          $primarykey"
                echo " "
                ;;

        *)
                echo "Script will now end, Thanks for playing"
                exit 0
                ;;
esac
echo ""
echo "#################################################"
echo "# The environment variables have been gathered. #"
echo "#################################################"
echo ""
echo "Press Enter to uninstall extension, or Press 's' to skip this step."
while : ; do
        read -n 1 k <&1
        if [[ $k = s ]] ; then
                printf "\nThis step has been skipped, Please press "Enter" to continue.\n"
                break
        else
                echo "Beginning uninstall of OmsAgentForLinux extension"
                # Remove OMSAgent
                az vm extension delete -g $resourcegroup --vm-name ${REPLY} -n OmsAgentForLinux
        fi
echo "Extension has been removed. To continue, press "enter" or 'q' to exit script."
break
done

while : ; do

        read -n 1 k <&1
        if [[ $k = q ]] ; then
                printf "\nThank you for using the script.\n"
                break
        else
                echo "Beginning install of OmsAgentForLinux extension."
                # Install OMSAgent extension
                 az vm extension set --resource-group $resourcegroup --vm-name ${REPLY} --name OmsAgentForLinux --publisher Microsoft.EnterpriseCloud.Monitoring --version 1.9.1 --protected-settings ''{"\"workspaceKey"\":"\"$primarykey"\"}'' --settings ''{"\"workspaceId"\":"\"$workspaceid"\"}''

                 echo "Re-install has been completed!"
                 break
        fi
done