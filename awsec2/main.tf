#fetch the latest amazon linux 2 AMI
data "aws_ssm_parameter" "latestami" {
   name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "awsappserver" {
  ami = data.aws_ssm_parameter.latestami.value
  instance_type = var.instance_type
  subnet_id = var.app_subnet_id
  vpc_security_group_ids = [var.private_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  user_data = templatefile("./awsec2/app_userdata.sh",{DBName=var.rds_db_name,DBUser=var.rds_db_user,DBPassword=var.rds_db_password,DBEndpoint="db.corp.animals4life.org"})
  tags = {
      Name = "aws-appserver"
  }
}
resource "aws_instance" "awsjumpbox" {
  ami = "ami-0f93c815788872c5d"
  instance_type = var.instance_type
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg]
  iam_instance_profile = var.ec2_ssm_instance_profile
  key_name = "A4L"
  tags = {
      Name = "aws-windows-jumpbox"
  }
}
