#!/bin/bash

INTERFACE=$(ip -br addr | grep UP | awk '{print $1}')

#mostrar la fecha y la interfaz activa
echo "-----------------------------------"
echo "Monitoreo de Red - $(date)"
echo "Interfaz activa: $INTERFACE"
echo "-----------------------------------"

#direccion IP
echo -e "\nDireccion IP local:"
hostname -I

#conexiones activas
echo -e "\nConexiones activas (Puerto, Direccion y PID):"
ss -tunap

echo "Presiona cualquier tecla para salir"
read -n 1

