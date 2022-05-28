<h3>### NFS ###</h3>

<h4>Описание домашнего задания</h4>

<ul>
<li>vagrant up должен поднимать 2 виртуалки: сервер и клиент;</li>
<li>на сервер должна быть расшарена директория;</li>
<li>на клиента она должна автоматически монтироваться при старте (fstab или autofs);</li>
<li>в шаре должна быть папка upload с правами на запись;</li>
<li>требования для NFS: NFSv3 по UDP, включенный firewall.</li>
<li>Настроить аутентификацию через KERBEROS (NFSv4)</li>
</ul>

<h4># Создадим виртуальные машины nfss (nfs-сервер) и nfsc (nfs-клиент)</h4>

<p>В домашней директории создадим директорию nfs, в котором будут храниться настройки виртуальных машин:</p>

<pre>[student@pv-homeworks1-10 sergsha]$ mkdir ./nfs
[student@pv-homeworks1-10 sergsha]$</pre>

<p>Перейдём в директорию nfs:</p>

<pre>[student@pv-homeworks1-10 sergsha]$ cd ./nfs/
[student@pv-homeworks1-10 nfs]$</pre>

<p>Создадим файл Vagrantfile:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vi ./Vagrantfile</pre>

<p>Заполним следующим содержимым:</p>

<pre># -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

#  config.vm.provision "ansible" do |ansible|
#    ansible.verbose = "vvv"
#    ansible.playbook = "playbook.yml"
#    ansible.become = "true"
#  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
  end

  config.vm.define "nfss" do |nfss|
    nfss.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "net1"
    nfss.vm.hostname = "nfss"
    nfss.vm.provision "shell", path: "nfss_script.sh"
  end

  config.vm.define "nfsc" do |nfsc|
    nfsc.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "net1"
    nfsc.vm.hostname = "nfsc"
    nfsc.vm.provision "shell", path: "nfsc_script.sh"
  end

end
</pre>

<p>Создадим ещё два скрипта nfss_script.sh и nfsc_script.sh:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vi ./nfss_script.sh</pre>

<pre>#!/bin/bash

# Install NFS utilites

yum -y install nfs-utils

# Enable and start firewalld

systemctl start firewalld
systemctl enable firewalld -f

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

cat<<EOF>/etc/exports
/srv/share 192.168.50.11(rw,sync,root_squash)
EOF

# Export directory for share

exportfs -r
</pre>

<pre>[student@pv-homeworks1-10 nfs]$ vi ./nfsc_script.sh</pre>

<pre>#!/bin/bash

# Install NFS utilites

yum -y install nfs-utils

# Enable and start firewalld

systemctl start firewalld
systemctl enable firewalld

# Add line to /etc/fstab

echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

# Reload daemons

systemctl daemon-reload
systemctl restart remote-fs.target
</pre>

<p>Запустим эти две виртуальные машины:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant up</pre>

<p>Проверим состояние созданных и запущенных машин:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
[student@pv-homeworks1-10 nfs]$</pre>

<h4># Проверка работоспособности</h4>

<p>Заходим на сервер nfss:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant ssh nfss
[vagrant@nfss ~]$</pre>

<p>Заходим в каталог /srv/share/upload:</p>

<pre>[vagrant@nfss ~]$ cd /srv/share/upload/
[vagrant@nfss upload]$</pre>

<p>Создадим тестовый файл check_file:</p>

<pre>[vagrant@nfss upload]$ touch check_file
[vagrant@nfss upload]$</pre>

<p>Проверим, что созданный файл check_file существует:</p>

<pre>[vagrant@nfss upload]$ ls -l ./check_file
-rw-rw-r--. 1 vagrant vagrant 0 May 27 12:56 ./check_file
[vagrant@nfss upload]$</pre>

<p>Заходим на клиентскую машину nfsc:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant ssh nfsc
[vagrant@nfsc ~]$</pre>

<p>Заходим в каталог /mnt/upload:</p>

<pre>[vagrant@nfsc ~]$ cd /mnt/upload/
[vagrant@nfsc upload]$</pre>

<p>Проверим наличие ранее созданного файла check_file:</p>

<pre>[vagrant@nfsc upload]$ ls -l ./check_file
-rw-rw-r--. 1 vagrant vagrant 0 May 27 12:56 ./check_file
[vagrant@nfsc upload]$</pre>

