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
# Load history on startup
history -r "$HISTFILE"

banner

configure_ddos() {
  local ddos_hist=".data/ddos_history"
  # Overwrite history file for each new configuration
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
    read -e -p "Tool to use (hping/nping/etc): " tool
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

  # Save all parameters to ddos_history (overwrite)
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
  # Llama a runtime.go con el modo ataque
  go run .confg/runtime.go --attack-ddos
}

show_ddos_progress() {
  # Llama a runtime.go con el modo progreso
  go run .confg/runtime.go --show-progress-ddos
}

auto_update() {
  REPO_URL="https://github.com/nobationgc/MSockets6.git"
  REPO_DIR="$(pwd)"
  if [ -d "$REPO_DIR/.git" ]; then
    echo "[*] Updating MSockets6 from $REPO_URL ..."
    git pull origin main && echo "[+] Update complete." || echo "[!] Update failed."
  else
    echo "[*] No git repository found. Cloning fresh copy..."
    git clone "$REPO_URL" MSockets6_update_tmp && echo "[+] Clone complete. Please manually replace your files from MSockets6_update_tmp." || echo "[!] Clone failed."
  fi
}

while true; do
  # Uses read -e to enable editing with arrows
  read -e -p "[MSockets6]: " line
  # Save the command to history
  echo "$line" >> "$HISTFILE"
  history -s "$line"
  # Convert the line to an array of words
  input=($line)
  [ ${#input[@]} -eq 0 ] && continue

  cmd="${input[0]}"
  args_array=("${input[@]:1}")

  case "$cmd" in
    "clear")
      clear
      banner
      ;;

    "cls")
      clear
      banner
      ;;
    "/fallback_")
      if [ ${#args_array[@]} -ge 1 ]; then
        case "${args_array[0]}" in
          on|1|true)
            got_=1
            ;;
          off|0|false)
            got_=0
            ;;
          toggle)
            if [ "$got_" -eq 0 ]; then got_=1; else got_=0; fi
            ;;
          *)
            echo "[!] Usage: /fallback_ on|off|toggle"
            continue
            ;;
        esac
      else
        got_=1
      fi
      sqlite3 "$DB" "INSERT OR REPLACE INTO preferences(key, value) VALUES('got_', '$got_');"
      echo "[+]: Fallback updated.. got_ = $got_"
      ;;
    "exit")
      echo "[+]: Closing.."
      break
      ;;
    "msk")
      if [ "${args_array[0]}" = "--configure-ddos" ]; then
        configure_ddos
        continue
      elif [ "${args_array[0]}" = "--attack-ddos" ]; then
        run_ddos_attack
        continue
      elif [ "${args_array[0]}" = "--show-progress(ddos)" ]; then
        show_ddos_progress
        continue
      elif [ "${args_array[0]}" = "--update" ]; then
        auto_update
        continue
      fi
      ;;
    *)
      if [ "$got_" -eq 0 ]; then
        echo "[!]: Unknown command: $cmd, trying to execute in Bash..."
      fi
      full_cmd="$cmd"
      if [ ${#args_array[@]} -gt 0 ]; then
        full_cmd+=" ${args_array[*]}"
      fi
      # Try to execute, capture error
      if ! eval "$full_cmd" 2>/dev/null; then
        echo "[!]: Command not found or failed: $cmd"
      fi
      ;;
  esac
done
