#!/bin/bash
#Funcion para scanear puertos
scan_ports() {
    local ip="$1"
    local ports="$2"
    local report_file="$3"

    ports=$(echo "$ports" | tr ',' ' ')

    echo "Escaneando los puertos: $ports en la IP: $ip"
    for port in $ports; do
        nc -zv -w 1 "$ip" "$port" &> /dev/null
        if [ $? -eq 0 ]; then
            echo "Puerto $port: ABIERTO"
        else
            echo "Puerto $port: CERRADO"
        fi
    done

    # Generar reporte si se solicita
    if [ -n "$report_file" ]; then
        echo "Reporte del escaneo:" > "$report_file"
        for port in $ports; do
            nc -zv -w 1 "$ip" "$port" &> /dev/null
            if [ $? -eq 0 ]; then
                echo "Puerto $port: ABIERTO" >> "$report_file"
            else
                echo "Puerto $port: CERRADO" >> "$report_file"
            fi
        done
        echo "Se guardo el reporte en :$report_file"
    fi
}

#Ejecucion
while true; do
    read -p "Escribe la dirección IP a escanear: " ip
    read -p "Escribe los puertos a escanear: " ports

    # Escaneo de puertos
    scan_ports "$ip" "$ports"

    # Preguntar por el reporte
    read -p "¿Quieres crear un reporte del escaneo? (s/n): " create_report
    #if [[ "$create_report" =~ ^[sS]$ ]]; then
     if [[ "$create_report" == "s" || "$create_report" == "S" ]]; then
        read -p "Escribe el nombre del archivo de reporte" report_file
        scan_ports "$ip" "$ports" "$report_file"
    fi
    break

done
