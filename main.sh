#!/bin/bash

# exemple usage : 
# ./main.sh \
# --application-image-tag="true" \
# --action="update" \
# --namespace="production" \
# --version-deploy="1.2.3" \
# --app-value-path="application/value.yml" \
# --network-value-path="network/value.yml" \
# --sidekiq-value-path="sidekiq/value.yml" \
# --app-chart-version="1.0.1" \
# --network-chart-version="1.0.0" \
# --sidekiq-chart-version="1.0.0" \
# --github-id="zefz848ezfze8e" \
# --github-path="cheerz/fotom" \
# --github-url="https://github.com/cheerz/fotom" \
# fotom

##############################################################
####################### ARGUMENTS ############################
##############################################################

versionToDeploy="" # => --version-deploy
namespace="" # => --namespace
action="" # => --action
useApplicationVersionForImageTag="false" # => -t
applicationValuePath="" # => --app-value-path
networkValuePath="" # => --network-value-path
sidekiqValuePath="" # => --sidekiq-value-path
cronJobsValuePath="" # => --cron-jobs-value-path
pgValuePath="" # => --pg-value-path
commonValuePath="" # => --common-value-path
applicationChartVersion="" # => --app-chart-version
networkChartVersion="" # => --network-chart-version
sidekiqChartVersion="" # => --sidekiq-chart-version
cronJobsChartVersion="" # => --cron-jobs-chart-version
pgChartVersion="" # => --pg-chart-version
githubId="" # => --github-id
githubPath="" # => --github-path
githubUrl="" # => --github-url

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "Kubernetes deploy pilot - Generate a deploy"
      echo " "
      echo "./main.sh [options] applicationName"
      echo " "
      echo "options:"
      echo "-h, --help                                      Show brief help"
      echo "--application-image-tag=true|false              Use application version for docker image tag"
      echo "--action=create|complete|update|cancel          Specify an action to apply"
      echo "--version-deploy=VERSIONTODEPLOY                Give the version to deploy"
      echo "--namespace=production|staging                  Target namespace"
      echo "--app-value-path=APPVALUEPATH                   Value file path for application"
      echo "--network-value-path=NETWORKVALUEPATH           Value file path for network"
      echo "--sidekiq-value-path=>SIDEKIQVALUEPATH          Value file path for sidekiq"
      echo "--cron-jobs-value-path=>CRONJOBSVALUEPATH       Value file path for cron jobs"
      echo "--pg-value-path=>PGVALUEPATH                    Value file path for postgresql"
      echo "--common-value-path=>COMMONVALUEPATH            Common value file path"
      echo "--app-chart-version=APPCHARTVERSION             Version to use for application chart"
      echo "--network-chart-version=NETWORKCHARTVERSION     Version to use for network chart"
      echo "--sidekiq-chart-version=SIDEKIQCHARTVERSION     Version to use for sidekiq chart"
      echo "--cron-jobs-chart-version=CRONJOBSCHARTVERSION  Version to use for cron jobs chart"
      echo "--pg-chart-version=PGCHARTVERSION               Version to use for postgresql chart"
      echo "--github-id=GITHUBID                            Github repo ID"
      echo "--github-path=GITHUBPATH                        Github repo PATH"
      echo "--github-url=GITHUBURL                          Github repo URL"
      exit 0
      ;;
    --application-image-tag*)
      useApplicationVersionForImageTag=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --github-id*)
      githubId=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --github-path*)
      githubPath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --github-url*)
      githubUrl=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --app-value-path*)
      applicationValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --network-value-path*)
      networkValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --sidekiq-value-path*)
      sidekiqValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --cron-jobs-value-path*)
      cronJobsValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --pg-value-path*)
      pgValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --common-value-path*)
      commonValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --app-chart-version*)
      applicationChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --network-chart-version*)
      networkChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --sidekiq-chart-version*)
      sidekiqChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --cron-jobs-chart-version*)
      cronJobsChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --pg-chart-version*)
      pgChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --action*)
      action=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --version-deploy*)
      versionToDeploy=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --namespace*)
      namespace=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

##############################################################
####################### VARIABLE #############################
##############################################################

applicationName=$1
actualVersion="v0.0.0"
helmChartRepositoryName="cheerz-registry"
helmChartRepositoryAddress="http://charts.k8s.cheerz.net"
applicationChartName="web-application"
networkChartName="web-network"
sidekiqChartName="worker-application"
cronJobsChartName="cron-jobs"
pgChartName="postgresql"
imagePullPolicy="IfNotPresent"

