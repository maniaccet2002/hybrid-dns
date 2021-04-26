#fetch the latest amazon linux 2 AMI
data "aws_ssm_parameter" "latestami" {
   name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
locals {
  router_ip = join("",[regex("^[0-9]*.[0-9]*.[0-9]*.",var.onprem_vpc_cidr),"2"])
}
#Windows jumpbox to test wordpress appliation
resource "aws_instance" "onpremjumpbox" {
  ami = var.windows_ami_id
  instance_type = var.instance_type
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  key_name = var.ssh_key_name
  user_data = templatefile("./onpreminstance/windows_userdata.ps1",{dns1=aws_instance.onpremdns1.private_ip,dns2=aws_instance.onpremdns2.private_ip})
  tags = {
      Name = "onprem-windows-jumpbox"
  }
  depends_on = [aws_instance.onpremdns2]
}

#EC2 instance for wordpress application
resource "aws_instance" "onpremappserver" {
  ami = data.aws_ssm_parameter.latestami.value
  instance_type = var.instance_type
  subnet_id = var.app_subnet_id
  vpc_security_group_ids = [var.private_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  user_data = templatefile("./onpreminstance/app_userdata.sh",{dns1_private_ip=tolist(var.onprem_dns_ips[0])[0],dns2_private_ip=tolist(var.onprem_dns_ips[1])[0],DBName=var.rds_db_name,DBUser=var.rds_db_user,DBPassword=var.rds_db_password,DBEndpoint=var.db_endpoint})
  tags = {
      Name = "onprem-appserver"
  }
}

#EC2 instance for wordpress database
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

#On premises DNS server1
resource "aws_instance" "onpremdns1" {
    ami = data.aws_ssm_parameter.latestami.value
    instance_type = var.instance_type
    iam_instance_profile = var.ec2_ssm_instance_profile
    network_interface {
    network_interface_id = var.onprem_dns_interface_ids[0] 
    device_index = 0
  }
    user_data = templatefile("./onpreminstance/dns_userdata.sh",{appprivateip=aws_instance.onpremappserver.private_ip,dbprivateip=aws_instance.onpremdbserver.private_ip,r53_inbound_ip1=var.inbound_ips[0],r53_inbound_ip2=var.inbound_ips[1],aws_dns_name=var.aws_dns_name,onprem_dns_name=var.onprem_dns_name,router_ip=local.router_ip})
    tags = {
        Name = "onprem-dnsserver1"
    }
    provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
      command = "sleep 100"
    }
    # restart on premises application server to configure DNS server1 and server2
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

#On premises DNS server2
resource "aws_instance" "onpremdns2" {
    ami = data.aws_ssm_parameter.latestami.value
    instance_type = var.instance_type
    iam_instance_profile = var.ec2_ssm_instance_profile
    network_interface {
    network_interface_id = var.onprem_dns_interface_ids[1] 
    device_index = 0
    }
    user_data = templatefile("./onpreminstance/dns_userdata.sh",{appprivateip=aws_instance.onpremappserver.private_ip,dbprivateip=aws_instance.onpremdbserver.private_ip,r53_inbound_ip1=var.inbound_ips[0],r53_inbound_ip2=var.inbound_ips[1],aws_dns_name=var.aws_dns_name,onprem_dns_name=var.onprem_dns_name,router_ip=local.router_ip})
    tags = {
        Name = "onprem-dnsserver2"
    }
    depends_on = [ aws_instance.onpremappserver ]
}
