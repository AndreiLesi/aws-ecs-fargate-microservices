# Microservices with AWS ECS and Fargate

## Overview
This project demonstrates a microservices architecture deployed on AWS ECS with Fargate. The services include:
- User Service: Manages users.
- Product Service: Manages products.
- Order Service: Processes orders.
- PostgreSQL Database: Stores user and product data.
- Cloud Map: Provides service discovery.
- Load Balancer: Distributes incoming traffic.

## Project Structure
- `service-users`: Flask app for user management.
- `service-products`: Flask app for product management.
- `service-orders`: Flask app for order processing.
- `service-db`: SQL scripts for database initialization and PostgresDB Database.
- `terraform`: Infrastructure as code using Terraform.


## Build Containers
```bash
docker build -t service-db ./service-db
docker build -t service-users ./service-users
docker build -t service-products ./service-products
docker build -t service-orders ./service-orders
```

## Test locally
```bash
docker run -d -p 5432:5432 --name service-db service-db
docker run -d -p 80:80 -d --name service-userss service-users
docker run -d -p 81:80 --name service-products service-products
docker run -d -p 82:80 --name service-orders service-orders
````

Add a User
```bash
curl -X POST http://localhost/users -H "Content-Type: application/json" -d '{"name": "John Doe", "password": "password123"}'
```

Add a Product
```bash
`curl -X POST http://localhost:81/products -H "Content-Type: application/json" -d '{"name": "Product1", "price": 10.99}'`
```

Add a Order
```bash
`curl -X POST http://localhost:82/orders -H "Content-Type: application/json" -d '{"user_id": 1, "product_id": 1, "quantity": 2}'`
````

Check If data is in database
```bash
curl http://localhost:80/users
curl http://localhost:81/products
curl http://localhost:82/orders
```
or open each page in your browser tab



## Upload Images to AWS ECR 
Login
```bash
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 975050378797.dkr.ecr.eu-central-1.amazonaws.com
```
**Create ECR Repositories:**
```bash
aws ecr create-repository --repository-name service-users
aws ecr create-repository --repository-name service-products
aws ecr create-repository --repository-name service-orders
aws ecr create-repository --repository-name service-db
````

**Upload Containers to ECR:**
service-db docker image:
```bash
docker tag service-db:latest 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-db:latest
docker push 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-db:latest
````

service-users docker image:
```bash
docker tag service-users:latest 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-users:latest
docker push 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-users:latest
```

service-products docker image:
```bash
docker tag service-products:latest 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-products:latest
docker push 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-products:latest
````

service-orders docker image:
```bash
docker tag service-orders:latest 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-orders:latest
docker push 975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-orders:latest
```

## Deploy Services using ECS
**Deploy Core infrastructure (VPC) and ECS Cluster**
```bash
cd terraform/core-infra
terraform init
terraform plan
terraform apply
````

**Deploy ECS Services with CloudMap and the Loadbalancer**
```bash
cd ../services/
```

change the `image` value in service-db.tf, service-orders.tf, service-products.tf and service-users.tf to your own URL

```bash
terraform init
terraform plan
terraform apply
```

### Test Services in the Cloud
**Note:** Use your loadbalancer URL!

Add a User
```bash
curl -X POST http://microservices-1901241888.eu-central-1.elb.amazonaws.com/users -H "Content-Type: application/json" -d '{"name": "John Doe", "password": "password123"}'
```

Add a Product
```bash
curl -X POST http://microservices-1901241888.eu-central-1.elb.amazonaws.com/products -H "Content-Type: application/json" -d '{"name": "Product1", "price": 10.99}'
```

Add a Order
```bash
curl -X POST http://microservices-1901241888.eu-central-1.elb.amazonaws.com/orders -H "Content-Type: application/json" -d '{"user_id": 1, "product_id": 1, "quantity": 2}'
```
visit
http://microservices-1901241888.eu-central-1.elb.amazonaws.com/users
http://microservices-1901241888.eu-central-1.elb.amazonaws.com/products
http://microservices-1901241888.eu-central-1.elb.amazonaws.com/orders

to validate your entries.