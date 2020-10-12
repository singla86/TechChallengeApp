resource "aws_db_instance" "techappdb" {
  identifier = "app"
  allocated_storage = 180
  backup_retention_period = 4
  engine = "postgres"
  instance_class = "db.t2.micro"
  storage_type = "gp2"
  name = "app"
  username = "postgres"
  password = "changeme"
  db_subnet_group_name = aws_db_subnet_group.persistent_data.id
  vpc_security_group_ids = [aws_security_group.service_security_group.id]
  parameter_group_name = "postgres12"
}

resource "aws_db_parameter_group" "postgres_dbparam" {
  name        = "postgres12"
  family      = "postgres12"
  description = "Parameter group for postgres12"

}
resource "aws_security_group" "postgres" {
  name = "pg"
  description = "Allow Postgres from peering VPC"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "postgresservice" {
  name            = "postgresservice"
  cluster         = aws_ecs_cluster.techapp_cluster.id
  task_definition = aws_ecs_task_definition.techappdb_task.arn
  launch_type     = "FARGATE"
  desired_count   = 3
  depends_on      = [aws_ecs_service.techappservice]

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.techappdb_task.family
    container_port   = 5432
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id,aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

resource "aws_db_subnet_group" "persistent_data" {
  name = "persistent_data"
  description = "Persistent Data"

  subnet_ids = [
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id,
    aws_default_subnet.default_subnet_c.id
  ]
}

resource "aws_ecs_task_definition" "techappdb_task" {
  family                   = "techappdb-task-family"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "techappdb-task-family",
      "image": "612563676328.dkr.ecr.ap-southeast-1.amazonaws.com/techappdb-ecr-repo:latest",
      "essential": true,
      "portMappings": [
        {
            "containerPort": 5432,
            "hostPort": 5432
          }
      ],
      "memory": 512,
      "cpu": 128
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}