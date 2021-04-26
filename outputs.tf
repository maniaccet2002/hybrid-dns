output "aws_wordpress_url" {
    value = join(".",["wordpress",var.aws_dns_name])
}
output "onpremises_wordpress_url" {
    value = join(".",["wordpress",var.onprem_dns_name])
}