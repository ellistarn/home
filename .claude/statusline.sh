#!/bin/bash
# Claude Code powerline statusline with git/k8s status

input=$(cat)
echo "$input" | jq -e . >/dev/null 2>&1 || { echo "⚠ invalid input"; exit 0; }

# Helper to extract JSON values
jq_get() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }

cwd=$(jq_get '.workspace.current_dir')
dir_name=$(basename "$cwd" 2>/dev/null || echo "?")

# Extract and clean model name
model=$(echo "$input" | jq -r 'if .model|type=="object" then .model.id//.model.name else .model end // "claude"' 2>/dev/null)
model=${model:-claude}; [[ $model == null ]] && model=claude
model=$(echo "$model" | sed 's/claude-//;s/-[0-9]*$//' | cut -c1-40)

# Colors
RST=$'\033[0m' BLD=$'\033[1m' BLK=$'\033[5m'
FG_BLK=$'\033[30m' FG_WHT=$'\033[97m'
BG_GRN=$'\033[42m' FG_GRN=$'\033[32m'
BG_BLU=$'\033[44m' FG_BLU=$'\033[34m'
SEP=''

# Git segment
git_seg="" next_fg=$FG_BLU
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [[ -z $branch ]] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    staged=$(echo "$status" | grep -c '^[MADRC]')
    modified=$(echo "$status" | grep -c '^.[MD]')
    untracked=$(echo "$status" | grep -c '^??')
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    git_status=""
    ((ahead>0)) && git_status+="⇡$ahead"; ((behind>0)) && git_status+="⇣$behind"
    ((staged>0)) && git_status+="+$staged"; ((modified>0)) && git_status+="!$modified"
    ((untracked>0)) && git_status+="?$untracked"

    if [[ -n $git_status ]]; then
        git_bg=$'\033[48;5;220m' git_fg=$'\033[38;5;220m'
        git_content="  $branch $git_status "
    else
        git_bg=$'\033[48;5;75m' git_fg=$'\033[38;5;75m'
        git_content="  $branch "
    fi
    git_seg="${FG_BLU}${git_bg}${SEP}${FG_BLK}${git_content}"
    next_fg=$git_fg
fi

# K8s segment
k8s_seg=""
k8s_ctx=$(kubectl config current-context 2>/dev/null)
if [[ -n $k8s_ctx && $k8s_ctx != null ]]; then
    case $k8s_ctx in
        arn:aws:eks:*) k8s_disp=${k8s_ctx##*cluster/} ;;
        gke_*) k8s_disp=$(echo "$k8s_ctx" | rev | cut -d_ -f1 | rev) ;;
        */*) k8s_disp=${k8s_ctx##*/} ;;
        *) k8s_disp=${k8s_ctx:0:25} ;;
    esac
    BG_PRP=$'\033[48;5;98m' FG_PRP=$'\033[38;5;98m'
    k8s_seg="${next_fg}${BG_PRP}${SEP}${FG_WHT}${BLD} ⎈ ${k8s_disp} ${RST}"
    next_fg=$FG_PRP
fi

# Context window segment
pct=$(printf "%.0f" "$(jq_get '.context_window.used_percentage')" 2>/dev/null || echo 0)
ctx_in=$(jq_get '.context_window.current_usage.input_tokens'); ctx_in=${ctx_in:-0}
ctx_out=$(jq_get '.context_window.current_usage.output_tokens'); ctx_out=${ctx_out:-0}
ctx_cache=$(jq_get '.context_window.current_usage.cache_read_input_tokens'); ctx_cache=${ctx_cache:-0}
tokens=$((ctx_in + ctx_out + ctx_cache))
cache_total=$((ctx_cache + ctx_in))
cache_pct=0; ((cache_total>0)) && cache_pct=$((ctx_cache * 100 / cache_total))

empty_bg=$'\033[48;5;236m' empty_fg=$'\033[38;5;236m'
ctx_seg="${next_fg}${empty_bg}${SEP}${FG_WHT} --% --% ${RST}"

if ((pct >= 0)) 2>/dev/null; then
    ((tokens>=1000)) && tok_disp="$((tokens/1000))k" || { ((tokens>0)) && tok_disp="$tokens" || tok_disp=""; }

    bar_blink=""
    if ((pct>95)); then fill_bg=$'\033[48;5;196m' fill_fg=$'\033[38;5;196m' bar_blink=$BLK
    elif ((pct>85)); then fill_bg=$'\033[48;5;208m' fill_fg=$'\033[38;5;208m'
    elif ((pct>70)); then fill_bg=$'\033[48;5;220m' fill_fg=$'\033[38;5;220m'
    else fill_bg=$'\033[48;5;78m' fill_fg=$'\033[38;5;78m'; fi

    ctx_content=" ${tok_disp} (${pct}%) "
    len=${#ctx_content} fill=$((pct * len / 100)); ((fill>len)) && fill=$len

    bar=""
    for ((i=0; i<len; i++)); do
        ((i<fill)) && bar+="${fill_bg}${FG_BLK}${ctx_content:i:1}" || bar+="${empty_bg}${FG_WHT}${ctx_content:i:1}"
    done
    ctx_seg="${next_fg}${fill_bg}${SEP}${bar_blink}${bar}${RST}"
fi
next_fg=$empty_fg

# Session cost segment
sess_seg=""
cost=$(jq_get '.cost.total_cost_usd')
if [[ -n $cost ]] && (( $(echo "$cost > 0" | bc 2>/dev/null || echo 0) )); then
    BG_GRY=$'\033[48;5;240m' FG_GRY=$'\033[38;5;240m'
    sess_seg="${next_fg}${BG_GRY}${SEP}${FG_WHT} $(printf '$%.2f' "$cost") (${cache_pct}%) ${RST}"
    next_fg=$FG_GRY
fi

# Output
echo -n "${BG_GRN}${FG_BLK}${BLD} 󰚩 $model ${RST}"
echo -n "${FG_GRN}${BG_BLU}${SEP}${FG_BLK}  $dir_name ${RST}"
echo -n "$git_seg$k8s_seg$ctx_seg$sess_seg${next_fg}${RST}${SEP}"
