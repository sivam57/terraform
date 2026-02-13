
############################################
# Security Group
############################################
module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "netflix-sg"
  description = "Security group for Netflix clone server"
  vpc_id      = var.vpc_id

  # Allow inbound traffic
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Jenkins"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      description = "SonarQube"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Allow all outbound traffic
  egress_rules = ["all-all"]
}

############################################
# EC2 Instance
############################################
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "netflix-server"

  instance_type          = var.instance_type
  ami                    = var.ami
  key_name               = var.key_pair
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [module.sg.security_group_id]

  monitoring = true
  user_data  = file("userdata.sh")

  root_block_device = [
    {
      volume_size           = 25
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "netflix-server"
  }
}

############################################
# Elastic IP
############################################
resource "aws_eip" "eip" {
  instance = module.ec2_instance.id
  domain   = "vpc"

  tags = {
    Name = "netflix-eip"
  }
}
