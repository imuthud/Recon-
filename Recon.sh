#!/bin/bash

set -e
set -o pipefail

### ========== CONFIGURATION ==========
# Default wordlists (can override via flags below)
WORDLIST="${WORDLIST:-wordlist.txt}"
DIRLIST="${DIRLIST:-directory-list.txt}"
RESOLVERS="${RESOLVERS:-resolvers.txt}"

### ========== COLORS ==========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

### ========== FUNCTIONS ==========

show_help() {
  echo -e "${YELLOW}Usage: $0 -d <domain>${RESET}"
  echo -e "Optional environment overrides:"
  echo -e "  WORDLIST='my-wordlist.txt'"
  echo -e "  DIRLIST='my-dirlist.txt'"
  echo -e "  RESOLVERS='my-resolvers.txt'"
  exit 1
}

# Check if required tools exist
check_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}[!] $cmd is not installed. Please install it before running the script.${RESET}"
    exit 1
  fi
}

check_file_exists() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo -e "${RED}[!] Required file '$file' does not exist. Please provide it.${RESET}"
    exit 1
  fi
}

### ========== ARG PARSING ==========

while getopts "d:" opt; do
  case $opt in
    d) domain="$OPTARG" ;;
    *) show_help ;;
  esac
done

[ -z "$domain" ] && show_help

### ========== TOOL CHECK ==========
echo -e "${YELLOW}[*] Checking required tools...${RESET}"

tools=(parallel subfinder assetfinder findomain puredns dnsx gau waybackurls hakrawler katana gf httpx naabu rustscan ffuf curl gf jsleak)
for t in "${tools[@]}"; do check_command "$t"; done

python3 -c "import requests" >/dev/null 2>&1 || {
  echo -e "${RED}[!] Python3 'requests' module is missing. Install using: pip3 install requests${RESET}"
  exit 1
}

### ========== FILE CHECK ==========
check_file_exists "$WORDLIST"
check_file_exists "$DIRLIST"
check_file_exists "$RESOLVERS"

### ========== WORKING FOLDER ==========
project="recon-$domain"
mkdir -p "$project"
cd "$project"

echo -e "${GREEN}[*] Recon started for: $domain${RESET}"

### ========== 1. Subdomain Enumeration ==========
echo -e "${YELLOW}[*] Running subdomain enumeration...${RESET}"
parallel --halt soon,fail=1 --tag ::: \
  "subfinder -d $domain -silent > subfinder.txt" \
  "assetfinder --subs-only $domain > assetfinder.txt" \
  "findomain -t $domain -q > findomain.txt" \
  "puredns bruteforce ../$WORDLIST $domain --resolvers ../$RESOLVERS --write puredns.txt" \
  "python3 ../ctfr.py -d $domain -o crtsh.txt"
wait
cat subfinder.txt assetfinder.txt findomain.txt puredns.txt crtsh.txt | sort -u > all_subs.txt

### ========== 2. Subdomain Live Checking ==========
echo -e "${YELLOW}[*] Validating live subdomains...${RESET}"
dnsx -silent -l all_subs.txt -o live_subs.txt

### ========== 3. URL Gathering ==========
echo -e "${YELLOW}[*] Crawling URLs (gau, waybackurls, hakrawler, katana)...${RESET}"
parallel --halt soon,fail=1 --tag ::: \
  "gau < live_subs.txt > gau.txt" \
  "waybackurls < live_subs.txt > wayback.txt" \
  "hakrawler -depth 1 -insecure -subs < live_subs.txt > hak.txt" \
  "katana -jc -fs < live_subs.txt > katana.txt"
wait
cat gau.txt wayback.txt hak.txt katana.txt | sort -u > all_urls.txt

### ========== 4. JavaScript Discovery ==========
echo -e "${YELLOW}[*] Extracting JavaScript file URLs...${RESET}"
grep -Ei "\.js(\?|$)" all_urls.txt | sort -u > js_files.txt

### ========== 5. Secrets/Leaks in JS (Parallel) ==========
echo -e "${YELLOW}[*] Running JS secrets analysis...${RESET}"
parallel ::: \
  "cat js_files.txt | while read url; do curl -s \"\$url\" | gf secrets; done > possible_secrets.txt" \
  "python3 ../SecretFinder.py -i js_files.txt -o cli > secretfinder.txt" \
  "jsleak -i js_files.txt > jsleak.txt"
wait
cat possible_secrets.txt secretfinder.txt jsleak.txt | sort -u > all_js_leaks.txt

### ========== 6. Sensitive Files & Bucket Discovery ==========
echo -e "${YELLOW}[*] Finding sensitive file extensions and AWS buckets...${RESET}"
grep -Ei '\.(csv|docx?|xlsx?|xml|sql|log|conf|bak|env|ini|json|pem|pfx|db|zip|gz|tar|rar)(\?|$)' all_urls.txt | sort -u > sensitive_files.txt
grep -Eo '([a-zA-Z0-9.-]+\.s3\.amazonaws\.com|s3\.[a-z0-9-]+\.amazonaws\.com/[a-zA-Z0-9._-]+)' all_urls.txt js_files.txt | sort -u > bucket.txt

### ========== 7. Port Scanning (Parallel) ==========
echo -e "${YELLOW}[*] Scanning open ports using naabu and rustscan...${RESET}"
parallel --halt soon,fail=1 --tag ::: \
  "naabu -iL live_subs.txt -top-ports 1000 -o naabu_ports.txt" \
  "rustscan -a live_subs.txt -r 1-10000 | tee rustscan_ports.txt"
wait
cat naabu_ports.txt rustscan_ports.txt | sort -u > open_ports.txt

### ========== 8. Directory/Files Discovery ==========
echo -e "${YELLOW}[*] Running directory brute-force with ffuf...${RESET}"
parallel -j 10 "ffuf -w ../$DIRLIST -u https://{}/FUZZ -mc 200,403,401 -t 50 -of json -o ffuf-{}.json" :::: live_subs.txt

### ========== 9. Stack Detection & Sensitive Endpoints ==========
echo -e "${YELLOW}[*] Detecting tech stack and probing sensitive paths...${RESET}"
httpx -l live_subs.txt -tech-detect -title -status-code -web-server -o stack_info.txt

paths=("/server-status" "/phpinfo.php" "/.git/" "/.env" "/config" "/wp-config.php" "/admin" "/manager/html" "/drupal/CHANGELOG.txt" "/nginx_status")
while read url; do
  for path in "${paths[@]}"; do
    code=$(curl -sk -o /dev/null -w "%{http_code}" "$url$path")
    [[ "$code" =~ ^2|3|4 ]] && echo "$url$path => $code"
  done
done < live_subs.txt > sensitive_paths.txt

echo -e "${GREEN}[*] Recon complete! Outputs saved in $project/${RESET}"
