#!/usr/bin/env bash
SESSION=goodmorning
SESSION2=workspace
echo "Checking for active session $SESSION..."
if [[ $(tmux ls) == *$SESSION* ]]; then
  echo "Session $SESSION found! Skipping..."
else
  echo "Session not found. Creating session $SESSION..."
  tmux new -s $SESSION -n ecli -d
  echo "Starting Eclipse..."
  tmux send-keys -t $SESSION "abeclipse.sh" C-m
  echo "Creating window "caff"..."
  tmux new-window -n caff -t $SESSION
  echo "Starting caffeinate"
  tmux send-keys -t $SESSION:1 "caffeinate -dimsu" C-m
fi

if [[ $(tmux ls) == *$SESSION2* ]]; then
  # if goodmorning exists, this should exist, and vice versa
  # still holding as a fallback
  echo "Session $SESSION2 found! Attaching..."
  tmux attach -t $SESSION2
  exit
else
  echo "Session not found. Creating session $SESSION2..."
  tmux new -s $SESSION2 -n ecli -d
  tmux send-keys -t $SESSION2:0 "cd ~" C-m
  echo "Creating window elis..."
  tmux new-window -n elishome -t $SESSION2
  tmux send-keys -t $SESSION2:1 "cd $ELIS_HOME" C-m
  echo "Creating window for e2tk..."
  tmux new-window -n e2tk -t $SESSION2
  tmux send-keys -t $SESSION2:2 "e2tk-mac.sh" C-m

  COUNTER=$((0))
  for var in "$@"
  do
    WINDOWNUM=$((COUNTER + 3))
    echo "Creating window for $var..."
    tmux new-window -n "project_$WINDOWNUM" -t $SESSION2
    tmux send-keys -t $SESSION2:$WINDOWNUM "cd $var" C-m
    let COUNTER++
  done

  tmux attach -t $SESSION2
fi
