function fish_user_key_bindings
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    starship init fish | source
    zoxide init fish | source
    fzf --fish | source
end
