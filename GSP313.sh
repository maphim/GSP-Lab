#!/bin/bash

# Task 1. Create a project jumphost instance

# Set the default values for the instance
INSTANCE_NAME="nucleus-jumphost-985"
MACHINE_TYPE="f1-micro"
IMAGE_FAMILY="debian-10"
ZONE="us-central1-a"

# Create the instance
gcloud compute instances create $INSTANCE_NAME \
--machine-type=$MACHINE_TYPE \
--image-family=$IMAGE_FAMILY \
--image-project=debian-cloud \
--zone=$ZONE


# Task 2. Create a Kubernetes service cluster

# Set the default values for the cluster
CLUSTER_NAME="my-cluster"
ZONE="us-west3-b"

# Create the cluster
gcloud container clusters create $CLUSTER_NAME \
--zone=$ZONE

# Deploy the hello-app container
kubectl create deployment hello-app \
--image=gcr.io/google-samples/hello-app:2.0

# Expose the app on port 8082
kubectl expose deployment hello-app \
--type=LoadBalancer \
--port=8082 \
--target-port=8080


# Task 3. Set up an HTTP load balancer

# Set the default values for the load balancer
INSTANCE_TEMPLATE_NAME="my-instance-template"
INSTANCE_GROUP_NAME="my-instance-group"
TARGET_POOL_NAME="my-target-pool"
FIREWALL_RULE_NAME="permit-tcp-rule-785"
HEALTH_CHECK_NAME="my-health-check"
BACKEND_SERVICE_NAME="my-backend-service"
URL_MAP_NAME="my-url-map"
FORWARDING_RULE_NAME="my-forwarding-rule"
ZONE="us-central1-a"
REGION="us-central1"

# Create an instance template
gcloud compute instance-templates create $INSTANCE_TEMPLATE_NAME \
--metadata-from-file startup-script=startup.sh \
--image-family=debian-10 \
--image-project=debian-cloud \
--tags=http-server \
--machine-type=n1-standard-1 \
--zone=$ZONE

# Create a target pool
gcloud compute target-pools create $TARGET_POOL_NAME \
--region=$REGION

# Create a managed instance group
gcloud compute instance-groups managed create $INSTANCE_GROUP_NAME \
--base-instance-name=$INSTANCE_GROUP_NAME \
--size=2 \
--template=$INSTANCE_TEMPLATE_NAME \
--target-pool=$TARGET_POOL_NAME \
--zone=$ZONE

# Create a firewall rule
gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
--allow=tcp:80 \
--target-tags=http-server \
--description="Allow HTTP traffic on port 80" \
--direction=INGRESS

# Create a health check
gcloud compute health-checks create http $HEALTH_CHECK_NAME \
--check-interval=30s \
--timeout=10s \
--unhealthy-threshold=3 \
--healthy-threshold=2 \
--port=80 \
--request-path=/ \
--region=$REGION

# Create a backend service
gcloud compute backend-services create $BACKEND_SERVICE_NAME \
--protocol=HTTP \
--health-checks=$HEALTH_CHECK_NAME \
--port-name=http \
--timeout=10s \
--region=$REGION \
--enable-cdn

# Attach the managed instance group to the backend service
gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
--instance-group=$INSTANCE_GROUP_NAME \
--instance-group-zone=$ZONE \
--region=$REGION

# Create a URL map
gcloud compute url-maps create $URL_MAP_NAME \
--default-service=$BACKEND_SERVICE_NAME

# Create a target HTTP proxy
gcloud compute target-http-proxies create $FORWARDING_RULE_NAME \
--url-map=$URL_MAP_NAME

# Create a forwarding rule
gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
--global \
--target-http-proxy=$FORWARDING_RULE_NAME \
--port-range=80