# 1. Groupe de Sécurité pour le Load Balancer (Ouvert à tous sur Internet)
resource "aws_security_group" "alb_sg" {
  name        = "minecraft-alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Groupe de Sécurité pour les serveurs EC2 (Accessibles UNIQUEMENT par l'ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "minecraft-ec2-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Récupérer l'image Amazon Linux 2023 la plus récente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# 4. Le modèle de lancement (L'ADN de tes serveurs)
resource "aws_launch_template" "flask_app" {
  name_prefix   = "minecraft-flask-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Le script exécuté au démarrage du serveur (Il installe Python et crée app.py)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 python3-pip
              
              cat << 'PYTHONEOF' > /home/ec2-user/app.py
              ${file("${path.module}/back/app.py")}
              PYTHONEOF
              
              pip3 install flask flask-cors pymysql
              
              # Lancement de l'API en arrière-plan
              nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &
              EOF
  )
}

# 5. L'Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "minecraft-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "flask_tg" {
  name     = "minecraft-flask-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/leaderboard"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }
}

# 6. L'Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "flask_asg" {
  name                = "minecraft-asg"
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.flask_tg.arn]

  min_size         = 2 # Haute disponibilité : toujours 2 instances actives min
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.flask_app.id
    version = "$Latest"
  }
}

# On affiche l'URL publique de l'API à la fin !
output "api_url" {
  value = "http://${aws_lb.main.dns_name}/api/leaderboard"
}