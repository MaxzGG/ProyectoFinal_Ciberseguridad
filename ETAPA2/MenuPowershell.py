import subprocess
import platform #Libreria para detectar SO
def MenuPowershell():
   
    ruta=r"C:\Users\angel\OneDrive\Desktop\Le facultad\3 Semestre\Programacion2\PIA\MenuPS.ps1"
    proceso=subprocess.Popen(
        ["powershell", "-ExecutionPolicy", "Bypass", "-File", ruta],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True    
    )
    print("Salida Output")
    # Leemos la salida en tiempo real línea por línea
    for linea in proceso.stdout:
        print(linea, end='')  # ya incluye salto de línea
    
    print("\nErrores (En caso de haber):")
    for error in proceso.stderr:
        print(error, end='')

    proceso.wait()

def detectar_SO():
    SO=platform.system() 

    if SO=="Windows":
        print("Sistema Operativo: Windows")
        print("Ejecutando Menu Powershell")
        MenuPowershell()
    elif SO=="Linux":
        print("Sistema Operativo Linux")
    elif SO=="Darwin":
        print("Sistema Operativo MacOs")
    else:
        print(f"Sistema operativo desconocido: {SO}")
