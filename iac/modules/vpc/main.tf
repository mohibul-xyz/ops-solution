# VPC Module with Single NAT Gateway
# Creates a basic VPC with public and private subnets
# Naming format: {project}-{environment}-resource-name

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-vpc"
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-igw"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-public-subnet-${var.availability_zones[count.index]}"
      Environment = var.environment
      Project     = var.project
      Type        = "public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name        = "${var.project}-${var.environment}-private-subnet-${var.availability_zones[count.index]}"
      Environment = var.environment
      Project     = var.project
      Type        = "private"
    }
  )
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-nat-eip"
      Environment = var.environment
      Project     = var.project
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Single NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-nat-gateway"
      Environment = var.environment
      Project     = var.project
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-public-rt"
      Environment = var.environment
      Project     = var.project
      Type        = "public"
    }
  )
}

# Private Route Table (single table for all private subnets)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-private-rt"
      Environment = var.environment
      Project     = var.project
      Type        = "private"
    }
  )
}

# Private Route to NAT Gateway
resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
