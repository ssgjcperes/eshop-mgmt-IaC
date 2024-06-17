#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * NAT Gateway
#  * Route Table
#  
#

data "aws_availability_zones" "available" {}

resource "aws_vpc" "mgmt" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "eshop-mgmt-terraform-vpc",
  }
}


resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.mgmt.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true

  tags = tomap({
    Name = "eshop-mgmt-terraform-public-subnet${count.index + 1}",
    "kubernetes.io/cluster/eshop-mgmt-${var.cluster_name}" = "shared",
  })
}


resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.mgmt.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.1${count.index}.0/24"
  map_public_ip_on_launch = false

  tags = tomap({
    Name = "eshop-mgmt-terraform-private-subnet${count.index + 1}",
    "kubernetes.io/cluster/eshop-mgmt-${var.cluster_name}" = "shared",
  })
}


resource "aws_internet_gateway" "mgmt" {
  vpc_id = aws_vpc.mgmt.id

  tags = {
    Name = "eshop-mgmt-terraform-igw"
  }
}

resource "aws_nat_gateway" "mgmt" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.mgmt]

  tags = {
    Name = "eshop-mgmt-terraform-ngw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mgmt.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mgmt.id
  }

  tags = {
    Name = "eshop-mgmt-terraform-public-route"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.mgmt.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mgmt.id
  }

  tags = {
    Name = "eshop-mgmt-terraform-private-route",
  }
}


resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.private.id
}


resource "aws_eip" "nat" {
  #vpc        = true
  depends_on = [aws_internet_gateway.mgmt]

  tags = {
    Name = "eshop-mgmt-terraform-NAT"
  }
}

