#!/bin/bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
output_style=$(echo "$input" | jq -r '.output_style.name')


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

case "$model" in
    *Opus*)   model_color="1;33" ;;
    *Sonnet*) model_color="1;95" ;;
    *Haiku*)  model_color="1;32" ;;
    *)        model_color="1;36" ;;
esac

printf "\033[${model_color}m%s\033[0m%s │ \033[${bar_color}m%s %d%%\033[0m \033[37m(%s)\033[0m" \
    "$model" "$style_display" "$progress_bar" "$context_pct" "$total_display"
