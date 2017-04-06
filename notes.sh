#!/usr/bin/env bash

function printOptions {
	local -a options=("${!1}") # "create array option exluding builtin param 1"
	for (( j=0; j<${#options[@]}; j+=2)); do
		local label=${options[$j]}
		local task=${options[$j+1]}
    echo "${label}) $task"
	done
}

function main_menu {
	local MAIN_OPTIONS=(
		1 'Recent Notes'
		2 'New Note'
		11 'Exit'
	)

	printOptions MAIN_OPTIONS[@]

	echo "Select an option: "
	read SELECTION

	case "$SELECTION" in
		1)
      recent_note
			;;
		2)
			new_note
			;;
		11)
			exit
			;;
	esac

	#go back to main
	main_menu
}

function recent_note {
  local -a recents=($(ls ~/notes))
  RECENTSEL=-1
  while [[ $RECENTSEL < 0 || $RECENTSEL > ${#recents[@]} ]]; do
    echo ${#recents[@]}
    echo "Select a note ([h]ome, [q]uit):"
    for (( j=0; j<${#recents[@]}; j+=1)); do
      local task=${recents[$j]}
      echo "${j}) $task"
    done
    read RECENTSEL
    echo $RECENTSEL
    if [[ $RECENTSEL = q ]]; then
      exit
    elif [[ $RECENTSEL = h ]]; then
      notes.sh && exit
    fi
  done
  vim ~/notes/${recents[$RECENTSEL]} && exit
}

function new_note {
  read -p "Project ID ([h]ome, [q]uit): " PROJ
  if [[ $PROJ = q ]]; then
    exit
  elif [[ $PROJ = h ]]; then
    main_menu
  fi
  read -p "Notes ID ([h]ome, [q]uit): " IDENT
  if [[ $IDENT = q ]]; then
    exit
  elif [[ $IDENT = h ]]; then
    main_menu
  fi
  NAME="notes-${PROJ}-$(date +%Y%m%d)-$IDENT"
  FILE=~/notes/${NAME}.txt
  if [[ -e $FILE ]]; then
    while [[ -e $FILE ]]; do
      read -p "Provide a unique ID ([h]ome, [q]uit): " IDENT
      NAME="notes-${PROJ}-$(date +%Y%m%d)-$IDENT"
      FILE=~/notes/${NAME}.txt
    done
  fi
  if [[ $IDENT = q ]]; then
    exit
  elif [[ $IDENT = h ]]; then
    main_menu
  fi
  echo "Creating $FILE..."
  touch $FILE
  vim $FILE && exit
}

main_menu
