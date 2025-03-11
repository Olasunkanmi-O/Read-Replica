# AWS RDS Read Replica and Multi-AZ Setup for WordPress
This project demonstrates how to set up a highly available and scalable WordPress application using **Amazon RDS (Relational Database Service)** with **Multi-AZ and Read Replicas**.

## Key Concepts

### What is a Read Replica?
In AWS, a **Read Replica** is a read-only, asynchronous copy of an RDS database instance. It helps improve performance and scalability by offloading read operations from the primary database. Key features include:
- Purpose: Improves performance and scalability by handling read traffic.
- Failover: No automatic failover; manual promotion is required to make a replica the primary.
- Replication Type: Asynchronous (data is replicated with some lag).
- Best Use Case: Scaling read-heavy applications, reducing latency, and enabling disaster recovery and migrations.

### What is Multi-AZ?
Multi-AZ (Availability Zone) is an AWS RDS feature that provides high availability by automatically replicating your database to a standby instance in a different Availability Zone. In case of a primary instance failure, AWS automatically fails over to the standby instance.

## Project Workflow
1. Set up the infrastructure for a WordPress website connected to a MySQL database.
2. Enable Multi-AZ for high availability and simulate a failover scenario.
3. Create a Read Replica to offload read traffic from the primary database.
4. Promote the Read Replica to a standalone database for disaster recovery.


## Requirements
to complete this project, you will need:

- Terraform: you can download it [here](https://developer.hashicorp.com/terraform/downloads) 
- AWS Account: Access to the AWS Management Console or AWS CLI
- IAM Permissions: Ensure your IAM user has the following permissions:
    - `rds:CreateDBInstance`
    - `ec2:CreateSecurityGroup`
    - `ec2:CreateSubnet`
    - `rds:CreateDBSubnetGroup`
    - `rds:CreateDBInstanceReadReplica`
    - `rds:PromoteReadReplica`
- Environment Variables: Set the following variables in your terminal
    ```bash
    export TF_VAR_db_username="your_database_username"
    export TF_VAR_db_password="your_database_password"
    ```


## Infrastructure Setup
The infrastructure for this project includes:
 - A VPC with public and private subnets
 - An RDS MySQL instance for the WordPress database.
 - An EC2 instance to host the WordPress application.
 - Security Groups to control access to the EC2 and RDS instances.
 - A Read Replica of the RDS instance for scalability.
The application used is the wordpress website connected to MySQL database

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.86.0 |

### Modules

No modules.

### Resources

| Name | Type | Purpose |
|------|------|---------|
| [aws_db_instance.wordpress-db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource | Primary MySQL database for WordPress
| [aws_db_subnet_group.db_sub_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource | Subnet group for the RDS instance.
| [aws_instance.webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource | EC2 instance hosting the WordPress application.
| [aws_security_group.back_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource | Security group for the RDS instance.
| [aws_security_group.front_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource | Security group for the EC2 instance.
| [aws_db_instance.wordpress-db-rr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source | Read replica of the primary database.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | webserver ami | `string` | `"ami-04681163a08179f28"` | no |
| <a name="input_az1"></a> [az1](#input\_az1) | availability zone 1 | `string` | `"us-east-1a"` | no |
| <a name="input_az2"></a> [az2](#input\_az2) | availability zone 2 | `string` | `"us-east-1b"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | database name | `string` | `"wordpress_db"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | database password | `string` | **(Set via environment variable)** | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | database username | `string` | **(Set via environment variable)** | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"t2.micro"` | no |
| <a name="input_priv_sub_01"></a> [priv\_sub\_01](#input\_priv\_sub\_01) | private subnet-1 cidr block | `string` | `"10.0.3.0/24"` | no |
| <a name="input_priv_sub_02"></a> [priv\_sub\_02](#input\_priv\_sub\_02) | private subnet-1 cidr block | `string` | `"10.0.4.0/24"` | no |
| <a name="input_pub_sub_01"></a> [pub\_sub\_01](#input\_pub\_sub\_01) | public subnet-1 cidr block | `string` | `"10.0.1.0/24"` | no |
| <a name="input_pub_sub_02"></a> [pub\_sub\_02](#input\_pub\_sub\_02) | public subnet-2 cidr block | `string` | `"10.0.2.0/24"` | no |
| <a name="input_rds_endpoint"></a> [rds\_endpoint](#input\_rds\_endpoint) | The endpoint of the RDS instance | `string` | `""` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | this is the cidr block for the vpc | `string` | `"10.0.0.0/16"` | no |

## Step-by-Step Guide

###  Add Multi AZ to the Database
 - select the database and click modify
 ![](/img/02.modify.png)
 - under availability and durability section, select the option to create a standby instance
 ![](/img/03.create-standby.png)
 - click continue
 ![](/img/04.continue.png)
 - In the scheduling of modifications, select apply immediately and click modify DB instance
 ![](/img/05.apply-immediately.png)
 - To confirm the configuration took place, go to events and see under messages
 

### Simulating the Redundancy we have set up
 
 - select your db instance and under actions, select reboot
 ![](/img/06.reboot.png)
 - on the next screen, select reboot with failover so that our secondary db instance can take over when the instance fails then click confirm
 ![](/img/07.reboot-with-failover.png)
 - Refresh the website page to see if it is still running, check events for updates 
 ![](/img/08.events.png)

 ### Creating Read Replica
 - select the db instance, under actions, choose create read replica
  ![](/img/09.create-read-replica.png)
 - give a name to the replica
 ![](/img/10.replica-name.png)
 - We have decided to deploy to the same region although any region can be used
 ![](/img/11.select-region.png)
 - Scroll to the bottom and click create read replica
 ![](/img/13.click-create.png)
 - under the database dashboard, you should see successfully created
 ![](/img/14.working%20rr.png)
 - Refresh your site to see if it is active
 ![](/img/working-site.png)

 ### Promote the Read Replica
 - select the read replica, click on actions then select promote
 ![](/img/15.promote.png)
 - leave everything as default then click promote 
 ![](/img/16.click-promote.png)
 - the read replica instance will reboot, at this point, it has become independent
 ![](/img/17.rr-rebooting.png)
 - After rebooting, refresh your website to see if it is still active
 ![](/img/working-site2.png) 

## Conclusion
In this project, we successfully set up a highly available and scalable WordPress application using AWS RDS with Multi-AZ and Read Replicas. By enabling Multi-AZ, we ensured high availability and automatic failover in case of a primary database failure. Additionally, we created a read replica to offload read traffic from the primary database, improving performance and scalability for read-heavy workloads.

We also simulated a failover scenario by rebooting the primary database with a failover, demonstrating how the standby instance takes over seamlessly. Finally, we promoted the read replica to a standalone database, showcasing its independence and utility in disaster recovery scenarios.

This setup is ideal for applications requiring high availability, scalability, and disaster recovery capabilities