<p>Создадим новый тестовый файл client_file:</p>

<pre>[vagrant@nfsc upload]$ touch client_file
[vagrant@nfsc upload]$</pre>

<p>Убедимся, что файл client_file успешно создан:</p>

<pre>[vagrant@nfsc upload]$ ls -l ./client_file
-rw-rw-r--. 1 vagrant vagrant 0 May 27 13:57 ./client_file
[vagrant@nfsc upload]$</pre>

<p>Вышеуказанные проверки прошли успешно, значит проблем с правами нет.</p>

<h4>Проверяем сервер nfss.</h4>

<p>Заходим на сервер в отдельном окне терминала:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant ssh nfss
Last login: Fri May 27 12:52:03 2022 from 10.0.2.2
[vagrant@nfss ~]$</pre>

<p>Перезагружаем сервер:</p>

<pre>[vagrant@nfss ~]$ sudo shutdown -r now
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
[student@pv-homeworks1-10 nfs]$</pre>

<p>Снова заходим на сервер nfsc:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant ssh nfss
Last login: Fri May 27 14:04:32 2022 from 10.0.2.2
[vagrant@nfss ~]$</pre>

<p>Проверяем наличие файлов в каталоге /srv/share/upload/:</p>

<pre>[vagrant@nfss ~]$ ls -l /srv/share/upload/
total 0
-rw-rw-r--. 1 vagrant vagrant 0 May 27 12:56 check_file
-rw-rw-r--. 1 vagrant vagrant 0 May 27 13:57 client_file
[vagrant@nfss ~]$</pre>

<p>Проверим статус сервера NFS:</p>

<pre>[vagrant@nfss ~]$ systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Fri 2022-05-27 14:09:17 UTC; 8min ago
  Process: 810 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 786 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 781 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 786 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service
[vagrant@nfss ~]$</pre>

<p>Проверим статус FirewallD:</p>

<pre>[vagrant@nfss ~]$ systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2022-05-27 14:09:08 UTC; 10min ago
     Docs: man:firewalld(1)
 Main PID: 408 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─408 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid
[vagrant@nfss ~]$</pre>

<p>Проверяем экспорты:</p>

<pre>[vagrant@nfss ~]$ sudo exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[vagrant@nfss ~]$</pre>

<p>Проверяем работу RPC:</p>

<pre>[vagrant@nfss ~]$ showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[vagrant@nfss ~]$</pre>

<h4>Проверяем клиент nfsc.</h4>

<p>Возвращаемся в терминал клиентской машины nfsc и перезагружаем:</p>

<pre>[vagrant@nfsc upload]$ sudo shutdown -r now
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
[student@pv-homeworks1-10 nfs]$</pre>

<p>Снова заходим:</p>

<pre>[student@pv-homeworks1-10 nfs]$ vagrant ssh nfsc
Last login: Fri May 27 14:10:28 2022 from 10.0.2.2
[vagrant@nfsc ~]$</pre>

<p>Проверяем работу RPC:</p>

<pre>[vagrant@nfsc ~]$ showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[vagrant@nfsc ~]$</pre>

<p>Заходим в каталог /mnt/upload:</p>

<pre>[vagrant@nfsc ~]$ cd /mnt/upload/
[vagrant@nfsc upload]$</pre>

<p>Проверяем статус монтирования:</p>

<pre>[vagrant@nfsc upload]$ mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=21,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10877)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[vagrant@nfsc upload]$</pre>

<p>Проверяем наличие ранее созданных файлов:</p>

<pre>[vagrant@nfsc upload]$ ls -l
total 0
-rw-rw-r--. 1 vagrant vagrant 0 May 27 12:56 check_file
-rw-rw-r--. 1 vagrant vagrant 0 May 27 13:57 client_file
[vagrant@nfsc upload]$</pre>

<p>Создаём тестовый файл final_check:</p>

<pre>[vagrant@nfsc upload]$ touch final_check
[vagrant@nfsc upload]$</pre>

<p>Проверяем, что файл final_check успешно создан:</p>

<pre>[vagrant@nfsc upload]$ ls -l ./final_check
-rw-rw-r--. 1 vagrant vagrant 0 May 27 15:41 ./final_check
[vagrant@nfsc upload]$</pre>

<p>Вышеуказанные проверки прошли успешно, значит демонстрационный стенд работоспособен и готов к работе.</p>
