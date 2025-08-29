package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

var (
	progressMu     sync.Mutex
	activeSessions int
	totalTraffic   int64
)

type DDoSConfig struct {
	Target     string
	Port       string
	FileSize   int
	AttackType string
	Tool       string
	Interval   int
	Sessions   int
}

func readConfig(path string) (*DDoSConfig, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	lines := []string{}
	for scanner.Scan() {
		lines = append(lines, strings.TrimSpace(scanner.Text()))
	}
	if len(lines) < 7 {
		return nil, fmt.Errorf("invalid config file")
	}
	fileSize, _ := strconv.Atoi(lines[2])
	interval := 0
	if lines[3] != "flood" {
		interval, _ = strconv.Atoi(lines[5])
	}
	sessions, _ := strconv.Atoi(lines[6])
	return &DDoSConfig{
		Target:     lines[0],
		Port:       lines[1],
		FileSize:   fileSize,
		AttackType: lines[3],
		Tool:       lines[4],
		Interval:   interval,
		Sessions:   sessions,
	}, nil
}

func attackSession(id int, cfg *DDoSConfig, wg *sync.WaitGroup) {
	defer wg.Done()
	progressMu.Lock()
	activeSessions++
	progressMu.Unlock()

	traffic := int64(0)
	for i := 0; i < 10; i++ { // Simulate 10 packets per session
		traffic += int64(cfg.FileSize)
		if cfg.AttackType != "flood" {
			time.Sleep(time.Duration(cfg.Interval) * time.Millisecond)
		}
	}
	progressMu.Lock()
	totalTraffic += traffic
	activeSessions--
	progressMu.Unlock()
}

func runAttack(cfg *DDoSConfig) {
	fmt.Printf("[*] Starting DDoS attack: %d sessions, target=%s, port=%s, type=%s, tool=%s\n",
		cfg.Sessions, cfg.Target, cfg.Port, cfg.AttackType, cfg.Tool)
	var wg sync.WaitGroup
	for i := 0; i < cfg.Sessions; i++ {
		wg.Add(1)
		go attackSession(i, cfg, &wg)
	}
	wg.Wait()
	fmt.Printf("[+] DDoS attack finished. Total traffic sent: %d bytes\n", totalTraffic)
}

func showProgress() {
	progressMu.Lock()
	fmt.Printf("[*] Active sessions: %d\n", activeSessions)
	fmt.Printf("[*] Total traffic sent: %d bytes\n", totalTraffic)
	// Simulate resource usage
	fmt.Printf("[*] CPU usage: %d%%\n", 10+activeSessions*5)
	fmt.Printf("[*] Memory usage: %d MB\n", 50+activeSessions*2)
	progressMu.Unlock()
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: runtime.go --attack-ddos | --show-progress-ddos")
		return
	}
	cfg, err := readConfig("./.data/ddos_history")
	if err != nil && os.Args[1] == "--attack-ddos" {
		fmt.Println("Error reading ddos_history:", err)
		return
	}
	switch os.Args[1] {
	case "--attack-ddos":
		runAttack(cfg)
	case "--show-progress-ddos":
		showProgress()
	default:
		fmt.Println("Unknown command")
	}
}
