resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "tech-challenge-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                    = aws_vpc.main.id
  cidr_block                = "10.0.1.0/24"
  map_public_ip_on_launch   = true

  tags = {
    name = "tech-challenge-public-a"
  }
}

#resource "aws_db_subnet_group" "main" {
#    name        = "tech-challenge-db-subnets"
#    subnet_ids  = [aws_subnet.public_a.id]
#
#    tags = {
#        name = "tech-challenge-db-subnets"
#    }
#}

#resource "aws_db_instance" "postgres" {
#    identifier          = "tech-challenge-postgres"
#    engine              = "postgres"
#    engine_version      = "15.5"
#    instance_class      = "db.t3.micro"
#    allocated_storage   = 20
#    username            = "techuser"
#    password            = "techpassword123"
#    db_name             = "techdb"
#    skip_final_snapshot = true
#    publicly_accessible = true
#    db_subnet_group_name = aws_db_subnet_group.main.name
#
#    tags = {
#        name = "tech-challenge-postgres"
#    }
#}

# Internet Gateway ligado na VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    name = "tech-challenge-igw"
  }
}

# Route table pública com rota default para a internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    name = "tech-challenge-public-rt"
  }
}

# Associação da subnet pública à route table pública
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}


# Security Group para a aplicação (HTTP)
resource "aws_security_group" "app_sg" {
  name        = "tech-challenge-app-sg"
  description = "Allow HTTP traffic to app"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
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

  tags = {
    name = "tech-challenge-app-sg"
  }
}

# Security Group para o banco (Postgres)
resource "aws_security_group" "db_sg" {
  name        = "tech-challenge-db-sg"
  description = "Allow Postgres from app SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Postgres from app SG"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "tech-challenge-db-sg"
  }
}
