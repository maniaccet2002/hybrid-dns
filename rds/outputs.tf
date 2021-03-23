output "wordpress_db_address" {
  value = aws_db_instance.wordpress_rds_instance.address
}