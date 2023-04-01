#!/bin/bash

# script.sh zone region

# Task 1: Set the default region and zone for all resources
gcloud config set compute/zone $1
gcloud config set compute/region $2

# Task 2: Create multiple web server instances
gcloud compute instances create www1 \
    --zone=$1 \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: www1</h3>" | tee /var/www/html/index.html'
      
gcloud compute instances create www2 \
    --zone=$1 \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: www2</h3>" | tee /var/www/html/index.html'
      
gcloud compute instances create www3 \
    --zone=$1 \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

# Task 3: Configure the load balancing service
gcloud compute addresses create network-lb-ip-1 \
    --region $2

gcloud compute http-health-checks create basic-check

gcloud compute target-pools create www-pool \
    --region $2 --http-health-check basic-check

gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3

gcloud compute forwarding-rules create www-rule \
    --region $2 \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool

# Task 4: Sending traffic to your instances
EXTERNAL_IP=$(gcloud compute forwarding-rules describe www-rule --region $2 --format="value(IPAddress)")

while true; do curl -m1 $EXTERNAL_IP; done
