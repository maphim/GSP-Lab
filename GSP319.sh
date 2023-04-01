To replace the params with variables from a file, we can create a config file with the following structure:

```
PROJECT_ID=qwiklabs-gcp-01-045655086c11
MONOLITH_ID=fancy-monolith-707
CLUSTER_NAME=fancy-prod-152
ORDERS_ID=fancy-orders-475
PRODUCTS_ID=fancy-products-937
FRONTEND_ID=fancy-frontend-722
```

Then, we can modify the script to read the variables from this file:

```
#!/bin/bash

# Read variables from config file
source config.env

# Task 1: Download the monolith code and build your container
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

cd ~/monolith-to-microservices
./setup.sh

cd ~/monolith-to-microservices/monolith
npm start

gcloud services enable cloudbuild.googleapis.com
gcloud builds submit --tag gcr.io/${PROJECT_ID}/fancytest:1.0.0 .

# Task 2: Create a kubernetes cluster and deploy the application
gcloud config set compute/zone us-central1-a
gcloud services enable container.googleapis.com
gcloud container clusters create $CLUSTER_NAME --num-nodes 3

kubectl create deployment fancytest --image=gcr.io/${PROJECT_ID}/fancytest:1.0.0
kubectl expose deployment fancytest --type=LoadBalancer --port 80 --target-port 8080

# Task 3: Create a containerized version of your Microservices
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$ORDERS_ID:1.0.0 .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$PRODUCTS_ID:1.0.0 .

# Task 4: Deploy the new microservices
kubectl create deployment $ORDERS_ID --image=gcr.io/${PROJECT_ID}/$ORDERS_ID:1.0.0
kubectl expose deployment $ORDERS_ID --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PRODUCTS_ID --image=gcr.io/${PROJECT_ID}/$PRODUCTS_ID:1.0.0
kubectl expose deployment $PRODUCTS_ID --type=LoadBalancer --port 80 --target-port 8082

# Task 5: Configure the Frontend microservice
cd ~/monolith-to-microservices/react-app
nano .env

# Task 6: Create a containerized version of the Frontend microservice
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${PROJECT_ID}/$FRONTEND_ID:1.0.0 .

# Task 7: Deploy the Frontend microservice
kubectl create deployment $FRONTEND_ID --image=gcr.io/${PROJECT_ID}/$FRONTEND_ID:1.0.0

kubectl expose deployment $FRONTEND_ID --type=LoadBalancer --port 80 --target-port 8080
```

This way, we can easily modify the params by changing the values in the config file, without having to modify the script itself.