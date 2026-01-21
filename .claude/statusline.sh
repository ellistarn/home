#!/bin/bash
# Claude Code statusline with powerline style and git status
# Uses nerd fonts and ANSI colors for rainbow effect

input=$(cat)

# Validate JSON and extract fields safely
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
    echo "⚠ invalid input"
    exit 0
fi

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
dir_name=$(basename "$cwd" 2>/dev/null || echo "?")

# Extract model - could be string or object with .id field
model=$(echo "$input" | jq -r '
  if .model | type == "object" then .model.id // .model.name // "claude"
  elif .model | type == "string" then .model
  else "claude"
  end
' 2>/dev/null)
[ -z "$model" ] || [ "$model" = "null" ] && model="claude"
# Clean up model name - remove claude- prefix and date suffix, truncate
model=$(echo "$model" | sed 's/claude-//' | sed 's/-[0-9]*$//' | cut -c1-40)

# ANSI color codes (using $'...' for proper escape handling)
RESET=$'\033[0m'
BG_BLUE=$'\033[44m'
FG_BLUE=$'\033[34m'
BG_GREEN=$'\033[42m'
FG_GREEN=$'\033[32m'
BG_YELLOW=$'\033[43m'
FG_YELLOW=$'\033[33m'
BG_CYAN=$'\033[46m'
FG_CYAN=$'\033[36m'
BG_RED=$'\033[41m'
FG_RED=$'\033[31m'
BG_ORANGE=$'\033[48;5;208m'
FG_ORANGE=$'\033[38;5;208m'
BG_MAGENTA=$'\033[45m'
FG_MAGENTA=$'\033[35m'
FG_BLACK=$'\033[30m'
FG_WHITE=$'\033[97m'
BOLD=$'\033[1m'
BLINK=$'\033[5m'

# Powerline separator
SEP=''

# Git info - git color changes based on dirty status, model stays constant
git_segment=""
model_bg=$BG_GREEN
model_fg=$FG_GREEN
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    # Get status counts
    status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    staged=$(echo "$status" | grep -c '^[MADRC]')
    modified=$(echo "$status" | grep -c '^.[MD]')
    untracked=$(echo "$status" | grep -c '^??')

    # Ahead/behind
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    # Build compact git status (starship style)
    git_status=""
    [ "$ahead" -gt 0 ] 2>/dev/null && git_status+="⇡$ahead"
    [ "$behind" -gt 0 ] 2>/dev/null && git_status+="⇣$behind"
    [ "$staged" -gt 0 ] && git_status+="+$staged"
    [ "$modified" -gt 0 ] && git_status+="!$modified"
    [ "$untracked" -gt 0 ] && git_status+="?$untracked"

    # Git color: green when clean, yellow/orange when dirty
    BG_LTBLUE=$'\033[48;5;75m'
    FG_LTBLUE=$'\033[38;5;75m'
    BG_LTYELLOW=$'\033[48;5;220m'
    FG_LTYELLOW=$'\033[38;5;220m'
    if [ -n "$git_status" ]; then
        # Dirty - yellow background
        git_bg=$BG_LTYELLOW
        git_fg=$FG_LTYELLOW
        git_content="  $branch $git_status "
    else
        # Clean - light blue background
        git_bg=$BG_LTBLUE
        git_fg=$FG_LTBLUE
        git_content="  $branch "
    fi
    git_segment="${FG_BLUE}${git_bg}${SEP}${FG_BLACK}${git_content}"
    next_fg=$git_fg
    next_bg=$BG_CYAN
else
    next_fg=$FG_BLUE
    next_bg=$BG_CYAN
fi

# Kubernetes context
k8s_segment=""
k8s_context=$(kubectl config current-context 2>/dev/null)
if [ -n "$k8s_context" ] && [ "$k8s_context" != "null" ]; then
    # Extract cluster name from various cloud provider formats
    if [[ "$k8s_context" == arn:aws:eks:* ]]; then
        # EKS ARN: arn:aws:eks:region:account:cluster/name
        k8s_display=$(echo "$k8s_context" | sed 's|.*cluster/||')
    elif [[ "$k8s_context" == gke_* ]]; then
        # GKE: gke_project_region_name
        k8s_display=$(echo "$k8s_context" | rev | cut -d_ -f1 | rev)
    elif [[ "$k8s_context" == */* ]]; then
        # Generic path-like format
        k8s_display=$(echo "$k8s_context" | rev | cut -d/ -f1 | rev)
    else
        # Use context name directly (truncate if long)
        k8s_display=$(echo "$k8s_context" | cut -c1-25)
    fi

    BG_PURPLE=$'\033[48;5;98m'
    FG_PURPLE=$'\033[38;5;98m'
    k8s_segment="${next_fg}${BG_PURPLE}${SEP}${FG_WHITE}${BOLD} ⎈ ${k8s_display} ${RESET}"
    next_fg=$FG_PURPLE
fi

# Context segment - progress bar showing context window usage
context_segment=""

# Use native used_percentage from API (resets properly after /clear)
pct=$(echo "$input" | jq '.context_window.used_percentage // 0' 2>/dev/null)
# Round to integer for display
pct=$(printf "%.0f" "$pct" 2>/dev/null || echo "0")

# Get current context tokens for display
ctx_input=$(echo "$input" | jq '.context_window.current_usage.input_tokens // 0' 2>/dev/null)
ctx_output=$(echo "$input" | jq '.context_window.current_usage.output_tokens // 0' 2>/dev/null)
ctx_cache_read=$(echo "$input" | jq '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
tokens=$((ctx_input + ctx_output + ctx_cache_read))

# Cache hit rate calculation
cache_pct=0
cache_total=$((ctx_cache_read + ctx_input))
if [ "$cache_total" -gt 0 ] 2>/dev/null; then
    cache_pct=$((ctx_cache_read * 100 / cache_total))
fi

if [ -n "$pct" ] && [ "$pct" != "null" ] && [ "$pct" -ge 0 ] 2>/dev/null; then

    # Format tokens with k suffix
    if [ -n "$tokens" ] && [ "$tokens" != "null" ] && [ "$tokens" -ge 1000 ] 2>/dev/null; then
        tokens_display="$((tokens / 1000))k"
    elif [ -n "$tokens" ] && [ "$tokens" != "null" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
        tokens_display="${tokens}"
    else
        tokens_display=""
    fi

    # Choose fill color based on usage
    if [ "$pct" -gt 95 ]; then
        fill_bg=$'\033[48;5;196m'  # red
        fill_fg=$'\033[38;5;196m'
        bar_blink=$BLINK
    elif [ "$pct" -gt 85 ]; then
        fill_bg=$'\033[48;5;208m'  # orange
        fill_fg=$'\033[38;5;208m'
        bar_blink=""
    elif [ "$pct" -gt 70 ]; then
        fill_bg=$'\033[48;5;220m'  # yellow
        fill_fg=$'\033[38;5;220m'
        bar_blink=""
    else
        fill_bg=$'\033[48;5;78m'   # green
        fill_fg=$'\033[38;5;78m'
        bar_blink=""
    fi
    empty_bg=$'\033[48;5;236m'  # dark gray for unfilled
    empty_fg=$'\033[38;5;236m'

    # Build content string with padding
    # Show tokens and context usage %
    ctx_content=" ${tokens_display} (${pct}%) "

    # Calculate fill point
    content_len=${#ctx_content}
    fill_chars=$((pct * content_len / 100))
    [ "$fill_chars" -gt "$content_len" ] && fill_chars=$content_len

    # Build segment char by char with appropriate background
    bar_output=""
    for ((i=0; i<content_len; i++)); do
        char="${ctx_content:$i:1}"
        if [ "$i" -lt "$fill_chars" ]; then
            bar_output+="${fill_bg}${FG_BLACK}${char}"
        else
            bar_output+="${empty_bg}${FG_WHITE}${char}"
        fi
    done

    context_segment="${next_fg}${fill_bg}${SEP}${bar_blink}${bar_output}${RESET}"
    next_fg=$empty_fg
fi

# Fallback if no context data
if [ -z "$context_segment" ]; then
    empty_bg=$'\033[48;5;236m'
    empty_fg=$'\033[38;5;236m'
    context_segment="${next_fg}${empty_bg}${SEP}${FG_WHITE} --% --% ${RESET}"
    next_fg=$empty_fg
fi

# Session segment - cumulative cost and stats
session_segment=""
cost=$(echo "$input" | jq '.cost.total_cost_usd // 0' 2>/dev/null)
if [ -n "$cost" ] && [ "$cost" != "null" ] 2>/dev/null; then
    # Check if cost is non-zero (handle floating point)
    cost_check=$(echo "$cost > 0" | bc 2>/dev/null || echo "0")
    if [ "$cost_check" = "1" ] || [ "$cost" != "0" ]; then
        cost_display=$(printf "\$%.2f" "$cost")

        # Build session display: $5.63 (99%)
        session_content=" ${cost_display} (${cache_pct}%) "

        BG_GRAY=$'\033[48;5;240m'
        FG_GRAY=$'\033[38;5;240m'
        session_segment="${next_fg}${BG_GRAY}${SEP}${FG_WHITE}${session_content}${RESET}"
        next_fg=$FG_GRAY
    fi
fi

# Build output with powerline style
# Model: green background with robot icon
echo -n "${model_bg}${FG_BLACK}${BOLD} 󰚩 $model ${RESET}"
echo -n "${model_fg}${BG_BLUE}${SEP}${FG_BLACK}  $dir_name ${RESET}"
echo -n "$git_segment"
echo -n "$k8s_segment"
echo -n "$context_segment"
echo -n "$session_segment"
echo -n "${next_fg}${RESET}${SEP}"
