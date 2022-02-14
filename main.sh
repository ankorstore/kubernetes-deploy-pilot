#!/bin/bash
# set -x
# exemple usage : 
# ./main.sh \
# --application-image-tag="true" \
# --action="update" \
# --namespace="production" \
# --version-deploy="1.2.3" \
# --app-value-path="application/value.yml" \
# --network-value-path="network/value.yml" \
# --worker-value-path="worker/value.yml" \
# --app-chart-version="1.0.1" \
# --network-chart-version="1.0.0" \
# --worker-chart-version="1.0.0" \
# --github-id="zefz848ezfze8e" \
# --github-path="ankorstore/ankorstore" \
# --github-url="https://github.com/ankorstore/ankorstore" \
# fotom

##############################################################
####################### ARGUMENTS ############################
##############################################################

action="" # => --action
useApplicationVersionForImageTag="false" # => --application-image-tag
forceScaleNewVersion="false" # => --force-scale-new-version
scaleDownPreviousVersion="false" # => --scale-down-previous-version
applicationValuePath="" # => --app-value-path
networkValuePath="" # => --network-value-path
workerValuePath="" # => --worker-value-path
cronJobsValuePath="" # => --cron-jobs-value-path
commonValuePath="" # => --common-value-path
applicationChartVersion="" # => --app-chart-version
networkChartVersion="" # => --network-chart-version
workerChartVersion="" # => --worker-chart-version
cronJobsChartVersion="" # => --cron-jobs-chart-version
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
      echo "-h, --help                                         Show brief help"
      echo "--application-image-tag=true|false                 Use application version for docker image tag"
      echo "--force-scale-new-version=true|false               Force scale the new version to the actual prod size"
      echo "--scale-down-previous-version=true|false           Scale down the previous version to reduce ressources consumptions"
      echo "--action=create|complete|update|cancel             Specify an action to apply"
      echo "--version-deploy=VERSIONTODEPLOY                   Give the version to deploy"
      echo "--namespace=production|staging                     Target namespace"
      echo "--app-value-path=APPVALUEPATH                      Value file path for application"
      echo "--network-value-path=NETWORKVALUEPATH              Value file path for network"
      echo "--worker-value-path=>WORKERVALUEPATH               Value file path for worker"
      echo "--cron-jobs-value-path=>CRONJOBSVALUEPATH          Value file path for cron jobs"
      echo "--postgresql-value-path=>POSTGRESQLVALUEPATH       Value file path for postgresql"
      echo "--common-value-path=>COMMONVALUEPATH               Common value file path"
      echo "--app-chart-version=APPCHARTVERSION                Version to use for application chart"
      echo "--network-chart-version=NETWORKCHARTVERSION        Version to use for network chart"
      echo "--worker-chart-version=WORKERCHARTVERSION          Version to use for worker chart"
      echo "--cron-jobs-chart-version=CRONJOBSCHARTVERSION     Version to use for cron jobs chart"
      echo "--github-id=GITHUBID                               Github repo ID"
      echo "--github-path=GITHUBPATH                           Github repo PATH"
      echo "--github-url=GITHUBURL                             Github repo URL"
      exit 0
      ;;
    --application-image-tag*)
      useApplicationVersionForImageTag=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --force-scale-new-version*)
      forceScaleNewVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --scale-down-previous-version*)
      scaleDownPreviousVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
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
    --worker-value-path*)
      workerValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --cron-jobs-value-path*)
      cronJobsValuePath=`echo $1 | sed -e 's/^[^=]*=//g'`
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
    --worker-chart-version*)
      workerChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --cron-jobs-chart-version*)
      cronJobsChartVersion=`echo $1 | sed -e 's/^[^=]*=//g'`
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
helmChartRepositoryName="ankorstore-registry"
helmChartRepositoryAddress="https://charts.tools.ankorstore.io/"
applicationChartName="web-application"
networkChartName="web-network"
workerChartName="worker-application"
cronJobsChartName="cron-jobs"
imagePullPolicy="IfNotPresent"
defaultNewVersionReplicas=2

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
  if [[ $tempVersion =~ ^staging-v{1}.* ]] || [[ $tempVersion =~ ^v{1}.* ]] || [[ $tempVersion == "staging" ]]; then
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
if [[ $workerChartVersion == "latest" ]]; then
  workerChartVersion=$(helm show chart $helmChartRepositoryName/$workerChartName | grep "version:" | awk '{ print $2}')
  echo "Latest worker chart version is $workerChartVersion"
