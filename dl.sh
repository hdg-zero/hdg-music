#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

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
Script is starting... Logs will be recorded in download.log
"

LOG_FILE="download.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to ensure required commands are installed
check_commands() {
    for cmd in yt-dlp ffmpeg; do
        if ! command -v "$cmd" &>/dev/null; then
            log "$cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Function to create the base directory for downloads
create_base_directory() {
    BASE_DIR="../02_MUSIC_DL"
    mkdir -p "$BASE_DIR"
}

# Function to download and process each URL
process_url() {
    local url="$1"
    local output_path="$BASE_DIR/%(artist)s/%(album)s/%(playlist_index)02d - %(title)s.%(ext)s"

    if [[ -f "${output_path//\%/}" ]]; then
        log "File already exists: ${output_path//\%/}"
        return
    fi

    yt-dlp -f bestaudio --quiet --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail \
           --add-metadata --parse-metadata "playlist_index:%(track_number)s" --concurrent-fragments 10 \
           --convert-thumbnails jpg --ppa "ffmpeg: -c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\"" \
           --output "$output_path" "$url" && log "Downloaded: $url"
}

# Function to rename artist folders to uppercase
rename_artist_folders() {
    find "$BASE_DIR" -type d | while read -r dir; do
        local parent_dir
        local base_name
        local upper_name

        parent_dir=$(dirname "$dir")
        base_name=$(basename "$dir")
        upper_name=$(echo "$base_name" | sed 'y/éèêëàáâäçùúûüîïôö/eeeeaaaacuuuuiioo/' | tr "[:lower:]" "[:upper:]")

       if [[ -d "$dir" ]]; then
            if [[ ! -d "$parent_dir/$upper_name" ]]; then
                mv -- "$dir" "$parent_dir/$upper_name" && log "Renamed folder: $dir to $parent_dir/$upper_name"
            else
                log "Folder already exists: $parent_dir/$upper_name. Skipping rename for $dir."
            fi
        else
            log "Source directory does not exist: $dir. Skipping rename."
        fi
    done
}

main() {
    check_commands
    create_base_directory

    URL_FILE="url.txt"
    if [[ ! -f "$URL_FILE" ]]; then
        log "$URL_FILE not found. Please ensure the file exists and try again."
        exit 1
    fi

    MAX_PROCESSES=12
    CURRENT_PROCESSES=0

    while IFS= read -r url || [[ -n "$url" ]]; do
        if [[ -n "$url" ]]; then
            log "Processing URL: $url"
            process_url "$url" &
            CURRENT_PROCESSES=$((CURRENT_PROCESSES + 1))

            if [[ $CURRENT_PROCESSES -ge $MAX_PROCESSES ]]; then
                wait -n
                CURRENT_PROCESSES=$((CURRENT_PROCESSES - 1))
            fi
        fi
    done < "$URL_FILE"

    wait

    rename_artist_folders
    log "Download process completed."
}

main
