provider "aws" {
  region = "ap-southeast-2"
}

#use data source to get a  registerd  amazonlinux2 ami

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "jenkin" {
#  ami           = "ami-043e0add5c8665836" cach nay la dung ami cua AM2 nhung ko duoc
  ami  = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = "keylab"
  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]

  # user_data = <<EOF
  #             #!/bin/bash
  #             sudo yum update –y
  #             sudo wget -O /etc/yum.repos.d/jenkins.repo \
  #   https://pkg.jenkins.io/redhat-stable/jenkins.repo
  #             sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
  #             sudo yum upgrade
  #             sudo amazon-linux-extras install java-openjdk11 -y
  #             sudo yum install jenkins -y
  #             sudo systemctl enable jenkins
  #             sudo systemctl start jenkins
  #           EOF
   tags = {
     Name = "jenkins-server"
   }

  
}
# an empty resource block 
resource "null_resource" "name" {
  #ssh into the EC2 instance
  connection {
    type          = "ssh"
    user          = "ec2-user"
    private_key   = file("/home/phuongvd/Desktop/k/keylab.pem")
    host          = aws_instance.jenkin.public_ip
  }
  
  # copy the  install jenkins.sh file  from your computer  to the EC2 Instance
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }
  # set permission and run the jenkins script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh",
    ]
  }
  # wait for ec2 to be created
  depends_on = [
     aws_instance.jenkin
   ]
}
resource "aws_security_group" "jenkins-sg" {
  name = "jenkins-sg"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-sg"
  }
}

# print the url of the jenkins server
output "website_url" {
  value  = join ("", ["http://", aws_instance.jenkin.public_dns, ":", "8080"])
}
