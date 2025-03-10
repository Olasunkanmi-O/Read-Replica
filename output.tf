output "webserver_ip" {
  value = aws_instance.webserver.public_ip
}

output "rds_endpoint" {
  value = local.rds_endpoint
}
