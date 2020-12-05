data "template_file" "user_data" {
  template = file("user-data.sh")
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

#resource "aws_vpc" "test_vpc" {
  #cidr_block = "172.127.0.0/16"
  #enable_dns_hostnames = false
  #enable_dns_support = false

  #tags = {
    #Name = "terraform"
  #}

#}

#resource "aws_subnet" "sub1" {
  #cidr_block = "172.127.3.0/24"
  ##vpc_id = aws_vpc.test_vpc.id

  #tags = {
    #Name = "terraform"
  #}
#}

#resource "aws_subnet" "sub2" {
  #cidr_block = "172.127.4.0/24"
  ##vpc_id = aws_vpc.test_vpc.id

  #tags = {
    #Name = "terraform"
  #}
#}

#resource "aws_db_subnet_group" "dbsubnet" {
  #name       = "main"
  #subnet_ids = [
    #aws_subnet.sub1.id,
    #aws_subnet.sub2.id,
  #]

  #tags = {
    #Name = "terraform"
  #}
#}

resource "aws_key_pair" "django" {
  key_name   = "django"
  public_key = file("key.pub")
}

resource "aws_security_group" "django" {
  name        = "django-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"
  #vpc_id = aws_vpc.test_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
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
    Name = "terraform"
  }
}


resource "aws_instance" "django" {
  key_name      = aws_key_pair.django.key_name
  ami           = "ami-0aef57767f5404a3c"
  instance_type = "t2.micro"

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "django"
  }

  vpc_security_group_ids = [
    aws_security_group.django.id
  ]

  connection {
    type        = "ssh"
    user        = "django"
    private_key = file("key")
    host        = self.public_ip
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 8
  }
}

resource "aws_eip" "django" {
  vpc      = true
  instance = aws_instance.django.id
}

resource "random_id" "random_16" {
  byte_length = 16 * 3 / 4
}

locals {
  db_password = random_id.random_16.b64_url
}


resource "aws_db_instance" "database" {
  allocated_storage = 10
  engine = "postgres"
  engine_version = "11.5"
  instance_class = "db.t2.micro"
  identifier = "djangodb"
  name = "django_prod"
  username = "webapp"
  password = local.db_password
  skip_final_snapshot = true
  #db_subnet_group_name = aws_db_subnet_group.dbsubnet.name
  vpc_security_group_ids = [
    aws_security_group.django.id
  ]

  tags = {
    Name = "terraform"
  }
}
