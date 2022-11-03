#!/usr/bin/env bash
userName=$USER
tmpLinuxDir="/home/${userName}/temp/linux"

main() {

    declare -A links
    links[0]="https://raw.githubusercontent.com/Gianlucas94/Migration/main/dns.txt"

    log_status Baixando arquivos de configuração...
    for link in "${!links[@]}"; do
        if ! wget --no-check-certificate --content-disposition "${links[$link]}"; then
            exit_error "Falha ao baixar arquivo do link: ${links[$link]}"
        fi
    done

    log_status "Resolvendo o problema do DNS..."
    if ! cat dns.txt >/etc/nsswitch.conf; then
        exit_error "Falha ao escrever no arquivo: /etc/nsswitch.conf"
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
    exit 1
}

log_status() {
    local message="$1"
    local yellow="\033[0;33m"
    local color_off="\033[0m"
    echo -e "\n${yellow}${message}${color_off}\n"
}

main
