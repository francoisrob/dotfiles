{...}: let
  # Nerd Font glyphs live in the Unicode private use area, and Nix strings have no
  # \u escape. Decoding through JSON keeps them as codepoints in the source rather
  # than invisible literal characters that are easy to drop in an edit.
  nf = codepoint: builtins.fromJSON ''"\u${codepoint}"'';
in {
  # This config used to live in an unmanaged ~/.config/spotify-player/app.toml,
  # so it was never reproducible. It is ported verbatim here, with two fixes:
  #
  #   - The old file asked for theme = "dracula", but spotify-player ships no
  #     built-in themes at all: they only exist in upstream's examples/theme.toml,
  #     and there was no theme.toml on disk. The name silently resolved to nothing
  #     and the player has been rendering its default palette the whole time.
  #   - "gruvbox_dark" below is upstream's own definition, which is already gruvbox
  #     medium contrast (bg #282828, fg #ebdbb2) and matches the console palette in
  #     modules/system/fonts.nix exactly.
  #
  # Home Manager now writes both app.toml and theme.toml. The old hand-written
  # app.toml is moved aside as app.toml.backup on the next switch, per
  # home-manager.backupFileExtension in modules/home.nix.
  programs.spotify-player = {
    enable = true;

    themes = [
      {
        name = "gruvbox_dark";
        palette = {
          background = "#282828";
          foreground = "#ebdbb2";
          black = "#282828";
          red = "#cc241d";
          green = "#98971a";
          yellow = "#d79921";
          blue = "#458588";
          magenta = "#b16286";
          cyan = "#689d6a";
          white = "#a89984";
          bright_black = "#928374";
          bright_red = "#fb4934";
          bright_green = "#b8bb26";
          bright_yellow = "#fabd2f";
          bright_blue = "#83a598";
          bright_magenta = "#d3869b";
          bright_cyan = "#8ec07c";
          bright_white = "#ebdbb2";
        };
      }
    ];

    settings = {
      theme = "gruvbox_dark";
      client_id = "d420a117a32841c2b3474932e49fb54b";
      client_port = 8080;
      login_redirect_uri = "http://127.0.0.1:8989/login";
      playback_format = ''
        {status} {track} • {artists} {liked}
        {album} • {genres}
        {metadata}'';
      playback_metadata_fields = [
        "repeat"
        "shuffle"
        "volume"
        "device"
      ];

      notify_timeout_in_secs = 0;
      notify_transient = false;
      enable_notify = false;
      notify_streaming_only = false;

      tracks_playback_limit = 50;
      app_refresh_duration_in_ms = 50;
      playback_refresh_duration_in_ms = 0;
      page_size_in_rows = 20;
      play_icon = nf "f04b";
      pause_icon = nf "f04c";
      liked_icon = " ${nf "f004"} ";
      explicit_icon = "[E]";
      border_type = "Rounded";
      progress_bar_type = "Line";
      progress_bar_position = "Bottom";
      genre_num = 2;
      cover_img_length = 20;
      cover_img_width = 10;
      cover_img_scale = 0.9;
      enable_media_control = true;
      enable_streaming = "Always";
      enable_cover_image_cache = true;
      default_device = "spotify-player";
      seek_duration_secs = 5;
      sort_artist_albums_by_type = false;

      notify_format = {
        summary = "{track} • {artists}";
        body = "{album}";
      };

      layout = {
        playback_window_position = "Top";
        playback_window_height = 6;
        library = {
          playlist_percent = 40;
          album_percent = 40;
        };
      };

      device = {
        name = "spotify-player";
        device_type = "speaker";
        volume = 100;
        bitrate = 320;
        audio_cache = false;
        normalization = false;
        autoplay = false;
      };
    };
  };
}
