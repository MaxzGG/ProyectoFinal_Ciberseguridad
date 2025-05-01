#ApiShodan Humberto
import requests

def shodan():
    while True :
        API_key = "vVw4W7B0SpHBir2Rl8WKbfikusZvsgOx"

        print("----/ Buscador de Ip en shodan \----\n1) Buscar ip\n2) Salir")
        opcion = input("Escoger una opcion: ")

        if opcion == "1":

            ip = input("Ingresa la ip a buscar: ") 
            url = "https://api.shodan.io/shodan/host/{}?key={}".format(ip, API_key)
            respuesta = requests.get(url)
            datos =  respuesta.json()

            if respuesta.status_code == 200: 
                llaves = [
                    'ip',
                    'isp',
                    'org',
                    'asn',
                    'port',
                    'transport',
                    'ip_str',
                    'city',
                    'region_code',
                    'country_name',
                    'country_code',
                    'latitude',
                    'longitude'
                ]

                print("----/ Datos \----")
                for llave in llaves:
                    valor = datos.get(llave)
                    print(f"{llave}: {valor}")

                r_vuelta = input("Buscar otra Ip? (s/n): ").lower()
                if r_vuelta != "s":
                    break
            else:
                er = "Se encontro un error: "+ datos.get("error")
                print(er)

        elif opcion == "2": 
            break
        else:
            print("\n####> Escoge una opcion del menu <#####\n")
    return 0