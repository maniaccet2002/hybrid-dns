#!/bin/bash -xe
# Configure Authentication Variables which are used below
DBName=${DBName}
DBUser=${DBUser}
DBPassword=${DBPassword}
DBEndpoint=${DBEndpoint}

# Install system software - including Web and DB
sudo yum update -y
sudo yum install -y mariadb-server httpd wget
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2


# Web and DB Servers Online - and set to startup

sudo systemctl enable httpd
sudo systemctl enable mariadb
sudo systemctl start httpd
sudo systemctl start mariadb

# Install Wordpress
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .
sudo rm -R wordpress
sudo rm latest.tar.gz

dns1_private_ip=${dns1_private_ip}
dns2_private_ip=${dns2_private_ip}
echo "DNS1=${dns1_private_ip}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DNS2=${dns2_private_ip}" >> /etc/sysconfig/network-scripts/ifcfg-eth0

# Configure Wordpress

sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php   
sudo chown apache:apache * -R
