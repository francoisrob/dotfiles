function fish_user_key_bindings
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source
end
