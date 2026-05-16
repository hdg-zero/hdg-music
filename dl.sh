#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="${LOG_FILE:-download.log}"
ERROR_LOG_FILE="${ERROR_LOG_FILE:-error.log}"
BASE_DIR="${BASE_DIR:-../02_MUSIC_DL}"
URL_FILE="${URL_FILE:-url.txt}"

MAX_PROCESSES="${MAX_PROCESSES:-4}"
FRAGMENTS="${FRAGMENTS:-4}"

AUDIO_FORMAT="${AUDIO_FORMAT:-mp3}"
AUDIO_QUALITY="${AUDIO_QUALITY:-0}"

REMOTE_COMPONENTS="${REMOTE_COMPONENTS:-ejs:github}"

# Optionnel : mets par exemple ARCHIVE_FILE=downloaded.txt pour éviter les doublons.
ARCHIVE_FILE="${ARCHIVE_FILE:-}"

# 1 = sortie yt-dlp moins bruyante en parallèle.
NO_PROGRESS="${NO_PROGRESS:-1}"

JS_RUNTIME_ARGS=()
CHILD_PIDS=()

print_banner() {
  cat <<'EOF'
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
/:::/    |:::::::::\____\     /::::::::::\____\ /:::/____/     \:::|    | /::\   \:::\   \:::\____\
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
EOF
}

log() {
  printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

log_error() {
  local msg
  msg="$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $*"
  printf '%s\n' "$msg" | tee -a "$LOG_FILE" "$ERROR_LOG_FILE" >&2
}

die() {
  log_error "$*"
  exit 1
}

cleanup() {
  local pid

  printf '\nInterruption détectée. Arrêt des téléchargements en cours...\n' >&2
  trap - SIGINT SIGTERM

  for pid in "${CHILD_PIDS[@]}"; do
    if command -v pkill >/dev/null 2>&1; then
      pkill -TERM -P "$pid" 2>/dev/null || true
    fi
    kill "$pid" 2>/dev/null || true
  done

  wait 2>/dev/null || true
  exit 130
}

is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

init_logs() {
  mkdir -p -- "$(dirname -- "$LOG_FILE")" "$(dirname -- "$ERROR_LOG_FILE")"
  : > "$LOG_FILE"
  : > "$ERROR_LOG_FILE"
}

validate_config() {
  is_positive_int "$MAX_PROCESSES" || die "MAX_PROCESSES doit être un entier positif : $MAX_PROCESSES"
  is_positive_int "$FRAGMENTS" || die "FRAGMENTS doit être un entier positif : $FRAGMENTS"

  [[ -f "$URL_FILE" ]] || die "$URL_FILE introuvable."
}

check_commands() {
  local cmd

  for cmd in yt-dlp ffmpeg ffprobe find sed tr; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd n'est pas installé."
  done
}

detect_js_runtime() {
  local runtime_path

  if runtime_path=$(command -v deno 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "deno:$runtime_path")
  elif runtime_path=$(command -v node 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "node:$runtime_path")
  elif runtime_path=$(command -v nodejs 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "node:$runtime_path")
  elif runtime_path=$(command -v quickjs 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "quickjs:$runtime_path")
  elif runtime_path=$(command -v qjs 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "quickjs:$runtime_path")
  elif runtime_path=$(command -v bun 2>/dev/null); then
    JS_RUNTIME_ARGS=(--js-runtimes "bun:$runtime_path")
  else
    log "Aucun runtime JS trouvé. Certaines vidéos peuvent être indisponibles."
    return 0
  fi

  log "JS runtime détecté : ${JS_RUNTIME_ARGS[1]}"
}

create_base_directory() {
  mkdir -p -- "$BASE_DIR"
}

trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "$value"
}

process_url() {
  local url="$1"
  local output_template
  local -a archive_arg=()
  local -a progress_arg=()
  local -a remote_components_arg=()

  output_template='%(artist,uploader,channel|UNKNOWN_ARTIST)s/%(album,playlist_title|SINGLES)s/%(playlist_index&{} - |)s%(title)s.%(ext)s'

  [[ -n "$ARCHIVE_FILE" ]] && archive_arg=(--download-archive "$ARCHIVE_FILE")
  [[ "$NO_PROGRESS" == "1" ]] && progress_arg=(--no-progress)
  [[ -n "$REMOTE_COMPONENTS" ]] && remote_components_arg=(--remote-components "$REMOTE_COMPONENTS")

  if yt-dlp "${JS_RUNTIME_ARGS[@]}" \
      "${remote_components_arg[@]}" \
      "${progress_arg[@]}" \
      "${archive_arg[@]}" \
      -f "bestaudio/best" \
      --extract-audio \
      --audio-format "$AUDIO_FORMAT" \
      --audio-quality "$AUDIO_QUALITY" \
      --embed-metadata \
      --parse-metadata "%(playlist_index|)s:%(track_number)s" \
      --embed-thumbnail \
      --convert-thumbnails jpg \
      --ppa 'ThumbnailsConvertor+ffmpeg_o:-c:v mjpeg -vf "crop=min(iw\,ih):min(iw\,ih)"' \
      --concurrent-fragments "$FRAGMENTS" \
      --paths "home:$BASE_DIR" \
      --output "$output_template" \
      --windows-filenames \
      -- "$url"; then
    log "Téléchargement réussi : $url"
  else
    local rc=$?
    log_error "Échec du téléchargement : $url"
    return "$rc"
  fi
}

