resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public"{
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.main.id
    route {
        cidr_block="0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public_assoc"{
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "sg"{
    vpc_id = aws_vpc.main.id

    ingress{
        from_port = 22
        to_port = 22
        protocol ="tcp"
        cidr_blocks = ["149.13.192.33/32"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol ="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
        from_port = 0 
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "ubuntu"{
    ami = "ami-091138d0f0d41ff90"
    instance_type = "t3.large"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.sg.id]
    associate_public_ip_address = true
    tags = {
        Name = "ubuntu-devops-t3.large"
    }
    key_name = "devops-key"
    user_data = <<-EOF
#!/bin/bash

apt update -y
apt install -y nginx wget tar curl software-properties-common

########################
# NGINX
########################
systemctl start nginx
systemctl enable nginx

cat <<EOT > /var/www/html/index.html
<h1>Salut din Terraform + DevOps Stack 🚀</h1>
EOT

########################
# NODE EXPORTER
########################
useradd -rs /bin/false node_exporter

cd /opt
wget 
https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-*.linux-amd64.tar.gz
tar xvf node_exporter-*.linux-amd64.tar.gz
mv node_exporter-* node_exporter

cat <<EOT > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=default.target
EOT

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

########################
# PROMETHEUS
########################
useradd -rs /bin/false prometheus

cd /opt
wget 
https://github.com/prometheus/prometheus/releases/latest/download/prometheus-*.linux-amd64.tar.gz
tar xvf prometheus-*.linux-amd64.tar.gz
mv prometheus-* prometheus

cat <<EOT > /etc/prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "node"
    static_configs:
      - targets: ["localhost:9100"]
EOT

cat <<EOT > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
ExecStart=/opt/prometheus/prometheus --config.file=/etc/prometheus.yml

[Install]
WantedBy=default.target
EOT

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

########################
# GRAFANA
########################
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

apt update -y
apt install -y grafana

systemctl enable grafana-server
systemctl start grafana-server

EOF
}

