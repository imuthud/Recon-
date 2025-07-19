#!/bin/bash

set -e
set -o pipefail

show_help() {
  echo "Usage: $0 -d <domain>"
  exit 1
}

# Parse arguments
while getopts "d:" opt; do
  case $opt in
    d) domain="$OPTARG" ;;
    *) show_help ;;
  esac
done

[ -z "$domain" ] && show_help

project="recon-$domain"
mkdir -p "$project"
cd "$project"

echo "[*] Subdomain Enumeration"
parallel --halt soon,fail=1 --tag ::: \
  "subfinder -d $domain -silent > subfinder.txt" \
  "assetfinder --subs-only $domain > assetfinder.txt" \
  "findomain -t $domain -q > findomain.txt" \
  "puredns bruteforce ../wordlist.txt $domain --resolvers ../resolvers.txt --write puredns.txt" \
  "python3 ../ctfr.py -d $domain -o crtsh.txt"
wait
cat subfinder.txt assetfinder.txt findomain.txt puredns.txt crtsh.txt | sort -u > all_subs.txt

echo "[*] Subdomain Validation"
dnsx -silent -l all_subs.txt -o live_subs.txt

echo "[*] URL & Content Gathering"
parallel --halt soon,fail=1 --tag ::: \
  "gau < live_subs.txt > gau.txt" \
  "waybackurls < live_subs.txt > wayback.txt" \
  "hakrawler -depth 1 -insecure -subs < live_subs.txt > hak.txt" \
  "katana -jc -fs < live_subs.txt > katana.txt"
wait
cat gau.txt wayback.txt hak.txt katana.txt | sort -u > all_urls.txt

echo "[*] JavaScript File Extraction"
grep -Ei "\.js(\?|$)" all_urls.txt | sort -u > js_files.txt

echo "[*] JavaScript Secrets & Key/Leak Analysis"
parallel --halt soon,fail=1 --tag ::: \
  "cat js_files.txt | while read url; do curl -s \"\$url\" | gf secrets; done > possible_secrets.txt" \
  "python3 ../SecretFinder.py -i js_files.txt -o cli > secretfinder.txt" \
  "jsleak -i js_files.txt > jsleak.txt"
wait
cat possible_secrets.txt secretfinder.txt jsleak.txt | sort -u > all_js_leaks.txt

echo "[*] Sensitive Files & Bucket Discovery"
grep -Ei '\.(csv|docx?|xlsx?|xml|sql|log|conf|bak|env|ini|json|pem|pfx|db|zip|gz|tar|rar)(\?|$)' all_urls.txt | sort -u > sensitive_files.txt
grep -Eo '([a-zA-Z0-9.-]+\.s3\.amazonaws\.com|s3\.[a-z0-9-]+\.amazonaws\.com/[a-zA-Z0-9._-]+)' all_urls.txt js_files.txt | sort -u > bucket.txt

echo "[*] Open Port Scanning"
parallel --halt soon,fail=1 --tag ::: \
  "naabu -iL live_subs.txt -top-ports 1000 -o naabu_ports.txt" \
  "rustscan -a live_subs.txt -r 1-10000 | tee rustscan_ports.txt"
wait
cat naabu_ports.txt rustscan_ports.txt | sort -u > open_ports.txt

echo "[*] Directory & File Fuzzing"
parallel -j 10 "ffuf -w ../directory-list.txt -u https://{}/FUZZ -mc 200,403,401 -t 50 -o ffuf-{}.json" :::: live_subs.txt

echo "[*] Tech Stack & Sensitive Endpoint Scanning"
httpx -l live_subs.txt -tech-detect -title -status-code -web-server -o stack_info.txt

paths=("/server-status" "/phpinfo.php" "/.git/" "/.env" "/config" "/wp-config.php" "/admin" "/manager/html" "/drupal/CHANGELOG.txt" "/nginx_status")
while read url; do
  for path in "${paths[@]}"; do
    code=$(curl -sk -o /dev/null -w "%{http_code}" "$url$path")
    [[ "$code" =~ ^2|3|4 ]] && echo "$url$path => $code"
  done
done < live_subs.txt > sensitive_paths.txt

echo "[*] Recon Automation Complete for $domain"
