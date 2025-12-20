# main.tf
# Recursos de banco (RDS), usando VPC/subnets/SGs definidos em network.tf.

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "tech-challenge-rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  tags = {
    Name = "tech-challenge-rds-subnet-group"
  }
}

resource "aws_db_instance" "comments_db" {
  identifier        = "tech-challenge-comments-db"
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  username = "comments_user"
  password = "ChangeMeStrong123!"
  db_name  = "commentsdb"
  port     = 5432

  storage_type        = "gp2"
  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name = "tech-challenge-comments-db"
  }
}