fi
if [[ $cronJobsChartVersion == "latest" ]]; then
  cronJobsChartVersion=$(helm show chart $helmChartRepositoryName/$cronJobsChartName | grep "version:" | awk '{ print $2}')
  echo "Latest cron jobs chart version is $cronJobsChartVersion"
fi

##############################################################
################# Application Deploy #########################
##############################################################

# force image pull policy in case of update but avoid it if no version installed 
if [[ $actualVersion != "v0.0.0" ]] && [[ $action == "update" ]]; then
  imagePullPolicy="Always"
fi
if [[ $applicationValuePath != "" ]]; then
  # if new version is not deployed yet, do it
  if [[ $useApplicationVersionForImageTag == false ]]; then
      helm upgrade --install \
      -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$applicationValuePath" \
      --set application.version=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --version $applicationChartVersion \
      -n $namespace \
      ${applicationName}-$versionToDeploy \
      $helmChartRepositoryName/$applicationChartName 
  else
      helm upgrade --install \
      -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$applicationValuePath" \
      --set application.version=$versionToDeploy \
      --set application.image.tag=$versionToDeploy \
      --set sidecar.image.tag=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --version $applicationChartVersion \
      -n $namespace \
      ${applicationName}-$versionToDeploy \
      $helmChartRepositoryName/$applicationChartName  
  fi
  # Security to stop the process in case of faillure
  if [[ $? -ne 0 ]]; then
    echo "Fail to deploy application with code : $?"
    echo "Deploy canceled"
    exit 1;
  else
    if [[ $forceScaleNewVersion == true ]] && [[ $actualVersion != "v0.0.0" ]]; then
      echo "Force scale new version to same pod number as running version"
      actualVersionReplicas=$(kubectl get hpa -n $namespace ${applicationName}-$safeActualVersion-hpa -o template --template={{.status.currentReplicas}})
      defaultNewVersionReplicas=$(kubectl get hpa -n $namespace ${applicationName}-$safeVersionToDeploy-hpa -o template --template={{.spec.minReplicas}})
      echo "Running version pod number: $actualVersionReplicas"
      echo "Default number of pod of the new version: $defaultNewVersionReplicas"
      #security to avoid going under new version min replicas
      if [[ $VersionToDeployMinReplicas > $actualVersionReplicas ]]; then
          echo "Security trigger, the running version pod number is under new version minimum"
          echo "For safety we keep minimum pod number of the new version as reference"
          actualVersionReplicas=$VersionToDeployMinReplicas
      fi
      kubectl patch -n $namespace hpa ${applicationName}-$safeVersionToDeploy-hpa -p "{\"spec\":{\"minReplicas\":$actualVersionReplicas}}"
      while true; do
          echo "Check for application to be ready";
          nbReady=$(kubectl get -n $namespace deployment.apps/${applicationName}-$safeVersionToDeploy-deploy -o template --template={{.status.readyReplicas}})
          echo "nbReady = $nbReady"
          echo "nbDesired = $actualVersionReplicas"
          if [[ $nbReady != "<no value>" ]];then
            if [[ $nbReady -ge $actualVersionReplicas ]]; then
              echo "New version properly scaled, lets continue deployment"
              break;
            fi
          fi
          sleep 5;
      done
    else
        # wait for ready
        while true; do
            echo "Check for application to be ready";
            nbReady=$(kubectl get -n $namespace deployment.apps/${applicationName}-$safeVersionToDeploy-deploy -o template --template={{.status.readyReplicas}})
            echo "nbReady = $nbReady"
            if [[ $nbReady != "<no value>" ]] && [[ $nbReady -ge 1 ]] ; then
                break;
            fi
            sleep 5;
        done
    fi
  fi

  # force roll out to be sure to have the last version 
  if [[ $actualVersion != "v0.0.0" ]] && [[ $action == "update" ]]; then
    kubectl rollout restart -n $namespace deployment.apps/${applicationName}-$safeVersionToDeploy-deploy
  fi
