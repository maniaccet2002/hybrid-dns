locals {
   cidr_list = [for cidr_block in cidrsubnets(var.aws_vpc_cidr,2,2,2,2) : cidrsubnets(cidr_block,2,2) ]
 }

 #VPC
resource "aws_vpc" "awsvpc" {
  cidr_block       = var.aws_vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  assign_generated_ipv6_cidr_block = "true"

  tags = {
    Name = "aws-vpc"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.awsvpc.id
}

#Public Subnet
resource "aws_subnet" "aws-public" {
  count = length(local.cidr_list[0])
  vpc_id = aws_vpc.awsvpc.id
  cidr_block = local.cidr_list[0][count.index] 
  map_public_ip_on_launch = true
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "aws-public-${split("-",var.az_list[count.index])[2]}"
  }
}

# Private subnet for application layer
resource "aws_subnet" "aws-app" {
  count = length(local.cidr_list[1])
  vpc_id = aws_vpc.awsvpc.id
  cidr_block = local.cidr_list[1][count.index] 
  map_public_ip_on_launch = false
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "aws-app-${split("-",var.az_list[count.index])[2]}"
  }
}

#Private subnet for database layer
resource "aws_subnet" "aws-db" {
  count = length(local.cidr_list[2])
  vpc_id = aws_vpc.awsvpc.id
  cidr_block = local.cidr_list[2][count.index] 
  map_public_ip_on_launch = false
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "aws-db-${split("-",var.az_list[count.index])[2]}"
  }
}


# Route table configurations for public subnet
resource "aws_route_table"  "public_route_table" {
  vpc_id = aws_vpc.awsvpc.id
}
resource "aws_route" "public_default_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_route_assoc" {
  count = length(local.cidr_list[0])
  subnet_id = aws_subnet.aws-public.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IP to be used for Nat Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}
# Nat gateway. Nat gateway is used by the EC2 instances to access the internet and download wordpress application
resource "aws_nat_gateway" "aws_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.aws-public.*.id[0]
}


# Route table configurations for private route table with route to NAT gateway
resource "aws_route_table"  "private_route_table" {
  vpc_id = aws_vpc.awsvpc.id
}
resource "aws_route" "private_default_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.aws_nat.id
}
resource "aws_route_table_association" "app_route_assoc" {
  count = length(local.cidr_list[1])
  subnet_id = aws_subnet.aws-app.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "db_route_assoc" {
  count = length(local.cidr_list[2])
  subnet_id = aws_subnet.aws-db.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}

#Security Group to be used for EC2 instances on the private subnet
resource "aws_security_group" "private_sg" {
  name = "private_sg"
  description = "Private Security Group"
  vpc_id = aws_vpc.awsvpc.id
  ingress  {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true 
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

#Security group for the windows instance on the public subnet
resource "aws_security_group" "public_sg" {
  name = "public_sg"
  description = "Public Security Group"
  vpc_id = aws_vpc.awsvpc.id
  ingress  {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true 
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

#VPC Interface endpoints for SSM.
resource "aws_vpc_endpoint" "ssmendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.awsvpc.id
  service_name = "com.amazonaws.us-east-1.ssm"
  subnet_ids = aws_subnet.aws-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ssmmessageendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.awsvpc.id
  service_name = "com.amazonaws.us-east-1.ssmmessages"
  subnet_ids = aws_subnet.aws-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ec2messageendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.awsvpc.id
  service_name = "com.amazonaws.us-east-1.ec2messages"
  subnet_ids = aws_subnet.aws-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}

#VPC Gateway endpoint for S3. Enables EC2 instances on the private subnet to download Amazon linux RPMs hosted on S3
resource "aws_vpc_endpoint" "s3gatewayendpoint" {
  vpc_endpoint_type = "Gateway"
  vpc_id = aws_vpc.awsvpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids = [ aws_route_table.private_route_table.id ]
}