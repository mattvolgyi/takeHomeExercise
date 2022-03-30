resource "aws_ecr_repository" "hello-world-ecr" {
  name = "hello-world-ecr"
}

resource "aws_ecs_service" "hello-world" {
  name            = "hello-world"

  task_definition = "${aws_ecs_task_definition.hello-world.arn}"
  cluster         = "${aws_ecs_cluster.app.id}"
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    assign_public_ip = false

    security_groups = [
      aws_security_group.egress_all.id,
      aws_security_group.ingress_api.id,
    ]

    subnets = [
      aws_subnet.private_d.id,
      aws_subnet.private_e.id,
    ]
  }

  load_balancer {
  container_name = "hello-world"
  target_group_arn = "${aws_lb_target_group.helloWorld.arn}"
  container_port = "5000"
  }
}

resource "aws_cloudwatch_log_group" "helloWorld" {
  name = "/ecs/helloWorld"
}

resource "aws_ecs_task_definition" "hello-world" {
  family = "hello-world"

  container_definitions = <<EOF
  [
    {
      "name": "hello-world",
      "image": "${aws_ecr_repository.hello-world-ecr.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "us-east-1",
          "awslogs-group": "/ecs/helloWorld",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  EOF

  # These are the minimum values for Fargate containers.
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  # This is required for Fargate containers.
  network_mode = "awsvpc"
}

resource "aws_iam_role" "task_execution_role" {
  name               = "task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Normally we'd prefer not to hardcode an ARN in our Terraform, but since this is
# an small challenge, it's okay.
data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

resource "aws_ecs_cluster" "app" {
  name = "app"
}

resource "aws_lb_target_group" "helloWorld" {
  name        = "helloWorld"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.helloWorld]
}

resource "aws_alb" "helloWorld" {
  name               = "helloWorld-lb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_d.id,
    aws_subnet.public_e.id,
  ]

  security_groups = [
    aws_security_group.http.id,
    aws_security_group.https.id,
    aws_security_group.egress_all.id,
  ]

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_alb_listener" "helloWorld_http" {
  load_balancer_arn = aws_alb.helloWorld.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.helloWorld.arn
  }
}

output "alb_url" {
  value = "http://${aws_alb.helloWorld.dns_name}"
}

