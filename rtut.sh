#!/usr/bin/env bash
SESSION=workspace
if [[ $(tmux ls) == *$SESSION* ]]; then
  tmux attach -t $SESSION
  exit
else
  tmux new -s $SESSION -n rtut -d
  tmux send-keys -t $SESSION:0 "cd ~/repos/ruby_tutorial" C-m

  tmux new-window -n editor -t $SESSION
  tmux send-keys -t $SESSION:1 "cd ~/repos/ruby_tutorial" C-m
  tmux send-keys -t $SESSION:1 "vim" C-m

  tmux new-window -n server -t $SESSION
  tmux send-keys -t $SESSION:2 "cd ~/repos/ruby_tutorial/$(ls ~/repos/ruby_tutorial | sort -n | tail -n1)" C-m
  tmux send-keys -t $SESSION:2 "rails s" C-m

  tmux attach -t $SESSION
fi
