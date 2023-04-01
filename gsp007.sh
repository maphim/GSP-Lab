#!/bin/bash

# GSP007.sh zone region

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

i=0
while [ $i -lt 10 ]
do
  curl -m1 $EXTERNAL_IP
  i=$((i+1))
done

# Task 5: Stop task 4

# Create the load balancer template
gcloud compute instance-templates create lb-backend-template \
   --region=us-east4 \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'

# Create the managed instance group based on the template
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=us-east4-c 

# Create the fw-allow-health-check firewall rule
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Create the global static external IP address
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

# Note the IPv4 address that was reserved
echo "IPv4 Address:"
gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global

# Create the health check for the load balancer
gcloud compute health-checks create http http-basic-check \
  --port 80

# Create the backend service
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# Add the instance group as the backend to the backend service
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=us-east4-c \
  --global

# Create the URL map to route incoming requests
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

# Create the target HTTP proxy to route requests to the URL map
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

# Create the global forwarding rule to route incoming requests to the proxy
gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1\
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80

