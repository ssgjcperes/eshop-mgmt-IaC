output "gateway_endpoint_id_map" {
    description = "Gateway endpoint id map"
    value = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "gateway_endpoint_cidr_map" {
    description = "Gateway endpoint cidr block map"
    value = { for k, v in aws_vpc_endpoint.gateway : k => v.cidr_blocks }
}

output "gateway_endpoint_prefixlist_map" {
    description = "Gateway endpoint prefix list map"
    value = { for k, v in aws_vpc_endpoint.gateway : k => v.prefix_list_id }
}

output "interface_endpoint_id_map" {
    description = "Interface endpoint id map"
    value = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_map" {
    description = "Interface endpoint dns entry map"
    value = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
}

output "interface_endpoint_if_map" {
    description = "Interface endpoint interface id map"
    value = { for k, v in aws_vpc_endpoint.interface : k => v.network_interface_ids }
}

# output "interface_endpoint_ip_map" {
#     description = "Interface endpoint private ip address map"
#     value = transpose({ for k, v in data.aws_network_interface.interface : v.private_ip => [split("^", k)[0]] })
# }