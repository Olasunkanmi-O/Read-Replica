
# vpc cidr block 
variable "vpc_cidr" {
    default="10.0.0.0/16"
    description = "this is the cidr block for the vpc"
}

# public subnet-1 cidr block
variable "pub_sub_01" {
    default = "10.0.1.0/24"  
} 

# public subnet-2 cidr block
variable "pub_sub_02" {
    default = "10.0.2.0/24"  
} 

# private subnet-1 cidr block
variable "priv_sub_01" {
    default = "10.0.3.0/24"  
} 

# private subnet-1 cidr block
variable "priv_sub_02" {
    default = "10.0.4.0/24"  
} 

# availability zone 1
variable "az1" {
    default = "us-east-1a"  
}

# availability zone 2
variable "az2" {
    default = "us-east-1b"  
}

# webserver ami
variable "ami" {
    default = "ami-04681163a08179f28" # amazon linux 2  
}

variable "instance_type" {
    default = "t2.micro" 
}

# database name
variable "db_name" {
  default = "wordpress_db"
}
# database username
variable "db_username" {
  default = "admin"
}
# database password
variable "db_password" {
  default = "Admin123"
}

variable "rds_endpoint" {
    description = "The endpoint of the RDS instance"
    type = string
    default = ""
}