#!/bin/bash
# ============================================================
#   CHANELOG VPN SCRIPT - OHP & BADVPN MENU
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ohp_header() {
  clear
  local domain=$(get_domain)
  local ohp_st bv_st stun_st

  systemctl is-active --quiet ohpserver && ohp_st="${GREEN}● ON${NC}"  || ohp_st="${RED}● OFF${NC}"
  systemctl is-active --quiet badvpn    && bv_st="${GREEN}● ON${NC}"   || bv_st="${RED}● OFF${NC}"
  systemctl is-active --quiet stunnel4  && stun_st="${GREEN}● ON${NC}" || stun_st="${RED}● OFF${NC}"

  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}        ⚡  OHP / BADVPN / STUNNEL MENU  ⚡${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}OHP Server   ${NC}: $ohp_st ${WHITE}(port 8080 → SSH:442)${NC}"
  echo -e "  ${YELLOW}BadVPN UDPGW ${NC}: $bv_st  ${WHITE}(port 7300)${NC}"
  echo -e "  ${YELLOW}Stunnel      ${NC}: $stun_st ${WHITE}(SSL-SSH port 222)${NC}"
  echo -e "${CYAN}$LINE${NC}"
}

ohp_menu() {
  ohp_header
  echo ""
  echo -e "  ${WHITE}OHP & BADVPN MANAGEMENT${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[1]${NC}  Restart OHP Server"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[2]${NC}  Ganti Port Target OHP"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[3]${NC}  Restart BadVPN UDPGW"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[4]${NC}  Restart Stunnel"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${CYAN}[5]${NC}  Status Semua Service"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${DIM}[0]${NC}  Kembali ke Menu Utama"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${WHITE}Pilih [0-5]${NC}: "
  read -r choice

  case "$choice" in
    1) systemctl restart ohpserver 2>/dev/null; echo -e "  ${GREEN}[✓] OHP Server di-restart${NC}"; sleep 2; ohp_menu ;;
    2) do_change_ohp_target ;;
    3) systemctl restart badvpn 2>/dev/null; echo -e "  ${GREEN}[✓] BadVPN UDPGW di-restart${NC}"; sleep 2; ohp_menu ;;
    4) systemctl restart stunnel4 2>/dev/null; echo -e "  ${GREEN}[✓] Stunnel di-restart${NC}"; sleep 2; ohp_menu ;;
    5) do_service_status ;;
    0) bash $SCRIPT_DIR/menu.sh ;;
    *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}"; sleep 1; ohp_menu ;;
  esac
}

do_change_ohp_target() {
  ohp_header
  echo ""
  echo -e "  ${WHITE}GANTI PORT TARGET OHP${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  Port yang tersedia: 22, 442, 109, 143"
  echo -ne "  ${YELLOW}Port target baru${NC}: "; read -r port
  [[ ! "$port" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}[!] Port tidak valid!${NC}"; sleep 2; ohp_menu; return; }

  # Update ExecStart di service file
  sed -i "s/-proxy 127.0.0.1:[0-9]*/-proxy 127.0.0.1:$port/" /etc/systemd/system/ohpserver.service 2>/dev/null
  systemctl daemon-reload 2>/dev/null
  systemctl restart ohpserver 2>/dev/null
  echo -e "  ${GREEN}[✓] OHP sekarang proxy ke port ${WHITE}$port${NC}"
  sleep 2; ohp_menu
}

do_service_status() {
  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}           ◈  STATUS SEMUA SERVICE  ◈${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo ""
  for svc in xray nginx dropbear ohpserver badvpn stunnel4 trojan-go fail2ban vnstat; do
    local st
    systemctl is-active --quiet "$svc" 2>/dev/null \
      && st="${GREEN}● ACTIVE${NC}" || st="${RED}● INACTIVE${NC}"
    printf "  %-15s: %b\n" "$svc" "$st"
  done
  echo ""
  echo -e "${CYAN}$LINE${NC}"
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  ohp_menu
}

ohp_menu
