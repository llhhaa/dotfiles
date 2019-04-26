#!/usr/bin/env bash
SESSION=tutorial
LATEST=$(ls ~/repos/ruby_tutorial | sort -n | tail -n1)
if [[ $(tmux ls) == *$SESSION* ]]; then
  tmux attach -t $SESSION
  exit
else
  tmux new -s $SESSION -n "editor" -d
  tmux send-keys -t $SESSION:0 "cd ~/repos/ruby_tutorial/$LATEST" C-m
  tmux send-keys -t $SESSION:0 "vim" C-m

  tmux new-window -t $SESSION
  tmux send-keys -t $SESSION:1 "cd ~/repos/ruby_tutorial/$LATEST" C-m

  tmux new-window -n server -t $SESSION
  tmux send-keys -t $SESSION:2 "cd ~/repos/ruby_tutorial/$LATEST" C-m
  tmux send-keys -t $SESSION:2 "rails s" C-m

  tmux attach -t $SESSION:0
fi
