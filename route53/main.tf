resource "aws_route53_zone" "aws_private_zone" {
    name = "aws.company.com"
    vpc {
        vpc_id = var.aws_vpc_id
    }
}
resource "aws_route53_record" "aws_company" {
    zone_id = aws_route53_zone.aws_private_zone.zone_id
    name = "web.aws.company.com"
    type = "A"
    ttl = "300"
    records = [var.appserver_ip]  
}
resource "aws_route53_record" "wordpressdb" {
    zone_id = aws_route53_zone.aws_private_zone.zone_id
    name = "wordpressdb.aws.company.com"
    type = "CNAME"
    ttl = "300"
    records = [var.wordpress_db_address]  
}
resource "aws_route53_resolver_endpoint" "route53_inbound_endpoint" {
  name = "route53_inbound_endpoint"
  direction = "INBOUND"
  security_group_ids = [ var.private_sg ]
  ip_address {
    subnet_id = var.aws-app-1a
  }
  ip_address {
    subnet_id = var.aws-app-1b
  }
}
resource "aws_route53_resolver_endpoint" "route53_outbound_endpoint" {
    name = "route53_outbound_endpoint"
    direction = "OUTBOUND"
    security_group_ids = [ var.private_sg ]
    ip_address {
        subnet_id = var.aws-app-1a
    }
    ip_address {
        subnet_id = var.aws-app-1b
    }
}
resource "aws_route53_resolver_rule" "onprem_dns_forward_rule" {
    domain_name = "corp.animals4life.org"
    name = "onprem_dns_forward_rule"
    rule_type = "FORWARD"
    resolver_endpoint_id = aws_route53_resolver_endpoint.route53_outbound_endpoint.id
    target_ip {
      ip = tolist(var.onprem_dns_ips[0])[0]
    }
    target_ip {
      ip = tolist(var.onprem_dns_ips[1])[0]
    } 
}
resource "aws_route53_resolver_rule_association" "onprem_rule_association" {
    resolver_rule_id = aws_route53_resolver_rule.onprem_dns_forward_rule.id
    vpc_id = var.aws_vpc_id
}