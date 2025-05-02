#Modulo para buscar vulnerabilidades en S.O recientes
import requests
import json

def vulnerabilidades():
    API_KEY=input("Ingresa tu API-KEY:\n")
    Sistema=input("Ingresa el SO:\n")
    URL="https://services.nvd.nist.gov/rest/json/cves/2.0"
    
    parametros={
        "keywordSearch": Sistema,
        "resultsPerPage": 10,
        "startIndex": 0,
    }

    encabezados={
        "apiKey": API_KEY
    }

    try:
        respuesta=requests.get(URL, params=parametros, headers=encabezados)
        respuesta.raise_for_status()
        datos=respuesta.json()

        for item in datos.get("vulnerabilities", []):
            cve=item.get("cve", )
            print(f"\n CVE ID: {cve.get('id')}")
            print(f"Publicado: {cve.get('published')}")
            print(f"Descripcion: {cve['descriptions'][0]['value']}")
            metrics=cve.get('metrics',{}) 
            cvss=metrics.get('cvssMetricV31') or metrics.get('cvssMetricV2')
            if cvss:
                score=cvss[0].get('cvssData', {}).get('baseScore')
                print(f"CVSS Score: {score}")
    except requests.exceptions.RequestException as e:
        print("Error al conectar la API: ",e)
    except (KeyError, IndexError, TypeError) as e:
        print("Error al procesar datos: ")

#Codigo antiguo
"""
    response=requests.get(URL, params=parametros, headers=encabezados)
    datos=response.json()

    for item in datos.get("vulnerabilities", []):
        cve=item.get("cve", {})
        print(f"\n CVE ID: {cve.get('id')}")
        print(f"Publicado: {cve.get('published')}")
        print(f"Descripcion: {cve['descriptions'][0]['value']}")

        metrics=cve.get('metrics',{}) 
        cvss=metrics.get('cvssMetricV31') or metrics.get('cvssMetricV2')
        if cvss:
            score=cvss[0].get('cvssData', {}).get('baseScore')
            print(f"CVSS Score: {score}")"""
