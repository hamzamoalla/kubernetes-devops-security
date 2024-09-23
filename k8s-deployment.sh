#!/bin/bash

#k8s-deployment.sh

sed -i "s|image: hamzamoalla/my_repo:devsecops-.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|" k8s_deployment_service.yaml

# kubectl -n default get deployment ${deploymentName} > /dev/null

# if [[ $? -ne 0 ]]; then
#     echo "deployment ${deploymentName} doesnt exist"
#     kubectl -n default apply -f k8s_deployment_service.yaml
# else
#     echo "deployment ${deploymentName} exist"
#     echo "image name - ${imageName}"
#     kubectl -n default set image deploy ${deploymentName} ${containerName}=${imageName} --record=true
# fi


kubectl -n default apply -f k8s_deployment_service.yaml
