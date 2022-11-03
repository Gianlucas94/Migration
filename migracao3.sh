#!/usr/bin/env bash
StartTime=$(date '+%H:%M:%S')
echo "INICIO: $StartTime"
read -p "Pressione qualquer tecla para iniciar a migração..."
HostnameVar=$HOSTNAME
Patrimonio="${HostnameVar:6:8}"
deviceType="${HostnameVar:5:1}"
userName=$USER
tmpLinuxDir="/home/${userName}/temp/linux"

main() {
    log_status "Instalando systemd..."
    if ! apt-get -y install systemd; then
        exit_fatal "Falha ao instalar systemd"
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
        exit_fatal "Falha ao alterar hostname: ${NovoHostName}"
    fi

    log_status "Desinstalando KACE e McAfee..."
    if ! sudo bash /opt/McAfee/agent/scripts/uninstall.sh; then
        exit_error "Falha ao desinstalar KACE"
    fi

    if ! sudo /opt/quest/kace/bin/AMPTools uninstall; then
        exit_error "Falha ao desinstalar McAfee"
    fi

    log_status "Instalando Manage Engine..."
    if mkdir -p "${tmpLinuxDir}"; then
        cd "${tmpLinuxDir}" || exit
    else
        exit_fatal "Falha ao criar diretório: ${tmpLinuxDir}"
    fi

    declare -A links
    links[0]="https://github.com/Gianlucas94/Migration/blob/main/UEMS_LinuxAgent.bin?raw=true"
    links[1]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/serverinfo.json"
    links[2]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/dns.txt"

    log_status Baixando arquivos de configuração...
    for link in "${!links[@]}"; do
        if ! wget --no-check-certificate --content-disposition "${links[$link]}"; then
            exit_fatal "Falha ao baixar arquivo do link: ${links[$link]}"
        fi
    done

    log_status "Tranformando arquivo UEMS_LinuxAgent.bin em executável..."
    if ! chmod +x UEMS_LinuxAgent.bin; then
        exit_fatal "Falha ao transformar arquivo UEMS_LinuxAgent.bin em executável"
    fi

    log_status "Executando UEMS_LinuxAgent.bin"
    if ! ./UEMS_LinuxAgent.bin; then
        exit_fatal "Falha ao executar UEMS_LinuxAgent.bin"
    fi

    log_status "Aguardando o ZScaler e o Defender serem instalados"
    until [ -d /opt/zscaler ] && [ -d /opt/microsoft ]; do
        spinner="/|\\-/|\\-"
        for i in $(seq 0 7); do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 1
        done
    done
    log_status "ZScaler e Defender instalados" >/dev/null

    log_status "Fazendo Backup do nsswitch.conf..."
    if ! cp /etc/nsswitch.conf nsswitch.bak; then
        exit_error "Falha ao criar o backup do nsswitch.conf"
    fi

    log_status "Resolvendo o problema do DNS..."
    if ! cat dns.txt >/etc/nsswitch.conf; then
        exit_error "Falha ao escrever no arquivo: /etc/nsswitch.conf"
    fi

    log_status "Reiniciando gerenciadores de rede..."
    declare -A networkmanagers
    networkmanagers[0]="network-manager"
    networkmanagers[1]="NetworkManager"
    networkmanagers[2]="systemd-networkd"
    echo ""
    for networkmanager in "${!networkmanagers[@]}"; do
        if ! systemctl restart "${networkmanagers[$networkmanager]}" >/dev/null; then
            exit_error "Falha ao reiniciar o ${networkmanagers[$networkmanager]}"
            echo ""
        fi
    done

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
    local EndTime=$(date '+%H:%M:%S')
    echo -e "\n${green}${message}${color_off}\n"
    echo -e "FINALIZADO: $EndTime"
    exit 0
}

exit_error() {
    local message="$1"
    local red="\033[0;31m"
    local color_off="\033[0m"
    echo -e "\n${red}${message}${color_off}\n"
}

exit_fatal() {
    local message="$1"
    local red="\033[0;31m"
    local color_off="\033[0m"
    echo -e "\n${red}${message}${color_off}\n"
    exit 1
}

log_status() {
    local message="$1"
    local yellow="\033[0;33m"
    local color_off="\033[0m"
    echo -e "\n${yellow}${message}${color_off}\n"
}

main
