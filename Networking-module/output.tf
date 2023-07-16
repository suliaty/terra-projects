output "vpc-id" {
    value = aws_vpc.main.id
}

output "pub-id" {
    value = aws_subnet.public.id
}

output "priv-id" {
    value = aws_subnet.private.id
}