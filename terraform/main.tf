# Resource VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpcCIDR
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "vpc-${var.projectName}-${var.environment}(${var.vpcCIDR})"
    MangedBy = "Terraform"
  }
}

# Resource Subnets
## Public Subnets
resource "aws_subnet" "publicSubnet" {
  count      = length(var.subnetsAZList)

  vpc_id     = aws_vpc.main.id
  availability_zone = var.subnetsAZList[count.index]
  map_public_ip_on_launch = "true"
  cidr_block = var.publicSubnetsCIDRList[count.index]

  tags = {
    Name = "subnet-public-${var.projectName}-${var.environment}(${var.publicSubnetsCIDRList[count.index]})"
    MangedBy = "Terraform"
  }
}

## Private NAT Subnets
resource "aws_subnet" "privateNatSubnet" {
  count      = length(var.subnetsAZList)

  vpc_id     = aws_vpc.main.id
  availability_zone = var.subnetsAZList[count.index]
  map_public_ip_on_launch = "false"
  cidr_block = var.privateNatSubnetsCIDRList[count.index]

  tags = {
    Name = "subnet-private-nat-${var.projectName}-${var.environment}(${var.privateNatSubnetsCIDRList[count.index]})"
    MangedBy = "Terraform"
  }
}

## Private Subnet
resource "aws_subnet" "privateSubnet" {
  count      = length(var.subnetsAZList)

  vpc_id     = aws_vpc.main.id
  availability_zone = var.subnetsAZList[count.index]
  map_public_ip_on_launch = "false"
  cidr_block = var.privateSubnetsCIDRList[count.index]

  tags = {
    Name = "subnet-private-${var.projectName}-${var.environment}(${var.privateSubnetsCIDRList[count.index]})"
    MangedBy = "Terraform"
  }
}

# Resource Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

# Resource Nat Gateway
## Elastic IPs for Nat Gateway
resource "aws_eip" "eip" {
  count    = length(var.subnetsAZList)

  domain   = "vpc"

  tags = {
    Name = "eips-nat${count.index}-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
  depends_on                = [aws_internet_gateway.igw]
}

## Nat Gateways
resource "aws_nat_gateway" "natgw" {
  count         = length(var.subnetsAZList)

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.publicSubnet[count.index].id

  tags = {
    Name     = "natgw${count.index}-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

# Resources Route Table
## Public Route Table
resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name     = "rtb-public-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

resource "aws_route_table_association" "publicRouteTableSubnetAssociation" {
  count = length(var.subnetsAZList)

  subnet_id      = aws_subnet.publicSubnet[count.index].id
  route_table_id = aws_route_table.publicRouteTable.id
  depends_on = [aws_internet_gateway.igw]
}

## Private Nat Route Table
resource "aws_route_table" "privateNatRouteTable" {
  count = length(var.subnetsAZList)

  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = {
    Name     = "rtb-private-nat${count.index}-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

resource "aws_route_table_association" "privateNatRouteTableSubnetAssociation" {
  count = length(var.subnetsAZList)

  subnet_id      = aws_subnet.privateNatSubnet[count.index].id
  route_table_id = aws_route_table.privateNatRouteTable[count.index].id
  depends_on = [aws_nat_gateway.natgw]
}

## Private Route Table
resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name     = "rtb-private-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

resource "aws_route_table_association" "privateRouteTableSubnetAssociation" {
  count = length(var.subnetsAZList)

  subnet_id      = aws_subnet.privateSubnet[count.index].id
  route_table_id = aws_route_table.privateRouteTable.id
}

# Resource Network ACL

# Network ACL
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name     = "nacl-${var.projectName}-${var.environment}"
    MangedBy = "Terraform"
  }
}

# Network ACL Subnet Association
resource "aws_network_acl_association" "naclPublicSubnetAssociation" {
  count = length(var.subnetsAZList)

  network_acl_id = aws_network_acl.nacl.id
  subnet_id      = aws_subnet.publicSubnet[count.index].id
}

resource "aws_network_acl_association" "naclPrivateNatSubnetAssociation" {
  count = length(var.subnetsAZList)

  network_acl_id = aws_network_acl.nacl.id
  subnet_id      = aws_subnet.privateNatSubnet[count.index].id
}

resource "aws_network_acl_association" "naclPrivateSubnetAssociation" {
  count = length(var.subnetsAZList)

  network_acl_id = aws_network_acl.nacl.id
  subnet_id      = aws_subnet.privateSubnet[count.index].id
}