fi
##############################################################
############### Network deploy and update ####################
##############################################################
if [[ $networkValuePath != "" ]]; then
  # Deploy the network part
  if [[ $namespace == "staging" ]] || [[ $action == "complete" ]]; then
    helm upgrade --install \
    -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$networkValuePath" \
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
    -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$networkValuePath" \
    --set deploy.complete=true  \
    --set github.id=$githubId \
    --set github.path=$githubPath \
    --set github.url=$githubUrl \
    --set deploy.newVersion=$actualVersion \
    ${applicationName}-network \
    -n $namespace \
    --version $networkChartVersion \
    $helmChartRepositoryName/$networkChartName 
  elif [[ $actualVersion == "v0.0.0" ]]; then
    helm upgrade --install \
    -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$networkValuePath" \
    --set deploy.complete=true \
    --set deploy.runningVersion=$actualVersion \
    --set deploy.newVersion=$versionToDeploy \
    --set github.id=$githubId \
    --set github.path=$githubPath \
    --set github.url=$githubUrl \
    --version $networkChartVersion \
    -n $namespace \
    ${applicationName}-network \
    $helmChartRepositoryName/$networkChartName 
  else
    helm upgrade --install \
    -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$networkValuePath" \
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
  if [[ $? -ne 0 ]]; then
    echo "Fail to deploy Network with code : $?"
    echo "Deploy canceled"
    exit 1;
  fi
  if [[ $forceScaleNewVersion == true ]] && [[ $actualVersion != "v0.0.0" ]]; then
    sleep 5
    echo "Scale down new version min replicas to default value: $defaultNewVersionReplicas"
    kubectl -n $namespace patch hpa ${applicationName}-${safeVersionToDeploy}-hpa -p "{\"spec\":{\"minReplicas\":$defaultNewVersionReplicas}}"
  fi
  if [[ $scaleDownPreviousVersion == true ]] && [[ $actualVersion != "v0.0.0" ]]; then
    sleep 5
    echo "Scale down running version min replicas 1"
    kubectl -n $namespace patch hpa ${applicationName}-${safeActualVersion}-hpa -p "{\"spec\":{\"minReplicas\":1}}"
  fi
fi

##############################################################
############### worker deploy and update ####################
##############################################################

