# MSockets6

MSockets6 is a command-line tool for managing network socket operations, including DDoS configuration and attack with persistent preferences and command history.

## Features

- Interactive shell with command history
- DDoS attack configuration and execution (**For testing purposes only in controlled environments, NEVER against unauthorized targets**)
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

## Usage

Run the main script:

```bash
bash main.sh
```

### Commands

- `msk --configure-ddos` : Configure DDoS attack parameters
- `msk --attack-ddos` : Run DDoS attack simulation
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

## Expected SHA256:

```txt
SHA: fcd4640ca9e6af97c0a20e6e4e06658a5ccc9799e498733838554d699ea28005
```