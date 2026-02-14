#!/usr/bin/env sh
set -eu;

root='.';
language='';
fix='0';

while [ "$#" -gt 0 ]; do
  case "$1" in
    --language)
      language="${2:-}";
      shift 2;
      ;;
    --fix)
      fix='1';
      shift 1;
      ;;
    --help)
      echo 'Usage: scripts/preflight.sh [--language <lang>] [--fix] [path]';
      echo 'Example: scripts/preflight.sh --language ts --fix /path/to/project';
      exit 0;
      ;;
    *)
      root="$1";
      shift 1;
      ;;
  esac;
done;

if [ ! -d "$root" ]; then
  echo 'Error: target path is not a directory.' 1>&2;
  exit 1;
fi;

echo 'Codex preflight starting.';
printf '%s%s\n' 'Target: ' "$root";

if [ ! -d "$root/agents/roles" ] && [ -d '/home/francois/dotfiles/.codex/agents/roles' ]; then
  echo 'Role templates not found at ./agents/roles.';
  echo 'Use /home/francois/dotfiles/.codex/agents/roles instead.';
fi;

for dir in node_modules dist build coverage .next .turbo; do
  if [ -d "$root/$dir" ]; then
    printf '%s%s%s\n' 'Warning: found ' "$dir" '. Workspace may not be clean.';
  fi;
done;

source_file="$(find "$root" -type f \( \
  -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o \
  -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o \
  -name '*.kt' -o -name '*.cs' -o -name '*.rb' \
\) \
  -not -path "$root/.git/*" \
  -not -path "$root/node_modules/*" \
  -not -path "$root/dist/*" \
  -not -path "$root/build/*" \
  -not -path "$root/coverage/*" \
  -print -quit \
)";

if [ -n "$source_file" ]; then
  echo 'Source files detected. Serena activation should work.';
  exit 0;
fi;

echo 'No source files detected. Serena may fail to activate.';
echo 'Consider adding a temporary placeholder source file in the target language.';

if [ "$fix" != '1' ]; then
  exit 0;
fi;

if [ -z "$language" ]; then
  echo 'Error: --fix requires --language (e.g., ts, js, py, go, rs).';
  exit 1;
fi;

comment='//';
ext='';

case "$language" in
  ts|typescript)
    ext='ts';
    ;;
  js|javascript)
    ext='js';
    ;;
  py|python)
    ext='py';
    comment='#';
    ;;
  go)
    ext='go';
    ;;
  rs|rust)
    ext='rs';
    ;;
  java)
    ext='java';
    ;;
  kt|kotlin)
    ext='kt';
    ;;
  cs|csharp)
    ext='cs';
    ;;
  rb|ruby)
    ext='rb';
    comment='#';
    ;;
  *)
    echo 'Error: unsupported language. Use ts, js, py, go, rs, java, kt, cs, rb.';
    exit 1;
    ;;
esac;

placeholder="$root/.codex-placeholder.$ext";

if [ -e "$placeholder" ]; then
  printf '%s%s\n' 'Placeholder already exists: ' "$placeholder";
  exit 0;
fi;

printf '%s codex placeholder for serena bootstrap\n' "$comment" > "$placeholder";
printf '%s%s\n' 'Created placeholder: ' "$placeholder";
echo 'Remove this file after Serena activation if not needed.';
