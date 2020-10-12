resource "aws_ecr_repository" "techapp_ecr_repo" {
  name = "techapp-ecr-repo"
}

resource "aws_ecs_cluster" "techapp_cluster" {
  name = "techapp-cluster" 
}
resource "aws_ecs_task_definition" "techapp" {
  family                   = "techapp-task-family"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "techapp-task-family",
      "image": "612563676328.dkr.ecr.ap-southeast-1.amazonaws.com/techapp-ecr-repo:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        },
      {
          "containerPort": 5432,
          "hostPort": 5432
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "appTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "techappservice" {
  name            = "techappservice"
  cluster         = aws_ecs_cluster.techapp_cluster.id
  task_definition = aws_ecs_task_definition.techapp.arn
  launch_type     = "FARGATE"
  desired_count   = 3

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.techapp.family
    container_port   = 3000
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id,aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}