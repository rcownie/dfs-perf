#!/bin/sh

if [ -x /usr/bin/yum ]; then
  packageManager="yum -y"
else
  packageManager="apt-get -y"
fi

if [ ! -d /usr/lib/jvm/default-java ]; then
  echo "Install default-jre-headless ..."
  sudo $packageManager install default-jre-headless
fi

if [ ! -x /usr/bin/fusermount ]; then
  echo "Install fuse3 ..."
  sudo $packageManager install fuse3
fi

if [ ! -f /sbin/mount.flexfs ]; then
  echo "Install flexfs ..."
  if [ `arch` = "x86_64" ]; then
    curl https://get.flexfs.io/latest/linux/amd64/mount.flexfs -o mount.flexfs
  elif [ `arch` = "aarch64" ]; then
    curl https://get.flexfs.io/latest/linux/arm64/mount.flexfs -o mount.flexfs    
  fi
  chmod +x mount.flexfs
  sudo mv mount.flexfs /sbin
fi

echo "Init flexfs volumes ..."
sudo mount.flexfs init --token 36a700e5-dcf3-41f4-a476-230424caf13b
sudo mount.flexfs init --token 290ee58d-4330-43f4-b97b-588257d1959c

if [ ! -d /flexfs ]; then
  echo "mkdir /flexfs ..."
  sudo mkdir /flexfs
  sudo chmod a+rwx /flexfs
fi
if [ ! -d /flexfs/base ]; then
  echo "mkdir /flexfs/base ..."
  sudo mkdir /flexfs/base
  sudo chmod a+rwx /flexfs/base
fi
if [ ! -d /flexfs/plus ]; then
  echo "mkdir /flexfs/plus ..."
  sudo mkdir /flexfs/plus
  sudo chmod a+rwx /flexfs/plus
fi

grep benchmark-base /etc/fstab >/dev/null || \
  sudo echo "benchmark-base /flexfs/base flexfs _netdev,nofail,noauto 0 0" >>/etc/fstab
grep benchmark-plus /etc/fstab >/dev/null || \
  sudo echo "benchmark-plus /flexfs/plus flexfs _netdev,nofail,noauto 0 0" >>/etc/fstab

echo "Mount flexfs volumes ..."
sudo mount /flexfs/base
#sudo mount /flexfs/plus

exit 0


