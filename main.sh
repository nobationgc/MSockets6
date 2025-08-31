#!/bin/bash

DB=".data/ServiceDaemon.db"
mkdir -p "$(dirname "$DB")"

if [ ! -f "$DB" ]; then
  sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS preferences (key TEXT PRIMARY KEY, value TEXT);"
  sqlite3 "$DB" "INSERT OR IGNORE INTO preferences(key, value) VALUES('got_', '0');"
fi

got_=$(sqlite3 "$DB" "SELECT value FROM preferences WHERE key='got_';" 2>/dev/null)
if ! [[ "$got_" =~ ^[0-9]+$ ]]; then
  got_=0
fi

on_sigint() {
  echo ""
  echo "[!]: Ctrl+C detected. Enter 'exit' to quit."
}
trap on_sigint SIGINT

banner() {
  echo "=================================="
  echo "          MSockets6 v0.1         "
  echo "     Developed by Kryos Group   "
  echo "=================================="
  echo ""
  echo "[*] fallback (debug) = $got_"
  echo ""
}

HISTFILE=".data/msockets_history"
touch "$HISTFILE"
history -r "$HISTFILE"

banner

# --------------------------
# Helpers seguros para dry-run / mem-req
# --------------------------
RUNTIME_BIN="go run .confg/runtime.go"   # <- Cambiar si compilás a un binario

_read_ddos_config() {
  local ddos_hist=".data/ddos_history"
  if [ ! -f "$ddos_hist" ]; then
    echo "[!] No ddos configuration found at $ddos_hist"
    return 1
  fi
  mapfile -t cfg < "$ddos_hist"
  Target="${cfg[0]:-}"
  Port="${cfg[1]:-}"
  FileSize="${cfg[2]:-}"
  AttackType="${cfg[3]:-}"
  Tool="${cfg[4]:-}"
  Interval="${cfg[5]:-}"
  Sessions="${cfg[6]:-}"

  if [ -z "$Target" ] || [ -z "$Port" ] || [ -z "$FileSize" ] || [ -z "$AttackType" ] || [ -z "$Tool" ] || [ -z "$Sessions" ]; then
    echo "[!] ddos_history incomplete. Run --configure-ddos first."
    return 1
  fi
  return 0
}

appear() {
  if ! _read_ddos_config; then return 1; fi
  $RUNTIME_BIN --dry-out "$Target" "$Port" "$FileSize" "$AttackType" "$Tool" "$Interval" "$Sessions"
}

appear_mem() {
  if ! _read_ddos_config; then return 1; fi
  $RUNTIME_BIN --mem-req "$Target" "$Port" "$FileSize" "$AttackType" "$Tool" "$Interval" "$Sessions"
}

appear_both() {
  if ! _read_ddos_config; then return 1; fi
  $RUNTIME_BIN --dry-out --mem-req "$Target" "$Port" "$FileSize" "$AttackType" "$Tool" "$Interval" "$Sessions"
}
# --------------------------

configure_ddos() {
  local ddos_hist=".data/ddos_history"
  : > "$ddos_hist"
  history -r "$ddos_hist"
  echo "=== DDoS Configuration ==="
  echo "Type 'exit' to cancel, 'save' to save and exit."
  local target port fileSize attack_type tool interval sessions

  while true; do
    read -e -p "Target (<ip|web>): " target
    [ "$target" = "exit" ] && echo "Cancelled." && return
    history -s "$target"
    break
  done

  while true; do
    read -e -p "Port: " port
    [ "$port" = "exit" ] && echo "Cancelled." && return
    history -s "$port"
    [[ "$port" =~ ^[0-9]+$ ]] && break || echo "Invalid port."
  done

  while true; do
    read -e -p "File size to send (bytes): " fileSize
    [ "$fileSize" = "exit" ] && echo "Cancelled." && return
    history -s "$fileSize"
    [[ "$fileSize" =~ ^[0-9]+$ ]] && break || echo "Invalid file size."
  done

  while true; do
    read -e -p "Attack type (flood/syn/udp): " attack_type
    [ "$attack_type" = "exit" ] && echo "Cancelled." && return
    history -s "$attack_type"
    [[ "$attack_type" =~ ^(flood|syn|udp)$ ]] && break || echo "Invalid attack type. Use flood, syn, or udp."
  done

  while true; do
    read -e -p "Tool to use (hping3/nping/etc): " tool
    [ "$tool" = "exit" ] && echo "Cancelled." && return
    history -s "$tool"
    [[ "$tool" =~ ^[a-zA-Z0-9_]+$ ]] && break || echo "Invalid tool name."
  done

  if [ "$attack_type" != "flood" ]; then
    while true; do
      read -e -p "Interval (ms): " interval
      [ "$interval" = "exit" ] && echo "Cancelled." && return
      history -s "$interval"
      [[ "$interval" =~ ^[0-9]+$ ]] && break || echo "Invalid interval."
    done
  else
    interval=""
  fi

  while true; do
    read -e -p "Sessions: " sessions
    [ "$sessions" = "exit" ] && echo "Cancelled." && return
    history -s "$sessions"
    [[ "$sessions" =~ ^[0-9]+$ ]] && break || echo "Invalid sessions."
  done

  {
    echo "$target"
    echo "$port"
    echo "$fileSize"
    echo "$attack_type"
    echo "$tool"
    echo "$interval"
    echo "$sessions"
  } > "$ddos_hist"

  echo "[+]: DDoS configuration saved."
}

run_ddos_attack() {

  python3 .confg/backend.py --attack-ddos
}

while true; do
  read -e -p "[MSockets6]: " line
  echo "$line" >> "$HISTFILE"
  history -s "$line"
  input=($line)
  [ ${#input[@]} -eq 0 ] && continue

  cmd="${input[0]}"
  args_array=("${input[@]:1}")

  case "$cmd" in
    "clear"|"cls")
      clear
      banner
      ;;
    "msk")
      case "${args_array[0]}" in
        "--configure-ddos") configure_ddos ;;
        "--get-ddos-dry") appear ;;
        "--get-ddos-mem") appear_mem ;;
        "--get-ddos-preview") appear_both ;;
        "--attack-ddos") run_ddos_attack ;;
        *) echo "[!] Unknown msk subcommand: ${args_array[0]}" ;;
      esac
      ;;
    "exit")
      echo "[+]: Closing.."
      break
      ;;
    *)
      eval "$line" 2>/dev/null || echo "[!] Unknown command: $cmd"
      ;;
  esac
done
