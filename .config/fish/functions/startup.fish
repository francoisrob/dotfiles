function start-fullstack --description 'Start backend and frontend in tmux'
  tmux new-session -c "$PWD" \; \
    split-window -v -p 25 -c "$PWD" \; \
    swap-pane -s 0 -t 1 \; \
    select-pane -t 1 \; \
    clock-mode \; \
    select-pane -t 0 \; \
    send-keys 'npm start' C-m \; \
    split-window -h -c "$PWD/angular-src" \; \
    send-keys 'npm start' C-m
end
