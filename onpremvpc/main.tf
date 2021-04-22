locals {
   cidr_list = [for cidr_block in cidrsubnets(var.onprem_vpc_cidr,2,2,2,2) : cidrsubnets(cidr_block,2,2) ]
 }
resource "aws_vpc" "onpremvpc" {
  cidr_block       = var.onprem_vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  assign_generated_ipv6_cidr_block = "true"

  tags = {
    Name = "onprem-vpc"
  }
  lifecycle {
    create_before_destroy = true
  }
}
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.onpremvpc.id
}
resource "aws_subnet" "onprem-public" {
  count = length(local.cidr_list[0])
  vpc_id = aws_vpc.onpremvpc.id
  cidr_block = local.cidr_list[0][count.index] 
  map_public_ip_on_launch = true
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "onprem-public-${split("-",var.az_list[count.index])[2]}"
  }
}
resource "aws_subnet" "onprem-app" {
  count = length(local.cidr_list[1])
  vpc_id = aws_vpc.onpremvpc.id
  cidr_block = local.cidr_list[1][count.index] 
  map_public_ip_on_launch = false
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "onprem-app-${split("-",var.az_list[count.index])[2]}"
  }
}
resource "aws_subnet" "onprem-db" {
  count = length(local.cidr_list[2])
  vpc_id = aws_vpc.onpremvpc.id
  cidr_block = local.cidr_list[2][count.index] 
  map_public_ip_on_launch = false
  availability_zone = var.az_list[count.index]
  tags = {
    Name = "onprem-db-${split("-",var.az_list[count.index])[2]}"
  }
}
# Route table configurations
resource "aws_route_table"  "public_route_table" {
  vpc_id = aws_vpc.onpremvpc.id
}
resource "aws_route" "public_default_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_route_assoc" {
  count = length(local.cidr_list[0])
  subnet_id = aws_subnet.onprem-public.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_eip" "nat_eip" {
  vpc = true
}
resource "aws_nat_gateway" "onprem_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.onprem-public.*.id[0]
}
resource "aws_route_table"  "private_route_table" {
  vpc_id = aws_vpc.onpremvpc.id
}
resource "aws_route" "private_default_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.onprem_nat.id
}
resource "aws_route_table_association" "private_route_assoc" {
  count = length(local.cidr_list[0])
  subnet_id = aws_subnet.onprem-app.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "private_route_assoc_db" {
  count = length(local.cidr_list[0])
  subnet_id = aws_subnet.onprem-db.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}
# Security group which allows public access 
resource "aws_security_group" "private_sg" {
  name = "onprem_private_sg"
  description = "Private Security Group"
  vpc_id = aws_vpc.onpremvpc.id
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
    from_port = 0
    to_port = 0
    protocol = -1
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
resource "aws_security_group" "public_sg" {
  name = "public_sg"
  description = "Public Security Group"
  vpc_id = aws_vpc.onpremvpc.id
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
resource "aws_security_group" "wordpress_db_sg_onprem" {
  name = "wordpress_rds_sg_onprem"
  description = "Wordpress RDS Security Group"
  vpc_id = aws_vpc.onpremvpc.id
  ingress  {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress  {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_network_interface" "dnsserver1_eni" {
  subnet_id = [for value in aws_subnet.onprem-app: value.id if value.tags.Name == "onprem-app-${split("-",var.az_list[0])[2]}"][0]
  security_groups = [aws_security_group.private_sg.id]
  depends_on = [
    aws_vpc_endpoint.ssmendpoint,
    aws_vpc_endpoint.ssmmessageendpoint,
    aws_vpc_endpoint.ec2messageendpoint,
    aws_vpc_endpoint.s3gatewayendpoint
  ]
}
resource "aws_network_interface" "dnsserver2_eni" {
  subnet_id = [for value in aws_subnet.onprem-app: value.id if value.tags.Name == "onprem-app-${split("-",var.az_list[1])[2]}"][0]
  security_groups = [aws_security_group.private_sg.id]
  depends_on = [
    aws_vpc_endpoint.ssmendpoint,
    aws_vpc_endpoint.ssmmessageendpoint,
    aws_vpc_endpoint.ec2messageendpoint,
    aws_vpc_endpoint.s3gatewayendpoint
  ]
}
resource "aws_vpc_endpoint" "ssmendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.onpremvpc.id
  service_name = "com.amazonaws.us-east-1.ssm"
  subnet_ids = aws_subnet.onprem-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ssmmessageendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.onpremvpc.id
  service_name = "com.amazonaws.us-east-1.ssmmessages"
  subnet_ids = aws_subnet.onprem-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ec2messageendpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.onpremvpc.id
  service_name = "com.amazonaws.us-east-1.ec2messages"
  subnet_ids = aws_subnet.onprem-app[*].id
  security_group_ids = [ aws_security_group.private_sg.id ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "s3gatewayendpoint" {
  vpc_endpoint_type = "Gateway"
  vpc_id = aws_vpc.onpremvpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids = [ aws_route_table.private_route_table.id ]
}