##############################################################
########################## DEBUG #############################
##############################################################
# echo "applicationName => $applicationName"
# echo "versionToDeploy => $versionToDeploy"
# echo "namespace => $namespace"
# echo "action => $action"
# echo "useApplicationVersionForImageTag => $useApplicationVersionForImageTag"
# echo "applicationValuePath => $applicationValuePath"
# echo "networkValuePath => $networkValuePath"
# echo "applicationChartVersion => $applicationChartVersion"
# echo "networkChartVersion => $networkChartVersion"
# echo "githubId => $githubId"
# echo "githubPath => $githubPath"
# echo "githubUrl => $githubUrl"

# exit 0

##############################################################
####################### FUNCTIONS ############################
##############################################################

function get_running_version {
  local tempVersion=$(kubectl get cm $applicationName-cm -n $namespace -o template --template={{.data.runningVersion}})
  # strict semver check + v prefix https://regexr.com/39s32
  if [[ $tempVersion =~ ^v{1}.* ]] || [[ $tempVersion == "staging" ]]; then
    actualVersion=$tempVersion
  fi
}

##############################################################
################### Init and security ########################
##############################################################
get_running_version;
safeActualVersion=$(echo $actualVersion | sed 's/\./-/g')
safeVersionToDeploy=$(echo $versionToDeploy | sed 's/\./-/g')

# Security to avoid upgrading in production version
if [[ $actualVersion == $versionToDeploy ]] && [[ $action != "update" ]]; then
  echo "The version you try to deploy is already in production."
  echo "Please update version number."
  exit 1;
fi

##############################################################
####################### Helm init ############################
##############################################################

# update all helm repository
helm repo add $helmChartRepositoryName $helmChartRepositoryAddress
helm repo update

# convert latest version name in the last avaible version on repo
if [[ $applicationChartVersion == "latest" ]]; then
  applicationChartVersion=$(helm show chart $helmChartRepositoryName/$applicationChartName | grep "version:" | awk '{ print $2}')
  echo "Latest application chart version is $applicationChartVersion"
fi
if [[ $networkChartVersion == "latest" ]]; then
  networkChartVersion=$(helm show chart $helmChartRepositoryName/$networkChartName | grep "version:" | awk '{ print $2}')
  echo "Latest network chart version is $networkChartVersion"
fi
if [[ $sidekiqChartVersion == "latest" ]]; then
  sidekiqChartVersion=$(helm show chart $helmChartRepositoryName/$sidekiqChartName | grep "version:" | awk '{ print $2}')
  echo "Latest worker chart version is $sidekiqChartVersion"
fi
if [[ $cronJobsChartVersion == "latest" ]]; then
  cronJobsChartVersion=$(helm show chart $helmChartRepositoryName/$cronJobsChartName | grep "version:" | awk '{ print $2}')
  echo "Latest cron jobs chart version is $cronJobsChartVersion"
fi
if [[ $pgChartVersion == "latest" ]]; then
  pgChartVersion=$(helm show chart $helmChartRepositoryName/$pgChartName | grep "version:" | awk '{ print $2}')
  echo "Latest cron jobs chart version is $pgChartVersion"
fi

##############################################################
################# Application Deploy #########################
##############################################################

# force image pull policy in case of update but avoid it if no version installed 
if [[ $actualVersion != "v0.0.0" ]] && [[ $action == "update" ]]; then
  imagePullPolicy="Always"
fi

