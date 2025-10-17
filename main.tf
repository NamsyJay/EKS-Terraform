provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "DefaultVPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "DefaultVPC"
  }
}

resource "aws_subnet" "lancash_subnet" {
  count = 2
  vpc_id                  = aws_vpc.DefaultVPC.id
  cidr_block              = cidrsubnet(aws_vpc.DefaultVPC.cidr_block, 8, count.index)
  availability_zone       = element(["eu-west-2a", "eu-west-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "lancash-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "lancash_igw" {
  vpc_id = aws_vpc.DefaultVPC.id

  tags = {
    Name = "lancash-igw"
  }
}

resource "aws_route_table" "lancash_route_table" {
  vpc_id = aws_vpc.DefaultVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lancash_igw.id
  }

  tags = {
    Name = "lancash-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.lancash_subnet[count.index].id
  route_table_id = aws_route_table.lancash_route_table.id
}

resource "aws_security_group" "Container-SG" {
  vpc_id = aws_vpc.DefaultVPC.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Container-SG"
  }
}

resource "aws_security_group" "Master-SG" {
  vpc_id = aws_vpc.DefaultVPC.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Container-SG"
  }
}

resource "aws_eks_cluster" "lancash" {
  name     = "lancash"
  role_arn = aws_iam_role.lancash_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.devopsshack_subnet[*].id
    security_group_ids = [aws_security_group.Container-SG.id]
  }
}

resource "aws_eks_node_group" "lancash" {
  cluster_name    = aws_eks_cluster.lancash.name
  node_group_name = "lancash-node-group"
  node_role_arn   = aws_iam_role.lancash_node_group_role.arn
  subnet_ids      = aws_subnet.lancash_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.devopsshack_node_sg.id]
  }
}

resource "aws_iam_role" "lancash" {
  name = "lancash"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::327902804526:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lancash_cluster_role_policy" {
  role       = aws_iam_role.lancash_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "lancash_node_group_role" {
  name = "lancash-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lancash_node_group_role_policy" {
  role       = aws_iam_role.lancash_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "lancash_node_group_cni_policy" {
  role       = aws_iam_role.lancash_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "lancash_node_group_registry_policy" {
  role       = aws_iam_role.lancash_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
