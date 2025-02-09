#!/bin/bash

# Kolory ANSI
Red='\033[0;31m'
Orange='\033[0;38;5;214m'
Green='\033[0;32m'
NC='\033[0m' # No Color

# Progowe wartości dla kolorowania
threshold_yellow=60
threshold_red=85
space="---------------------------------------------------------------"

while true; do
    # Clearing terminal before refreshing
    tput clear
    
    # Download current datas
    services=("apache2" "mysql" "nginx")

    services_status=$(for service in "${services[@]}"; do
        if systemctl list-units --type=service --all | grep -q "$service"; then
            status=$(systemctl is-active "$service" 2>/dev/null)
            if [[ "$status" == "active" ]]; then
                color="${Green}" #Active - green
            else
                color="${Red}" #Inactive - RED
            fi
            printf "%-20s | ${color}%-10s${NC}\n" "$service" "$status"
        else
            printf "%-20s | ${Red}%-20s${NC}\n" "$service" "N/A"
        fi
    done)
    osinfo=$(awk -F= '/^PRETTY_NAME/ {gsub(/"/, "", $2); print $2}' /etc/os-release)
    archinfo=$(uname -m)
    memoryusage=$(free -k | awk 'NR==2 {used=$3 / 1024 /1024; total=$2 / 1024 / 1024; percent=used / total * 100; printf "%-6s | %.2f GB / %.2f GB (%d%%)\n", "", used, total, percent}')
    usage=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')
    uptimer=$(uptime -p | sed 's/up //' | awk '{printf "%-19s | %s\n", "Uptime", $0 }')
    diskusage=$(df -h | awk -v Green="${Green}" -v Orange="${Orange}" -v Red="${Red}" -v NC="${NC}" 'NR>1 {
        usage = substr($5, 1, length($5)-1);
        if (usage < 60) color=Green;
        else if (usage >= 60 && usage < 80) color=Orange;
        else color=Red;

        printf "%s%-20s | %-4s / %-3s (%-2s%% Used)%s\n", color, $1, $3, $2, usage, NC
    }')
    cpuinform=$(awk -F ': ' '!seen[$2]++ {
        if ($1 ~ /model name/) printf "%-20s | %s\n", "CPU Model", $2;
        else if ($1 ~ /cpu MHz/) printf "%-20s | %s MHz\n", "CPU MHz ", $2;}' /proc/cpuinfo)
    graphicard=$(lspci | grep -i vga | awk -F': ' '{printf "%-21s| %s\n", "GPU", $2}')
    network_usage=$(awk '
        NR>2 {
            recv[$1] = $2;
            trans[$1] = $10;
        }
        END {
            for (iface in recv) {
                printf "%-20s | Download: %.2f MB/s | Upload: %.2f MB/s\n", iface, recv[iface] / 1024 / 1024, trans[iface] / 1024 / 1024;
            }
        }
    ' /proc/net/dev)
    iamwho=$(whoami)

    # Nagłówek
    echo -e "${Orange}===============================================================${NC}"
    echo -e "${Orange}                       SYSTEM MONITORING                       ${NC}"
    echo -e "${Orange}===============================================================${NC}"
    echo -e "Current User         | $iamwho"
    echo -e "$cpuinform"
    echo -e "$graphicard"
    echo -e "OS Version           | $osinfo"
    echo -e "Architecture         | $archinfo"
    echo -e "$space"
    echo -e "${Orange}Memory Usage: ${NC}$memoryusage"
    echo "$space"
    echo -e "${Orange}Disk Usage: ${NC}"
    echo -e "$space"
    echo -e "$diskusage"
    echo "$space"
    echo "$network_usage"
    echo -e "$space"
    echo -e "${Orange}Services Status: ${NC} "
    echo -e "$space"
    echo -e "$services_status"
    echo "$space"
    echo -e "${Orange} $uptimer${NC}"
    echo "$space"
    echo -e "${Orange}Last Updated:        | $(date +'%Y-%m-%d %H:%M')${NC}"
    echo -e "${Orange}===============================================================${NC}"


    Log_data="${space}\n${space}\nUser: ${iamwho}\n ${cpuinform}\n ${graphicard}\nOS: ${osinfo}\nArch: ${archinfo}\nMemory Usage: ${memoryusage}\nDisk Usage:\n ${diskusage}\nNetwork Usage:\n ${network_usage}\nServices Status:\n ${services_status}\nUptime: ${uptimer}\n Last Updated: $(date +'%Y-%m-%d %H:%M')"

    clean_log=$(echo -e "$Log_data" | sed 's/\x1b\[[0-9;]*m//g')

    echo -e "$clean_log" >> Log.txt
    # refreshing for 15 seconds
    sleep 15
done
