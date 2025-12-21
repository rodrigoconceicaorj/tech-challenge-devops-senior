# main.tf
# Recursos de banco (RDS), usando VPC/subnets/SGs definidos em network.tf.

resource "aws_iam_role" "rds_monitoring_role" {
  name = "tech-challenge-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_subnet_group" "rds_subnet_group_new" {
  name = "tech-challenge-rds-subnet-group-v2"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  tags = {
    Name = "tech-challenge-rds-subnet-group-v2"
  }
}

resource "aws_db_instance" "comments_db" {
  identifier        = "tech-challenge-comments-db-v2"
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password
  db_name  = "commentsdb"
  port     = 5432

  storage_type        = "gp3"
  multi_az            = true
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = true
  backup_retention_period = 7

  storage_encrypted = true
  performance_insights_enabled = true
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  copy_tags_to_snapshot = true
  auto_minor_version_upgrade = true

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group_new.name

  tags = {
    Name = "tech-challenge-comments-db-v2"
  }
}
