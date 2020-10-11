#!/bin/bash

##############################################################
####################### VARIABLE #############################
##############################################################
versionToDeploy=$1;
applicationName=$2
namespace=$3
completeDeploy=$4;
applicationValuePath=$5;
networkValuePath=$6;
actualVersion="v0.0.0"
checkApplicationDeployedReturn="false"
checkNetworkDeployedReturn="false"

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

# if new version is not deployed yet, do it
if [[ $checkApplicationDeployedReturn == false ]]; then
  helm install -f $BASE_WORKING_PATH/$applicationValuePath \
  --set application.version=$versionToDeploy \
  ${applicationName}-$versionToDeploy \
  cheerz-registry/web-application 
fi

# if no version already running, force full deploy
if [[ $actualVersion == "v0.0.0" ]]; then
  completeDeploy="true"
fi

# Decision tree for network deploy part
if [[ $checkNetworkDeployedReturn == false ]]; then
  if [[ $completeDeploy == true ]]; then
    helm install -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=$completeDeploy  \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    cheerz-registry/web-network 
  else
    helm install -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=$completeDeploy  \
    --set deploy.runningVersion=$actualVersion \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    cheerz-registry/web-network 
  fi
else
  if [[ $completeDeploy == true ]]; then
    helm upgrade -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=$completeDeploy \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    cheerz-registry/web-network 
  else
    helm upgrade -f $BASE_WORKING_PATH/$networkValuePath \
    --set deploy.complete=$completeDeploy \
    --set deploy.runningVersion=$actualVersion \
    --set deploy.newVersion=$versionToDeploy \
    ${applicationName}-network \
    cheerz-registry/web-network 
  fi
fi



if [[ $actualVersion != "v0.0.0" ]] && [[ $completeDeploy == true ]] && [[ $actualVersion != $versionToDeploy ]]; then
  # delete old useless version
  helm delete ${applicationName}-${actualVersion}
fi

# clean if old release stay in place
if [[ $actualVersion != "v0.0.0" ]] && [[ $completeDeploy == true ]]; then
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
echo "::set-output name=complete::$(echo $completeDeploy)"