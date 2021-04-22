#fetch the latest amazon linux 2 AMI
data "aws_ssm_parameter" "latestami" {
   name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "onpremjumpbox" {
  ami = "ami-0f93c815788872c5d"
  instance_type = var.instance_type
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  key_name = "A4L"
  tags = {
      Name = "onprem-windows-jumpbox"
  }
}

resource "aws_instance" "onpremappserver" {
  ami = data.aws_ssm_parameter.latestami.value
  instance_type = var.instance_type
  subnet_id = var.app_subnet_id
  vpc_security_group_ids = [var.private_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  user_data = templatefile("./onpreminstance/app_userdata.sh",{dns1_private_ip=tolist(var.onprem_dns_ips[0])[0],dns2_private_ip=tolist(var.onprem_dns_ips[1])[0],DBName=var.rds_db_name,DBUser=var.rds_db_user,DBPassword=var.rds_db_password,DBEndpoint="wordpressdb.aws.company.com"})
  tags = {
      Name = "onprem-appserver"
  }
}
resource "aws_instance" "onpremdbserver" {
  ami = data.aws_ssm_parameter.latestami.value
  instance_type = var.instance_type
  subnet_id = var.db_subnet_id
  vpc_security_group_ids = [var.wordpress_db_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  user_data = templatefile("./onpreminstance/db_userdata.sh",{DBName=var.rds_db_name,DBUser=var.rds_db_user,DBPassword=var.rds_db_password,DBRootPassword=var.rds_db_password,APPServerDns=var.app_server_dns,APPServerIP=var.app_server_ip})
  tags = {
      Name = "onprem-dbserver"
  }
}
resource "aws_instance" "onpremdns1" {
    ami = data.aws_ssm_parameter.latestami.value
    instance_type = var.instance_type
    iam_instance_profile = var.ec2_ssm_instance_profile
    network_interface {
    network_interface_id = var.onprem_dns_interface_ids[0] 
    device_index = 0
  }
    user_data = templatefile("./onpreminstance/dns_userdata.sh",{appprivateip=aws_instance.onpremappserver.private_ip,dbprivateip=aws_instance.onpremdbserver.private_ip,r53_inbound_ip1=var.inbound_ips[0],r53_inbound_ip2=var.inbound_ips[1]})
    tags = {
        Name = "onprem-dnsserver1"
    }
    provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
      command = "sleep 100"
    }
    provisioner "local-exec" {
      on_failure = fail
      interpreter = ["/bin/bash", "-c"]
      command = "aws ec2 reboot-instances --instance-ids ${aws_instance.onpremappserver.id}"
    }
    provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
      command = "sleep 100"
    }
    depends_on = [ aws_instance.onpremappserver ]
}
resource "aws_instance" "onpremdns2" {
    ami = data.aws_ssm_parameter.latestami.value
    instance_type = var.instance_type
    iam_instance_profile = var.ec2_ssm_instance_profile
    network_interface {
    network_interface_id = var.onprem_dns_interface_ids[1] 
    device_index = 0
    }
    user_data = templatefile("./onpreminstance/dns_userdata.sh",{appprivateip=aws_instance.onpremappserver.private_ip,dbprivateip=aws_instance.onpremdbserver.private_ip,r53_inbound_ip1=var.inbound_ips[0],r53_inbound_ip2=var.inbound_ips[1]})
    tags = {
        Name = "onprem-dnsserver2"
    }
    depends_on = [ aws_instance.onpremappserver ]
}
