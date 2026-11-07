{
  config,
  pkgs,
  ...
}: let
  modelsDir = "${config.home.homeDirectory}/.local/share/models";

  # Per-model settings for the router. A section named after a file in
  # modelsDir (file name without .gguf) sets that model's flags; the section
  # name is also the model id clients such as pi send.
  presets = pkgs.writeText "llama-models.ini" ''
    version = 1

    [*]
    n-gpu-layers = 99
    flash-attn = on
    jinja = true
    parallel = 1
    cache-type-k = q8_0
    cache-type-v = q8_0

    [Ornith-1.5-9B-Q5_K_M]
    load-on-startup = true
    ctx-size = 65536
    cache-ram = 2048
    spec-type = draft-mtp
    spec-draft-n-max = 2
    chat-template-kwargs = {"enable_thinking":false}
    temp = 0.6
    top-p = 0.95
    top-k = 20
  '';
in {
  home.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.python3Packages.huggingface-hub # gives the `hf` command for downloads
  ];

  # llama.cpp in router mode on 127.0.0.1:3080 (localhost only). Models live
  # in ~/.local/share/models: one .gguf file per model, or a subfolder per
  # model when it has more than one file (the image add-on's name must start
  # with "mmproj"). Only one model is loaded at a time; asking for another by
  # name unloads the current one.
  systemd.user.services.llama-server = {
    Unit = {
      Description = "llama.cpp router (127.0.0.1:3080)";
      After = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server --models-dir ${modelsDir} --models-preset ${presets} --models-max 1 --host 127.0.0.1 --port 3080 --api-key local";
      Restart = "always";
      RestartSec = 15;
      Nice = 15;
      IOSchedulingClass = "idle";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
