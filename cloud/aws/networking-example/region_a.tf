
resource "aws_vpc" "vpc" {
  tags = {
    Name = "r53-lab-vpc"
  }
  cidr_block = "172.3.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1a" {
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "r53-lab-1a"
  }
  availability_zone = "us-east-1a"
  cidr_block = "172.3.0.0/24"
  # ipv6_cidr_block = "30"
}

resource "aws_subnet" "subnet1b" {
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "r53-lab-1b"
  }
  availability_zone = "us-east-1b"
  cidr_block = "172.3.1.0/24"
  # ipv6_cidr_block = "31"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "r53-lab-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "r53-lab-rt"
  }
}

resource "aws_route_table_association" "rta-a" {
  subnet_id      = aws_subnet.subnet1a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta-b" {
  subnet_id      = aws_subnet.subnet1b.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route" "r" {
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
  route_table_id            = aws_route_table.rt.id
  depends_on = [
    aws_route_table.rt
  ]
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "sg"
  vpc_id      = aws_vpc.vpc.id

  ingress = [
    {
      description      = "http"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "https"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"] // Set your IP subnet for SSH access
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  # egress = [
  #   {
  #     description      = "any"
  #     from_port        = 0
  #     to_port          = 0
  #     protocol         = "-1"
  #     cidr_blocks      = ["0.0.0.0/0"]
  #     ipv6_cidr_blocks = ["::/0"]
  #     prefix_list_ids  = []
  #     security_groups  = []
  #     self             = false
  #   }
  # ]
}

###
### Region A setup
##
## Create web1-east instance
  # Create elastic network interface
  resource "aws_network_interface" "eni1" {
    subnet_id       = aws_subnet.subnet1a.id
    description     = "web1-east eth0"
    private_ips     = ["172.3.0.10"]
    security_groups = [aws_security_group.sg.id]

  }

  resource "aws_eip" "web1-eip" {
    network_interface = aws_network_interface.eni1.id
    depends_on = [
      aws_internet_gateway.igw
    ]
  }

  resource "aws_instance" "web1-east" {
    ami           = local.region_a_ami # us-east-1
    key_name      = local.region_key_pair
    instance_type = "t2.micro"
    
    network_interface {
      network_interface_id = aws_network_interface.eni1.id
      device_index         = 0
      delete_on_termination = false
    }

    tags = {
      Name = "web1-east"
    }
  }

##
## Create web2-east instance
  resource "aws_network_interface" "eni2" {
    subnet_id       = aws_subnet.subnet1b.id
    description     = "web2-east eth0"
    private_ips     = ["172.3.1.20"]
    security_groups = [aws_security_group.sg.id]

  }

  resource "aws_eip" "web2-eip" {
    network_interface = aws_network_interface.eni2.id
    depends_on = [
      aws_internet_gateway.igw
    ]
  }

  resource "aws_instance" "web2-east" {
    ami           = "ami-48351d32" # us-east-1
    key_name      = "ccnetkeypair"
    instance_type = "t2.micro"
    
    network_interface {
      network_interface_id = aws_network_interface.eni2.id
      device_index         = 0
      delete_on_termination = false
    }

    tags = {
      Name = "web2-east"
    }
  }
