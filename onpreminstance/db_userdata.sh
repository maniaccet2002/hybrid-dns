#!/bin/bash -xe
# STEP 1 - Configure Authentication Variables which are used below
DBName=${DBName}
DBUser=${DBUser}
DBPassword=${DBPassword}
DBRootPassword=${DBRootPassword}
APPServerDns=${APPServerDns}
APPServerIP=${APPServerIP}

sudo yum update -y
sudo yum install -y mariadb-server

sudo systemctl enable mariadb
sudo systemctl start mariadb

mysqladmin -u root password $DBRootPassword

echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'$APPServerDns' IDENTIFIED BY '$DBPassword' ;" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'$APPServerIP' IDENTIFIED BY '$DBPassword' ;" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup