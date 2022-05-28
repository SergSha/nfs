#!/bin/bash

# Install NFS utilites

yum -y install nfs-utils

# Enable and start firewalld

systemctl start firewalld
systemctl enable firewalld

# Add firewall rules

firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent

firewall-cmd --reload

# Enable and start NFS

systemctl start nfs
systemctl enable nfs

# Create and set up a directory for share

mkdir -p /srv/share/upload
chown -R nfsnobody: /srv/share
chmod 0777 /srv/share/upload

# Create a file /etc/exports

cat << EOF > /etc/exports
/srv/share 192.168.50.11(rw,sync,root_squash)
EOF

# Export directory for share

exportfs -r
