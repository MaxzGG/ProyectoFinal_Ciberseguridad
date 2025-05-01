#MENU PRINCIPAL PARA LAS HERRAMIENTAS DE NUESTRO PIA PYTHON
from Modulo1 import shodan
from Modulo2 import Ipabuse
from Modulo3 import vulnerabilidades
from Modulo4 import menu_principal
from Modulo5 import menuVirusTotal

while True:
    print("="*8,"MENU","="*8)
    print("Selecciona una opcion del menu\n" 
    "1)API SHODAN\n"
    "2)API IPABUSE\n"
    "3)Vulnerabiliades de Sistemas Operativos recientes\n"
    "4)Monitor de recursos del sistema\n"
    "5)API VirusTotal\n"
    "6)Salir")

    opcion=int(input("Ingresa tu opcion:\n"))

    if opcion == 0 or opcion < 0:
        print("Ingresa una opcion valida!")
    elif opcion == 1:
        shodan()
    elif opcion == 2:
        Ipabuse()
    elif opcion == 3:
        vulnerabilidades()
    elif opcion == 4:
        menu_principal()
    elif opcion == 5:
        menuVirusTotal()
    elif opcion == 6:
        break
    else:
        print("Elige una opcion valida!")