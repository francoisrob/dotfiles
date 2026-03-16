#!/usr/bin/env bash
# Claude Code status line script
# Shows: model name | context progress bar | sub-agents | background bash tasks

input=$(cat)

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# --- Context window ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- Progress bar ---
build_bar() {
  local pct="${1:-0}"
  local width=10
  local filled=$(( (pct * width + 99) / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}#"; done
  for ((i=0; i<empty; i++)); do bar="${bar}-"; done
  printf "%s" "$bar"
}

# --- Sub-agents ---
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
agent_info=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # Look for Task tool_use entries in the transcript (subagent invocations)
  agent_names=$(jq -r '
    .messages[]?
    | select(.role == "assistant")
    | .content[]?
    | select(.type == "tool_use" and (.name == "Task" or .name == "Agent" or (.name | test("agent|task"; "i"))))
    | .input.agent_name // .input.name // .name
  ' "$transcript" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')
  if [ -n "$agent_names" ]; then
    agent_info=" | agents:${agent_names}"
  fi
fi

# Also check if agent field is present in the JSON input (--agent flag)
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
if [ -n "$agent_name" ]; then
  agent_info=" | agent:${agent_name}"
fi

# --- Background bash tasks spawned by Claude Code ---
# Strategy: parse the transcript JSONL for evidence of background shell activity.
#
# When Claude runs Bash with run_in_background:true, the tool result message
# contains text matching "Shell ID: shell_N" (or a shell_id field).
# A shell is considered still running if it was started (shell_id seen in a
# "started" result) but has not yet produced a "completed" / exit-code result.
#
# Transcript is JSONL: each line is one message object with a "role" field.
# Tool results are role=="tool" and have a "content" array of blocks.
bg_info=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  bg_info=$(jq -rn '
    # Read all lines as a stream of message objects
    [inputs] |

    # Collect tool result content texts
    # Each tool result line has: {"role":"tool","content":[{"type":"text","text":"..."}],...}
    # or content may be a plain string in older formats.
    # We gather all result texts and look for shell_id patterns.

    # Pass 1: find all shell IDs that were ever started (appear in a "started" result)
    . as $msgs |

    # shell_id strings look like "shell_1", "shell_2", etc.
    # "Started" results contain "Background process started" or "Shell ID: shell_N"
    # "Completed" results contain "has been terminated", "exited with", "completed", "Exit code"

    ( $msgs[]
      | select(.role == "tool")
      | ( if (.content | type) == "array" then .content[].text // "" else .content // "" end )
      | select(type == "string")
      | scan("Shell ID: (shell_[0-9]+)")
    ) as $started_id |

    # Pass 2: collect all shell IDs that have a completion/termination result
    ( [ $msgs[]
        | select(.role == "tool")
        | ( if (.content | type) == "array" then .content[].text // "" else .content // "" end )
        | select(type == "string")
        | select(
            test("has been terminated|exited with|Exit code|completed|finished|process ended"; "i")
          )
        | scan("shell_[0-9]+")
      ] | unique
    ) as $done_ids |

    # A shell is "active" if started but not in done list
    $started_id | select(. as $id | $done_ids | index($id) | not)
  ' "$transcript" 2>/dev/null | sort -u)

  if [ -n "$bg_info" ]; then
    bg_count=$(echo "$bg_info" | wc -l | tr -d ' ')
    bg_ids=$(echo "$bg_info" | tr '\n' ',' | sed 's/,$//')
    bg_part=" | bg:[${bg_ids}]"
  else
    bg_part=""
  fi
else
  bg_part=""
fi

# --- Assemble output ---
if [ -n "$used_pct" ]; then
  bar=$(build_bar "$used_pct")
  ctx_part="[${bar}] ${used_pct}% used"
else
  ctx_part="[----------] --% used"
fi

printf "%s | %s%s%s" \
  "$model" \
  "$ctx_part" \
  "$agent_info" \
  "$bg_part"
