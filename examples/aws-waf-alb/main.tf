provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/aws/vpc"

  project     = "example"
  environment = "dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Example = "aws-waf-alb"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids["public-1"]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from WAF-protected ALB</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server"
  }
}

resource "aws_lb" "this" {
  name               = "example-waf-alb"
  internal          = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = [module.vpc.public_subnet_ids["public-1"], module.vpc.public_subnet_ids["public-2"]]

  enable_deletion_protection = false

  tags = {
    Example = "aws-waf-alb"
  }
}

resource "aws_security_group" "alb" {
  name        = "example-waf-alb"
  vpc_id      = module.vpc.vpc_id

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

resource "aws_lb_target_group" "this" {
  name     = "example-waf-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

module "waf" {
  source = "../../modules/aws/waf"

  project     = "example"
  environment = "dev"

  enable_rate_limiting          = true
  rate_limit_threshold         = 2000
  enable_aws_managed_common_ruleset = true
  enable_aws_managed_bad_inputs    = true

  alb_arn_list = [aws_lb.this.arn]

  tags = {
    Example = "aws-waf-alb"
  }
}
