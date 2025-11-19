# main/outputs.tf
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "ec2_private_ip" {
  value = aws_instance.app.private_ip
}

output "app_bucket" {
  value = aws_s3_bucket.app_bucket.bucket
}
