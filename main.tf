resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
}

resource "aws_subnet" "pubsub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "pubsub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw1" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.pubsub1.id
    route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.pubsub2.id
    route_table_id = aws_route_table.RT.id
}

# Create a Security Group
resource "aws_security_group" "mysg1" {
  name        = "firstsg"
  description = "first sg group"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP access for VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "SSH access for VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

#Create S3 bucket
resource "aws_s3_bucket" "webs3" {
  bucket = "firstproject2023s3bucketforterraformdemo"

  tags = {
    Name        = "webbucket"
  }
}

#Create a EC2 Instance
resource "aws_instance" "webserver1" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pubsub1.id
  vpc_security_group_ids = [aws_security_group.mysg1.id]
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_instance" "webserver2" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pubsub2.id
  vpc_security_group_ids = [aws_security_group.mysg1.id]
  user_data              = base64encode(file("userdata1.sh"))
}

#createa ALB

resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg1.id]
  subnets            = [aws_subnet.pubsub1.id,aws_subnet.pubsub2.id]
  tags = {
    Environment = "demo"
  }
}

#Create a Target Group
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

#Attach a Instance to target group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.id
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.id
  target_id        = aws_instance.webserver2.id
  port             = 80
}

#Create ALB Listener
resource "aws_lb_listener" "Listener" {
  load_balancer_arn = aws_lb.myalb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.id
  }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name

