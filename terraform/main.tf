variable "git_pwd" {
      type = "string"
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "allow_all_jenkins" {
  name        = "allow_all_jenkins"
  description = "Allow all inbound/outbound traffic"
  
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all_jenkins"
  }
}

resource "aws_instance" "jenkins-server" {
  ami = "ami-657bd20a" 
  availability_zone = "eu-central-1a"  
  instance_type = "t2.medium"
  key_name = "aws-demo"
  vpc_security_group_ids = ["${aws_security_group.allow_all_jenkins.id}"]
  
  user_data = <<-EOF
              #!/bin/bash
              yum -y update
              yum -y install git
              yum -y groupinstall "Development Tools"
              yum -y install java-1.8.0
              yum -y remove java-1.7.0-openjdk
              yum -y install docker
              service docker start
              usermod -a -G docker ec2-user
              newgrp docker
              mkdir -p /home/ec2-user/jenkins_home
              chown -R ec2-user:ec2-user /home/ec2-user/jenkins_home
              chown -R 1000:1000 /home/ec2-user/jenkins_home
              # git before or after?
              git clone https://edigonzales:${var.git_pwd}@bitbucket.org/edigonzales/aws-jenkins-server-config.git /home/ec2-user/jenkins_home
              sudo -u ec2-user docker run -dit --restart unless-stopped -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /home/ec2-user/jenkins_home:/var/jenkins_home sogis/jenkins-docker 
              chown -R 1000:1000 /home/ec2-user/jenkins_home
              EOF

  tags {
    Name = "jenkins-server"
  }
}

output "ec2-ip" {
  value = "${aws_instance.jenkins-server.public_ip}"  
}