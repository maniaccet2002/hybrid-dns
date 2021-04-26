#VPC peering connection between AWS and simulated On premises VPC
resource "aws_vpc_peering_connection" "vpcpeer" {
    peer_vpc_id = var.onprem_vpc_id
    vpc_id = var.aws_vpc_id
    auto_accept = true
}

#Routes for AWS VPC
resource "aws_route" "route_vpcpeer_aws" {
    route_table_id = var.aws_route_table_id
    destination_cidr_block = var.onprem_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpcpeer.id
}
resource "aws_route" "route_vpcpeer_aws_private" {
    route_table_id = var.aws_private_route_table_id
    destination_cidr_block = var.onprem_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpcpeer.id
}

#Routes for On premises VPC
resource "aws_route" "route_vpcpeer_onprem" {
    route_table_id = var.onprem_route_table_id
    destination_cidr_block = var.aws_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpcpeer.id
}
resource "aws_route" "route_vpcpeer_onprem_privtae" {
    route_table_id = var.private_route_table_id
    destination_cidr_block = var.aws_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpcpeer.id
}