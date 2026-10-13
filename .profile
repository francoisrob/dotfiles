# Login environment for POSIX shells (sh and bash login shells). Fish does not
# read this file; it activates mise in config.fish.
#
# The Paperclip server on Tselio runs the Apex agent on this PC over SSH. Before
# every command it sources /etc/profile and this file, then runs `node` and
# `claude` through `sh`. mise shims are the documented way to expose mise-managed
# tools (node, bun, pnpm) to a non-interactive POSIX shell.
PATH="$HOME/.local/share/mise/shims:$PATH"

# Workaround for a Paperclip bug (nightly 2026.1010.0, still on master): the
# server copies this PC's PATH into the run environment and then looks up its
# own `ssh` binary on the server along it. The server's ssh is /usr/bin/ssh;
# NixOS does not put /usr/bin on PATH. On this PC /usr/bin holds only `env`
# and `sh`, so appending it changes nothing here. Remove once upstream resolves
# ssh with the controller's own environment (issue text in the operator's
# scratch notes, paperclip-ssh-path-issue.md).
PATH="$PATH:/usr/bin"
export PATH
