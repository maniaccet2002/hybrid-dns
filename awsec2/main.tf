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
  tags = {
      Name = "aws-appserver"
  }
}
