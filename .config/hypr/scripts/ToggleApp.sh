#!/usr/bin/env bash
# Generic Toggle Script for Hyprland
# Usage: ./ToggleApp.sh <unique_name> <terminal_command> <window_title>

NAME=$1
TERMINAL_CMD=$2
WINDOW_TITLE=$3

if [ -z "$NAME" ] || [ -z "$TERMINAL_CMD" ] || [ -z "$WINDOW_TITLE" ]; then
  echo "Usage: $0 <unique_name> <terminal_command> <window_title>"
  exit 1
fi

SPECIAL_WS="special:$NAME"
ADDR_FILE="/tmp/${NAME}_toggle_addr"

# Dropdown size and position configuration (percentages)
WIDTH_PERCENT=75
HEIGHT_PERCENT=75
Y_PERCENT=10
SLIDE_STEPS=5

# Function to get window geometry
get_window_geometry() {
  local addr="$1"
  hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"'
}

# Function to animate window slide down (show)
animate_slide_down() {
  local addr="$1"
  local target_x="$2"
  local target_y="$3"
  local width="$4"
  local height="$5"
  local start_y=$((target_y - height - 50))
  local step_y=$(((target_y - start_y) / SLIDE_STEPS))

  hyprctl dispatch movewindowpixel "exact $target_x $start_y,address:$addr" >/dev/null 2>&1
  sleep 0.05
  for i in $(seq 1 $SLIDE_STEPS); do
    local current_y=$((start_y + (step_y * i)))
    hyprctl dispatch movewindowpixel "exact $target_x $current_y,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done
  hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$addr" >/dev/null 2>&1
}

# Function to animate window slide up (hide)
animate_slide_up() {
  local addr="$1"
  local start_x="$2"
  local start_y="$3"
  local width="$4"
  local height="$5"
  local end_y=$((start_y - height - 50))
  local step_y=$(((start_y - end_y) / SLIDE_STEPS))

  for i in $(seq 1 $SLIDE_STEPS); do
    local current_y=$((start_y - (step_y * i)))
    hyprctl dispatch movewindowpixel "exact $start_x $current_y,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done
}

# Function to get monitor info
get_monitor_info() {
  hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height) \(.scale) \(.name)"'
}

# Function to calculate position
calculate_position() {
  local monitor_info=$(get_monitor_info)
  local mon_x=$(echo $monitor_info | cut -d' ' -f1)
  local mon_y=$(echo $monitor_info | cut -d' ' -f2)
  local mon_width=$(echo $monitor_info | cut -d' ' -f3)
  local mon_height=$(echo $monitor_info | cut -d' ' -f4)
  local mon_scale=$(echo $monitor_info | cut -d' ' -f5)
  local mon_name=$(echo $monitor_info | cut -d' ' -f6)

  if [ -z "$mon_scale" ] || [ "$mon_scale" = "null" ]; then mon_scale="1.0"; fi

  local logical_width=$(echo "$mon_width / $mon_scale" | bc | cut -d'.' -f1)
  local logical_height=$(echo "$mon_height / $mon_scale" | bc | cut -d'.' -f1)

  local width=$((logical_width * WIDTH_PERCENT / 100))
  local height=$((logical_height * HEIGHT_PERCENT / 100))
  local y_offset=$((logical_height * Y_PERCENT / 100))
  local x_offset=$(((logical_width - width) / 2))

  local final_x=$((mon_x + x_offset))
  local final_y=$((mon_y + y_offset))

  echo "$final_x $final_y $width $height $mon_name"
}

CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

get_addr() { [ -f "$ADDR_FILE" ] && cut -d' ' -f1 "$ADDR_FILE"; }

exists() {
  local addr=$(get_addr)
  [ -n "$addr" ] && hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1
}

in_special() {
  local addr=$(get_addr)
  [ -n "$addr" ] && hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "'$SPECIAL_WS'")' >/dev/null 2>&1
}

spawn() {
  local pos_info=$(calculate_position)
  local target_x=$(echo $pos_info | cut -d' ' -f1)
  local target_y=$(echo $pos_info | cut -d' ' -f2)
  local width=$(echo $pos_info | cut -d' ' -f3)
  local height=$(echo $pos_info | cut -d' ' -f4)
  local monitor_name=$(echo $pos_info | cut -d' ' -f5)

  local windows_before=$(hyprctl clients -j)
  hyprctl dispatch exec "[float; size $width $height; workspace $SPECIAL_WS silent] $TERMINAL_CMD"
  
  for i in {1..30}; do
    sleep 0.1
    local windows_after=$(hyprctl clients -j)
    if [ $(echo "$windows_after" | jq 'length') -gt $(echo "$windows_before" | jq 'length') ]; then
      new_addr=$(comm -13 <(echo "$windows_before" | jq -r '.[].address' | sort) <(echo "$windows_after" | jq -r '.[].address' | sort) | head -1)
      break
    fi
  done

  if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
    echo "$new_addr $monitor_name" >"$ADDR_FILE"
    sleep 0.2
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$new_addr"
    hyprctl dispatch pin "address:$new_addr"
    animate_slide_down "$new_addr" "$target_x" "$target_y" "$width" "$height"
    return 0
  fi
  return 1
}

if exists; then
  ADDR=$(get_addr)
  if in_special; then
    pos_info=$(calculate_position)
    target_x=$(echo $pos_info | cut -d' ' -f1)
    target_y=$(echo $pos_info | cut -d' ' -f2)
    width=$(echo $pos_info | cut -d' ' -f3)
    height=$(echo $pos_info | cut -d' ' -f4)

    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$ADDR"
    hyprctl dispatch pin "address:$ADDR"
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$ADDR"
    animate_slide_down "$ADDR" "$target_x" "$target_y" "$width" "$height"
    hyprctl dispatch focuswindow "address:$ADDR"
  else
    geometry=$(get_window_geometry "$ADDR")
    if [ -n "$geometry" ]; then
      curr_x=$(echo $geometry | cut -d' ' -f1)
      curr_y=$(echo $geometry | cut -d' ' -f2)
      curr_width=$(echo $geometry | cut -d' ' -f3)
      curr_height=$(echo $geometry | cut -d' ' -f4)
      animate_slide_up "$ADDR" "$curr_x" "$curr_y" "$curr_width" "$curr_height"
      sleep 0.1
    fi
    hyprctl dispatch pin "address:$ADDR"
    hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$ADDR"
  fi
else
  spawn && hyprctl dispatch focuswindow "address:$(get_addr)"
fi
