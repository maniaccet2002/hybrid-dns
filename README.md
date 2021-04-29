# HYBRID DNS ARCHITECTURE
# Overview
This project provides terraform automation scripts to deploy Hybrid DNS between AWS and On premises infrastructure using Route53 Inbound and Outbound resolver endpoints. 
To demonstrate the usage of Hybrid DNS configuration, a sample wordpress application is deployed on the On premises side which connects to an RDS database on the AWS side using inbound endpoints and Route 53 DNS record. Also a wordpress application is deployed on the AWS side which connects to its database residing on the On premises side using Outbound endpoints and Route53 resolver rules

Note:
For simplicity purpose, the on premises infrastructure is also deployed on AWS on a separate VPC. VPC peering connection is used to establish the network connectivity between AWS VPC and the simulated On premises infrastrucutre

## Route53 Resolver Inbound endpoint
Any VPC created within AWS receives automatic DNS resolution from the Route53 resolver. Amazan EC2 instances can send DNS queries to R53 resolver which uses the reserved IP address of VPC CIDR IP + 2. If you establish network connectivity between AWS and On premises datacenter using VPN or direct connect, the DNS servers on the on premises side can send the DNS queries to R53 resolver.But R53 resolver will not accept DNS queries from IP addresses outside the VPC network range. To resolver this, you can create Inbound endpoints. DNS serves on the On premises data center can forward the DNS queries to inbound endpoints which then forwards those queries to R53 resolver. 

## Route53 Resolver Outbound endpoint
When you have network connectivity established between AWS and On premises datacenter using VPN or direct connect, DNS queries can be sent to the On premises DNS server by configuring Outbound endpoints and resolver rules. When R53 resolver receives the DNS query request from an EC2 instance, it checks the resolver rules to select the outbound endpoint and forwards the request. Outbound endpoint in turn forwards the DNS queries to the On premises DNS servers

# Hybrid DNS Architecture

https://github.com/maniaccet2002/hybrid-dns/blob/master/Hybrid%20DNS%20architecture.png


# Prerequisites
•	Have an AWS Account and have your default credentials and region configured
•	Have terraform installed
•	Create a SSH key pair in your AWS default region. 
•	Check variables.tf to modify the default values for the terraform variables


# How to deploy the terraform stack
•	Download the terraform code from the github repo
•	cd hydrid-dns
•	terraform init
•	terraform validate
•	terraform apply --auto-approve


You will be prompted to enter the SSH key pair

# How to destroy the terraform stack
•	cd hybrid-dns
•	terraform destroy --auto-approve


# Caution
While most of the resources created by this terraform stack comes under the AWS freee tier, there are few resources like NAT Gateway, VPC endpoints and Route53 endpoints which incurs charges

# Testing 
As mentioned in the overview section, a sample wordpress application is deployed on the On premises side connecting to its database on the AWS side and vice versa. Since all these EC2 instances are in a private subnet, the wordpress application cannot be accessed from the public internet. As part of this terraform automation script, a windows EC2 instance is deployed both on a public subnet. You can connect to these windows instances and use the Internet explorer inside these windows instances to check the wordpress application using URLs "wordpress.aws.mycompany.com"(AWS) and "wordpress.onprem.mycompany.com"(On prem)

