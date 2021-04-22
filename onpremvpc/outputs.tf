output "onpremvpcid" {
  value = aws_vpc.onpremvpc.id
  description = "ONPREM VPC ID"
}
output "onprem-public-1a" {
  value = [for value in aws_subnet.onprem-public: value.id if value.tags.Name == "onprem-public-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for public subnet on AZ 1a"
}
output "onprem-public-1b" {
  value = [for value in aws_subnet.onprem-public: value.id if value.tags.Name == "onprem-public-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for public subnet on AZ 1b"
}
output "onprem-app-1a" {
  value = [for value in aws_subnet.onprem-app: value.id if value.tags.Name == "onprem-app-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for application subnet on AZ 1b"
}
output "onprem-app-1b" {
  value = [for value in aws_subnet.onprem-app: value.id if value.tags.Name == "onprem-app-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for application subnet on AZ 1b"
}
output "onprem-db-1a" {
  value = [for value in aws_subnet.onprem-db: value.id if value.tags.Name == "onprem-db-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for database subnet on AZ 1a"
}
output "onprem-db-1b" {
  value = [for value in aws_subnet.onprem-db: value.id if value.tags.Name == "onprem-db-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for database subnet on AZ 1b"
}
output "private_sg" {
  value = aws_security_group.private_sg.id
}
output "public_sg" {
  value = aws_security_group.private_sg.id
}
output "wordpress_db_sg" {
  value = aws_security_group.wordpress_db_sg_onprem.id
}
output "onprem_route_table_id" {
  value = aws_route_table.public_route_table.id
}
output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}
output "onprem_dns_interface_ids" {
  value = [aws_network_interface.dnsserver1_eni.id,aws_network_interface.dnsserver2_eni.id]
}
output "onprem_dns_ips" {
  value = [aws_network_interface.dnsserver1_eni.private_ips,aws_network_interface.dnsserver2_eni.private_ips]
}