#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$REPO_ROOT/overlays/firmware-extended/10-firmware-config/root/usr/local/share/firmware-config/force-cleanup.sha256"

cd "$REPO_ROOT"

get_old_hash() {
    local commit=$1
    local file=$2
    git show "${commit}^:${file}" 2>/dev/null | sha256sum | cut -d' ' -f1
}

get_target_path() {
    local src=$1
    echo "$src" | sed 's|.*default-config/||'
}

declare -A commit_files
declare -a commit_order

while read -r line; do
    if [[ $line =~ ^([0-9a-f]{7,})\ (.*)$ ]]; then
        commit_hash="${BASH_REMATCH[1]}"
        commit_msg="${BASH_REMATCH[2]}"
        current_commit="$commit_hash"
        current_msg="$commit_msg"
        if [[ -z "${commit_files[$commit_hash]}" ]]; then
            commit_order+=("$commit_hash")
            commit_files["${commit_hash}_msg"]="$commit_msg"
        fi
    elif [[ -n $line && -n $current_commit ]]; then
        commit_files["${current_commit}_files"]+="$line"$'\n'
    fi
done < <(git log --oneline --diff-filter=M --name-only -- "**/default-config/extended/*.cfg" "**/default-config/extended/**/*.cfg")

: > "$OUTPUT_FILE"

for commit_hash in "${commit_order[@]}"; do
    commit_msg="${commit_files["${commit_hash}_msg"]}"
    files="${commit_files["${commit_hash}_files"]}"
    first_entry=true

    while IFS= read -r file; do
        [[ -z $file ]] && continue

        target_path=$(get_target_path "$file")
        old_hash=$(get_old_hash "$commit_hash" "$file")

        if [[ -n $old_hash && $old_hash != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]]; then
            if $first_entry; then
                echo "# $commit_msg ($commit_hash)" >> "$OUTPUT_FILE"
                first_entry=false
            fi
            echo "$old_hash  $target_path" >> "$OUTPUT_FILE"
        fi
    done <<< "$files"

    if ! $first_entry; then
        echo >> "$OUTPUT_FILE"
    fi
done

sed -i '${/^$/d;}' "$OUTPUT_FILE"

echo "Updated: $OUTPUT_FILE"
echo "Entries:"
grep -c "^[a-f0-9]" "$OUTPUT_FILE" || echo "0"
