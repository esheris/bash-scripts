#!/bin/bash
curl -O -k https://chef-server/chef-client.rpm
curl -O -k https://chef-server/validation.pem
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep instanceId | awk -F\" '{print $4}'`
INSTANCE=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}'`
sudo rpm -i chef-client.rpm
mkdir -p /etc/chef
sudo cp validation.pem /etc/chef/
sudo echo "node_name \""$1-$REGION-$2-$INSTANCE "\"" > /etc/chef/client.rb
sudo echo "chef_server_url \"https://54.68.195.174/\"" >> /etc/chef/client.rb
sudo echo "environment \"$2\""
sudo chef-client -o role[$1]
