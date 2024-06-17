## VPC_ID
output "vpc_id" {
  value = aws_vpc.mgmt.id
}

## Public_subnet_id
output "public_subnet_id" {
  value = [aws_subnet.public.*.id[0], aws_subnet.public.*.id[1]]
}

## Private_subnet_id
output "private_subnet_id" {
  value = [aws_subnet.private.*.id[0], aws_subnet.private.*.id[1]]
}

## Nat GW IP for var
output "nat_gateway_ip" {
  value = aws_eip.nat.public_ip
}