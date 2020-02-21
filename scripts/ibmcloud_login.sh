#!/bin/bash
# set -x

if [ "$DEPLOY_TARGET" == "cf" ]; then
    ibmcloud login -a "cloud.ibm.com" --apikey "$API_KEY"
    ibmcloud target --cf -o "$PROD_ORG_NAME" -s "$PROD_SPACE_NAME"
# else
#     ibmcloud login -a "cloud.ibm.com" -r "$PROD_REGION_ID" --apikey "$API_KEY" -g "$PROD_RESOURCE_GROUP" 
fi

# if [ "$DEPLOY_TARGET" == "helm" ] || [ "$DEPLOY_TARGET" == "knative" ]; then
#     ibmcloud ks init
#     ibmcloud ks clusters
#     $(ibmcloud ks cluster config --cluster "$PROD_CLUSTER_NAME" --export)
# fi
