output "appserver_ip" {
    value = aws_instance.awsappserver.private_ip
}
output "app_server_dns" {
    value = aws_instance.awsappserver.private_dns
}