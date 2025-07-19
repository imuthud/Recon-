#!/bin/bash

set -e

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

print_banner() {
  echo -e "${YELLOW}"
  echo "===================================="
  echo "   Recon Tool Installer by Muthu D  "
  echo "===================================="
  echo -e "${RESET}"
}

print_banner

# ============ Python Requirements ============= #
echo -e "${GREEN}[+] Installing Python requirements...${RESET}"
cat <<EOF > requirements.txt
requests
colorama
dnspython
EOF

pip3 install -r requirements.txt

# ============ Golang Tools Installation ============= #
echo -e "${GREEN}[+] Installing Golang-based recon tools...${RESET}"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}[!] Go is not installed. Please install Golang before continuing.${RESET}"
    exit 1
fi

go install github.com/projectdiscovery/subfinder/v2@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/d3mondev/puredns/v2@latest
go install github.com/lc/gau@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/gf@latest
go install github.com/hakluke/hakrawler@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/sensepost/gowitness@latest

# Add Go bin to PATH if not already present
if ! echo $PATH | grep -q "$(go env GOPATH)/bin"; then
  echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
  source ~/.bashrc
fi

# ============ Wordlists ============= #
echo -e "${GREEN}[+] Downloading wordlists...${RESET}"
curl -s -o wordlist.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt
curl -s -o directory-list.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt
curl -s -o resolvers.txt https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt

# ============ Optional Tools Notice ============ #
echo -e "${YELLOW}[!] Please install these manually if needed:${RESET}"
echo -e "${YELLOW}• findomain ➤ https://github.com/findomain/findomain/releases${RESET}"
echo -e "${YELLOW}• rustscan  ➤ https://github.com/RustScan/RustScan/releases${RESET}"
echo -e "${YELLOW}• jsleak    ➤ https://github.com/chinchang/jsleak${RESET}"
echo -e "${YELLOW}• SecretFinder ➤ git clone https://github.com/m4ll0k/SecretFinder${RESET}"
echo

# ============ GNU Parallel ============ #
if ! command -v parallel &> /dev/null; then
    echo -e "${GREEN}[+] Installing GNU parallel...${RESET}"
    sudo apt install parallel -y 2>/dev/null || \
    brew install parallel 2>/dev/null || \
    echo -e "${RED}[!] Parallel not installed. Please install manually.${RESET}"
else
    echo -e "${GREEN}[✓] GNU parallel is already installed.${RESET}"
fi

# ============ Done! ============ #
echo
echo -e "${GREEN}[✓] All Done! You can now run Recon.sh like this:${RESET}"
echo -e "${YELLOW}     ./Recon.sh -d example.com${RESET}"
