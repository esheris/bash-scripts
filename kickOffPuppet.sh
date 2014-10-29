#!/bin/bash
USER="USER"
ORG="ORG"
ORGUNIT="OU"
PCI="NO_PCI"
TYPE="APP"
PATCHEDVER="5.8"
CURRVER=`lsb_release -r | awk '{print $2}' | cut -c1`
SERVER=`uname -n`

#find out datacenter server is located in based on nslookup IP to set mountpoints and puppetmaster
SRVLOCATION=`/usr/bin/nslookup ${SERVER} | /bin/grep Address: | /usr/bin/tail -1 | /bin/cut -d. -f2`
case $SRVLOCATION in
 15*) puppetMaster=<puppetmaster1>; nfs_server_infra="<nfsshare1>"; nfs_server_depot="<nfs2share1>";;
 14*) puppetMaster=<puppetmaster2>; nfs_server_infra="<nfsshare2>"; nfs_server_depot="<nfs2share2>";;
   *) puppetMaster=<puppetmaster3>; nfs_server_infra="<nfsshare3>"; nfs_server_depot="<nfs2share3>";;
esac

#copy correct resolv.conf settings.
/bin/cp -f /etc/resolv.conf /etc/resolv.conf.bak
/bin/cp -f /etc/resolv.conf.prod /etc/resolv.conf
#Fix the TMO repo because it’s pointing to an old server
sed -i 's/<oldserver>/<newserver>/g' /etc/yum.repos.d/<repofile>

#mount nfs/infra so we can install the puppet agent
echo "$nfs_server_infra /nfs/infra nfs ro,nosuid,soft 0 0" >> /etc/fstab
mkdir -p /nfs/infra
echo "$nfs_server_depot /depot/linux_x86 nfs ro,nosuid,soft 0 2" >> /etc/fstab
mkdir -p /depot/linux_x86
mount -a

# install puppet prereqs if oel5
if [ $CURRVER -eq 5 ]
then
yum --enablerepo=* install -y pkgconfig
yum install -y /nfs/infra/virt-what-1.11-2.el5.x86_64.rpm
fi

/nfs/infra/install_puppet -I

mkdir -p /etc/puppetlabs/facter/facts.d/
cat >/etc/puppetlabs/facter/facts.d/build.txt << EOF
organization=$ORG
organizational_unit=$ORGUNIT
pci=$PCI
server_type=$TYPE
oel_version=$PATCHEDVER
EOF

ssh $USER@$puppetMaster "pmksh -c 'puppet cert sign `hostname`'"

puppet agent -t --environment=puppet_build_branch
