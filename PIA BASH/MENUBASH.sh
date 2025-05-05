#!/bin/bash

while true; do
	clear
	echo "====MENU===="
	echo "Selecciona una opcion del menu"
	echo "1) Escaner de puertos"
	echo "2) Monitor de red"
	echo "3)Salir"
	read -p "Opcion: " opcion 

	case $opcion in 
	1)
		./Modulo1.sh
		;;
	2)
		./Modulo2.sh
		;;
	3)
		exit 0
		;;
	*)
	echo "Selecciona una opcion valida!"
	;;
	esac
done

