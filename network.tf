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