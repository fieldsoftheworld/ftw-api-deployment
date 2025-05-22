output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_subnet_az1.id,
    aws_subnet.public_subnet_az2.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    aws_subnet.private_subnet_az1.id,
    aws_subnet.private_subnet_az2.id
  ]
}

output "nat_gateway_ips" {
  description = "Public IP addresses of the NAT gateway(s)"
  value       = aws_eip.nat_eip[*].public_ip
}

output "internet_gateway_id" {
  description = "The ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private_route_table[*].id
}