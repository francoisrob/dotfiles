function fish_user_key_bindings
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Add any custom keybindings below
    # Example: bind \cr 'fzf_history'
end
