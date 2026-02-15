#!/bin/bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.cwd')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
project_name=$(basename "$project_dir")
output_style=$(echo "$input" | jq -r '.output_style.name')

lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
session_time_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
total_input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_cost=$(echo "$input" | jq -r '.cost.total_cost // 0')

context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
current_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
current_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
current_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current_cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')

if [ "$context_size" != "null" ] && [ "$context_size" -gt 0 ]; then
    current_total=$((current_input + current_output + current_cache_read + current_cache_create))
    context_pct=$((current_total * 100 / context_size))
    [ "$context_pct" -gt 100 ] && context_pct=100
    [ "$context_pct" -lt 0 ] && context_pct=0

    if [ "$context_size" -ge 1000000 ]; then
        max_display=$(awk "BEGIN {printf \"%.0fM\", $context_size/1000000}")
    elif [ "$context_size" -ge 1000 ]; then
        max_display=$(awk "BEGIN {printf \"%.0fK\", $context_size/1000}")
    else
        max_display="$context_size"
    fi

    if [ "$current_total" -ge 1000000 ]; then
        total_display=$(awk "BEGIN {printf \"%.0fK\", $current_total/1000}")
    elif [ "$current_total" -ge 1000 ]; then
        total_display=$(awk "BEGIN {printf \"%.0fK\", $current_total/1000}")
    else
        total_display="$current_total"
    fi
else
    context_pct=0
    max_display="?"
    total_display="0"
fi

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")

git_branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
            branch_color="90"
        elif echo "$branch" | grep -q "fix"; then
            branch_color="91"
        else
            branch_color="35"
        fi
        if git -C "$current_dir" diff --no-ext-diff --quiet --exit-code 2>/dev/null && \
           git -C "$current_dir" diff --cached --no-ext-diff --quiet --exit-code 2>/dev/null; then
            git_branch=$(printf " \033[37m(\033[${branch_color}m%s\033[37m)\033[0m" "$branch")
        else
            git_branch=$(printf " \033[37m(\033[${branch_color}m%s*\033[37m)\033[0m" "$branch")
        fi
    fi
fi

remaining_pct=$((100 - context_pct))

if [ "$remaining_pct" -le 20 ]; then
    bar_color="91"
elif [ "$remaining_pct" -le 40 ]; then
    bar_color="93"
else
    bar_color="92"
fi

bar_length=20
filled_length=$((context_pct * bar_length / 100))
empty_length=$((bar_length - filled_length))

progress_bar="["
for ((i=0; i<filled_length; i++)); do
    progress_bar+="█"
done
for ((i=0; i<empty_length; i++)); do
    progress_bar+="░"
done
progress_bar+="]"

if [ "$output_style" != "default" ] && [ "$output_style" != "null" ] && [ -n "$output_style" ]; then
    style_display=$(printf " \033[90m[%s]\033[0m" "$output_style")
else
    style_display=""
fi

if [ "$dir_name" != "$project_name" ]; then
    dir_display=$(printf "\033[36m%s\033[0m/\033[1;36m%s\033[0m" "$project_name" "$dir_name")
else
    dir_display=$(printf "\033[1;36m%s\033[0m" "$project_name")
fi

case "$model" in
    *Opus*)   model_color="1;33" ;;
    *Sonnet*) model_color="1;95" ;;
    *Haiku*)  model_color="1;32" ;;
    *)        model_color="1;36" ;;
esac

if [ "$total_cost" != "null" ]; then
    cost_display=$(awk "BEGIN {printf \"\$%.0f\", $total_cost}")
else
    cost_display="\$0"
fi

session_time_sec=$((session_time_ms / 1000))
session_hours=$((session_time_sec / 3600))
session_mins=$(((session_time_sec % 3600) / 60))
session_secs=$((session_time_sec % 60))

if [ "$session_hours" -gt 0 ]; then
    time_display=$(printf "%02d:%02d:%02d" "$session_hours" "$session_mins" "$session_secs")
else
    time_display=$(printf "%02d:%02d" "$session_mins" "$session_secs")
fi

if [ "$total_input_tokens" -ge 1000 ]; then
    input_display=$(awk "BEGIN {printf \"%.0fK\", $total_input_tokens/1000}")
else
    input_display="$total_input_tokens"
fi

if [ "$total_output_tokens" -ge 1000 ]; then
    output_display=$(awk "BEGIN {printf \"%.0fK\", $total_output_tokens/1000}")
else
    output_display="$total_output_tokens"
fi

printf "\033[${model_color}m%s\033[0m%s │ \033[${bar_color}m%s %d%%\033[0m \033[37m(%s)\033[0m │ \033[32m+%s\033[0m \033[31m-%s\033[0m │ ↓%s ↑%s │ %s%s │ \033[93m%s\033[0m │ \033[92m%s\033[0m" \
    "$model" "$style_display" "$progress_bar" "$context_pct" "$total_display" "$lines_added" "$lines_removed" "$input_display" "$output_display" "$dir_display" "$git_branch" "$time_display" "$cost_display"
