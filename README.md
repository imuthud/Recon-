# Recon.sh — Automated Fast Recon Framework

## Usage

chmod +x Recon.sh
./Recon.sh -d example.com


## Requirements

- `subfinder`, `assetfinder`, `findomain`, `puredns`, `ctfr.py`
- `dnsx`, `gau`, `waybackurls`, `hakrawler`, `katana`
- `gf`, `SecretFinder.py`, `jsleak`
- `naabu`, `rustscan`, `ffuf`, `httpx`, `curl`, `parallel`
- **Wordlists:** `wordlist.txt` (subdomains), `directory-list.txt` (files/dirs), `resolvers.txt` (DNS)

Install each tool from their official releases or package managers (see their GitHub repositories).

## Output

All outputs are saved in a sub-folder named after your target:  
- `all_subs.txt` — All discovered subdomains  
- `live_subs.txt` — Validated live subdomains  
- `all_urls.txt` — All URLs/endpoints  
- `js_files.txt` — JavaScript files  
- `all_js_leaks.txt` — API keys/secrets/leaks  
- `sensitive_files.txt` — Sensitive file links  
- `bucket.txt` — AWS bucket names  
- `open_ports.txt` — Open ports list  
- `ffuf-<sub>.json` — Directory brute-forcing results  
- `stack_info.txt` — Tech stack info  
- `sensitive_paths.txt` — Sensitive endpoint findings  

## License

MIT or your preferred license.

## Download or create:

wordlist.txt – For subdomain brute-forcing

resolvers.txt – For PureDNS

directory-list.txt – For FFUF

You can use public resources like:

bash
curl -O https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt -o wordlist.txt
curl -O https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt
curl -O https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o directory-list.txt
