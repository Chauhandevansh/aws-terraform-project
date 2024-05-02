resource "aws_vpc" "my_vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet-1a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "piblic-subnet-01"
  }
}

resource "aws_subnet" "subnet-1b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-02"
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
      Name = "main"
    }
  
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "my_route_table"
  }
}

resource "aws_route_table_association" "public-1a" {
  subnet_id      = aws_subnet.subnet-1a.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "public-1b" {
  subnet_id      = aws_subnet.subnet-1b.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "alb-sg" {
  name = "ALB-SG"
  description = "Allow traffic to Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "alb-sg"
  }
  ingress {
    description = "Allow HTTP traffic for Load Balancer"
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

resource "aws_security_group" "web-sg" {
  name = "web-sg"
  description = "Allow all HTTP traffic to Web Server"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "web-sg"
  }
  ingress {
    description = "Allow HTTP for webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb-sg.id]

  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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


resource "aws_s3_bucket" "s3-bucket" {
  bucket  = "devansh-terraform-project"

  tags = {
    Name  = "terrafrom_bucket"
  }
}

resource "aws_instance" "web_server_1" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1a.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data = base64encode(file("userdata.sh"))
  tags = {
    Name = "Public-1a"
  }
}

resource "aws_instance" "web_server_2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1b.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data = base64encode(file("userdata1.sh"))

  tags = {
    Name = "Public-1b"
  }
} 

#Target Group 
resource "aws_lb_target_group" "my_target_group" {
  name     = "tf-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }  
}

resource "aws_lb" "mylb" {
  name = "myalb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = [aws_subnet.subnet-1a.id, aws_subnet.subnet-1b.id]
  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.mylb.dns_name
}