output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs of public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  description = "IDs of private subnets"
  value       = [for s in aws_subnet.private : s.id]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}