# if new version is not deployed yet, do it
if [[ $action != "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
  if [[ $useApplicationVersionForImageTag == false ]]; then
      helm upgrade --install \
      -f "$BASE_WORKING_PATH/$applicationValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
      --set application.version=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --version $applicationChartVersion \
      -n $namespace \
      ${applicationName}-$versionToDeploy \
      $helmChartRepositoryName/$applicationChartName 
  else
      helm upgrade --install \
      -f "$BASE_WORKING_PATH/$applicationValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
      --set application.version=$versionToDeploy \
      --set application.image.tag=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --version $applicationChartVersion \
      -n $namespace \
      ${applicationName}-$versionToDeploy \
      $helmChartRepositoryName/$applicationChartName  
  fi
  # Security to stop the process in case of faillure
  if [[ $? != 0 ]]; then
    echo "Fail to deploy application with code : $?"
    echo "Deploy canceled"
    exit 1;
  fi
fi
# force roll out to be sure to have the last version 
if [[ $actualVersion != "v0.0.0" ]] && [[ $action == "update" ]]; then
  kubectl rollout restart -n $namespace deployment.apps/${applicationName}-$safeVersionToDeploy-deploy
fi

##############################################################
################### Deploy auto scaler #######################
##############################################################

 # Auto scale new version to be ready for prod volume
if [[ $action == "complete" ]] && [[ $actualVersion != "v0.0.0" ]]; then
  # get replicas on running version
  actualVersionReplicas=$(kubectl get hpa -n $namespace ${applicationName}-$safeActualVersion-hpa -o template --template={{.status.currentReplicas}})
  # get new version min replicas
  VersionToDeployMinReplicas=$(kubectl get hpa -n $namespace ${applicationName}-$safeVersionToDeploy-hpa -o template --template={{.spec.minReplicas}})
  # check if valid int
  if [[ "$actualVersionReplicas" == "$actualVersionReplicas" ]] && [[ "$VersionToDeployMinReplicas" == "$VersionToDeployMinReplicas" ]] 2>/dev/null
  then
    #security to avoid going under new version min replicas
    if [[ $VersionToDeployMinReplicas > $actualVersionReplicas ]]; then
      actualVersionReplicas=$VersionToDeployMinReplicas
    fi
    kubectl scale deploy ${applicationName}-$safeVersionToDeploy-deploy -n $namespace --replicas=$actualVersionReplicas
  fi
fi

##############################################################
############### Network deploy and update ####################
##############################################################

# Deploy the network part
if [[ $namespace == "staging" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
  helm upgrade --install \
  -f "$BASE_WORKING_PATH/$networkValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
  --set deploy.complete=true \
  --set deploy.newVersion=$versionToDeploy \
  --set github.id=$githubId \
  --set github.path=$githubPath \
  --set github.url=$githubUrl \
  --version $networkChartVersion \
  -n $namespace \
  ${applicationName}-network \
  $helmChartRepositoryName/$networkChartName 
elif [[ $action == "cancel" ]]; then
  helm upgrade --install \
  -f "$BASE_WORKING_PATH/$networkValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
  --set deploy.complete=true  \
  --set github.id=$githubId \
  --set github.path=$githubPath \
  --set github.url=$githubUrl \
  --set deploy.newVersion=$actualVersion \
  ${applicationName}-network \
  -n $namespace \
  --version $networkChartVersion \
  $helmChartRepositoryName/$networkChartName 
else
  helm upgrade --install \
  -f "$BASE_WORKING_PATH/$networkValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
  --set deploy.complete=false \
  --set github.id=$githubId \
  --set github.path=$githubPath \
  --set github.url=$githubUrl \
  --set deploy.runningVersion=$actualVersion \
  --set deploy.newVersion=$versionToDeploy \
  --version $networkChartVersion \
  -n $namespace \
  ${applicationName}-network \
  $helmChartRepositoryName/$networkChartName 
fi
# Security to stop the process in case of faillure
if [[ $? != 0 ]]; then
  echo "Fail to deploy Network with code : $?"
  echo "Deploy canceled"
  exit 1;
fi

##############################################################
############### sidekiq deploy and update ####################
##############################################################

# Deploy the sidekiq part
if [[ $sidekiqValuePath != "" ]]; then
  echo "sidekiqValuePath not empty so we check if we deploy it"
  if [[ $action == "update" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    echo "It's a complete install or a new install, so we deploy sidekiq on version $versionToDeploy"
    if [[ $useApplicationVersionForImageTag == false ]]; then
    helm upgrade --install \
    -f "$BASE_WORKING_PATH/$sidekiqValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
    --set deploy.complete=true \
    --set application.version=$versionToDeploy \
    --set application.image.pullPolicy=$imagePullPolicy \
    --set github.id=$githubId \
    --set github.path=$githubPath \
    --set github.url=$githubUrl \
    --version $sidekiqChartVersion \
    -n $namespace \
    ${applicationName}-sidekiq \
    $helmChartRepositoryName/$sidekiqChartName 
    else
      helm upgrade --install \
      -f "$BASE_WORKING_PATH/$sidekiqValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
      --set deploy.complete=true \
      --set application.version=$versionToDeploy \
      --set application.image.tag=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --set github.id=$githubId \
      --set github.path=$githubPath \
      --set github.url=$githubUrl \
      --version $sidekiqChartVersion \
      -n $namespace \
      ${applicationName}-sidekiq \
      $helmChartRepositoryName/$sidekiqChartName 
    fi
    # Security to stop the process in case of faillure
    if [[ $? != 0 ]]; then
      echo "Fail to deploy sidekiq with code : $?"
      echo "Deploy canceled"
      exit 1;
    fi
    # force roll out to be sure to have the last version 
    if [[ $actualVersion != "v0.0.0" ]] && [[ $action == "update" ]]; then
      kubectl rollout restart -n $namespace deployment.apps/${applicationName}-sidekiq-$safeVersionToDeploy-deploy
    fi
    echo "sidekiq deployed successfully"
  else
    echo "It's not a complete deploy so we don't deploy sidekiq"
  fi
else
  echo "sidekiqValuePath empty so we ignore it"
fi

##############################################################
############### cronjobs deploy and update ###################
##############################################################

# Deploy the cronjob part
if [[ $cronJobsValuePath != "" ]]; then
  echo "CronJobsValuePath not empty so we check if we deploy it"
  if [[ $namespace == "staging" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    echo "It's a complete install or a new install, so we deploy cron jobs"
    helm upgrade --install \
    -f "$BASE_WORKING_PATH/$cronJobsValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
    --set deploy.complete=true \
    --set application.version=$versionToDeploy \
    --set github.id=$githubId \
    --set github.path=$githubPath \
    --set github.url=$githubUrl \
    --version $cronJobsChartVersion \
    -n $namespace \
    ${applicationName}-cron-jobs \
    $helmChartRepositoryName/$cronJobsChartName 
    # Security to stop the process in case of faillure
    if [[ $? != 0 ]]; then
      echo "Fail to deploy cron jobs with code : $?"
      echo "Deploy canceled"
      exit 1;
    fi
    echo "Cron jobs deployed successfully"
  else
    echo "It's not a complete deploy so we don't deploy cron jobs"
  fi
else
  echo "CronJobsValuePath empty so we ignore it"
fi

##############################################################
################## PostgreSQL Deploy #########################
##############################################################

# Deploy the Postgresql part
if [[ $pgValuePath != "" ]]; then
  echo "pgValuePath not empty so we check if we deploy it"
  if [[ $namespace == "staging" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    echo "It's a complete install or a new install, so we deploy postgresql"
    helm upgrade --install \
    -f "$BASE_WORKING_PATH/$pgValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
    --set application.version=$versionToDeploy \
    --version $pgChartVersion \
    -n $namespace \
    ${applicationName}-pg-$versionToDeploy \
    $helmChartRepositoryName/$pgChartName 
    # Security to stop the process in case of faillure
    if [[ $? != 0 ]]; then
      echo "Fail to deploy postgresql with code : $?"
      echo "Deploy canceled"
      exit 1;
    fi
    echo "postgresql deployed successfully"
  else
    echo "It's not a complete deploy so we don't deploy postgresql"
  fi
else
  echo "pgValuePath empty so we ignore it"
fi

##############################################################
##################### Deploy smoother ########################
##############################################################

# Soft old version cleaner
if [[ $actualVersion != "v0.0.0" ]] && [[ $actualVersion != $versionToDeploy ]]; then
  # delete old useless version
  if [[ $action == "complete" ]]; then
    # helm delete -n $namespace ${applicationName}-${actualVersion}
    # instead of deleting old application we set min replicas to 0 and will decrease progressivly
    helm upgrade \
    -f "$BASE_WORKING_PATH/$applicationValuePath$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo ,$BASE_WORKING_PATH/$commonValuePath; fi)" \
    --set application.version=$actualVersion \
    --set application.image.tag=$actualVersion \
    --set autoscaling.minReplicas=1 \
    --version $applicationChartVersion \
    -n $namespace \
    ${applicationName}-$actualVersion \
    $helmChartRepositoryName/$applicationChartName 
  elif [[ $action == "cancel" ]]; then
    helm delete -n $namespace ${applicationName}-${versionToDeploy}
  fi
fi

##############################################################
############ Clean and archive to keep env clean #############
##############################################################

# Hard archive version cleaner
if [[ $actualVersion != "v0.0.0" ]] && ( [[ $action == "complete" ]] || [[ $action == "cancel" ]] ); then
  listRelease=$(helm ls -n $namespace -q --filter $applicationName-v.*)
  for release in $listRelease
  do
    if [[ $release != ${applicationName}-${versionToDeploy} ]] && [[ $release != ${applicationName}-${actualVersion} ]]; then
      helm delete -n $namespace $release
    fi
  done
fi

# Delete useless empty RS 
kubectl -n $namespace delete rs $(kubectl get rs --no-headers -n $namespace -l "app.kubernetes.io/instance=${applicationName}-${versionToDeploy}" | awk '{if ($2 + $3 + $4 == 0) print $1}')


##############################################################
########################## OUPUT #############################
##############################################################

echo "::set-output name=new-version:$(echo $versionToDeploy)"
echo "::set-output name=actual-version:$(echo $actualVersion)"