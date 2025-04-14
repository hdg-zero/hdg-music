#!/usr/bin/env bash

set -o pipefail
set -u

LOG_FILE="download.log"
ERROR_LOG_FILE="error.log"
BASE_DIR="../02_MUSIC_DL"
URL_FILE="url.txt"
MAX_PROCESSES=12

echo "
          _____                 _____                     _____                     _____          
         /\    \               |\    \                   /\    \                   /\    \         
        /::\____\              |:\____\                 /::\    \                 /::\    \        
       /::::|   |              |::|   |                /::::\    \               /::::\    \       
      /:::::|   |              |::|   |               /::::::\    \             /::::::\    \      
     /::::::|   |              |::|   |              /:::/\:::\    \           /:::/\:::\    \     
    /:::/|::|   |              |::|   |             /:::/  \:::\    \         /:::/__\:::\    \    
   /:::/ |::|   |              |::|   |            /:::/    \:::\    \        \:::\   \:::\    \   
  /:::/  |::|___|______        |::|___|______     /:::/    / \:::\    \     ___\:::\   \:::\    \  
 /:::/   |::::::::\    \       /::::::::\    \   /:::/    /   \:::\ ___\   /\   \:::\   \:::\    \ 
/:::/    |:::::::::\____\     /::::::::::\____\ /:::/____/     \:::|    | /::\   \:::\   \:::\____\\
\::/    / ~~~~~/:::/    /    /:::/~~~~/~~/____/ \:::\    \     /:::|____| \:::\   \:::\   \::/    /
 \/____/      /:::/    /    /:::/    /           \:::\    \   /:::/    /   \:::\   \:::\   \/____/ 
             /:::/    /    /:::/    /             \:::\    \ /:::/    /     \:::\   \:::\    \     
            /:::/    /    /:::/    /               \:::\    /:::/    /       \:::\   \:::\____\    
           /:::/    /     \::/    /                 \:::\  /:::/    /         \:::\  /:::/    /    
          /:::/    /       \/____/                   \:::\/:::/    /           \:::\/:::/    /     
         /:::/    /                                   \::::::/    /             \::::::/    /      
        /:::/    /                                     \::::/    /               \::::/    /       
        \::/    /                                       \::/____/                 \::/    /        
         \/____/                                         ~~                        \/____/         
Music Youtube Downloader Script
Script is starting... Logs will be recorded in $LOG_FILE
"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$LOG_FILE" >> "$ERROR_LOG_FILE"
}

check_commands() {
    for cmd in yt-dlp ffmpeg; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "$cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

create_base_directory() {
    mkdir -p "$BASE_DIR"
}

process_url() {
    local url="$1"
    local output_path="$BASE_DIR/%(artist)s/%(album)s/%(playlist_index)02d - %(title)s.%(ext)s"

    yt-dlp -f bestaudio --quiet --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail \
           --add-metadata --parse-metadata "playlist_index:%(track_number)s" --concurrent-fragments 10 \
           --convert-thumbnails jpg --ppa "ffmpeg: -c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\"" \
           --output "$output_path" "$url"

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to process: $url"
        echo "⚠️  Failed to download album: $url"
        return $exit_code
    else
        log "✅ Successfully downloaded: $url"
    fi
}

rename_artist_folders() {
    find "$BASE_DIR" -type d | while read -r dir; do
        local parent_dir base_name upper_name
        parent_dir=$(dirname "$dir")
        base_name=$(basename "$dir")
        upper_name=$(echo "$base_name" | sed 'y/éèêëàáâäçùúûüîïôö/eeeeaaaacuuuuiioo/' | tr "[:lower:]" "[:upper:]")

        if [[ "$dir" != "$parent_dir/$upper_name" && ! -d "$parent_dir/$upper_name" ]]; then
            mv -- "$dir" "$parent_dir/$upper_name" && log "Renamed folder: $dir → $parent_dir/$upper_name"
        fi
    done
}

main() {
    check_commands
    create_base_directory

    if [[ ! -f "$URL_FILE" ]]; then
        log_error "$URL_FILE not found. Please provide the file and try again."
        exit 1
    fi

    > "$LOG_FILE"
    > "$ERROR_LOG_FILE"

    CURRENT_PROCESSES=0
    declare -a pids=()

    while IFS= read -r url || [[ -n "$url" ]]; do
        [[ -z "$url" ]] && continue

        (
            log "🚀 Starting download for: $url"
            if ! process_url "$url"; then
                log_error "❌ Error downloading: $url"
            fi
        ) &

        pids+=($!)
        CURRENT_PROCESSES=$((CURRENT_PROCESSES + 1))

        if (( CURRENT_PROCESSES >= MAX_PROCESSES )); then
            wait -n
            CURRENT_PROCESSES=$((CURRENT_PROCESSES - 1))
        fi
    done < "$URL_FILE"

    wait  # Wait for all background jobs to finish
    rename_artist_folders
    log "🎉 Download process completed. Check $ERROR_LOG_FILE for any failed albums."
}

main
