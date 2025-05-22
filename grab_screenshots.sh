#!/usr/bin/env bash
set -euo pipefail

# list of timestamps (in minutes)
times=(
  0.25 0.5 0.75 1 1.25 1.5 1.75 2
  2.5 3 3.5 4 4.5 5 6 7 8 9 10
  12 14 16 18 20 25 30 35 40 45
  50 55 60 65 70
)

# extensions to try
exts=(mp4 mkv)

# top‐level output directory
outdir="Video Screenshots"
mkdir -p "$outdir"

for num in {1..20}; do
  found_any=false

  for ext in "${exts[@]}"; do
    infile="${num}_Cleaned.${ext}"
    if [[ -f "$infile" ]]; then
      found_any=true
      echo "Processing $infile …"

      # make per-video subfolder
      vid_out="$outdir/$num"
      mkdir -p "$vid_out"

      # get duration in seconds (float → int)
      duration=$(ffprobe -v error -show_entries format=duration \
                  -of default=noprint_wrappers=1:nokey=1 "$infile")
      dur_int=${duration%.*}

      for t in "${times[@]}"; do
        # total seconds (integer)
        seconds=$(awk "BEGIN { printf \"%d\", $t * 60 }")

        # skip if beyond file length
        if (( seconds > dur_int )); then
          echo " ⚠ Skipping ${t} min (>${dur_int}s) for $infile"
          continue
        fi

        # format as HH_MM_SS
        hrs=$(( seconds / 3600 ))
        mins=$(( (seconds % 3600) / 60 ))
        secs=$(( seconds % 60 ))
        time_label=$(printf "%02d_%02d_%02d" $hrs $mins $secs)

        outfile="$vid_out/${num}_${time_label}.png"

        ffmpeg \
          -hide_banner -loglevel error \
          -ss "$seconds" \
          -i "$infile" \
          -frames:v 1 \
          -q:v 2 \
          "$outfile"

        echo " → $outfile"
      done

      echo
    fi
  done

  if ! $found_any; then
    echo "Warning: no .mp4 or .mkv found for prefix ${num}_Cleaned, skipping."
  fi
done