# Deploy the worker part
if [[ $workerValuePath != "" ]]; then
  echo "workerValuePath not empty so we check if we deploy it"
  if [[ $action == "update" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    echo "It's a complete install or a new install, so we deploy worker on version $versionToDeploy"
    if [[ $useApplicationVersionForImageTag == false ]]; then
    helm upgrade --install \
    -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$workerValuePath" \
    --set deploy.complete=true \
    --set application.version=$versionToDeploy \
    --set application.image.pullPolicy=$imagePullPolicy \
    --set github.id=$githubId \
    --set github.path=$githubPath \
    --set github.url=$githubUrl \
    --version $workerChartVersion \
    -n $namespace \
    ${applicationName}-worker \
    $helmChartRepositoryName/$workerChartName 
    else
      helm upgrade --install \
      -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$workerValuePath" \
      --set deploy.complete=true \
      --set application.version=$versionToDeploy \
      --set application.image.tag=$versionToDeploy \
      --set application.image.pullPolicy=$imagePullPolicy \
      --set github.id=$githubId \
      --set github.path=$githubPath \
      --set github.url=$githubUrl \
      --version $workerChartVersion \
      -n $namespace \
      ${applicationName}-worker \
      $helmChartRepositoryName/$workerChartName 
    fi
    # Security to stop the process in case of faillure
    if [[ $? -ne 0 ]]; then
      echo "Fail to deploy worker with code : $?"
      echo "Deploy canceled"
      exit 1;
    fi
    # force roll out to be sure to have the last version 
    if [[ $action == "update" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]] ; then
      kubectl rollout restart -n $namespace deployment.apps/${applicationName}-worker-$safeVersionToDeploy-deploy
    fi
    echo "worker deployed successfully"
  else
    echo "It's not a complete deploy so we don't deploy worker"
  fi
else
  echo "workerValuePath empty so we ignore it"
fi

##############################################################
############### cronjobs deploy and update ###################
##############################################################

# Deploy the cronjob part
if [[ $cronJobsValuePath != "" ]]; then
  echo "CronJobsValuePath not empty so we check if we deploy it"
  if [[ $action == "update" ]] || [[ $action == "complete" ]] || [[ $actualVersion == "v0.0.0" ]]; then
    echo "It's a complete install or a new install, so we deploy cron jobs"
    if [[ $useApplicationVersionForImageTag == false ]]; then
        helm upgrade --install \
        -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$cronJobsValuePath" \
        --set deploy.complete=true \
        --set application.version=$versionToDeploy \
        --set github.id=$githubId \
        --set github.path=$githubPath \
        --set github.url=$githubUrl \
        --version $cronJobsChartVersion \
        -n $namespace \
        ${applicationName}-cron-jobs \
        $helmChartRepositoryName/$cronJobsChartName 
    else
        helm upgrade --install \
        -f "$(if [ -f $BASE_WORKING_PATH/$commonValuePath ]; then echo $BASE_WORKING_PATH/$commonValuePath,; fi)$BASE_WORKING_PATH/$cronJobsValuePath" \
        --set deploy.complete=true \
        --set application.version=$versionToDeploy \
        --set application.image.tag=$versionToDeploy \
        --set github.id=$githubId \
        --set github.path=$githubPath \
        --set github.url=$githubUrl \
        --version $cronJobsChartVersion \
        -n $namespace \
        ${applicationName}-cron-jobs \
        $helmChartRepositoryName/$cronJobsChartName 
    fi
    # Security to stop the process in case of faillure
    if [[ $? -ne 0 ]]; then
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
############ Clean and archive to keep env clean #############
##############################################################
# Hard archive version cleaner
if [[ $actualVersion != "v0.0.0" ]]; then
  staging_regex="^$applicationName-(staging|$namespace)-v([0-9]*)\.([0-9]*)"
  listRelease=$(helm ls -n $namespace -q --filter $applicationName-)
  echo "Release to delete : $listRelease"
  echo "check compare: ${applicationName}-${versionToDeploy}"
  echo ""
  for release in $listRelease
  do
    echo "Check on $release"
    if [[ $action == "complete" ]]; then
      echo "Action complete"
      if [[ $versionToDeploy =~ $staging_regex ]]; then
        echo "compare toDeployRunNb=$toDeployRunNb, toDeployTryNb=$toDeployTryNb"
        toDeployRunNb=${BASH_REMATCH[2]}
        toDeployTryNb=${BASH_REMATCH[3]}
        if [[ $actualVersion =~ $staging_regex ]]; then
          echo "with actualRunNb=$actualRunNb, actualTryNb=$actualTryNb"
          actualRunNb=${BASH_REMATCH[2]}
          actualTryNb=${BASH_REMATCH[3]}
          if [[ $toDeployRunNb > $actualRunNb ]] || ( [[ $toDeployRunNb == $actualRunNb ]] && ( [[ $toDeployTryNb > $actualTryNb ]] || [[ $toDeployTryNb == $actualTryNb ]] ) ); then
            echo "first condition OK";
            if [[ $release != ${applicationName}-${versionToDeploy} ]] && [[ $release != ${applicationName}-${actualVersion} ]] && [[ $release != ${applicationName}-network ]] && [[ $release != ${applicationName}-cron-jobs ]]; then
              echo "Delete $release"
              helm delete -n $namespace $release
            fi
          fi
        fi
      else 
        echo "Release do not seem to be staging deploy"
        echo "We skip anti regression test"
        if [[ $release != ${applicationName}-${versionToDeploy} ]] && [[ $release != ${applicationName}-${actualVersion} ]] && [[ $release != ${applicationName}-network ]] && [[ $release != ${applicationName}-cron-jobs ]]; then
          echo "Delete $release"
          helm delete -n $namespace $release
        fi
      fi
    elif [[ $action == "cancel" ]]; then
      echo "Action cancel"
      if [[ $release != ${applicationName}-${versionToDeploy} ]] && [[ $release != ${applicationName}-${actualVersion} ]] && [[ $release != ${applicationName}-network ]] && [[ $release != ${applicationName}-cron-jobs ]]; then
        helm delete -n $namespace $release
        echo "Delete $release"
      fi
    else 
      echo "Unknown Action $action"
    fi
  done
fi

# Delete useless empty RS 
kubectl -n $namespace delete rs $(kubectl get rs --no-headers -n $namespace -l "app.kubernetes.io/name=${applicationName}" | awk '{if ($2 + $3 + $4 == 0) print $1}')


##############################################################
########################## OUPUT #############################
##############################################################

echo "::set-output name=new-version:$(echo $versionToDeploy)"
echo "::set-output name=actual-version:$(echo $actualVersion)"