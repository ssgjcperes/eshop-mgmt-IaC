#
# Outputs
#

### output bastion public ip, admin private ip added
output "bastion_server_public_ip" {
    description = "EC2 Bastion Server's Public IP"
    value = aws_instance.bastion.public_ip
}

output "admin_server_private_ip" {
    description = "EC2 Admin Server's Private IP"
    value = aws_instance.admin.private_ip
}

output "mgmt_vpc_id" {
    description = "MGMT VPC ID"
    value = module.vpc.vpc_id
}

### output my ip
output "my_ip" {
    description = "My IP"
    value = "${chomp(data.http.get_my_public_ip.response_body)}"
}

### output nat gateway public ip
output "nat_gateway_ip" {
    description = "nat gateway eip"
    value = module.vpc.nat_gateway_ip
}
