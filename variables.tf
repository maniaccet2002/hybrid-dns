variable "aws_region" {
    default = "us-east-1"
}
variable "aws_vpc_cidr" {
    default = "10.10.0.0/16"
}
variable "onprem_vpc_cidr" {
    default = "192.168.10.0/24"
}
variable "rds_db_engine" {
    default = "mysql"
}
variable "rds_db_engine_version" {
    default = "5.6.46"
}
variable "rds_instance_class" {
    default = "db.t2.micro"
}
variable "multi_az" {
    default = false
}
variable "wordpress_db_name" {
    default = "wordpressdb"
}
variable "wordpress_db_user" {
    default = "wordpress"
}
variable "wordpress_db_password" {
    description = "Password for the Wordpress Database"
    sensitive = true
    default = "wordpress"
}
variable "rds_storage_type" {
    default = "gp2"
}
variable "rds_allocated_storage" {
    default = 20
}