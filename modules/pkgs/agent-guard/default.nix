# kill-alerts (system service) and agent-revive (user service) share this package.
# The tests run on every build, so a broken version never gets deployed.
{
  lib,
  runCommand,
  python3,
}: let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "py") ./.;
  };
in
  runCommand "agent-guard" {
    nativeBuildInputs = [python3];
    passthru.python = python3;
  } ''
    cp ${src}/*.py .
    python3 -B -m unittest -v test_kill_alerts test_agent_revive
    install -Dm644 -t $out/lib oomkill.py kill_alerts.py agent_revive.py
  ''
