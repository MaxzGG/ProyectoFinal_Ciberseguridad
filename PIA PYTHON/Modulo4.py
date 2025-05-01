#Ideas de modulos: Analizar recursos del sistema; carga del procesador, uso de la ram, 
# almacenamiento disponible, procesos en curso con el consumo de dicho proceso, uso de red, cuantos megas se consumen etc
import psutil
from datetime import datetime
import time
import subprocess
import socket
import os
import sys

#Uso de CPU
def obtener_uso_cpu():
    temporizador=time.time()
    while time.time() - temporizador <10:
        CPU=psutil.cpu_percent(interval=1)
        print(f"Carga actual del cpu: {CPU}%", end="\r")
        
#Uso de memoria RAM
def obtener_uso_ram():
    RAM=psutil.virtual_memory()
    print(f"Memoria RAM usada: {RAM.used / (1024 ** 3):.2f} GB / {RAM.total / (1024 ** 3):.2f} GB")
    print(f"Porcentaje de RAM usada: {RAM.percent}%")

#Almacenamiento del dispositivo
def almacenamiento():
    almacenamiento=psutil.disk_usage("C:\\")
    total=almacenamiento.total / (1024**3)
    usado=almacenamiento.used / (1024**3)
    libre=almacenamiento.free / (1024**3)
    porcentaje=almacenamiento.percent

    print(f"Capacidad total de almacenamiento: {total:.2f} GB")
    print(f"Espacio usado del almacenamiento: {usado:.2f} GB")
    print(f"Almacenamiento libre: {libre:.2f} GB")
    print(f"Porcentaje de uso del almacenamiento: {porcentaje:.2f} %")

#Listar procesos del sistema
def procesos_en_curso():
    try:
        limite=float(input("Ingresa el porcentaje del uso del CPU para filtrar:\n"))
    except ValueError:
        print("Ingresa un porcentaje valido")
    
    for proceso in psutil.process_iter():
        proceso.cpu_percent(interval=None)

    time.sleep(1)
    print(f"Procesos de mas de {limite}%:\n")
    for proceso in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
        try:
            CPU=proceso.info['cpu_percent']
            RAM=proceso.info['memory_percent']
            if CPU > limite:
                print(f"PID: {proceso.info['pid']:5} | Nombre: {proceso.info['name'][:20]:20} | CPU: {CPU:5.1f}% | RAM: {RAM:5.1f}%")
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue

#Uso de red wifi
def monitor_wifi():
    def nombre_de_red():
        try:
            resultado=subprocess.check_output("netsh wlan show interfaces", shell=True).decode('utf-8', errors='ignore')
            for linea in resultado.split('\n'):
                if "SSID" in linea and "BSSID" not in linea:
                    return linea.split(":", 1)[1].strip()
        except Exception as e:
            return f"Error al obtener SSID: {e}"
        return "No conectado"
    
    def obtener_ip():
        try:
            hostname=socket.gethostname()
            ip=socket.gethostbyname(hostname)
            return ip 
        except:
            return "IP no disponible"
    
    def trafico_de_red():
        contador1=psutil.net_io_counters()
        time.sleep(1)
        contador2=psutil.net_io_counters()
        enviado=(contador2.bytes_sent - contador1.bytes_sent)/1024
        recibido=(contador2.bytes_recv - contador1.bytes_recv)/1024
        return enviado, recibido
    
    def funcion_principal():
        os.system("cls" if os.name=='nt' else 'clear') #Limpiar pantalla
        print(f"SSID: {nombre_de_red()}")
        print(f"IP local: {obtener_ip()}")
        print("")

        for _ in range(10):
            enviado, recibido= trafico_de_red()
            sys.stdout.write("\033[F\033[F")
            sys.stdout.write(f"Enviados: {enviado:.2f} KB/s\n")
            sys.stdout.write(f"Recibidos: {recibido:.2f} KB/s\n")
            sys.stdout.flush()
        
    funcion_principal()
    
def menu_principal():
    while True:
        print("="*8, "MENU", "="*8)
        print("Selecciona una opcion del menu\n" 
        "1)Monitor del procesador\n"
        "2)Monitor del uso de RAM\n"
        "3)Monitor de uso del almacenamiento del dispositivo\n"
        "4)Procesos en curso\n"
        "5)Monitor de red Wi-Fi\n"
        "6)Salir")

        opcion=int(input("Ingresa tu opcion:\n"))

        if opcion == 0 or opcion <0:
            print("Ingresa una opcion valida!")
        elif opcion == 1:
            obtener_uso_cpu()
        elif opcion == 2:
            obtener_uso_ram()
        elif opcion == 3:
            almacenamiento()
        elif opcion == 4:
            procesos_en_curso()
        elif opcion == 5:
            monitor_wifi()
        elif opcion == 6:
            break
        else:
            print("Ingresa una opcion valida!")