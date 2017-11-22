#!/usr/bin/env bash
SESSION=goodmorning
SESSION2=workspace

if [[ $(tmux ls) == *$SESSION* ]]; then
  echo "Session $SESSION found! Killing..."
  tmux kill-session -t $SESSION
fi

if [[ $(tmux ls) == *$SESSION2* ]]; then
  echo "Session $SESSION2 found! Killing..."
  tmux kill-session -t $SESSION2
  exit
fi
