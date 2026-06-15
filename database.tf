# 1. Le Groupe de Sous-réseaux (Pour dire à RDS où se placer)
resource "aws_db_subnet_group" "minecraft_db_subnet" {
  name       = "minecraft-db-subnet-group"
  # On place la base de données UNIQUEMENT dans les sous-réseaux privés pour la sécurité
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "Minecraft DB Subnet Group"
  }
}

# 2. Le Groupe de Sécurité (Le pare-feu de la base de données)
resource "aws_security_group" "rds_sg" {
  name        = "minecraft-rds-security-group"
  description = "Autorise le trafic MySQL depuis le VPC"
  vpc_id      = aws_vpc.main.id

  # Règle d'entrée : On autorise le port 3306 (MySQL) depuis l'intérieur du VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft-rds-sg"
  }
}

# 3. L'Instance de Base de Données (MySQL)
resource "aws_db_instance" "minecraft_db" {
  identifier           = "minecraft-leaderboard-db"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro" # Fait partie du Free Tier AWS / Compatible AWS Academy
  username             = "admin"
  password             = "MinecraftAdmin123!" # À changer idéalement, mais ok pour un TP
  
  db_subnet_group_name   = aws_db_subnet_group.minecraft_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  skip_final_snapshot  = true # Très important pour pouvoir détruire l'infra facilement à la fin du semestre
  publicly_accessible  = false # La base reste invisible depuis Internet

  tags = {
    Name = "Minecraft Leaderboard Database"
  }
}

# 4. On demande à Terraform de nous afficher l'adresse de connexion à la fin
output "rds_endpoint" {
  description = "L'adresse de connexion pour l'API Flask"
  value       = aws_db_instance.minecraft_db.endpoint
}