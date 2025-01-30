#!/bin/bash

# name: Game Server Utility
# author: Eric Deering
# date last updated: 20250129

declare -a server_list=()
declare -a running_server_list=()

log() {
  echo "$1" >> ./log.txt
}

ensure_server_list_exists() {
  filename="server-list.txt"
  if ! [ -f "./$filename" ]; then
    touch "$filename"
  fi
}

add_server() {
  ensure_server_list_exists
  if [ ! -e "$1" ]; then
    echo "Could not find $1"
  fi
  echo "$1" >> server-list.txt
  echo "Added server path: $1"
}

populate_server_list() {
  ensure_server_list_exists
  server_list=()
  while IFS= read -r line; do
    server_list+=("$line")
  done < ./server-list.txt
}

list_available_servers() {
  populate_server_list
  count=0
  for element in "${server_list[@]}"; do
    echo "$count). $element"
    count=$((count + 1))
  done
}

list_running_servers() {
  running_server_list=()
  populate_server_list
  count=0
  for element in ${server_list[@]}; do
    session=$(echo "$element" | sed 's/\./_/g')
    line=$(tmux ls -F "#{session_name}" | grep "$session")
    if [ -n "$line" ]; then
      echo "$count). $element"
      count=$((count + 1))
      running_server_list+=("$session")
    fi
  done
}

start_server() {
  tmux new-session -d -s "$1" "/bin/bash $1"
}

close_server() {
  echo "Called close_server with $1"
  tmux send-keys -t "$1" C-c
}

remove_server() {
  path=$(echo "$1" | sed 's/\//\\\//g')
  sed -i.bak "/$path/d" ./server-list.txt
}

###
# Main body of script
###

clear

while [ TRUE ]; do

  echo "Please select an option"
  echo "1.) Start Server"
  echo "2.) Close Server"
  echo "3.) Add Server"
  echo "4.) Remove Server"
  echo "5.) Exit"
  read -p "Option Number: " selection
  
  case "$selection" in
    "1") echo "Please select which server you would like to start."
      list_available_servers
      read -p "Server Selection: " selection
      start_server "${server_list[$selection]}"
      ;;
    "2") echo "Please select which server you would like to close."
      list_running_servers
      read -p "Server Selection: " selection
      close_server "${running_server_list[$selection]}"
      ;;
    "3") echo "Please input the path of the servers start script."
      read -p "Script Path: " start_script_path
      add_server "$start_script_path"
      ;;
    "4") echo "Please select which server you would like to remove."
      list_available_servers
      read -p "Server Selection: " selection
      remove_server "${server_list[$selection]}"
      ;;
    "5") exit 0
      ;;
    *) echo "option unknown, please select a valid option by inputting the number of the option you would like."
      ;;
  esac

done
