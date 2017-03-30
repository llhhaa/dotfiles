#!/usr/bin/env bash
read -p "Project ID ('q' quits): " PROJ
if [[ $PROJ = q ]]; then
  exit
fi
read -p "Notes ID ('q' quits): " IDENT
if [[ $IDENT = q ]]; then
  exit
fi
NAME="notes-${PROJ}-$(date +%Y%m%d)-$IDENT"
FILE=~/notes/${NAME}.txt
while [[ -e $FILE ]]; do
  read -p "ID already used today. Provide a unique ID ('q' quits): " IDENT
  NAME="notes-${PROJ}-$(date +%Y%m%d)-$IDENT"
  FILE=~/notes/${NAME}.txt
done
if [[ $IDENT = q ]]; then
  exit
fi
echo "Creating $FILE..."
touch $FILE
vim $FILE
