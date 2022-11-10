#!/usr/bin/env bash
StartTime=$(date '+%H:%M:%S')
echo "INICIO: $StartTime"
read -p "Pressione qualquer tecla para iniciar a migração..."
HostnameVar=$(hostname -s)
Patrimonio="${HostnameVar:6:8}"
deviceType="${HostnameVar:5:1}"
userName=$USER
tmpMACOSDir="/Users/${userName}/temp/MACOS"
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

main() {
    if ! ${HostnameVar:0:9} -eq "ENCSABCAM"; then
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
        log_step "Novo dispositivo: ${NovoHostName}"
        echo ""
        log_step "Alterando hostname..."
        if ! sudo scutil --set ComputerName "$NovoHostName" >/dev/null; then
            exit_fatal "Falha ao alterar hostname: ${NovoHostName}"
        fi
        if ! sudo scutil --set HostName "$NovoHostName" >/dev/null; then
            exit_fatal "Falha ao alterar hostname: ${NovoHostName}"
        fi
        if ! sudo scutil --set LocalHostName "$NovoHostName" >/dev/null; then
            exit_fatal "Falha ao alterar hostname: ${NovoHostName}"
        fi
    else
        log_step "Hostname já alterado."
    fi

    log_step "Desinstalando KACE"
    if ! sudo /Library/Application\ Support/Quest/KACE/bin/AMPTools uninstall; then
        log_error "Falha ao desinstalar KACE"
    fi

    log_step "Desinstalando ATP"
    if ! sudo /usr/local/McAfee/uninstall ATP; then
        log_error "Falha ao desinstalar ATP"
    fi
    log_step "Desinstalando EPM"
    if ! sudo /usr/local/McAfee/uninstall EPM; then
        log_error "Falha ao desinstalar EPM"
    fi
    cd /
    log_step "Desinstalando McAfee Agent"
    if ! sudo /Library/McAfee/agent/scripts/uninstall.sh; then
        log_error "Falha ao desinstalar McAfee Agent"
    fi

    log_step "Criando pasta temporária."
    if mkdir -p "${tmpMACOSDir}"; then
        cd "${tmpMACOSDir}" || exit
    else
        exit_fatal "Falha ao criar diretório: ${tmpMACOSDir}"
    fi

    declare -a links
    links[0]="https://github.com/Gianlucas94/Migration/raw/main/macos/UEMS_MacAgent.pkg"
    links[1]="https://github.com/Gianlucas94/Migration/raw/main/macos/CompanyPortal-Installer.pkg"
    links[2]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/macos/serverinfo.plist"
    links[3]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/macos/DMRootCA.crt"

    log_step "Baixando arquivos de configuração..."
    for link in "${!links[@]}"; do
        if ! curl -OL "${links[$link]}"; then
            exit_fatal "Falha ao baixar arquivo do link: ${links[$link]}"
        fi
    done

    log_step "Instalando Company Portal"
    if ! sudo installer -pkg "${tmpMACOSDir}/CompanyPortal-Installer.pkg" -target /; then
        exit_fatal "Falha ao instalar o Company Portal"
    fi

    log_step "Instalando Manage Engine"
    if ! sudo installer -pkg "${tmpMACOSDir}/UEMS_MacAgent.pkg" -target /; then
        exit_fatal "Falha ao instalar o Manage Engine"
    fi
    : '
    log_step "Aguardando o ZScaler e o Defender serem instalados"
    until [ -d /opt/zscaler ] && [ -d /opt/microsoft ]; do
        spinner="/|\\-/|\\-"
        for i in $(seq 0 7); do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 1
        done
    done
    log_step "ZScaler e Defender instalados" >/dev/null

    log_step "Fazendo Backup do nsswitch.conf..."
    if ! cp /etc/nsswitch.conf nsswitch.bak; then
        log_error "Falha ao criar o backup do nsswitch.conf"
    fi

    log_step "Resolvendo o problema do DNS..."
    if ! cat dns.txt > /etc/nsswitch.conf; then
        log_error "Falha ao escrever no arquivo: /etc/nsswitch.conf"
    fi

    log_step "Reiniciando gerenciadores de rede..."
    declare -A networkmanagers
    networkmanagers[0]="network-manager"
    networkmanagers[1]="NetworkManager"
    networkmanagers[2]="systemd-networkd"
    echo ""
    for networkmanager in "${!networkmanagers[@]}"; do
        if ! systemctl restart "${networkmanagers[$networkmanager]}" >/dev/null; then
            log_error "Falha ao reiniciar o ${networkmanagers[$networkmanager]}"
            echo ""
        else
            log_positive "${networkmanagers[$networkmanager]} reiniciado com sucesso."
        fi
    done
'

    log_step "Apagando pasta Temp"
    if ! rm -rf /home/${userName}/temp/linux; then
        log_error "Falha ao deletar a pasta Temp"
    fi

    exit_success "Script executado com sucesso!"
}

exit_success() {
    local message="$1"
    local green="\033[1;32m"
    local color_off="\033[0m"
    local EndTime=$(date '+%H:%M:%S')
    echo -e "\n${green}${message}${color_off}\n"
    echo -e "Serial Number: $serialNumber"
    echo -e "Hostname: $NovoHostName"
    echo -e "FINALIZADO: $EndTime"
    exit 0
}

log_error() {
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

log_step() {
    local message="$1"
    local yellow="\033[0;33m"
    local color_off="\033[0m"
    echo -e "\n${yellow}${message}${color_off}\n"
}

log_positive() {
    local message="$1"
    local green="\033[0;32m"
    local color_off="\033[0m"
    echo -e "\n${green}${message}${color_off}\n"
}

main
