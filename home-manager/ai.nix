{
  config,
  pkgs,
  ...
}: let
  modelsDir = "${config.home.homeDirectory}/.local/share/models";

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
    pkgs.python3Packages.huggingface-hub
  ];

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
