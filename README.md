# MSockets6

MSockets6 is a command-line tool for managing network socket operations, including DDoS configuration and attack simulation, with persistent preferences and command history.

## Features

- Interactive shell with command history
- DDoS attack configuration and simulation
- SQLite-based persistent preferences
- Auto-update from GitHub repository

## Installation

Clone the repository and enter the project directory:

```bash
git clone https://github.com/nobationgc/MSockets6.git
cd MSockets6
chmod +x main.sh
./main.sh
```

Make sure you have Bash, SQLite3, Git, and Go installed.

## Push to GitHub

Initialize git (if not done), add all files, commit, and push:

```bash
git init
git remote add origin https://github.com/yourusername/MSockets6.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

Replace `yourusername` with your GitHub username.

## Usage

Run the main script:

```bash
bash main.sh
```

### Commands

- `msk --configure-ddos` : Configure DDoS attack parameters
- `msk --attack-ddos` : Run DDoS attack simulation
- `msk --show-progress(ddos)` : Show DDoS attack progress
- `msk --update` : Update MSockets6 from GitHub
- `clear` / `cls` : Clear the screen
- `/fallback_ on|off|toggle` : Toggle fallback mode
- `exit` : Exit the shell

## Requirements

- Bash
- SQLite3
- Git
- Go (for runtime.go execution)

## License

Apache 2.0