normalize_folder_name() {
  local name="$1"

  if command -v iconv >/dev/null 2>&1; then
    name=$(printf '%s' "$name" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "$name")
  fi

  name=$(
    printf '%s' "$name" \
      | LC_ALL=C tr '[:lower:]' '[:upper:]' \
      | LC_ALL=C sed -E 's/[^A-Z0-9._ -]+/_/g; s/[[:space:]]+/ /g; s/^ +| +$//g; s/_{2,}/_/g'
  )

  [[ -n "$name" ]] || name="_"
  printf '%s' "$name"
}

unique_target() {
  local target="$1"
  local dir base stem ext n candidate

  [[ ! -e "$target" ]] && {
    printf '%s' "$target"
    return 0
  }

  dir=$(dirname -- "$target")
  base=$(basename -- "$target")

  if [[ "$base" == *.* && "$base" != .* ]]; then
    stem="${base%.*}"
    ext=".${base##*.}"
  else
    stem="$base"
    ext=""
  fi

  n=1
  while :; do
    candidate="$dir/${stem} ($n)$ext"
    [[ ! -e "$candidate" ]] && {
      printf '%s' "$candidate"
      return 0
    }
    n=$((n + 1))
  done
}

merge_tree() {
  local src="$1"
  local dst="$2"
  local item base target

  mkdir -p -- "$dst"
  shopt -s dotglob nullglob

  for item in "$src"/*; do
    base=$(basename -- "$item")
    target="$dst/$base"

    if [[ -d "$item" && -d "$target" ]]; then
      merge_tree "$item" "$target"
    else
      target=$(unique_target "$target")
      if ! mv -- "$item" "$target"; then
        log_error "Impossible de déplacer $item vers $target"
      fi
    fi
  done

  shopt -u dotglob nullglob
  rmdir -- "$src" 2>/dev/null || true
}

rename_artist_folders() {
  local dir base_name normalized_name parent_dir target_dir tmp
  local -a dirs=()

  while IFS= read -r -d '' dir; do
    dirs+=("$dir")
  done < <(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue

    parent_dir=$(dirname -- "$dir")
    base_name=$(basename -- "$dir")
    normalized_name=$(normalize_folder_name "$base_name")
    target_dir="$parent_dir/$normalized_name"

    [[ "$base_name" == "$normalized_name" ]] && continue

    if [[ -e "$target_dir" && "$dir" -ef "$target_dir" ]]; then
      tmp="$parent_dir/.rename-${$}-${RANDOM}"
      while [[ -e "$tmp" ]]; do
        tmp="$parent_dir/.rename-${$}-${RANDOM}"
      done

      mv -- "$dir" "$tmp"
      mv -- "$tmp" "$target_dir"
      log "Dossier renommé : $base_name -> $normalized_name"

    elif [[ ! -e "$target_dir" ]]; then
      mv -- "$dir" "$target_dir"
      log "Dossier renommé : $base_name -> $normalized_name"

    else
      merge_tree "$dir" "$target_dir"
      log "Dossier fusionné : $base_name -> $normalized_name"
    fi
  done
}

run_download() {
  local url="$1"

  log "Début : $url"
  process_url "$url"
}

main() {
  trap cleanup SIGINT SIGTERM

  init_logs
  print_banner
  log "Script démarré. Logs : $LOG_FILE ; erreurs : $ERROR_LOG_FILE"

  validate_config
  check_commands
  detect_js_runtime
  create_base_directory

  local failed=0
  local running=0
  local url

  while IFS= read -r url || [[ -n "$url" ]]; do
    url=$(trim "$url")

    [[ -z "$url" || "$url" == \#* ]] && continue

    run_download "$url" &
    CHILD_PIDS+=("$!")
    running=$((running + 1))

    if (( running >= MAX_PROCESSES )); then
      if ! wait -n; then
        failed=$((failed + 1))
      fi
      running=$((running - 1))
    fi
  done < "$URL_FILE"

  while (( running > 0 )); do
    if ! wait -n; then
      failed=$((failed + 1))
    fi
    running=$((running - 1))
  done

  log "Formatage des dossiers d'artistes..."
  rename_artist_folders

  if (( failed > 0 )); then
    log_error "Terminé avec $failed téléchargement(s) en échec. Voir $ERROR_LOG_FILE."
    return 1
  fi

  log "Téléchargement terminé sans erreur."
}

main "$@"