{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  data = config.xdg.dataHome;

  path = [
    "${home}/.local/bin"
    "${data}/mise/shims"
    "${data}/bun/bin"
    "${data}/npm/bin"
    "${home}/.cargo/bin"
  ];

  variables = {
    BUN_INSTALL = "${data}/bun";
    BUN_INSTALL_CACHE_DIR = "${config.xdg.cacheHome}/bun/install/cache";
    NPM_CONFIG_PREFIX = "${data}/npm";
    GOBIN = "${home}/.local/bin";
  };

  fishSessionVars = pkgs.runCommandLocal "hm-session-vars.fish" {} ''
    mkdir -p $out/etc/profile.d
    (echo "function setup_hm_session_vars;"
    ${pkgs.buildPackages.babelfish}/bin/babelfish \
      <${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
    echo "end"
    echo "setup_hm_session_vars") > $out/etc/profile.d/hm-session-vars.fish
  '';
in {
  home.sessionPath = path;
  home.sessionVariables = variables;
  home.packages = [fishSessionVars];

  systemd.user.sessionVariables = variables;

  xdg.configFile."environment.d/60-home-manager-path.conf".text = ''
    PATH=${lib.concatStringsSep ":" path}:$PATH
  '';
}
