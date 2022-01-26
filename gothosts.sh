#!/bin/bash

# Define colors...
RED=`tput bold && tput setaf 1`
GREEN=`tput bold && tput setaf 2`
YELLOW=`tput bold && tput setaf 3`
BLUE=`tput bold && tput setaf 4`
NC=`tput sgr0`

function RED(){
  echo -e "${RED}${1}${NC}"
}
function GREEN(){
  echo -e "${GREEN}${1}${NC}"
}
function YELLOW(){
  echo -e "${YELLOW}${1}${NC}"
}
function BLUE(){
  echo -e "${BLUE}${1}${NC}"
}

# Testing if root...
if [ $UID -ne 0 ]
then
  RED "════════════════════════════════════════════════════════════════════════════════"
  RED "[*] You must run this script as root!"
  RED "════════════════════════════════════════════════════════════════════════════════"
  exit
fi

# title
function _title {
BLUE "════════════════════════════════════════════════════════════════════════════════"
BLUE "  ██████╗  ██████╗ ████████╗    ██╗  ██╗ ██████╗ ███████╗████████╗███████╗██████╗"
BLUE " ██╔════╝ ██╔═══██╗╚══██╔══╝    ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔════╝╚════██╗"
BLUE " ██║  ███╗██║   ██║   ██║       ███████║██║   ██║███████╗   ██║   ███████╗  ▄███╔╝"
BLUE " ██║   ██║██║   ██║   ██║       ██╔══██║██║   ██║╚════██║   ██║   ╚════██║  ▀▀══╝"
BLUE " ╚██████╔╝╚██████╔╝   ██║       ██║  ██║╚██████╔╝███████║   ██║   ███████║  ██╗"
BLUE "  ╚═════╝  ╚═════╝    ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝  ╚═╝"
BLUE "════════════════════════════════════════════════════════════════════════════════"
YELLOW "Simple Subnet Host Discovery Script  - V.1.2"
YELLOW "By Mimic Lynx"
BLUE "════════════════════════════════════════════════════════════════════════════════"
}

# processing arguments for autorecon
if [[ ! -z $# ]]; then
  if [[ $1 == "-a" ]] || [[ $2 == "-a" ]]; then
    if [[ ! -z $3 ]]; then 
      autorecon_options=$3
    fi
    autorecon_var="-a"
  elif [[ $1 == "-h" ]]; then
    help_command
  fi
fi 

# help command
function help_command {
  RED "USAGE: Please read the following examples to see how to use the 'gothosts' script."
  echo
  RED "EXAMPLES:"
  YELLOW "RUNNING THE SCRIPT WITHOUT ARGUMENTS:" && GREEN "sudo ./gothosts.sh" && echo
  YELLOW "RUNNING THE SCRIPT WITH AN IP RANGE:" && GREEN "sudo ./gothosts.sh 192.168.0.1/24  OR 192.168.0.1-255" && echo
  YELLOW "RUNNING THE SCRIPT WITH AUTORECON:" && GREEN "sudo ./gothosts.sh -a" && echo
  YELLOW "RUNNING THE SCRIPT WITH AUTORECON AND OPTIONS:" && GREEN "sudo ./gothosts.sh -a '-v --only-scan-dir'" && echo 
  YELLOW "RUNNING THE SCRIPT WITH AN IP RANGE AND AUTORECON WITH OPTIONS:" && GREEN "sudo ./gothosts.sh 192.168.0.1-255 -a '-v --only-scan-dir'" && echo
}

# defining IP range and setting output filename
function config {
  if [[ -z $1 ]]; then
    BLUE "════════════════════════════════════════════════════════════════════════════════"
    BLUE "[*] Please enter IP range (e.g. 192.168.0.1-120, 192.168.0.0/24)" && echo
    read IP_RANGE && echo
    BLUE "════════════════════════════════════════════════════════════════════════════════" && echo
  elif [[ $1 == *"."*"."*"."* ]]; then
    IP_RANGE=$1
  else
    help_command
    exit
  fi
  FILENAME="Alive_hosts.txt"
  TMP_FILE="tmp.txt"
  touch $FILENAME
  touch $TMP_FILE
}


# fping command
function fping_scans {
  BLUE "[*] RUNNING FPING SCAN"
  if [[ $IP_RANGE == *"-"* ]]; then
    FPING_IP_RANGE="$(awk -F'-' '{print $1}' <<< 172.16.64.1-255) $(awk -F'.' '{print $1"."$2"."$3"."}' <<< $IP_RANGE)$(awk -F'-' '{print $2}' <<< $IP_RANGE)"
    fping -a -g $FPING_IP_RANGE 2>/dev/null >> $TMP_FILE
  else
    fping -a -g $IP_RANGE 2>/dev/null >> $TMP_FILE
  fi
  GREEN "[*] fping scan complete!" && echo
  BLUE "════════════════════════════════════════════════════════════════════════════════" && echo
}

# nmap commands
function nmap_scans {
  BLUE "[*] RUNNING NMAP SCANS"
  YELLOW "[*] Starting Ping scan"
  nmap -n -sn -PE $IP_RANGE -oG - | awk '/Up$/{print $2}' >> $TMP_FILE
  GREEN "[*] Ping scan complete!"
  YELLOW "[*] Starting SYN Scan"
  sudo nmap -n -sS $IP_RANGE -oG - | awk '/Up$/{print $2}' >> $TMP_FILE
  GREEN "[*] SYN scan complete!"
  YELLOW "[*] Starting ARP Ping scan"
  nmap -n -PR $IP_RANGE -oG - | awk '/Up$/{print $2}' >> $TMP_FILE
  GREEN "[*] ARP Ping scan complete!" && echo
  BLUE "════════════════════════════════════════════════════════════════════════════════" && echo
}

# sorting the output
function cleanup {
  BLUE "[*] DOING SOME CLEANUP AND SORTING"
  sudo sort $TMP_FILE | sudo uniq > $FILENAME && sudo rm $TMP_FILE
  GREEN "[*] Output sorting complete!" && echo
  BLUE "════════════════════════════════════════════════════════════════════════════════"
  BLUE "[*] List of Hosts got saved to $FILENAME" && echo
  cat $FILENAME && echo
  BLUE "════════════════════════════════════════════════════════════════════════════════"
}

# going straight to autorecon
function autorecon_scan  {
  if [[ ! -z $autorecon_var ]] && [[ $autorecon_var == "-a" ]]; then
    if [[ ! -z $autorecon_options ]]; then 
      BLUE "[*] STARTING AUTORECON WITH THE FOUND HOSTS AND THE OPTIONS $autorecon_options"
      YELLOW "[*] Autorecon is running! This may take some time!!!"
      sudo autorecon -t Alive_hosts.txt $autorecon_options
      GREEN "[*] Autorecon scan complete!"
    else
      BLUE "[*] STARTING AUTORECON WITH THE FOUND HOSTS"
      YELLOW "[*] Autorecon is running! This may take some time!!!"
      sudo autorecon -t Alive_hosts.txt
      GREEN "[*] Autorecon scan complete!"
    fi
  else
    exit
  fi
}

_title
config $1
fping_scans
nmap_scans
cleanup
autorecon_scan
exit
