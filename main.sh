#!/bin/bash

##############################################################
####################### VARIABLE #############################
##############################################################
versionToDeploy=$1
applicationName=$2
namespace=$3
action=$4
useApplicationVersionForImageTag=$5
applicationValuePath=$6
networkValuePath=$7
applicationChartVersion=$8
networkChartVersion=$9
actualVersion="v0.0.0"
checkApplicationDeployedReturn="false"
checkNetworkDeployedReturn="false"
helmChartRepositoryName="cheerz-registry"
helmChartRepositoryAddress="http://charts.k8s.cheerz.net"
applicationChartName="web-application"
networkChartName="web-network"

##############################################################
####################### FUNCTIONS ############################
##############################################################

function get_running_version {
  local tempVersion=$(kubectl get cm hello-cm -n $namespace -o template --template={{.data.runningVersion}})
  # strict semver check + v prefix https://regexr.com/39s32
  if [[ $tempVersion =~ ^v{1}.* ]]; then
    actualVersion=$tempVersion
  fi
}

function checkNetworkDeployed {
  local return=$(helm ls -q --filter $applicationName-network)
  if [[ ${return[@]} ]]; then
    checkNetworkDeployedReturn="true"
  fi
}

function checkApplicationDeployed {
  local return=$(helm ls -q --filter ${applicationName}-$versionToDeploy)
  if [[ ${return[@]} ]]; then
    checkApplicationDeployedReturn="true"
  fi
}

##############################################################
########################## CODE ##############################
##############################################################
get_running_version;
checkNetworkDeployed;
checkApplicationDeployed;

# update all helm repository
helm repo add $helmChartRepositoryName $helmChartRepositoryAddress
helm repo update

# convert latest version name in the last avaible version on repo
if [[ $applicationChartVersion == "latest" ]]; then
  applicationChartVersion=$(helm show chart $helmChartRepositoryName/$applicationChartName | grep "version:" | awk '{ print $2}')
fi
if [[ $networkChartVersion == "latest" ]]; then
  networkChartVersion=$(helm show chart $helmChartRepositoryName/$networkChartName | grep "version:" | awk '{ print $2}')
fi

# if new version is not deployed yet, do it
if [[ $checkApplicationDeployedReturn == false ]]; then
  if [[ $useApplicationVersionForImageTag == false ]]; then
    helm install -f $BASE_WORKING_PATH/$applicationValuePath \
    --set application.version=$versionToDeploy \
    ${applicationName}-$versionToDeploy \
    --version $applicationChartVersion \
    $helmChartRepositoryName/$applicationChartName 
  else
    helm install -f $BASE_WORKING_PATH/$applicationValuePath \
    --set application.version=$versionToDeploy \
    --set application.image.tag=$versionToDeploy \
    ${applicationName}-$versionToDeploy \
    --version $applicationChartVersion \
    $helmChartRepositoryName/$applicationChartName  
  fi
fi

# Decision tree for network deploy part
if [[ $checkNetworkDeployedReturn == false ]]; then
  if [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    helm install -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=true  \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    --version $networkChartVersion \
    $helmChartRepositoryName/$networkChartName 
  elif [[ $action == "cancel" ]]; then
    helm install -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=true  \
    --set deploy.newVersion=$actualVersion \
    ${applicationName}-network \
    $helmChartRepositoryName/$networkChartName 
  else
    helm install -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=false  \
    --set deploy.runningVersion=$actualVersion \
    --set deploy.newVersion=$versionToDeploy \
    --version $networkChartVersion \
    ${applicationName}-network \
    $helmChartRepositoryName/$networkChartName 
  fi
else
  if [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    helm upgrade -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=true \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    --version $networkChartVersion \
    $helmChartRepositoryName/$networkChartName 
  elif [[ $action == "cancel" ]]; then
    helm upgrade -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=true  \
    --set deploy.newVersion=$actualVersion \
    --version $networkChartVersion \
    ${applicationName}-network \
    $helmChartRepositoryName/$networkChartName 
  else
    helm upgrade -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=false \
    --set deploy.runningVersion=$actualVersion \
    --set deploy.newVersion=$versionToDeploy \
    --version $networkChartVersion \
    ${applicationName}-network \
    $helmChartRepositoryName/$networkChartName 
  fi
fi



if [[ $actualVersion != "v0.0.0" ]] && [[ $actualVersion != $versionToDeploy ]]; then
  # delete old useless version
  if [[ $action == "complete" ]]; then
    helm delete ${applicationName}-${actualVersion}
  elif [[ $action == "cancel" ]]; then
    helm delete ${applicationName}-${versionToDeploy}
  fi
fi

# clean if old release stay in place
if [[ $actualVersion != "v0.0.0" ]] && ( [[ $action == "complete" ]] || [[ $action == "cancel" ]] ); then
  listRelease=$(helm ls -q --filter $applicationName-v.*)
  for release in $listRelease
  do
    if [[ $release != ${applicationName}-${versionToDeploy} ]]; then
      helm delete $release
    fi
  done
fi



##############################################################
########################## OUPUT #############################
##############################################################

echo "::set-output name=new-version:$(echo $versionToDeploy)"
echo "::set-output name=actual-version:$(echo $actualVersion)"