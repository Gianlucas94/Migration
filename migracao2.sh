#!/usr/bin/env bash
read -p "Pressione qualquer tecla para iniciar a migração..."
HostnameVar=$HOSTNAME
Patrimonio="${HostnameVar:6:8}"
deviceType="${HostnameVar:5:1}"
userName=$USER
tmpLinuxDir="/home/${userName}/temp/linux"

main() {


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
    exit 0
}

log_status() {
    local message="$1"
    local yellow="\033[0;33m"
    local color_off="\033[0m"
    echo -e "\n${yellow}${message}${color_off}\n"
}

main
