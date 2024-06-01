# URL Shortener

This repository contains the necessary AWS cloud resources needed to support the deployment of a simple URL shortener application on AWS Elastic Kubernetes Service

The `main.tf` file in the `terraform/infra` directory will set up the necessary VPC, RDS, Elasticache and EKS resources

The `main.tf` file in the `terraform/load-balancer-controller` directory will set up AWS Load Balancer Controller which will load balance requests to our AWS EKS cluster.