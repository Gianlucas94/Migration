#!/usr/bin/env bash
read -p "Pressione qualquer tecla para iniciar a migração..."
HostnameVar=$HOSTNAME
Patrimonio="${HostnameVar:6:8}"
deviceType="${HostnameVar:5:1}"
userName=$USER
tmpLinuxDir="/home/${userName}/temp/linux"

main() {
    log_status "Instalando systemd..."
    if ! apt-get install systemd; then
        exit_error "Falha ao instalar systemd"
    fi

    log_status "Verificando tipo de dispositivo..."
    case "${deviceType}" in
    "N")
        deviceType="LT"
        ;;
    "D")
        deviceType="DT"
        ;;
    esac

    NovoHostName="ENCSABCAM${deviceType}${Patrimonio}"
    log_status "Novo dispositivo: ${NovoHostName}"

    log_status "Alterando hostname..."
    if ! hostnamectl set-hostname "$NovoHostName" >/dev/null; then
        exit_error "Falha ao alterar hostname: ${NovoHostName}"
    fi

    log_status "Desinstalando KACE e McAfee..."
    if ! sudo bash /opt/McAfee/agent/scripts/uninstall.sh; then
        exit_error "Falha ao desinstalar McAfee"
    fi

    if ! sudo /opt/quest/kace/bin/AMPTools uninstall; then
        exit_error "Falha ao desinstalar McAfee"
    fi

    log_status "Instalando Manage Engine..."
    if mkdir -p "${tmpLinuxDir}"; then
        cd "${tmpLinuxDir}" || exit
    else
        exit_error "Falha ao criar diretório: ${tmpLinuxDir}"
    fi

    declare -A links
    links[0]="https://github.com/Gianlucas94/Migration/blob/main/UEMS_LinuxAgent.bin?raw=true"
    links[1]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/serverinfo.json"
    links[2]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/dns.txt"

    log_status Baixando arquivos de configuração...
    for link in "${!links[@]}"; do
        if ! wget --no-check-certificate --content-disposition "${links[$link]}"; then
            exit_error "Falha ao baixar arquivo do link: ${links[$link]}"
        fi
    done

    log_status "Tranformando arquivo UEMS_LinuxAgent.bin em executável..."
    if ! chmod +x UEMS_LinuxAgent.bin; then
        exit_error "Falha ao transformar arquivo UEMS_LinuxAgent.bin em executável"
    fi

    log_status "Executando UEMS_LinuxAgent.bin"
    if ! ./UEMS_LinuxAgent.bin; then
        exit_error "Falha ao executar UEMS_LinuxAgent.bin"
    fi

    log_status "Verificando se o ZScaler e o Defender foram instalados"
    until [ -d /opt/zscaler ] && [ -d /opt/microsoft ]; do
        spinner="/|\\-/|\\-"
            for i in $(seq 0 7); do
                echo -n "${spinner:$i:1}"
                echo -en "\010"
                sleep 1
        done
    done
    exit_sucess "ZScaler e Defender instalados" >/dev/null

    log_status "Resolvendo o problema do DNS..."
    if ! cat dns.txt >/etc/nsswitch.conf; then
        exit_error "Falha ao escrever no arquivo: /etc/nsswitch.conf"
    fi

    log_status "Reiniciando gerenciador de rede..."
    if ! systemctl restart network-manager; then
        exit_error "Falha ao reiniciar gerenciador de rede"
    fi

    log_status "Apagando pasta Temp"
    if ! rm -rf /home/${userName}/temp/linux; then
        exit_error "Falha ao deletar a pasta Temp"
    fi

    exit_success "Script executado com sucesso!"
}

exit_success() {
    local message="$1"
    local green="\033[0;32m"
    local color_off="\033[0m"
    echo -e "\n${green}${message}${color_off}\n"
    exit 0
}

exit_error() {
    local message="$1"
    local red="\033[0;31m"
    local color_off="\033[0m"
    echo -e "\n${red}${message}${color_off}\n"
}

log_status() {
    local message="$1"
    local yellow="\033[0;33m"
    local color_off="\033[0m"
    echo -e "\n${yellow}${message}${color_off}\n"
}

main