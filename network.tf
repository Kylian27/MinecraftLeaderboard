# Le réseau principal (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "minecraft-vpc"
  }
}

# Passerelle Internet (pour rendre la couche publique accessible)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "minecraft-igw"
  }
}

# Sous-réseaux Publics
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # <-- Changement ici
  map_public_ip_on_launch = true

  tags = {
    Name = "minecraft-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b" # <-- Changement ici
  map_public_ip_on_launch = true

  tags = {
    Name = "minecraft-public-2"
  }
}

# Sous-réseaux Privés
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a" # <-- Changement ici

  tags = {
    Name = "minecraft-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b" # <-- Changement ici

  tags = {
    Name = "minecraft-private-2"
  }
}

# -----------------------------------------------------------------
# ROUTES
# -----------------------------------------------------------------

# 1. Table de routage publique (Pour que l'ALB puisse te répondre via l'Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "minecraft-public-rt" }
}

# Association de la table publique aux sous-réseaux publics
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 2. NAT Gateway (Pour que les EC2 privées puissent télécharger Python)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "minecraft-nat-eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id # Le NAT se place obligatoirement dans un réseau public
  depends_on    = [aws_internet_gateway.igw]
  tags = { Name = "minecraft-nat-gw" }
}

# 3. Table de routage privée (Envoie le trafic sortant des serveurs vers le NAT)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "minecraft-private-rt" }
}

# Association de la table privée aux sous-réseaux privés
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}