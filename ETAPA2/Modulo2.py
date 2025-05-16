import requests
def Ipabuse():
    API_KEY=""
    direccion_ip=input("Ingresa la direccion ip a revisar:\n")
    url="https://api.abuseipdb.com/api/v2/check"


    consulta={
        "ipAddress":direccion_ip,
        "maxAgeInDays":"90" #Maximo 90 dias de haberse reportado
    }
    encabezados={
        "Accept": "aplication/json",
        "key":API_KEY
    }

    try:
        respuesta=requests.get(url, headers=encabezados, params=consulta)
        respuesta.raise_for_status() #Tipo condicional para verificar errores
        datos=respuesta.json()
        print("IP:",datos['data']['ipAddress'])
        print("Pais:",datos['data']['countryCode'])
        print("Reportes totales:",datos['data']['totalReports'])
        print("Ultimo Reporte:",datos['data']['lastReportedAt'])
    except requests.exceptions.RequestException as e:
        print("Error al consultar la API: ",e)

#Codigo antiguo     
"""    respuesta=requests.get(url, headers=encabezados, params=consulta)

    if respuesta.status_code == 200:
        datos=respuesta.json()
        print("IP:",datos['data']['ipAddress'])
        print("Pais:",datos['data']['countryCode'])
        print("Reportes totales:",datos['data']['totalReports'])
        print("Ultimo Reporte:",datos['data']['lastReportedAt'])
    else:
        print("Error:",respuesta.status_code, respuesta.text)"""
