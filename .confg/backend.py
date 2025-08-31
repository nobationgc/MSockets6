import subprocess
import os

# Directorio donde está este script Python
script_dir = os.path.dirname(os.path.abspath(__file__))

# Ruta completa a runtime.go
runtime_go_path = os.path.join(script_dir, "runtime.go")

# Ruta completa al archivo ddos_history (está en ../.data)
file_path = os.path.join(script_dir, "..", ".data", "ddos_history")

# Abrir y leer las líneas del archivo
with open(file_path, "r") as f:
    lines = [line.strip() for line in f.readlines()]

# Comprobar que hay suficientes líneas
if len(lines) < 7:
    raise ValueError("El archivo no tiene suficientes líneas para extraer todos los valores.")

# Asignar valores a variables
Target = lines[0]
Port = lines[1]
FileSize = lines[2]
AttackType = lines[3]
Tool = lines[4]
Interval = lines[5]
Sessions = lines[6]

# Función rty
def rty():
    print(f"[+]: Running attack at: {AttackType} lock: {Target}:{Port} with: {Tool} interval?: {Interval} sessions: {Sessions} filesize: {FileSize}")

    # Llamar a runtime.go pasando todos los valores como argumentos
    subprocess.run([
        "go", "run", runtime_go_path,
        Target,
        Port,
        FileSize,
        AttackType,
        Tool,
        Interval,
        Sessions
    ])

# Llamar a la función
rty()
