# kubernetes-deploy-pilot

# reference
github-api-get.sh => https://gist.github.com/mbohun/b161521b2440b9f08b59


# Install 
helm install -f manifest/application-value.yml --set application.version=$(cat VERSION) hello-$(cat VERSION) cheerz-registry/web-application 
helm install -f manifest/network-value.yml --set deploy.complete=true  --set deploy.newVersion=$(cat VERSION) hello-network cheerz-registry/web-network 
visit : http://hello.k8s.cheerz.net

new version 
helm install -f manifest/application-value.yml --set application.version=$(cat VERSION) hello-$(cat VERSION) cheerz-registry/web-application 
helm upgrade -f manifest/network-value.yml --set deploy.complete=false --set deploy.runningVersion=v0.0.1 --set deploy.newVersion=$(cat VERSION) hello-network cheerz-registry/web-network 



# use
export BASE_WORKING_PATH="/home/jonathan/projects/ci-reference" && /bin/bash ./main.sh v0.0.3 hello production false