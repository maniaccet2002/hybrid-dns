#Create RDS Subnet group
resource "aws_db_subnet_group" "wordpress_rds_sg" {
  name = "wordpress_rds_sg"
  subnet_ids = var.db_subnet_list
  tags = {
      Name = "Wordpress RDS Security Group"
  }
}

#Securtity group for RDS database
resource "aws_security_group" "wordpress_rds_sg" {
  name = "wordpress_rds_sg"
  description = "Wordpress RDS Security Group"
  vpc_id = var.aws_vpc_id
  ingress  {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Mysql RDS cluster and instance
resource "aws_db_instance" "wordpress_rds_instance" {
  allocated_storage = var.rds_allocated_storage
  storage_type         = var.rds_storage_type
  engine = var.rds_db_engine
  engine_version = var.rds_db_engine_version
  instance_class       = var.rds_instance_class
  identifier = var.rds_db_name
  name = var.rds_db_name
  username = var.rds_db_user
  password = var.rds_db_password
  db_subnet_group_name = aws_db_subnet_group.wordpress_rds_sg.name
  vpc_security_group_ids = [aws_security_group.wordpress_rds_sg.id]
  skip_final_snapshot = true
  availability_zone = var.availability_zone
  multi_az = var.multi_az
}