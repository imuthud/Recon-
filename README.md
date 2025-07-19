

### ✅ `README.md`

```
# 🔍 Recon.sh – Fast, Parallel, Local Recon Automation Tool

`Recon.sh` is a powerful, fast recon automation script designed for bug bounty hunters and penetration testers. It performs subdomain enumeration, URL gathering, JS analysis, port scanning, bucket detection, and more — all from your own PC, with **no APIs or external accounts required**.

---

## 🚀 Features

✅ Subdomain Enumeration (Parallel, Multi-Tool)  
✅ URL Gathering + JS Discovery  
✅ Secrets Detection in JS (via multiple tools)  
✅ AWS S3 Bucket Discovery  
✅ Port Scanning with Naabu & Rustscan  
✅ Directory Bruteforcing (ffuf)  
✅ Tech Stack Detection + Sensitive Endpoints  
✅ Full Parallelism, Per-Domain Output Folder

---

## ⚙️ Requirements

Please install the following tools manually (many are Go-based):

| Tool         | Installation Command |
|--------------|----------------------|
| [`subfinder`](https://github.com/projectdiscovery/subfinder) | `go install github.com/projectdiscovery/subfinder/v2@latest` |
| `assetfinder` | `go install github.com/tomnomnom/assetfinder@latest` |
| `findomain`   | Download binary from [Releases](https://github.com/findomain/findomain/releases) |
| `puredns`     | `go install github.com/d3mondev/puredns@latest` |
| `gau`         | `go install github.com/lc/gau@latest` |
| `waybackurls` | `go install github.com/tomnomnom/waybackurls@latest` |
| `hakrawler`   | `go install github.com/hakluke/hakrawler@latest` |
| `katana`      | `go install github.com/projectdiscovery/katana/cmd/katana@latest` |
| `dnsx`        | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest` |
| `naabu`       | `go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest` |
| `rustscan`    | Download from [Releases](https://github.com/RustScan/RustScan/releases) |
| `ffuf`        | `go install github.com/ffuf/ffuf/v2@latest` |
| `httpx`       | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` |
| `gf`          | `go install github.com/tomnomnom/gf@latest` |
| `jsleak`      | Clone or install via npm, or use binary if supported |
| `SecretFinder.py` | Clone from [SecretFinder](https://github.com/m4ll0k/SecretFinder) |
| `GNU parallel`| `sudo apt install parallel` or `brew install parallel` (macOS)

> 🐍 Python3 and pip should be installed for running SecretFinder and ctfr.py

---

## 📁 Wordlists Required

| File             | Description                         |
|------------------|-------------------------------------|
| `wordlist.txt`   | For subdomain brute-force (`puredns`) |
| `resolvers.txt`  | DNS resolvers list (used with PureDNS) |
| `directory-list.txt` | Directory brute-force (used by ffuf) |

You can grab these easily:

```
curl -O https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt
curl -O https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt -o wordlist.txt
curl -O https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o directory-list.txt
```

---

## 🛠 Usage

```
chmod +x Recon.sh
./Recon.sh -d target.com
```

```
WORDLIST=my-subwordlist.txt \
DIRLIST=my-ffuf.txt \
RESOLVERS=my-resolvers.txt \
./Recon.sh -d example.com
```

---

## 📦 Output Directory Structure

Each run creates a project folder: `recon-example.com/`

Inside:

```
live_subs.txt          – Validated, live subdomains
all_urls.txt           – URL archive + crawler results
js_files.txt           – List of all discovered JS files
all_js_leaks.txt       – Secrets, keys, tokens found (merged)
bucket.txt             – AWS S3 bucket mentions in JS/URLs
open_ports.txt         – Merged output from naabu + rustscan
sensitive_files.txt    – Sensitive file extensions in discovered URLs
stack_info.txt         – HTTPx full stack profiling
sensitive_paths.txt    – Access to risky paths (admin/login/git/env)
ffuf-.json        – Raw ffuf scans per subdomain
```

> All tool-generated outputs are saved to uniquely named files inside the folder.

---

## 🙋 FAQs

**Do I need an API key for subfinder / gau?**  
No! This script uses sources that work without authentication (or fallbacks silently).

**Can I run it offline?**  
No. This tool queries live assets, so you’ll need internet access.

**Can I run it on Windows?**  
Recommended on Linux/Mac or WSL. Some tools are *nix-focused.

---

## 📄 License

MIT License – Use freely, at your own risk.

---

## ❤️ Credits / Inspired By

- Tomnomnom CLI toolkit
- ProjectDiscovery suite
- m4ll0k | lc | trickest | sensepost | community
```
