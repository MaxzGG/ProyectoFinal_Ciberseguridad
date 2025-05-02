import requests
import time

def virustotalarchivos():#Angel
    API_KEY=input("Ingresa tu API-KEY:\n")
    URL="https://www.virustotal.com/api/v3/files"
    HEADERS={'x-apikey': API_KEY}

    archivo=input("Ingresa la ruta del archivo para analizar:\n")
    try:

        with open(archivo, "rb") as file:
            archivos={'file': (archivo, file)}
            response=requests.post(URL, files=archivos, headers=HEADERS)

        if response.status_code == 200:
            resultado=response.json()
            analisis=resultado['data']['id']
            print(f"Archivo enviado;\nID del analisis: {analisis}")

            time.sleep(15)
            URL2=f"https://www.virustotal.com/api/v3/analyses/{analisis}"

            try:

                resultado2=requests.get(URL2, headers=HEADERS)

                if resultado2.status_code == 200:
                    datos=resultado2.json()
                    x=datos['data']['attributes']['stats']
                    print("="*8,"RESULTADOS DE ANALISIS","="*8)
                    print(f"Malware: {x['malicious']}")
                    print(f"Sospecha: {x['suspicious']}")
                    print(f"Limpios: {x['harmless']}")
                else:
                    print(f"Error: {resultado2.status_code} - {resultado2.text}")
            except requests.RequestException as e:
                print("Error al obtener resultado de analisis: ",e)
        else:
            print(f"Error al enviar archivo: {response.status_code} - {response.text}")
    
    except FileNotFoundError:
        print("El archivo ingresado no existe")
    except requests.RequestException as e:
        print("Error en la conexion a la API: ",e)
    except Exception as e:
        print("ERROR: ",e)
     


def virustotalurl():#Humberto
    API_KEY = "a79c610c152ba8021a3926bb5a04300a57eaef59d95176bb0f307d25cd56ae4e"
    url_vt = "https://www.virustotal.com/api/v3/urls"

    url_analizada = input("Ingresar la URL a escanear: ") #"https://www.youtube.com" 
    headers={
        'x-apikey': API_KEY,
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    data={
        'url': url_analizada
    }
    #---------------------------------------------------------------------------#
    try:
        respuesta_POST = requests.post(url=url_vt,headers=headers, data=data) 
        respuesta_POST.raise_for_status()
        datos_salida = respuesta_POST.json()

        url_analisis = datos_salida['data']['links']['self']

        respuesta_GET = requests.get(url=url_analisis, headers=headers)
        respuesta_GET.raise_for_status()
        respuesta_json = respuesta_GET.json()
    #-----------------------------------------------------------------#
        print( f"Datos del analisis: {respuesta_json['data']['id']}\n"
            f"->Estatus: {respuesta_json['data']['attributes']['status']}\n"
            f"->resultados:\n"
            f"-Malicioso: {respuesta_json['data']['attributes']['stats']['malicious']}\n"
            f"-Sospechoso: {respuesta_json['data']['attributes']['stats']['suspicious']}\n"
            f"-No detectado: {respuesta_json['data']['attributes']['stats']['undetected']}\n"
            f"-No danino: {respuesta_json['data']['attributes']['stats']['harmless']}"
        )
    except requests.RequestException as e:
        print("Error al conectar con la API: ",e)
    except KeyError as e:
        print("Error con la clave")
    except Exception as e:
        print("ERROR ",e)
        
    return 0


def menuVirusTotal():
    while True:
        print("="*8,"MENU","="*8)
        print("Selecciona una opcion del menu\n"
              "1)Analizar archivo con API de Virus Total\n"
              "2)Analizar URL con API de virus Total\n"
              "3)Salir")
        
        opcion=int(input("Ingresa tu opcion:\n"))

        if opcion == 0 or opcion <0:
            print("Elige una opcion valida!")
        elif opcion == 1:
            virustotalarchivos()
        elif opcion == 2:
            virustotalurl()
        elif opcion == 3:
            break
        else:
            print("Elige una opcion valida")
