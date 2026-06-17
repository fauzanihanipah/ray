#!/bin/bash
# ============================================================
#   CHANELOG VPN SCRIPT - TROJAN-GO MENU
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TROJAN_CONFIG="/etc/trojan-go/config.json"

trojan_header() {
  clear
  local domain=$(get_domain)
  local status
  systemctl is-active --quiet trojan-go \
    && status="${GREEN}● RUNNING${NC}" || status="${RED}● STOPPED${NC}"

  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}             ⚡  TROJAN-GO MENU  ⚡${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Domain       ${NC}: ${WHITE}$domain${NC}"
  echo -e "  ${YELLOW}Status       ${NC}: $status"
  echo -e "  ${YELLOW}Port         ${NC}: ${WHITE}444${NC}"
  echo -e "  ${YELLOW}WebSocket    ${NC}: ${WHITE}/trojan-ws${NC}"
  if [[ -f "$TROJAN_CONFIG" ]]; then
    local pw=$(jq -r '.password[0] // "N/A"' "$TROJAN_CONFIG" 2>/dev/null)
    echo -e "  ${YELLOW}Password     ${NC}: ${WHITE}$pw${NC}"
  fi
  echo -e "${CYAN}$LINE${NC}"
}

trojan_menu() {
  trojan_header
  echo ""
  echo -e "  ${WHITE}TROJAN-GO MANAGEMENT${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[1]${NC}  Ganti Password Trojan"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[2]${NC}  Tambah Password"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[3]${NC}  Restart Trojan-Go"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${CYAN}[4]${NC}  Lihat Config Trojan"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${CYAN}[5]${NC}  Tampilkan Link Trojan"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${DIM}[0]${NC}  Kembali ke Menu Utama"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${WHITE}Pilih [0-5]${NC}: "
  read -r choice

  case "$choice" in
    1) do_change_trojan_password ;;
    2) do_add_trojan_password ;;
    3) do_restart_trojan ;;
    4) do_view_trojan_config ;;
    5) do_show_trojan_link ;;
    0) bash $SCRIPT_DIR/menu.sh ;;
    *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}"; sleep 1; trojan_menu ;;
  esac
}

do_change_trojan_password() {
  trojan_header
  echo ""
  echo -e "  ${WHITE}GANTI PASSWORD TROJAN${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Password baru${NC}: "; read -r newpw
  [[ -z "$newpw" ]] && { echo -e "  ${RED}[!] Password kosong!${NC}"; sleep 2; trojan_menu; return; }

  local tmp=$(mktemp)
  jq --arg pw "$newpw" '.password = [$pw]' "$TROJAN_CONFIG" > "$tmp" && mv "$tmp" "$TROJAN_CONFIG"
  systemctl restart trojan-go 2>/dev/null
  echo -e "  ${GREEN}[✓] Password diubah ke: ${WHITE}$newpw${NC}"
  sleep 2; trojan_menu
}

do_add_trojan_password() {
  trojan_header
  echo ""
  echo -e "  ${WHITE}TAMBAH PASSWORD TROJAN${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Password tambahan${NC}: "; read -r newpw
  [[ -z "$newpw" ]] && { echo -e "  ${RED}[!] Password kosong!${NC}"; sleep 2; trojan_menu; return; }

  local tmp=$(mktemp)
  jq --arg pw "$newpw" '.password += [$pw]' "$TROJAN_CONFIG" > "$tmp" && mv "$tmp" "$TROJAN_CONFIG"
  systemctl restart trojan-go 2>/dev/null
  echo -e "  ${GREEN}[✓] Password ${WHITE}$newpw${NC} ditambahkan!"
  sleep 2; trojan_menu
}

do_restart_trojan() {
  trojan_header
  echo ""
  echo -e "  ${CYAN}[*]${NC} Restart Trojan-Go..."
  systemctl restart trojan-go 2>/dev/null
  sleep 1
  local st
  systemctl is-active --quiet trojan-go && st="${GREEN}RUNNING${NC}" || st="${RED}STOPPED${NC}"
  echo -e "  ${GREEN}[✓]${NC} Status: $st"
  sleep 2; trojan_menu
}

do_view_trojan_config() {
  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}           ◈  TROJAN-GO CONFIG  ◈${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo ""
  cat "$TROJAN_CONFIG" 2>/dev/null || echo "  Config tidak ditemukan!"
  echo ""
  echo -e "${CYAN}$LINE${NC}"
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  trojan_menu
}

do_show_trojan_link() {
  trojan_header
  echo ""
  local domain=$(get_domain)
  local pw=$(jq -r '.password[0] // "changeme123"' "$TROJAN_CONFIG" 2>/dev/null)
  local link="trojan://${pw}@${domain}:444?security=tls&type=ws&path=%2Ftrojan-ws&host=${domain}&sni=${domain}#${domain}-trojan"

  echo -e "  ${WHITE}LINK TROJAN-GO${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Domain   ${NC}: ${WHITE}$domain${NC}"
  echo -e "  ${YELLOW}Port     ${NC}: ${WHITE}444${NC}"
  echo -e "  ${YELLOW}Password ${NC}: ${WHITE}$pw${NC}"
  echo -e "  ${YELLOW}Path     ${NC}: ${WHITE}/trojan-ws${NC}"
  echo -e "  ${YELLOW}TLS      ${NC}: ${GREEN}ON${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}Link:${NC}"
  echo -e "  ${GREEN}$link${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  trojan_menu
}

trojan_menu
