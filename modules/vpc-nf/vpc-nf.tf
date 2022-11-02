#VPC and network
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "vpc_terraform2"
    environment = var.environment_tag
  }
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet_gw"
    Environment = var.environment_tag
  }
}

resource "aws_route" "route" {
  route_table_id            = aws_vpc.my_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.aws_internet_gateway.id
}

#Routing tables:
resource "aws_route_table" "fw_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
  }

  tags = {
    Name = "fw_rtb"
    environment = var.environment_tag
  }
}

resource "aws_route_table_association" "fw_rtb" {
  subnet_id      = aws_subnet.my_fw_subnet.id
  route_table_id = aws_route_table.fw_rtb.id
}

resource "aws_route_table" "int_rtb" {
  vpc_id = aws_vpc.my_vpc.id
/*
  Could not find support to create a route that points to a vpce. Used the "null_resource" instead

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id  = <<??>>
  }
*/
  tags = {
    Name = "int_rtb"
    environment = var.environment_tag
  }
}

resource "aws_route_table_association" "int_rtb" {
  subnet_id      = aws_subnet.my_internal_subnet.id
  route_table_id = aws_route_table.int_rtb.id
}


resource "aws_route_table" "vpc_rtb" {
  vpc_id = aws_vpc.my_vpc.id

/*
  Could not find support to create a route that points to a vpce. Used the "null_resource" instead

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = <<??>>
  }
*/
  tags = {
    Name = "vpc_rtb"
    environment = var.environment_tag

  }
}

resource "aws_subnet" "my_fw_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.fw_cidr_block

  tags = {
    Name = "my_fw_subnet"
    environment = var.environment_tag
  }
}

resource "aws_subnet" "my_internal_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.internal_cidr_block

  tags = {
    Name = "my_internal_subnet"
    environment = var.environment_tag
  }
}

#firewall
/*
resource "aws_networkfirewall_rule_group" "fw_rule" {
  capacity = 1000
  name     = "fwrule"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 5
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              source {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}
resource "aws_networkfirewall_firewall_policy" "fw_policy" {
  name = "fwpolicy"
  firewall_policy {
    stateless_default_actions = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
    stateless_rule_group_reference {
      priority     = 20
      resource_arn = aws_networkfirewall_rule_group.fw_rule.arn
    }
  }
}
resource "aws_networkfirewall_firewall" "fw" {
  firewall_policy_arn = aws_networkfirewall_firewall_policy.fw_policy.arn
  name                = "fw"
  vpc_id              = aws_vpc.my_vpc.id
  subnet_mapping {
    subnet_id          = aws_subnet.my_fw_subnet.id
  }
}

#Instances
#Sample instance
resource "aws_instance" "my_web01" {
  ami = var.web01_ami
  #private_ip = "10.0.10.10"
  associate_public_ip_address = true
  instance_type = var.instance_type
  subnet_id = aws_subnet.my_internal_subnet.id
  key_name = var.key_name
  security_groups = [aws_security_group.web01_sg.id]
  tags = {
    Name = "web1"
    environment = var.environment_tag

  }
}

#Sample Security Group

resource "aws_security_group" "web01_sg" {
  name        = "web01_sg"
  description = "web01_sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "ICMP ALL"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Instance01"
    Environment = var.environment_tag

  }
}

#Logging:

resource "aws_flow_log" "my_vpcflow_log" {
  iam_role_arn    = aws_iam_role.my_vpcflow_log_role.arn
  log_destination = aws_cloudwatch_log_group.my_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.my_vpc.id
}

resource "aws_cloudwatch_log_group" "my_log_group" {
  name = "my_log_group"
}

resource "aws_iam_role" "my_vpcflow_log_role" {
  name = "my_vpcflow_log"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "my_vpcflow_log_policy" {
  name = "my_vpcflow_log_policy"
  role = aws_iam_role.my_vpcflow_log_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


#Null Resources:
#I am using these for the things I could not find native support for from Terraform

# Get the vpce ID that is associated with the firewall

resource "null_resource" "get_vpce_id" {
  depends_on =[aws_networkfirewall_firewall.fw]
  provisioner "local-exec" {
    command = "aws network-firewall describe-firewall --firewall-name fw --query 'FirewallStatus.SyncStates.*.Attachment[].EndpointId' --output text > ${path.module}/vpce_id.txt"
  }
}

data "local_file" "vpce_id" {
  filename = "${path.module}/vpce_id.txt"
  depends_on = [null_resource.get_vpce_id]
}

#Set Edge Association 
resource "null_resource" "route_edge_association" {
  depends_on = [aws_route_table.vpc_rtb,aws_internet_gateway.aws_internet_gateway]
  provisioner "local-exec" {
    command = "aws ec2 associate-route-table --region us-east-1 --route-table-id ${aws_route_table.vpc_rtb.id} --gateway-id ${aws_internet_gateway.aws_internet_gateway.id}"
  }
}

#add routes to vpce

resource "null_resource" "add_route_internal" {
  depends_on = [aws_route_table.int_rtb,data.local_file.vpce_id]
  provisioner "local-exec" {
    command = "aws ec2 create-route --region us-east-1 --route-table-id ${aws_route_table.int_rtb.id} --destination-cidr-block 0.0.0.0/0 --vpc-endpoint-id ${data.local_file.vpce_id.content} >/tmp/route_internal.txt"
  }
}


resource "null_resource" "add_route_vpc" {
  depends_on = [aws_route_table.vpc_rtb,data.local_file.vpce_id]
  provisioner "local-exec" {
    command = "aws ec2 create-route --region us-east-1 --route-table-id ${aws_route_table.vpc_rtb.id} --destination-cidr-block 10.10.1.0/24 --vpc-endpoint-id ${data.local_file.vpce_id.content} >/tmp/route_vpc.txt"
  } 
}

}
*/