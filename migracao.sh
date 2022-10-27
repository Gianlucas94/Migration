#!/bin/bash
sudo su
apt-get install systemd

##GERANDO NOVO NOME
HostnameVar=$HOSTNAME >/dev/null
Patrimonio=$(echo ${HostnameVar:6:8}) >/dev/null
deviceType=$(echo ${HostnameVar:5:1}) >/dev/null
if [ "$deviceType" = "N" ]
then
    deviceType="LT"
fi
if [ "$deviceType" = "D" ]
 then
    deviceType="DT"
fi
NovoHostName="ENCSABCAM$deviceType$Patrimonio" >/dev/null
echo Esse e o novo  $NovoHostName

##ALTERANDO O HOSTNAME
hostnamectl set-hostname "$NovoHostName" >/dev/null
hostnamectl set-hostname "$NovoHostName" >/dev/null

##Desinstalando KACE e McAfee
sudo bash /opt/McAfee/agent/scripts/uninstall.sh
sudo /opt/quest/kace/bin/AMPTools uninstall

cd /home/logindousuario/temp/linux/

chmod +x UEMS_LinuxAgent.bin
./UEMS_LinuxAgent.bin