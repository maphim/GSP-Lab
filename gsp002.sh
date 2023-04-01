#!/bin/bash

# GSP002.sh zone region

# Set the region to us-central1
gcloud config set compute/region $2

# Set the zone to us-central1-a
gcloud config set compute/zone $1

# Get the project ID and store it in an environment variable
export PROJECT_ID=$(gcloud config get-value project)

# Get the zone and store it in an environment variable
export ZONE=$(gcloud config get-value compute/zone)

# Print the project ID and zone
echo -e "PROJECT ID: $PROJECT_ID\nZONE: $ZONE"

# Create a VM instance
gcloud compute instances create gcelab2 --machine-type e2-medium --zone $ZONE
