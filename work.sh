#!/usr/bin/env bash

# open a tmux session with a vim window for a given dir in ~/repos/

SESSION=$1
if [[ $(tmux ls) == *$SESSION* ]]; then
  tmux attach -t $SESSION
  exit
else
  cd ~/repos/$1
  tmux new -s $SESSION -n "editor" -d # new session w/ window named "editor"
  tmux send-keys -t $SESSION:0 "vim" C-m # start vim in that window
  tmux new-window -t $SESSION # create a second window
  tmux attach -t $SESSION:0 -c ~/repos/$1 # attach to session and change context
fi
