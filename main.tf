$ cat main.tf
provider "aws" {
  region = "us-east-1"
}

# Generate SSH Key Pair
resource "tls_private_key" "devops_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "devops_key_pair" {
  key_name   = "devops-key"
  public_key = tls_private_key.devops_key.public_key_openssh
}

# VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id
}

# Route Table
resource "aws_route_table" "devops_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }
}

# Subnet
resource "aws_subnet" "devops_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "devops_rta" {
  subnet_id      = aws_subnet.devops_subnet.id
  route_table_id = aws_route_table.devops_rt.id
}

# Security Group
resource "aws_security_group" "devops_sg" {
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 9090
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

# AMI ID (Ubuntu 22.04 LTS)
variable "ami_id" {
  default = "ami-0f282c4a357a44c9b"
}

# EC2 Instances
resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.devops_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  key_name                    = aws_key_pair.devops_key_pair.key_name
  tags = { Name = "Jenkins Server" }
}

resource "aws_instance" "docker_host" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.devops_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  key_name                    = aws_key_pair.devops_key_pair.key_name
  tags = { Name = "Docker Host" }
}

resource "aws_instance" "k8s_master" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.devops_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  key_name                    = aws_key_pair.devops_key_pair.key_name
  tags = { Name = "K8s Control Plane" }
}

resource "aws_instance" "k8s_worker" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.devops_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  key_name                    = aws_key_pair.devops_key_pair.key_name
  tags = { Name = "K8s Worker Node" }
}

resource "aws_instance" "monitoring_vm" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.devops_subnet.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  key_name                    = aws_key_pair.devops_key_pair.key_name
  tags = { Name = "Monitoring VM" }
}

# Outputs
output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}
output "docker_host_ip" {
  value = aws_instance.docker_host.public_ip
}
output "k8s_master_ip" {
  value = aws_instance.k8s_master.public_ip
}
output "k8s_worker_ip" {
  value = aws_instance.k8s_worker.public_ip
}
output "monitoring_vm_ip" {
  value = aws_instance.monitoring_vm.public_ip
}
output "private_key_pem" {
  value     = tls_private_key.devops_key.private_key_pem
  sensitive = true
}


