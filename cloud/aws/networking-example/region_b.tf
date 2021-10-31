
resource "aws_vpc" "vpc_b" {
  tags = {
    Name = "r53-lab-vpc"
  }
  cidr_block = "172.9.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1a_b" {
  vpc_id     = aws_vpc.vpc_b.id
  tags = {
    Name = "r53-lab-1a"
  }
  availability_zone = "us-west-1a"
  cidr_block = "172.9.0.0/24"
}

resource "aws_subnet" "subnet1b_b" {
  vpc_id     = aws_vpc.vpc_b.id
  tags = {
    Name = "r53-lab-1b"
  }
  availability_zone = "us-west-1b"
  cidr_block = "172.9.1.0/24"
}

resource "aws_internet_gateway" "igw_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags = {
    Name = "r53-lab-igw"
  }
}

resource "aws_route_table" "rt_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags = {
    Name = "r53-lab-rt"
  }
}

resource "aws_route_table_association" "rta-a_b" {
  subnet_id      = aws_subnet.subnet1a_b.id
  route_table_id = aws_route_table.rt_b.id
}

resource "aws_route_table_association" "rta-b_b" {
  subnet_id      = aws_subnet.subnet1b_b.id
  route_table_id = aws_route_table.rt_b.id
}

resource "aws_route" "r_b" {
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw_b.id
  route_table_id            = aws_route_table.rt_b.id
  depends_on = [
    aws_route_table.rt_b
  ]
}

resource "aws_security_group" "sg_b" {
  name        = "sg"
  description = "sg"
  vpc_id      = aws_vpc.vpc_b.id

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
  resource "aws_network_interface" "eni1_b" {
    subnet_id       = aws_subnet.subnet1a_b.id
    description     = "web1-west eth0"
    private_ips     = ["172.9.0.10"]
    security_groups = [aws_security_group.sg_b.id]

  }

  resource "aws_eip" "web1-eip_b" {
    network_interface = aws_network_interface.eni1_b.id
    depends_on = [
      aws_internet_gateway.igw_b
    ]
  }

  resource "aws_instance" "web1-east_b" {
    ami           = local.region_b_ami # us-east-1
    key_name      = local.region_key_pair
    instance_type = "t2.micro"
    
    network_interface {
      network_interface_id = aws_network_interface.eni1_b.id
      device_index         = 0
      delete_on_termination = false
    }

    tags = {
      Name = "web1-west"
    }
  }

##
## Create web2-west instance
  resource "aws_network_interface" "eni2_b" {
    subnet_id       = aws_subnet.subnet1b_b.id
    description     = "web2-west eth0"
    private_ips     = ["172.9.1.20"]
    security_groups = [aws_security_group.sg_b.id]

  }

  resource "aws_eip" "web2-eip_b" {
    network_interface = aws_network_interface.eni2_b.id
    depends_on = [
      aws_internet_gateway.igw_b
    ]
  }

  resource "aws_instance" "web2-east_b" {
    ami           = local.region_b_ami # us-east-1
    key_name      = local.region_key_pair
    instance_type = "t2.micro"
    
    network_interface {
      network_interface_id = aws_network_interface.eni2_b.id
      device_index         = 0
      delete_on_termination = false
    }

    tags = {
      Name = "web2-west"
    }
  }
