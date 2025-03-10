# create the vpc block
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# create public subnet 1
resource "aws_subnet" "pub_sub_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pub_sub_01
  availability_zone = var.az1

  tags = {
    Name = "pub_sub_01"
  }
}

# create public subnet 2
resource "aws_subnet" "pub_sub_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pub_sub_02
  availability_zone = var.az2

  tags = {
    Name = "pub_sub_01"
  }
}

# create private subnet 1
resource "aws_subnet" "priv_sub_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.priv_sub_01
  availability_zone = var.az1

  tags = {
    Name = "priv_sub_01"
  }
}

# create private subnet 2
resource "aws_subnet" "priv_sub_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.priv_sub_02
  availability_zone = var.az2

  tags = {
    Name = "priv_sub_02"
  }
}

# create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

# elastic ip
resource "aws_eip" "eip" {
  domain   = "vpc"
}

# create nat-gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub_sub_01.id

  tags = {
    Name = "nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# create public route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# create private route table
resource "aws_route_table" "priv_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
}

# public route table association 1
resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.pub_sub_01.id
  route_table_id = aws_route_table.pub_rt.id
}

# public route table association 2
resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.pub_sub_02.id
  route_table_id = aws_route_table.pub_rt.id
}

# private route table association 1 
resource "aws_route_table_association" "priv_1" {
  subnet_id      = aws_subnet.priv_sub_01.id
  route_table_id = aws_route_table.priv_rt.id
}

# private route table association 1 
resource "aws_route_table_association" "priv_2" {
  subnet_id      = aws_subnet.priv_sub_02.id
  route_table_id = aws_route_table.priv_rt.id
}

#key pair generation
resource "aws_key_pair" "deployer" {
  key_name   = "test"
  public_key = file("./test.pub")
}

# front end security group
resource "aws_security_group" "front_sg" {
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "allow ssh"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow http"
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow https"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

# backend security group
resource "aws_security_group" "back_sg" {
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "allow mysql"
    protocol = "tcp"
    from_port = 3306
    to_port = 3306
    security_groups = [ aws_security_group.front_sg.id ]
    
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_instance" "webserver" {
  ami=var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id = aws_subnet.pub_sub_01.id
  key_name = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.front_sg.id]
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y 
  sudo yum upgrade -y
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo yum install unzip -y
  unzip awscliv2.zip 
  sudo ./aws/install
  sudo amazon-linux-extras enable php8.2
  sudo yum clean metadata
  sudo yum install httpd php php-mysqlnd -y
  sudo yum install wget -y
  wget https://wordpress.org/wordpress-6.1.1.tar.gz
  tar -xzf wordpress-6.1.1.tar.gz 
  cp -r wordpress/* /var/www/html
  rm -rf wordpress
  rm -rf wordpress-6.1.1.tar.gz
  chmod -R 755 wp-content
  chown -R apache:apache wp-content
  cd /var/www/html && mv wp-config-sample.php wp-config.php
  sed -i "s@define( 'DB_NAME', 'database_name_here' )@define( 'DB_NAME', '${var.db_name}' )@g" /var/www/html/wp-config.php
  sed -i "s@define( 'DB_USER', 'username_here' )@define( 'DB_USER', '${var.db_username}' )@g" /var/www/html/wp-config.php
  sed -i "s@define( 'DB_PASSWORD', 'password_here' )@define( 'DB_PASSWORD', '${var.db_password}' )@g" /var/www/html/wp-config.php
  sed -i "s@define( 'DB_HOST', 'localhost' )@define( 'DB_HOST', '${element(split(":", local.rds_endpoint), 0)}')@g" /var/www/html/wp-config.php
  sudo systemctl enable httpd
  sudo systemctl start httpd
  sudo setenforce 0
  sudo hostnamectl hostname webserver
  EOF

}



# mysql wordpress database instance 
resource "aws_db_instance" "wordpress-db" {
  allocated_storage       = 10
  db_name                 = var.db_name
  engine                  = "mysql"
  engine_version          = "8.0"
  backup_retention_period = 7
  instance_class          = "db.t3.micro"
  identifier              = "wordpress-db"
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.db_sub_group.id
  vpc_security_group_ids  = [aws_security_group.back_sg.id]

}

data "aws_db_instance" "wordpress-db-rr" {
  db_instance_identifier = "wordpress-db-rr"

  depends_on = [ aws_db_instance.wordpress-db ]
}

locals {
  rds_endpoint = data.aws_db_instance.wordpress-db-rr.endpoint
}



# create database subnet group
resource "aws_db_subnet_group" "db_sub_group" {
  name       = "db_sub_group"
  subnet_ids = [aws_subnet.priv_sub_01.id, aws_subnet.priv_sub_02.id]
 
}