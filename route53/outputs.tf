output "inbound_ips" {
    value = aws_route53_resolver_endpoint.route53_inbound_endpoint.ip_address[*].ip
}