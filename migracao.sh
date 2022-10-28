#!/bin/bash
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

##Desinstalando KACE e McAfee
sudo bash /opt/McAfee/agent/scripts/uninstall.sh
sudo /opt/quest/kace/bin/AMPTools uninstall

##Instalando Manage Engine
userName=$USER
mkdir /home/$userName/temp/linux/
cd /home/$userName/temp/linux/
wget --no-check-certificate --content-disposition https://github.com/Gianlucas94/Migration/blob/main/UEMS_LinuxAgent.bin?raw=true
wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/Gianlucas94/Migration/main/serverinfo.json
wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/Gianlucas94/Migration/main/dns.txt
chmod +x UEMS_LinuxAgent.bin
./UEMS_LinuxAgent.bin

##Verificando se os Microsoft Defender e ZScaler Foram instalados
echo "Verificando se o ZScaler e o Defender foram instalados"
until [ -d /opt/zscaler ] && [ -d /opt/microsoft ] 
do
     sleep 5
done
echo "ZScaler e Defender instalados" >/dev/null

##Resolvendo o problema do DNS
cat dns.txt > /etc/nsswitch.conf
systemctl restart network-manager