#!/usr/bin/env bash
# Check that a URL - or a minted aftv.news code - behaves the way the Downloader
# app needs it to on an Nvidia Shield / Fire TV / Google TV box.
#
# Downloader fails quietly in ways a browser does not. It names the saved file
# from the response, so a target that does not resolve to a .apk gets saved as
# something Android refuses to open, and an HTML response gets rendered as a
# page instead of downloaded. Both look like "nothing happened" on a TV.
#
#   ./scripts/check-downloader-url.sh                 # the permanent APK URL
#   ./scripts/check-downloader-url.sh 123456          # a minted Downloader code
#   ./scripts/check-downloader-url.sh https://host/x.apk
#
# Exits non-zero if the target would not install cleanly.

set -uo pipefail

DEFAULT_URL="https://github.com/Devils-XDK/xdk-flix-plugin-dist/releases/latest/download/XDKNet_AndroidTV.apk"

arg="${1:-$DEFAULT_URL}"

# Downloader treats bare digits as a code and resolves them against aftv.news.
# Mirror that here so a code can be checked end to end after it is minted.
if [[ "$arg" =~ ^[0-9]+$ ]]; then
  url="https://aftv.news/$arg"
  echo "Code $arg -> $url"
elif [[ "$arg" =~ ^https?:// ]]; then
  url="$arg"
else
  url="https://$arg"
fi

fail=0
note()  { printf '  %-6s %s\n' "$1" "$2"; }
pass_() { note "OK"   "$1"; }
warn_() { note "WARN" "$1"; }
bad_()  { note "FAIL" "$1"; fail=1; }
info_() { note "INFO" "$1"; }

echo "Checking: $url"
echo

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
hdr="$tmp/h"

# One ranged GET: cheap (a single byte of a 77 MB file) but it still walks the
# whole redirect chain and returns the real headers of the final response.
read -r status final ctype <<<"$(
  curl -sSL -r 0-3 -D "$hdr" -o "$tmp/body" --max-time 60 \
    -w '%{http_code} %{url_effective} %{content_type}' "$url" 2>/dev/null
)"

if [[ -z "${status:-}" || "$status" == "000" ]]; then
  bad_ "unreachable - Downloader will show a connection error"
  echo; echo "RESULT: FAIL"; exit 1
fi

# 200 for a plain GET, 206 when the server honours the range probe.
if [[ "$status" == "200" || "$status" == "206" ]]; then
  pass_ "reachable (HTTP $status)"
else
  bad_ "HTTP $status - Downloader needs a 200"
fi

# Take the last value seen, i.e. the final response after all redirects.
last_header() {
  tr -d '\r' < "$hdr" | grep -i "^$1:" | tail -1 | cut -d: -f2- | sed 's/^ *//'
}

if [[ "$final" != "$url" ]]; then
  # Release assets land on a signed URL whose path is a bare UUID, so the host
  # is the useful part to report; the full query string is noise.
  info_ "redirects to ${final%%\?*}"
fi

# Downloader names the file from Content-Disposition when the server sends one,
# and falls back to the final URL path when it does not.
cd_header=$(last_header 'content-disposition')
cd_name=$(sed -n 's/.*filename\*\?=\(.*\)/\1/p' <<<"$cd_header" \
          | tr -d '"' | sed "s/^UTF-8''//" | sed 's/;.*//' | tail -1)
path_name="${final##*/}"; path_name="${path_name%%\?*}"

if [[ -n "$cd_name" ]]; then
  filename="$cd_name"; source="Content-Disposition"
else
  filename="$path_name"; source="the URL path"
fi

if [[ "$filename" == *.apk ]]; then
  pass_ "saves as '$filename' (from $source)"
  if [[ -n "$cd_name" && "$path_name" != *.apk ]]; then
    # Worth stating plainly: the .apk name exists only in a header here. Every
    # current Downloader build honours it, but the URL alone does not say .apk.
    info_ "the URL path itself is not a .apk - the name comes from the header"
  fi
else
  bad_ "saves as '$filename' (from $source) - not .apk, so the install prompt never appears"
fi

# A code is minted once and then shared forever, so a version in the filename
# is a time bomb: the URL works today and 404s the day the next build ships.
if [[ "$filename" =~ [0-9]+\.[0-9]+ ]]; then
  bad_ "'$filename' has a version in its name - this URL breaks on the next release; point the code at a fixed-name asset"
else
  pass_ "no version in the filename - the URL survives future releases"
fi

ctype="${ctype%%;*}"
case "$ctype" in
  application/vnd.android.package-archive)
    pass_ "content-type $ctype" ;;
  application/octet-stream|binary/octet-stream)
    pass_ "content-type $ctype (fine - the filename decides)" ;;
  text/html*)
    bad_ "content-type $ctype - Downloader renders this as a page, it does not download it" ;;
  text/plain*)
    bad_ "content-type $ctype - not a binary download; usually an error page, or HTML served by raw.githubusercontent.com" ;;
  *)
    warn_ "content-type $ctype - unusual, verify on a real device" ;;
esac

# With a range request the total is in Content-Range (bytes 0-0/77174534);
# Content-Length would just say 1.
size=$(last_header 'content-range' | sed 's#.*/##' | tr -dc '0-9')
[[ -z "$size" ]] && size=$(last_header 'content-length' | tr -dc '0-9')

if [[ -n "$size" ]] && (( size > 1048576 )); then
  pass_ "size $(( size / 1048576 )) MB"
elif [[ -n "$size" ]] && (( size > 1 )); then
  bad_ "size $size bytes - far too small to be the app"
else
  warn_ "server did not report a size - Downloader cannot show a progress bar"
fi

# A real APK is a zip, so the first bytes are the local file header magic.
if [[ -s "$tmp/body" ]] && [[ "$(head -c2 "$tmp/body")" == "PK" ]]; then
  pass_ "starts with a zip header - this is a real APK"
else
  warn_ "could not confirm the zip header (server may ignore range requests)"
fi

echo
if (( fail )); then
  echo "RESULT: FAIL - do not point a Downloader code at this URL."
  exit 1
fi
echo "RESULT: PASS - safe to mint a Downloader code for this URL at https://go.aftvnews.com"
