output "awsvpcid" {
  value = aws_vpc.awsvpc.id
  description = "AWS VPC ID"
}
output "aws-public-1a" {
  value = [for value in aws_subnet.aws-public: value.id if value.tags.Name == "aws-public-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for public subnet on AZ 1a"
}
output "aws-public-1b" {
  value = [for value in aws_subnet.aws-public: value.id if value.tags.Name == "aws-public-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for public subnet on AZ 1a"
}
output "aws-app-1a" {
  value = [for value in aws_subnet.aws-app: value.id if value.tags.Name == "aws-app-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for application subnet on AZ 1b"
}
output "aws-app-1b" {
  value = [for value in aws_subnet.aws-app: value.id if value.tags.Name == "aws-app-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for application subnet on AZ 1b"
}
output "aws-db-1a" {
  value = [for value in aws_subnet.aws-db: value.id if value.tags.Name == "aws-db-${split("-",var.az_list[0])[2]}"][0]
  description = "ID for database subnet on AZ 1a"
}
output "aws-db-1b" {
  value = [for value in aws_subnet.aws-db: value.id if value.tags.Name == "aws-db-${split("-",var.az_list[1])[2]}"][0]
  description = "ID for database subnet on AZ 1b"
}
output "private_sg" {
  value = aws_security_group.private_sg.id
}
output "aws_route_table_id" {
  value = aws_route_table.public_route_table.id
}
output "aws_private_route_table_id" {
  value = aws_route_table.private_route_table.id
}