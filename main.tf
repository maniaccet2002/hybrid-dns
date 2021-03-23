data "aws_availability_zones" "available" {}
locals {
  az_list = slice(data.aws_availability_zones.available.names,0,2)
}
# IAM Role for SSM Access
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  }) 
}
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy_attachment" {
  role = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2_ssm_instance_profile"
  role = aws_iam_role.ec2_ssm_role.name
}

module "awsvpc" {
    source = "./awsvpc"
    aws_vpc_cidr = var.aws_vpc_cidr
    az_list = local.az_list
}
module "onpremvpc" {
    source = "./onpremvpc"
    onprem_vpc_cidr = var.onprem_vpc_cidr
    az_list = local.az_list
}
module "awsec2" {
    source = "./awsec2"
    instance_type = "t2.micro"
    public_subnet_id = module.awsvpc.aws-public-1a
    app_subnet_id = module.awsvpc.aws-app-1a
    private_sg = module.awsvpc.private_sg
    ec2_ssm_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
    depends_on = [module.awsvpc]
}
module "onpremec2" {
    source = "./onpreminstance"
    instance_type = "t2.micro"
    public_subnet_id = module.onpremvpc.onprem-public-1a
    app_subnet_id = module.onpremvpc.onprem-app-1a
    private_sg = module.onpremvpc.private_sg
    ec2_ssm_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
    onprem_dns_interface_ids = module.onpremvpc.onprem_dns_interface_ids
    onprem_dns_ips = module.onpremvpc.onprem_dns_ips
    inbound_ips = module.route53.inbound_ips
    rds_db_name = var.wordpress_db_name
    rds_db_user = var.wordpress_db_user
    rds_db_password = var.wordpress_db_password
    depends_on = [module.onpremvpc]
}
module "route53" {
  source = "./route53"
  aws_vpc_id = module.awsvpc.awsvpcid
  appserver_ip = module.awsec2.appserver_ip
  private_sg = module.awsvpc.private_sg
  aws-app-1a = module.awsvpc.aws-app-1a
  aws-app-1b = module.awsvpc.aws-app-1b
  onprem_dns_ips = module.onpremvpc.onprem_dns_ips
  wordpress_db_address = module.rds.wordpress_db_address
}
module "vpcpeer" {
  source = "./vpcpeer"
  onprem_vpc_id = module.onpremvpc.onpremvpcid
  aws_vpc_id = module.awsvpc.awsvpcid
  aws_route_table_id = module.awsvpc.aws_route_table_id
  aws_private_route_table_id = module.awsvpc.aws_private_route_table_id
  onprem_route_table_id = module.onpremvpc.onprem_route_table_id
  private_route_table_id = module.onpremvpc.private_route_table_id
  aws_vpc_cidr = var.aws_vpc_cidr
  onprem_vpc_cidr = var.onprem_vpc_cidr
}
module "rds" {
    source = "./rds"
    db_subnet_list = [module.awsvpc.aws-db-1a,module.awsvpc.aws-db-1b] 
    aws_vpc_id = module.awsvpc.awsvpcid
    rds_instance_class = var.rds_instance_class
    rds_db_engine = var.rds_db_engine
    rds_db_engine_version = var.rds_db_engine_version
    rds_db_name = var.wordpress_db_name
    rds_db_user = var.wordpress_db_user
    rds_db_password = var.wordpress_db_password
    availability_zone = local.az_list[0]
    multi_az = false
    rds_storage_type = var.rds_storage_type
    rds_allocated_storage = var.rds_allocated_storage 
}
