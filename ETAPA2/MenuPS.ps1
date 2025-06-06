﻿<#
.SYNOPSIS
Script de seguridad multifuncional con menú interactivo para análisis de archivos y red.

.DESCRIPTION
Este script proporciona un menú interactivo para realizar diversas tareas de seguridad,
incluyendo el escaneo de archivos locales basado en filtros configurables, consulta
de hashes de archivos en VirusTotal, eliminación de archivos sospechosos, escaneo
básico de puertos remotos, consulta de información de IP/host en Shodan y la obtención
de un informe básico de seguridad del sistema local. Permite cargar y guardar
configuraciones en un archivo JSON para persistencia entre ejecuciones.

.EXAMPLE
.\script definitivo.ps1
Inicia el script y muestra el menú principal interactivo.

.NOTES
Requiere permisos elevados (Ejecutar como Administrador) para algunas funciones
como la eliminación de archivos o la obtención de cierto informe de seguridad local.
Requiere conexión a internet para consultar VirusTotal y Shodan.
Necesita API Keys configuradas en el menú para usar las funcionalidades de
VirusTotal y Shodan.

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
(Documentación oficial de Microsoft sobre ayuda basada en comentarios)
#>

# --- Inicialización y Carga de Configuración ---
# Define la ruta del archivo de configuración en el mismo directorio del script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ConfigFile = Join-Path -Path $ScriptDir -ChildPath "config.json"

<#
.SYNOPSIS
Carga la configuración desde un archivo JSON.

.DESCRIPTION
Intenta leer el archivo de configuración 'config.json' ubicado en el mismo directorio
del script. Si el archivo existe y es válido, carga los valores de configuración
globales. Si el archivo no existe, no se puede leer o tiene errores, establece
los valores por defecto y crea el archivo con esos valores.

.NOTES
La ruta del archivo de configuración es global ($Global:ConfigFile).
Utiliza codificación UTF8 para leer el archivo.
Si falla la carga, llama a Establecer-ValoresPorDefecto.
#>
function Cargar-Configuracion {
    if (Test-Path $Global:ConfigFile) {
        try {
            $configJson = Get-Content -Path $Global:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            # Asignar valores cargados a variables globales si existen en el archivo
            if ($configJson.PSObject.Properties.Name -contains 'ShodanApiKey') { $Global:ShodanApiKey = $configJson.ShodanApiKey } else { $Global:ShodanApiKey = $null }
            if ($configJson.PSObject.Properties.Name -contains 'PuertoScanTimeout') { $Global:PuertoScanTimeout = $configJson.PuertoScanTimeout }
            if ($configJson.PSObject.Properties.Name -contains 'PuertosComunes') { $Global:PuertosComunes = $configJson.PuertosComunes }
            if ($configJson.PSObject.Properties.Name -contains 'ExtensionesSospechosas') { $Global:ExtensionesSospechosas = $configJson.ExtensionesSospechosas }
            if ($configJson.PSObject.Properties.Name -contains 'UbicacionesSospechosas') { $Global:UbicacionesSospechosas = $configJson.UbicacionesSospechosas }
            if ($configJson.PSObject.Properties.Name -contains 'TamañoMinimoMB') { $Global:TamañoMinimoMB = $configJson.TamañoMinimoMB }
            if ($configJson.PSObject.Properties.Name -contains 'TamañoMaximoMB') { $Global:TamañoMaximoMB = $configJson.TamañoMaximoMB }
            if ($configJson.PSObject.Properties.Name -contains 'PuntajeUmbral') { $Global:PuntajeUmbral = $configJson.PuntajeUmbral }
            if ($configJson.PSObject.Properties.Name -contains 'VirusTotalApiKey') { $Global:VirusTotalApiKey = $configJson.VirusTotalApiKey }
            if ($configJson.PSObject.Properties.Name -contains 'RutaEscaneo') { $Global:RutaEscaneo = $configJson.RutaEscaneo }
            Write-Host "Configuración cargada desde $($Global:ConfigFile)" -ForegroundColor Green
        } catch {
            Write-Warning "No se pudo cargar o parsear el archivo de configuración $($Global:ConfigFile). Se usarán los valores por defecto. Error: $($_.Exception.Message)"
            Establecer-ValoresPorDefecto
        }
    } else {
        Write-Host "Archivo de configuración no encontrado. Usando valores por defecto y creando '$($Global:ConfigFile)'." -ForegroundColor Yellow
        Establecer-ValoresPorDefecto
    }
}

<#
.SYNOPSIS
Guarda la configuración actual en un archivo JSON.

.DESCRIPTION
Toma los valores de las variables de configuración globales y los guarda
en formato JSON en el archivo 'config.json' en el mismo directorio del script.
Esto permite que las configuraciones persistan entre ejecuciones.

.NOTES
La ruta del archivo de configuración es global ($Global:ConfigFile).
Sobrescribe el archivo existente.
Utiliza codificación UTF8 para escribir el archivo.
#>
function Guardar-Configuracion {
    $config = @{
        ShodanApiKey           = $Global:ShodanApiKey
        PuertoScanTimeout      = $Global:PuertoScanTimeout
        PuertosComunes         = $Global:PuertosComunes
        ExtensionesSospechosas = $Global:ExtensionesSospechosas
        UbicacionesSospechosas = $Global:UbicacionesSospechosas
        TamañoMinimoMB         = $Global:TamañoMinimoMB
        TamañoMaximoMB         = $Global:TamañoMaximoMB
        PuntajeUmbral          = $Global:PuntajeUmbral
        VirusTotalApiKey       = $Global:VirusTotalApiKey
        RutaEscaneo            = $Global:RutaEscaneo
    }
    try {
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8 -Force
        # Write-Host "Configuración guardada en $($Global:ConfigFile)" -ForegroundColor Green
    } catch {
        Write-Error "No se pudo guardar la configuración en $($Global:ConfigFile). Error: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
Establece los valores por defecto para la configuración global.

.DESCRIPTION
Asigna un conjunto predefinido de valores a las variables de configuración globales.
Esta función se utiliza al inicio si no se encuentra o no se puede cargar
el archivo de configuración, y también después de cargar los valores por defecto
para asegurar que el archivo 'config.json' se cree.

.NOTES
Los valores por defecto incluyen placeholders para las API Keys de Shodan y VirusTotal.
Llama a Guardar-Configuracion después de establecer los valores.
#>
function Establecer-ValoresPorDefecto {
    $Global:ShodanApiKey = "TU_API_KEY_SHODAN_AQUI"
    $Global:PuertoScanTimeout = 500
    $Global:PuertosComunes = @(21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080)
    $Global:ExtensionesSospechosas = @(".exe", ".scr", ".bat", ".cmd", ".ps1", ".vbs", ".js", ".lnk")
    $Global:UbicacionesSospechosas = @("C:\Users\Public", "$env:TEMP", "$env:APPDATA")
    $Global:TamañoMinimoMB = 0.01
    $Global:TamañoMaximoMB = 100
    $Global:PuntajeUmbral = 3
    $Global:VirusTotalApiKey = "TU_API_KEY_VIRUSTOTAL_AQUI"
    $Global:RutaEscaneo = "C:\Users\Public"
    Guardar-Configuracion
}

# --- Variables Globales Adicionales ---
$Global:UltimosSospechosos = $null # Almacenará los resultados del último escaneo de archivos
$Global:UltimosArchivosOcultos = $null # Almacenará los resultados del último listado de archivos ocultos

# --- Cargar Configuración al Inicio ---
Cargar-Configuracion

# --- Funciones de Análisis de Archivos ---

<#
.SYNOPSIS
Calcula un puntaje de sospecha para un archivo basado en criterios definidos.

.DESCRIPTION
Evalúa un archivo específico comparando su extensión, ubicación y tamaño con
listas y umbrales de configuración globales. Asigna puntos por cada criterio
que coincida y devuelve el puntaje total.

.PARAMETER Archivo
Objeto System.IO.FileInfo que representa el archivo a calcular su puntaje de sospecha.

.NOTES
Los criterios y umbrales se toman de las variables globales de configuración.
#>
function Calcular-PuntajeSospecha {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$Archivo
    )

    $puntaje = 0

    if ($Global:ExtensionesSospechosas -contains $Archivo.Extension.ToLower()) {
        $puntaje += 2
    }

    foreach ($ubicacion in $Global:UbicacionesSospechosas) {
        $ubicacionExpandida = $ExecutionContext.InvokeCommand.ExpandString($ubicacion)
        if ($Archivo.FullName.StartsWith($ubicacionExpandida, [System.StringComparison]::OrdinalIgnoreCase)) {
            $puntaje += 1
            break
        }
    }

    $tamañoMB = $Archivo.Length / 1MB
    if ($tamañoMB -lt $Global:TamañoMinimoMB -or $tamañoMB -gt $Global::TamañoMaximoMB) {
        $puntaje += 1
    }

    return $puntaje
}

<#
.SYNOPSIS
Busca y lista archivos con el atributo 'Hidden' en la ruta especificada.

.DESCRIPTION
Esta función recorre recursivamente un directorio buscando archivos que tengan
establecido el atributo 'Hidden'. Siempre mostrará los resultados en la consola
y, opcionalmente, puede exportarlos a un archivo CSV.

.PARAMETER Path
La ruta del directorio donde se iniciará la búsqueda de archivos ocultos.
Este parámetro es obligatorio.

.PARAMETER OutputPath
La ruta completa del archivo CSV donde se guardará el listado. Si este parámetro
no se especifica, el listado solo se mostrará en la consola.

.OUTPUTS
System.IO.FileInfo[] o PSCustomObject[] - Un array de objetos que representan
los archivos ocultos encontrados. La función devuelve $null si la ruta no existe o hay
un error de búsqueda.

.NOTES
Utiliza Get-ChildItem con -Force y -Recurse para buscar en subdirectorios, incluyendo elementos ocultos/del sistema.
Verifica el atributo 'Hidden' usando el operador bitwise AND.
Puede requerir permisos elevados si se buscan archivos en directorios protegidos.
Siempre muestra el listado en la consola si se encuentran archivos.
#>
function Get-HiddenFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Verificar si la ruta existe y es un directorio
    if (-Not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "La ruta especificada no existe o no es un directorio válido: '$Path'"
        return $null
    }

    Write-Host "Buscando archivos ocultos en '$Path'..." -ForegroundColor Gray

    $files = @()
    try {
        $files = Get-ChildItem -Path $Path -Recurse -Force -File | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
    } catch {
        Write-Error "Error al buscar archivos ocultos en '{0}': {1}" -f $Path, $_.Exception.Message
        return $null
    }


    if ($files.Count -eq 0) {
        Write-Output "No se encontraron archivos ocultos en '$Path'."
        return @()
    } else {
        Write-Host "$($files.Count) archivos ocultos encontrados en '$Path'." -ForegroundColor Green

        # Mostrar en consola
        Write-Host "`nArchivos Ocultos Encontrados:" -ForegroundColor White
        $files | Select-Object FullName, Name, Length, LastWriteTime | Format-Table -AutoSize

        # Si OutputPath está especificado, exportar a CSV
        if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
             try {
                $files | Select-Object FullName, Name, Length, LastWriteTime | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -Force
                Write-Output "Reporte de archivos ocultos generado en: $OutputPath" -ForegroundColor Green
             } catch {
                 Write-Error "No se pudo generar el reporte en '{0}': {1}" -f $OutputPath, $_.Exception.Message
             }
        }

        return $files
    }
}

<#
.SYNOPSIS
Busca archivos sospechosos en una ruta específica.

.DESCRIPTION
Recorre recursivamente el directorio especificado en $Global:RutaEscaneo,
aplica la función Calcular-PuntajeSospecha a cada archivo y recopila una lista
de archivos cuyo puntaje de sospecha supera el umbral configurado en
$Global:PuntajeUmbral. Calcula y añade el hash SHA256 si es posible.

.OUTPUTS
System.Collections.Generic.List[PSCustomObject] - Una lista de objetos personalizados
que representan los archivos sospechosos encontrados, incluyendo Ruta, Puntaje,
Hash (SHA256) y TamañoMB. Devuelve $null si la ruta de escaneo no es válida.

.NOTES
Muestra una barra de progreso durante el escaneo.
Maneja errores si no se pueden acceder a archivos o calcular su hash.
La ruta de escaneo se toma de $Global:RutaEscaneo.
El umbral de puntaje se toma de $Global:PuntajeUmbral.
#>
function Escanear-ArchivosSospechosos {
    # Asegurarse que la ruta existe antes de escanear
    if (-not (Test-Path -Path $Global:RutaEscaneo -PathType Container)) {
        Write-Error "La ruta de escaneo '$($Global:RutaEscaneo)' no es válida o no es un directorio."
        return $null
    }

    $archivos = Get-ChildItem -Path $Global:RutaEscaneo -Recurse -File -ErrorAction SilentlyContinue
    $sospechosos = [System.Collections.Generic.List[PSCustomObject]]::new()

    Write-Host "Escaneando en $($Global:RutaEscaneo)..." -ForegroundColor Gray
    $totalArchivos = $archivos.Count
    $contador = 0
    $progreso = 0

    if ($totalArchivos -eq 0) {
        Write-Host "No se encontraron archivos en la ruta especificada." -ForegroundColor Yellow
        return $sospechosos
    }

    foreach ($archivo in $archivos) {
        $contador++
        $progresoActual = [math]::Floor(($contador / $totalArchivos) * 100)
        if ($progresoActual -gt $progreso) {
             Write-Progress -Activity "Escaneando Archivos" -Status "$progresoActual% Completado ($contador/$totalArchivos)" -PercentComplete $progresoActual
             $progreso = $progresoActual
        }

        try {
            $puntaje = Calcular-PuntajeSospecha -Archivo $archivo
            if ($puntaje -ge $Global:PuntajeUmbral) {
                $hashInfo = Get-FileHash -Path $archivo.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($hashInfo) {
                    $sospechosos.Add([PSCustomObject]@{
                        Ruta    = $archivo.FullName
                        Puntaje = $puntaje
                        Hash    = $hashInfo.Hash
                        TamañoMB= [math]::Round($archivo.Length / 1MB, 2)
                    })
                } else {
                     Write-Warning "No se pudo calcular el hash para '$($archivo.FullName)'."
                }
            }
        } catch {
            Write-Warning "No se pudo procesar el archivo '$($archivo.FullName)': $($_.Exception.Message)"
        }
    }
    Write-Progress -Activity "Escaneando Archivos" -Completed
    return $sospechosos
}

<#
.SYNOPSIS
Consulta información sobre un hash de archivo en VirusTotal.

.DESCRIPTION
Envía una solicitud a la API pública de VirusTotal (v2) para obtener el reporte
de un hash de archivo SHA256. Muestra información como positivos detectados,
fecha de escaneo y enlace permanente.

.PARAMETER Hash
El hash SHA256 del archivo a consultar en VirusTotal.

.OUTPUTS
PSCustomObject - Un objeto con los resultados de la consulta a la API de VirusTotal
si es exitosa, o $null si falla la consulta (API Key no configurada, hash inválido,
error de red, límite de API, etc.).

.NOTES
Requiere que la API Key de VirusTotal esté configurada en $Global:VirusTotalApiKey.
Utiliza la API v2 de VirusTotal.
Respeta el límite de 4 consultas por minuto para la API pública, insertando pausas.
Maneja varios códigos de error de la API.
#>
function Consultar-VirusTotal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Hash
    )

    # Verificar si la API Key está configurada
    if (-not $Global:VirusTotalApiKey -or $Global:VirusTotalApiKey -match "TU_API_KEY" -or [string]::IsNullOrWhiteSpace($Global:VirusTotalApiKey)) {
        Write-Error "La API Key de VirusTotal no está configurada. Por favor, configúrala en el menú 'Análisis de Archivos -> Configurar Filtros y Opciones'."
        return $null
    }

    # Validar formato del hash (SHA256 = 64 hex chars)
    if ($Hash -notmatch '^[a-fA-F0-9]{64}$') {
         Write-Error "El hash '$Hash' no parece ser un SHA256 válido."
         return $null
    }

    $uri = "https://www.virustotal.com/vtapi/v2/file/report"
    $parameters = @{
        apikey   = $Global:VirusTotalApiKey
        resource = $Hash
    }

    try {
        $respuesta = Invoke-RestMethod -Method Get -Uri $uri -Body $parameters -TimeoutSec 30 -ErrorAction Stop
        return $respuesta
    } catch {
        $errorMessage = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage += " (Código de estado: $statusCode)"
            if ($statusCode -eq 403) { $errorMessage += " - Revisa tu API Key o permisos."}
            if ($statusCode -eq 204) { $errorMessage += " - Límite de API excedido (Rate limit). Espera un minuto."}
        }
        Write-Error "Error al consultar VirusTotal para el hash $Hash. $errorMessage"
        return $null
    }
}

<#
.SYNOPSIS
Ejecuta el proceso completo de análisis de archivos sospechosos.

.DESCRIPTION
Llama a la función Escanear-ArchivosSospechosos para obtener la lista de archivos
sospechosos según la configuración actual. Almacena los resultados en la variable
global $Global:UltimosSospechosos y muestra un resumen formateado en la consola.

.NOTES
Si el escaneo falla (ej. ruta inválida), limpia la lista global de sospechosos.
Muestra el número de archivos encontrados y opciones para ver/analizar/eliminar.
#>
function Ejecutar-AnalisisDeArchivos {
    Write-Host "`nEjecutando Análisis de Archivos Sospechosos..." -ForegroundColor Yellow
    $sospechosos = Escanear-ArchivosSospechosos

    if ($null -eq $sospechosos) {
        $Global:UltimosSospechosos = $null
        return
    }

    $Global:UltimosSospechosos = $sospechosos

    if ($Global:UltimosSospechosos -and $Global:UltimosSospechosos.Count -gt 0) {
        Write-Host "`n$($Global:UltimosSospechosos.Count) Archivos Sospechosos Encontrados." -ForegroundColor Red
        Write-Host "Use la opción '1.3 Ver Lista de Archivos Sospechosos' para ver los detalles." -ForegroundColor Yellow
    } else {
        Write-Host "`nNo se encontraron archivos sospechosos con el umbral actual en '$($Global:RutaEscaneo)'." -ForegroundColor Green
    }
    Write-Host "Análisis de archivos completado."
}

<#
.SYNOPSIS
Muestra el menú para configurar los filtros y opciones del análisis de archivos.

.DESCRIPTION
Presenta un submenú interactivo donde el usuario puede modificar las extensiones
sospechosas, ubicaciones, tamaños mínimo/máximo, puntaje umbral, ruta de escaneo
y la API Key de VirusTotal. Llama a Guardar-Configuracion cuando se modifica
algún valor.

.NOTES
Este menú es llamado desde Mostrar-Submenu1.
Utiliza un bucle do/while para mantener el menú activo hasta que el usuario
elija volver (opción 0).
#>
function Configurar-FiltrosAnalisisArchivos {
    Write-Host "`nConfigurando Filtros para Análisis de Archivos..." -ForegroundColor Yellow
    Mostrar-MenuConfiguracionArchivos
}

<#
.SYNOPSIS
Muestra la lista de archivos sospechosos encontrados en el último escaneo.

.DESCRIPTION
Recupera la lista de archivos almacenada en $Global:UltimosSospechosos y la
muestra formateada en la consola, incluyendo la ruta, puntaje de sospecha,
hash SHA256 y tamaño.

.NOTES
Si no hay resultados del último escaneo (la variable global está vacía o $null),
informa al usuario.
#>
function Ver-ListaSospechosos {
    Write-Host "`nLista de Archivos Sospechosos del Último Análisis:" -ForegroundColor Yellow
    if ($null -ne $Global:UltimosSospechosos -and $Global:UltimosSospechosos.Count -gt 0) {
         $Global:UltimosSospechosos | Select-Object Ruta, Puntaje, Hash, TamañoMB | Format-Table -AutoSize
    } else {
        Write-Host "No hay resultados de análisis previos disponibles o no se encontraron archivos sospechosos." -ForegroundColor Green
        Write-Host "Ejecuta primero el 'Escanear Archivos Sospechosos' (Opción 1.1)." -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
Envía los hashes de los archivos sospechosos a VirusTotal para su consulta.

.DESCRIPTION
Itera sobre la lista de archivos sospechosos almacenada en $Global:UltimosSospechosos.
Para cada archivo que tenga un hash calculado, llama a Consultar-VirusTotal
y muestra los resultados obtenidos de la API de VirusTotal. Incluye una pausa
entre consultas para respetar los límites de la API pública.

.NOTES
Requiere que la API Key de VirusTotal esté configurada.
Procesa la lista del último escaneo, no realiza un nuevo escaneo de archivos.
Maneja archivos sin hash (saltándolos).
#>
function Enviar-AVirusTotal {
    Write-Host "`nEnviando hashes de archivos sospechosos a VirusTotal..." -ForegroundColor Yellow

    $sospechosos = $Global:UltimosSospechosos

    if ($null -eq $sospechosos -or $sospechosos.Count -eq 0) {
        Write-Warning "No hay archivos sospechosos en la lista del último análisis. Ejecuta primero 'Escanear Archivos Sospechosos' (Opción 1.1)."
        return
    }

    if (-not $Global:VirusTotalApiKey -or $Global:VirusTotalApiKey -match "TU_API_KEY" -or [string]::IsNullOrWhiteSpace($Global:VirusTotalApiKey)) {
        Write-Error "Error: La API Key de VirusTotal no está configurada."
        Write-Warning "Por favor, configúrala en el menú 'Análisis de Archivos -> Configurar Filtros y Opciones'."
        return
    }

    Write-Host "Se consultarán $($sospechosos.Count) hashes."
    $contador = 0
    foreach ($archivo in $sospechosos) {
        $contador++
        if (-not $archivo.Hash -or $archivo.Hash -eq 'N/A') {
            Write-Warning "Saltando archivo sin hash: $($archivo.Ruta)"
            continue
        }

        Write-Host "`n($contador/$($sospechosos.Count)) Consultando VirusTotal para: $($archivo.Ruta)..." -ForegroundColor White
        Write-Host "  Hash: $($archivo.Hash)" -ForegroundColor Gray
        $resultado = Consultar-VirusTotal -Hash $archivo.Hash

        if ($resultado -ne $null) {
            if ($resultado.response_code -eq 1) {
                 Write-Host "  Resultados:" -ForegroundColor White
                 Write-Host "    Positivos/Total AVs: $($resultado.positives) / $($resultado.total)"
                 Write-Host "    Fecha Escaneo VT: $($resultado.scan_date)"
                 Write-Host "    Enlace Permanente: $($resultado.permalink)" -ForegroundColor Blue
                 if ($resultado.positives -gt 0) {
                     Write-Host "    ¡Posible amenaza detectada!" -ForegroundColor Red
                 } else {
                     Write-Host "    No detectado como malicioso por los motores consultados." -ForegroundColor Green
                 }
            } elseif ($resultado.response_code -eq 0) {
                 Write-Host "  El hash no fue encontrado en la base de datos de VirusTotal." -ForegroundColor Yellow
            } else {
                Write-Warning "Respuesta de VirusTotal (código $($resultado.response_code)): $($resultado.verbose_msg)"
            }
        } else {
            Write-Error "  No se pudo obtener respuesta de VirusTotal para este hash (revisar mensajes de error anteriores)."
        }

        # Pausa para cumplir con el límite de la API pública de VirusTotal (4 consultas por minuto)
        if ($contador -lt $sospechosos.Count) {
            Write-Host "Esperando 15 segundos para la siguiente consulta (límite API pública VT)..." -ForegroundColor Gray
            Start-Sleep -Seconds 15
        }
    }
    Write-Host "`nConsulta a VirusTotal completada." -ForegroundColor Green
}

<#
.SYNOPSIS
Permite al usuario revisar y eliminar archivos de la lista de sospechosos.

.DESCRIPTION
Muestra la lista de archivos sospechosos del último escaneo y le pide al usuario
confirmación para eliminar cada archivo individualmente. Requiere una doble
confirmación para prevenir eliminaciones accidentales.

.NOTES
Esta acción es IRREVERSIBLE. Los archivos se envían a la papelera de reciclaje
o se eliminan permanentemente dependiendo de la configuración del sistema.
Requiere permisos de escritura/eliminación sobre los archivos.
Opera sobre la lista almacenada en $Global:UltimosSospechosos.
#>
function Eliminar-ArchivosMaliciosos {
    Write-Host "`nEliminar Archivos Sospechosos (requiere confirmación)..." -ForegroundColor Red -BackgroundColor Black

    $sospechosos = $Global:UltimosSospechosos

    if ($null -eq $sospechosos -or $sospechosos.Count -eq 0) {
        Write-Warning "No hay archivos sospechosos en la lista del último análisis. Ejecuta primero 'Escanear Archivos Sospechosos' (Opción 1.1)."
        return
    }

    Write-Host "Se encontraron $($sospechosos.Count) archivos en la lista de sospechosos." -ForegroundColor Yellow
    Write-Warning "¡¡¡PRECAUCIÓN!!! Esta acción intentará ELIMINAR archivos permanentemente."

    Write-Host "Lista de Archivos a Revisar:" -ForegroundColor White
    $sospechosos | Format-Table -AutoSize Ruta, Puntaje, TamañoMB

    $confirmacionGeneral = Read-Host "¿Deseas proceder a revisar CADA archivo para eliminarlo individualmente? (s/n)"
    if ($confirmacionGeneral -ne 's') {
        Write-Host "Operación de eliminación cancelada." -ForegroundColor Yellow
        return
    }

    $listaActualizada = $Global:UltimosSospechosos.Clone()

    foreach ($archivo in $Global:UltimosSospechosos) {
        Write-Host "`nArchivo: $($archivo.Ruta)" -ForegroundColor White
        Write-Host "Puntaje: $($archivo.Puntaje), Tamaño: $($archivo.TamañoMB) MB" -ForegroundColor White

        $confirmacion = ''
        while ($confirmacion -notin @('s', 'n', 'c')) {
             $confirmacion = Read-Host "¿ELIMINAR este archivo? (s = Sí / n = No / c = Cancelar todo)"
        }

        if ($confirmacion -eq "s") {
            $confirmacion2 = Read-Host "¿Estás ABSOLUTAMENTE SEGURO de querer eliminar '$($archivo.Ruta)'? (s/n)"
            if ($confirmacion2 -eq 's') {
                 try {
                    Write-Host "Intentando eliminar '$($archivo.Ruta)'..." -ForegroundColor Magenta
                    Remove-Item -Path $archivo.Ruta -Force -ErrorAction Stop
                    Write-Host " Archivo eliminado exitosamente." -ForegroundColor Green
                    $itemToRemove = $listaActualizada | Where-Object { $_.Ruta -eq $archivo.Ruta }
                    if ($itemToRemove) { $listaActualizada.Remove($itemToRemove) }
                 } catch {
                    Write-Error "Error al eliminar el archivo '$($archivo.Ruta)': $($_.Exception.Message)"
                    Write-Warning "Puede que el archivo esté en uso, no exista ya, o necesites permisos elevados."
                 }
            } else {
                 Write-Host " Eliminación cancelada para este archivo." -ForegroundColor Yellow
            }

        } elseif ($confirmacion -eq "c") {
            Write-Host "Operación de eliminación cancelada por el usuario." -ForegroundColor Yellow
            $Global:UltimosSospechosos = $listaActualizada
            return
        }
         else {
            Write-Host " Eliminación omitida para este archivo." -ForegroundColor Yellow
        }
    }

     $Global:UltimosSospechosos = $listaActualizada
     Write-Host "`nProceso de revisión para eliminación completado." -ForegroundColor Green
     if ($Global:UltimosSospechosos.Count -gt 0) {
         Write-Host "Quedan $($Global:UltimosSospechosos.Count) archivos en la lista de sospechosos."
     } else {
         Write-Host "La lista de sospechosos está ahora vacía."
     }
}

<#
.SYNOPSIS
Muestra el menú para configurar los filtros y opciones del análisis de archivos.

.DESCRIPTION
Presenta un submenú interactivo donde el usuario puede modificar las extensiones
sospechosas, ubicaciones, tamaños mínimo/máximo, puntaje umbral, ruta de escaneo
y la API Key de VirusTotal. Llama a Guardar-Configuracion cuando se modifica
algún valor.

.NOTES
Este menú es llamado desde Mostrar-Submenu1.
Utiliza un bucle do/while para mantener el menú activo hasta que el usuario
elija volver (opción 0).
#>
function Mostrar-MenuConfiguracionArchivos {
    do {
        Write-Host "`n--- Configuración del Análisis de Archivos ---" -ForegroundColor Cyan
        Write-Host "1. Establecer extensiones sospechosas (actual: $($Global:ExtensionesSospechosas -join ', '))"
        Write-Host "2. Establecer ubicaciones sospechosas (actual: $($Global:UbicacionesSospechosas -join ', '))"
        Write-Host "3. Establecer tamaño mínimo de archivo (MB) (actual: $($Global:TamañoMinimoMB))"
        Write-Host "4. Establecer tamaño máximo de archivo (MB) (actual: $($Global:TamañoMaximoMB))"
        Write-Host "5. Establecer puntaje umbral de sospecha (actual: $($Global:PuntajeUmbral))"
        Write-Host "6. Establecer ruta de escaneo (actual: $($Global:RutaEscaneo))"
        Write-Host "7. Establecer API Key de VirusTotal (actual: $(if ($Global:VirusTotalApiKey -notmatch 'TU_API_KEY' -and -not [string]::IsNullOrWhiteSpace($Global:VirusTotalApiKey)) { 'Configurada' } else { 'NO Configurada' }))"
        Write-Host "0. Volver al menú de Análisis de Archivos"
        Write-Host "----------------------------------------------" -ForegroundColor Cyan
        $opcion = Read-Host "Selecciona una opción"

        switch ($opcion) {
            "1" {
                $extensionesInput = Read-Host "Ingresa las extensiones separadas por comas (ej: .exe,.dll,.bat)"
                $nuevasExtensiones = $extensionesInput.Split(",") | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -like '.*' -and $_.Length -gt 1}
                if ($nuevasExtensiones) {
                    $Global:ExtensionesSospechosas = $nuevasExtensiones
                    Write-Host "Extensiones actualizadas." -ForegroundColor Green
                    Guardar-Configuracion
                } else {
                    Write-Warning "Entrada inválida. Asegúrate de que las extensiones empiecen con '.' y no estén vacías (ej: .exe,.dll)."
                }
            }
            "2" {
                $ubicacionesInput = Read-Host "Ingresa las rutas separadas por comas (ej: C:\Temp,`$env:APPDATA\Roaming)"
                $nuevasUbicaciones = $ubicacionesInput.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                 if ($nuevasUbicaciones) {
                    $Global:UbicacionesSospechosas = $nuevasUbicaciones
                    Write-Host "Ubicaciones actualizadas." -ForegroundColor Green
                    Guardar-Configuracion
                 } else {
                    Write-Warning "Entrada inválida o ninguna ubicación proporcionada."
                 }
            }
            "3" {
                $minimoInput = Read-Host "Ingresa el tamaño mínimo en MB (ej: 0.01)"
                [double]$minimoDouble = 0 # Inicializar la variable
                if ([double]::TryParse($minimoInput, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$minimoDouble) -and $minimoDouble -ge 0) {
                     $Global:TamañoMinimoMB = $minimoDouble
                     Write-Host "Tamaño mínimo actualizado a $Global:TamañoMinimoMB MB." -ForegroundColor Green
                     Guardar-Configuracion
                } else {
                    Write-Warning "Entrada inválida. Ingresa un número positivo (usa '.' como separador decimal)."
                }
            }
            "4" {
                 $maximoInput = Read-Host "Ingresa el tamaño máximo en MB (ej: 100)"
                 [double]$maximoDouble = 0 # Inicializar la variable
                 if ([double]::TryParse($maximoInput, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$maximoDouble) -and $maximoDouble -gt 0) {
                     if ($maximoDouble -ge $Global:TamañoMinimoMB) {
                        $Global:TamañoMaximoMB = $maximoDouble
                        Write-Host "Tamaño máximo actualizado a $Global:TamañoMaximoMB MB." -ForegroundColor Green
                        Guardar-Configuracion
                     } else {
                         Write-Warning "El tamaño máximo ($maximoDouble MB) debe ser mayor o igual al mínimo ($($Global:TamañoMinimoMB) MB)."
                     }
                 } else {
                     Write-Warning "Entrada inválida. Ingresa un número positivo mayor que cero (usa '.' como separador decimal)."
                 }
            }
            "5" {
                $umbralInput = Read-Host "Ingresa el puntaje umbral (número entero >= 0, ej: 3)"
                [int]$umbralInt = 0 # <<-- ¡Inicializar la variable aquí!
                if ([int]::TryParse($umbralInput, [ref]$umbralInt) -and $umbralInt -ge 0) {
                    $Global:PuntajeUmbral = $umbralInt
                    Write-Host "Puntaje umbral actualizado a $Global:PuntajeUmbral." -ForegroundColor Green
                    Guardar-Configuracion
                } else {
                    Write-Warning "Entrada inválida. Ingresa un número entero positivo o cero."
                }
            }
            "6" {
                $rutaInput = Read-Host "Ingresa la nueva ruta de escaneo (ej: C:\Users\Public)"
                if (-not [string]::IsNullOrWhiteSpace($rutaInput)) {
                    if (Test-Path -Path $rutaInput -PathType Container) {
                        $Global:RutaEscaneo = $rutaInput
                        Write-Host "Ruta de escaneo actualizada a '$Global:RutaEscaneo'." -ForegroundColor Green
                        Guardar-Configuracion
                    } else {
                         Write-Warning "La ruta '$rutaInput' no existe actualmente o no es un directorio. Se guardará, pero el escaneo fallará si no es válida al ejecutar."
                         $Global:RutaEscaneo = $rutaInput
                         Guardar-Configuracion
                    }
                } else {
                    Write-Warning "La ruta no puede estar vacía."
                }
            }
            "7" {
                $apiKeyInput = Read-Host "Ingresa tu API Key de VirusTotal (dejar en blanco para no cambiar)"
                if (-not [string]::IsNullOrWhiteSpace($apiKeyInput)) {
                    $Global:VirusTotalApiKey = $apiKeyInput.Trim()
                    Write-Host "API Key de VirusTotal actualizada." -ForegroundColor Green
                    Guardar-Configuracion
                } else {
                    Write-Host "API Key no modificada." -ForegroundColor Yellow
                }
            }
            "0" { return }
            default { Write-Warning "Opción no válida." }
        }
    } while ($true)
}

<#
.SYNOPSIS
Muestra el submenú de opciones para el Análisis de Archivos.

.DESCRIPTION
Presenta al usuario las opciones disponibles para el análisis de archivos,
como escanear, configurar filtros, ver la lista de sospechosos, enviar a
VirusTotal, eliminar archivos y listar/ver archivos ocultos. Ejecuta la
función correspondiente a la opción seleccionada.

.NOTES
Este menú es parte de la interfaz interactiva principal del script.
Permite volver al menú principal con la opción 0.
Las opciones 1.1 y 1.6 realizan escaneos/listados, pero la visualización detallada
de los resultados se hace con las opciones 1.3 y 1.7 respectivamente.
#>
function Mostrar-Submenu1 {
    do {
        Write-Host "`n--- Análisis de Archivos ---" -ForegroundColor Cyan
        Write-Host "1.1 Escanear Archivos Sospechosos"
        Write-Host "1.2 Configurar Filtros y Opciones"
        Write-Host "1.3 Ver Lista de Archivos Sospechosos (del último escaneo)"
        Write-Host "1.4 Enviar Hashes de Sospechosos a VirusTotal"
        Write-Host "1.5 Eliminar Archivos Sospechosos (con confirmación)"
        Write-Host "1.6 Listado de Archivos Ocultos (Buscar y Mostrar/Guardar)"
        Write-Host "1.7 Ver Lista de Archivos Ocultos (del último listado)" # Nueva opción
        Write-Host "0. Volver al menú principal"
        Write-Host "--------------------------" -ForegroundColor Cyan
        $subopcion = Read-Host "Elige una opción (0-7)" # Rango actualizado
        switch ($subopcion) {
            "1" {
                Ejecutar-AnalisisDeArchivos
                # La visualización se hace con la opción 1.3 ahora
            }
            "2" { Configurar-FiltrosAnalisisArchivos }
            "3" { Ver-ListaSospechosos }
            "4" { Enviar-AVirusTotal }
            "5" { Eliminar-ArchivosMaliciosos }
            "6" {
                Write-Host "`n--- Listado de Archivos Ocultos ---" -ForegroundColor Yellow

                $scanPath = $Global:RutaEscaneo

                $useDefaultPath = Read-Host "Usar la ruta de escaneo configurada ('$scanPath') para buscar ocultos? (s/n)"
                if ($useDefaultPath -ne 's') {
                    $customPath = Read-Host "Ingresa la ruta donde buscar archivos ocultos (Enter para cancelar)"
                    if (-not [string]::IsNullOrWhiteSpace($customPath)) {
                        $scanPath = $customPath.Trim()
                    } else {
                        Write-Warning "No se especificó una ruta. Operación de listado de ocultos cancelada."
                        break
                    }
                }

                $saveToFile = Read-Host "¿Guardar el listado en un archivo CSV? (s/n)"
                $outputPath = $null
                if ($saveToFile -eq 's') {
                    $defaultFileName = "HiddenFilesReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                    $outputDir = $ScriptDir
                    $fullOutputPath = Join-Path -Path $outputDir -ChildPath $defaultFileName

                    $outputPathInput = Read-Host "Ingresa la ruta completa para guardar el reporte (Enter para usar por defecto: '$fullOutputPath')"
                    if (-not [string]::IsNullOrWhiteSpace($outputPathInput)) {
                        $outputPath = $outputPathInput.Trim()
                    } else {
                        $outputPath = $fullOutputPath
                    }
                }

                Write-Host "" # Línea en blanco antes de la salida de la función
                # Llamar a la función Get-HiddenFiles y almacenar su resultado en la variable global
                $Global:UltimosArchivosOcultos = Get-HiddenFiles -Path $scanPath -OutputPath $outputPath

                Write-Host "`nListado de archivos ocultos completado." -ForegroundColor Yellow
            }
            "7" { # Nuevo caso 7: Ver último listado de archivos ocultos
                 Write-Host "`nLista de Archivos Ocultos del Último Listado:" -ForegroundColor Yellow
                 if ($null -ne $Global:UltimosArchivosOcultos -and $Global:UltimosArchivosOcultos.Count -gt 0) {
                      $Global:UltimosArchivosOcultos | Select-Object FullName, Name, Length, LastWriteTime | Format-Table -AutoSize
                 } else {
                     Write-Host "No hay resultados de listado de archivos ocultos previos disponibles." -ForegroundColor Green
                     Write-Host "Ejecuta primero 'Listado de Archivos Ocultos' (Opción 1.6)." -ForegroundColor Yellow
                 }
            }
            "0" { return }
            default { Write-Warning "Opción inválida." }
        }
    } while ($true)
}


# --- Funciones de Análisis de Red ---

<#
.SYNOPSIS
Genera un informe básico de seguridad del sistema local.

.DESCRIPTION
Recopila y muestra información sobre políticas de seguridad (contraseñas, bloqueo),
estado de UAC, configuración de auditoría (ej. inicio de sesión), configuración
del Firewall de Windows Defender (perfiles y reglas activas) y puertos TCP/UDP
en estado de escucha localmente.

.NOTES
Algunas partes del informe requieren permisos elevados (Ejecutar como Administrador)
para acceder a la configuración de políticas de seguridad y auditoría.
Utiliza herramientas del sistema como `secedit` y `auditpol`, y cmdlets como
`Get-NetFirewallProfile`, `Get-NetFirewallRule`, `Get-NetTCPConnection`,
`Get-NetUDPEndpoint`.
#>
function Obtener-InformeSeguridadLocal {
     Write-Host "`nInforme de Seguridad Local:" -ForegroundColor Cyan
     Write-Host "==================================="

     # Políticas de Contraseñas y Bloqueo
     Write-Host "`nPolíticas de Contraseñas y Bloqueo de Cuenta (requiere permisos elevados):" -ForegroundColor Green
     $cfgFile = Join-Path -Path $env:TEMP -ChildPath "secpol_export.cfg"
     secedit /export /cfg $cfgFile /quiet | Out-Null
     Start-Sleep -Milliseconds 500
     if (Test-Path $cfgFile) {
         try {
             $encoding = [System.Text.Encoding]::Default # Codificación usada por secedit
             $contenido = Get-Content $cfgFile -Encoding $encoding
             $politicas = $contenido | Where-Object { $_ -match '^\s*(MinimumPasswordLength|MaximumPasswordAge|MinimumPasswordAge|PasswordHistorySize|LockoutBadCount|LockoutDuration|ResetLockoutCount)\s*=\s*\d+' }
             if ($politicas) {
                 $politicas | ForEach-Object { Write-Host "  $($_.Trim())" }
             } else {
                 Write-Host "  No se encontraron políticas relevantes o el archivo está vacío/formato inesperado." -ForegroundColor Yellow
             }
         } catch {
              Write-Warning "Error al leer el archivo {0}: {1}" -f $cfgFile, $_.Exception.Message
         } finally {
             Remove-Item $cfgFile -Force -ErrorAction SilentlyContinue
         }
     } else {
         Write-Warning "No se pudo exportar la configuración de seguridad local (secedit). Ejecuta como Administrador."
     }

     # Control de Cuentas de Usuario (UAC)
     Write-Host "`nControl de Cuentas de Usuario (UAC):" -ForegroundColor Green
     try {
         $uacEnabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction Stop
         Write-Host "  EnableLUA (UAC Activado): $($uacEnabled.EnableLUA) (1 = Activado, 0 = Desactivado)"
         $uacPromptAdmin = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
         if ($uacPromptAdmin) { Write-Host "  ConsentPromptBehaviorAdmin (Prompt Admin): $($uacPromptAdmin.ConsentPromptBehaviorAdmin) (0=NoPrompt, 1=SecureDesktopCreds, 2=SecureDesktopConsent, 3=DesktopCreds, 4=DesktopConsent, 5=Default)" }
         $uacPromptUser = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -ErrorAction SilentlyContinue
         if ($uacPromptUser) { Write-Host "  ConsentPromptBehaviorUser (Prompt User): $($uacPromptUser.ConsentPromptBehaviorUser) (0=AutoDeny, 1=PromptCreds, 3=PromptConsent)"}

     } catch {
         Write-Warning "No se pudo obtener el estado de UAC desde el registro."
     }

     # Configuración de Auditoría (Ejemplo básico - política de inicio de sesión)
     Write-Host "`nConfiguración de Auditoría (Ejemplo: Auditoría de Inicio de Sesión - requiere permisos elevados):" -ForegroundColor Green
     try {
         $auditOutput = auditpol /get /subcategory:"Inicio de sesión" /r
         if ($auditOutput) {
            $csvAudit = $auditOutput | ConvertFrom-Csv
            $loginAuditing = $csvAudit | Where-Object { $_.'Subcategoría' -eq 'Inicio de sesión' } | Select-Object -ExpandProperty 'Inclusión de configuración'
            Write-Host "  Auditoría de 'Inicio de sesión' (Configuración): $loginAuditing"
         } else {
            Write-Warning "No se obtuvo salida de auditpol."
         }
     } catch {
         Write-Warning "No se pudo obtener la política de auditoría (auditpol). Ejecuta como Administrador. Error: $($_.Exception.Message)"
     }

     # Configuración del Firewall
     Write-Host "`nConfiguración del Firewall de Windows Defender:" -ForegroundColor Green
     try {
         $profiles = Get-NetFirewallProfile -ErrorAction Stop
         foreach ($p in $profiles) {
             Write-Host "  Perfil $($p.Name): Habilitado=$($p.Enabled), Bloquear Entrante=$($p.DefaultInboundAction), Permitir Saliente=$($p.DefaultOutboundAction)"
         }
     } catch {
         Write-Warning "No se pudo obtener la configuración del firewall (Get-NetFirewallProfile). Error: $($_.Exception.Message)"
     }

     # Reglas activas del Firewall (algunas, como ejemplo)
     Write-Host "`nReglas Activas del Firewall (Primeras 5 de cada tipo):" -ForegroundColor Green
     try {
         Write-Host "  Reglas de Entrada Permitidas:"
         Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Select-Object -First 5 DisplayName, Group | Format-Table -AutoSize

         Write-Host "`n  Reglas de Salida Bloqueadas:"
         Get-NetFirewallRule -Enabled True -Direction Outbound -Action Block -ErrorAction SilentlyContinue | Select-Object -First 5 DisplayName, Group | Format-Table -AutoSize

     } catch {
         Write-Warning "No se pudo recuperar las reglas del firewall (Get-NetFirewallRule). Error: $($_.Exception.Message)"
     }

     # Puertos TCP en Escucha (Listening)
     Write-Host "`nPuertos TCP Abiertos Localmente (Estado: Listen):" -ForegroundColor Green
     try {
         $tcpListeners = Get-NetTCPConnection -State Listen -ErrorAction Stop
         if ($tcpListeners) {
             $tcpListeners | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
         } else {
             Write-Host "  No se encontraron puertos TCP en estado Listen." -ForegroundColor Green
         }
     } catch {
         Write-Warning "No se pudieron obtener conexiones TCP (Get-NetTCPConnection). Error: $($_.Exception.Message)"
     }

     # Puertos UDP en Escucha
     Write-Host "`nPuertos UDP Abiertos Localmente (Endpoints):" -ForegroundColor Green
     try {
         $udpListeners = Get-NetUDPEndpoint -ErrorAction Stop
          if ($udpListeners) {
             $udpListeners | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
         } else {
             Write-Host "  No se encontraron endpoints UDP locales." -ForegroundColor Green
         }
     } catch {
         Write-Warning "No se pudieron obtener conexiones UDP (Get-NetUDPEndpoint). Error: $($_.Exception.Message)"
     }

     Write-Host "==================================="
}


<#
.SYNOPSIS
Realiza un escaneo de puertos comunes en un host remoto.

.DESCRIPTION
Intenta establecer una conexión TCP a cada uno de los puertos listados en la
configuración global ($Global:PuertosComunes) en la dirección IP o nombre de host
especificado. Reporta si el puerto está abierto (conexión exitosa dentro del timeout)
o cerrado/filtrado (timeout o conexión rechazada).

.PARAMETER HostName
La dirección IP o nombre de host del objetivo para el escaneo de puertos.

.PARAMETER TimeoutMs
El tiempo máximo de espera en milisegundos para establecer una conexión a cada puerto.
Tomado de la configuración global ($Global:PuertoScanTimeout).

.NOTES
Puede ser bloqueado por firewalls en el host objetivo o en la red.
Puede reportar puertos como "Timeout/Filtrado" si la conexión no se completa
dentro del tiempo especificado.
Resuelve el nombre de host a IP antes de escanear.
#>
function Escanear-PuertosComunes {
    param(
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        [Parameter(Mandatory=$true)]
        [int]$TimeoutMs
    )

    Write-Host "`nIniciando escaneo de puertos comunes en '$HostName'..." -ForegroundColor Yellow

    # Intentar resolver el HostName a IP
    $ipAddress = $null
    try {
        $ipAddress = ([System.Net.Dns]::GetHostAddresses($HostName) | Where-Object {$_.AddressFamily -eq 'InterNetwork'} | Select-Object -First 1).IPAddressToString
        if (-not $ipAddress) {
             $ipAddress = ([System.Net.Dns]::GetHostAddresses($HostName) | Select-Object -First 1).IPAddressToString
        }
        Write-Host "Resolviendo '$HostName' a '$ipAddress'" -ForegroundColor Gray
    } catch {
        Write-Error "No se pudo resolver el nombre de host '$HostName'. Error: $($_.Exception.Message)"
        return
    }

    if (-not $ipAddress) {
         Write-Error "No se pudo obtener una dirección IP para '$HostName'."
         return
    }

    Write-Host "Puertos a escanear: $($Global:PuertosComunes -join ', ')"
    Write-Host "Timeout por puerto: $($TimeoutMs) ms"

    $puertosAbiertos = @()
    $puertosCerrados = @()

    foreach ($puerto in $Global:PuertosComunes) {
        Write-Host "..Escaneando puerto $puerto" -NoNewline -ForegroundColor Gray

        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $conexion = $null
        $resultado = $false

        try {
            $conexion = $tcpClient.ConnectAsync($ipAddress, $puerto)
            $resultado = $conexion.Wait($TimeoutMs)

            if ($resultado) {
                Write-Host "`r  Puerto $puerto : Abierto      " -ForegroundColor Green
                $puertosAbiertos += $puerto
                $tcpClient.Close()
            } else {
                Write-Host "`r  Puerto $puerto : Timeout/Filtrado" -ForegroundColor Yellow
                $puertosCerrados += "$puerto (Timeout)"
                $tcpClient.Close()
            }
        } catch [System.Net.Sockets.SocketException] {
            if ($_.Exception.SocketErrorCode -eq 'ConnectionRefused') {
                Write-Host "`r  Puerto $puerto : Cerrado (Rechazado)" -ForegroundColor Red
                $puertosCerrados += "$puerto (Cerrado)"
            } elseif ($_.Exception.Sockets.SocketErrorCode -eq 'HostUnreachable' -or $_.Exception.Sockets.SocketErrorCode -eq 'NetworkUnreachable') {
                 Write-Host "`r  Puerto $puerto : Host/Red Inaccesible" -ForegroundColor DarkRed
                 $puertosCerrados += "$puerto (Inaccesible)"
            } else {
                 Write-Host "`r  Puerto $puerto : Error ($($_.Exception.SocketErrorCode))" -ForegroundColor DarkRed
                 $puertosCerrados += "$puerto (Error: $($_.Exception.SocketErrorCode))"
            }
        } catch {
            Write-Host "`r  Puerto $puerto : Error Desconocido" -ForegroundColor DarkRed
            Write-Warning "Error inesperado escaneando puerto {0}: {1}" -f $puerto, $_.Exception.Message
            $puertosCerrados += "$puerto (Error Desc.)"
        } finally {
            if ($tcpClient -ne $null) {
                $tcpClient.Dispose()
            }
        }
    }

    Write-Host "`nEscaneo completado para '$HostName' ($ipAddress)."
    if ($puertosAbiertos.Count -gt 0) {
        Write-Host " Puertos Abiertos encontrados:" -ForegroundColor Green
        Write-Host "  $($puertosAbiertos -join ', ')"
    } else {
        Write-Host " No se encontraron puertos abiertos en la lista común." -ForegroundColor Yellow
    }
}


<#
.SYNOPSIS
Consulta información pública sobre una IP o host en Shodan.

.DESCRIPTION
Utiliza la API de Shodan para obtener detalles públicos sobre una dirección
IP o nombre de host, como puertos abiertos detectados por Shodan, vulnerabilidades
conocidas (CVEs) asociadas, información de organización, país y ciudad.

.PARAMETER ConsultaShodan
La dirección IP o nombre de host a consultar en Shodan. Se intentará resolver
a una dirección IP si no es una IP válida.

.NOTES
Requiere que la API Key de Shodan esté configurada en $Global:ShodanApiKey.
Shodan requiere una dirección IP válida para esta funcionalidad.
Maneja errores de la API de Shodan (ej. IP no encontrada, error de autenticación).
#>
function Monitorear-Red-Shodan {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConsultaShodan
    )

    Write-Host "`nConsultando Shodan para '$ConsultaShodan'..." -ForegroundColor Yellow

    # Verificar si la API Key de Shodan está configurada
    if (-not $Global:ShodanApiKey -or $Global:ShodanApiKey -match "TU_API_KEY" -or [string]::IsNullOrWhiteSpace($Global:ShodanApiKey)) {
        Write-Error "La API Key de Shodan no está configurada."
        Write-Warning "Por favor, configúrala en el menú 'Análisis de Red -> Configurar API Key Shodan'."
        return
    }

    # Intentar obtener la IP si no lo es ya
    $ipAddress = $null
    if ($ConsultaShodan -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        $ipAddress = $ConsultaShodan
    } else {
         try {
            $ipAddress = ([System.Net.Dns]::GetHostAddresses($ConsultaShodan) | Where-Object {$_.AddressFamily -eq 'InterNetwork'} | Select-Object -First 1).IPAddressToString
             if (-not $ipAddress) { $ipAddress = ([System.Net.Dns]::GetHostAddresses($ConsultaShodan) | Select-Object -First 1).IPAddressToString }
            Write-Host "Resolviendo '$ConsultaShodan' a '$ipAddress'" -ForegroundColor Gray
         } catch {
            Write-Error "No se pudo resolver '$ConsultaShodan' a una dirección IP. Shodan requiere una IP para esta función. Error: $($_.Exception.Message)"
            return
         }
    }

     if (-not $ipAddress) {
         Write-Error "No se pudo obtener una dirección IP válida para consultar Shodan."
         return
     }

    # Construir la URL de la API
    $apiUrl = "https://api.shodan.io/shodan/host/$ipAddress"
    $apiKeyParam = "?key=$($Global:ShodanApiKey)"
    $uri = $apiUrl + $apiKeyParam

    Write-Host "Consultando URI: $apiUrl" -ForegroundColor Gray #(No mostrar API key)

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30 -ErrorAction Stop

        # Mostrar resultados
        Write-Host "`n--- Información de Shodan para $ipAddress ---" -ForegroundColor Cyan
        Write-Host " IP: $($response.ip_str)"
        Write-Host " Hostnames: $($response.hostnames -join ', ')"
        Write-Host " Organización (ISP): $($response.org)"
        Write-Host " País: $($response.country_name)"
        Write-Host " Ciudad: $($response.city)"
        Write-Host " Última actualización Shodan: $($response.last_update)"

        if ($response.ports) {
            Write-Host "`n Puertos Abiertos detectados por Shodan:" -ForegroundColor Green
            $portsArray = $response.ports | ForEach-Object {[int]$_} | Sort-Object
            Write-Host "  $($portsArray -join ', ')"
        } else {
            Write-Host "`n No hay puertos abiertos listados por Shodan." -ForegroundColor Yellow
        }

        if ($response.vulns) {
            Write-Host "`n Vulnerabilidades conocidas (CVEs) listadas por Shodan:" -ForegroundColor Red
            $response.vulns | ForEach-Object { Write-Host "  - $_" }
        } else {
            Write-Host "`n No hay vulnerabilidades conocidas listadas por Shodan." -ForegroundColor Green
        }

        # Mostrar más detalles de servicios si están disponibles
        if ($response.data) {
            Write-Host "`n Detalles adicionales de Servicios:" -ForegroundColor White
            foreach ($service in $response.data) {
                Write-Host "  Puerto: $($service.port)" -ForegroundColor White
                Write-Host "    Transporte: $($service.transport)"
                if ($service.product) { Write-Host "    Producto: $($service.product)" }
                if ($service.version) { Write-Host "    Versión: $($service.version)" }
                if ($service.os) { Write-Host "    OS detectado: $($service.os)" }
                if ($service.data) {
                     $bannerSnippet = $service.data.split([Environment]::NewLine)[0]
                     Write-Host "    Banner (inicio): $bannerSnippet" -ForegroundColor Gray
                }
                 Write-Host # Línea en blanco para separar servicios
            }
        }

        Write-Host "--- Fin de la Información de Shodan ---" -ForegroundColor Cyan

    } catch {
        $errorMessage = $_.Exception.Message
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage += " (Código de estado: $statusCode)."
            try {
                 $errorBody = $_.Exception.Response.GetResponseStream()
                 $reader = New-Object System.IO.StreamReader($errorBody)
                 $errorJson = $reader.ReadToEnd() | ConvertFrom-Json -ErrorAction SilentlyContinue
                 if ($errorJson -and $errorJson.error) {
                     $errorMessage += " Mensaje Shodan: $($errorJson.error)"
                 }
                 $reader.Close()
            } catch {
                # Ignorar si no se puede leer el cuerpo del error
            }
        }

        if ($statusCode -eq 404) {
             Write-Warning "Shodan no tiene información registrada para la IP '$ipAddress'."
        } elseif ($statusCode -eq 401) {
             Write-Error "Error de autenticación con Shodan (401). Revisa tu API Key."
        } else {
             Write-Error "Error al consultar Shodan para $ipAddress. $errorMessage"
        }
    }
}

<#
.SYNOPSIS
Muestra el submenú de opciones para el Análisis de Red.

.DESCRIPTION
Presenta al usuario las opciones disponibles para el análisis de red, como
escanear puertos comunes en un host remoto, consultar Shodan para una IP,
configurar el timeout de escaneo de puertos, obtener un informe de seguridad
local y configurar la API Key de Shodan. Ejecuta la función correspondiente
a la opción seleccionada.

.NOTES
Este menú es parte de la interfaz interactiva principal del script.
Permite volver al menú principal con la opción 0.
#>
function Mostrar-Submenu2 {
    do {
        Write-Host "`n--- Análisis de Red ---" -ForegroundColor Cyan
        Write-Host "2.1 Escaneo de Puertos Comunes (Remoto)"
        Write-Host "2.2 Monitorear con Shodan (IP Remota)"
        Write-Host "2.3 Configurar Timeout Escaneo Puertos (actual: $($Global:PuertoScanTimeout) ms)"
        Write-Host "2.4 Informe de Seguridad Local"
        Write-Host "2.5 Configurar API Key Shodan (actual: $(if ($Global:ShodanApiKey -notmatch 'TU_API_KEY' -and -not [string]::IsNullOrWhiteSpace($Global:ShodanApiKey)) { 'Configurada' } else { 'NO Configurada' }))"
        Write-Host "0. Volver al menú principal"
        Write-Host "-----------------------" -ForegroundColor Cyan
        $subopcion = Read-Host "Elige una opción (0-5)"
        switch ($subopcion) {
            "1" {
                $hostObjetivo = Read-Host "Introduce la dirección IP o nombre de host a escanear"
                if (-not [string]::IsNullOrWhiteSpace($hostObjetivo)) {
                    Escanear-PuertosComunes -HostName $hostObjetivo -TimeoutMs $Global:PuertoScanTimeout
                } else { Write-Warning "Nombre de host/IP no puede estar vacío."}
            }
            "2" {
                $consulta = Read-Host "Introduce la dirección IP (o nombre de host resoluble) a consultar en Shodan"
                 if (-not [string]::IsNullOrWhiteSpace($consulta)) {
                    Monitorear-Red-Shodan -ConsultaShodan $consulta
                 } else { Write-Warning "La IP/Nombre de host no puede estar vacío."}
            }
            "3" {
                 $timeoutInput = Read-Host "Introduce el nuevo timeout para escaneo de puertos (en milisegundos, ej: 500)"
                 [int]$timeoutInt = 0
                 if ([int]::TryParse($timeoutInput, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$timeoutInt) -and $timeoutInt -gt 50) {
                     $Global:PuertoScanTimeout = $timeoutInt
                     Write-Host -ForegroundColor Green "Timeout configurado a $Global:PuertoScanTimeout ms."
                     Guardar-Configuracion
                 } else {
                     Write-Warning "Entrada inválida. Ingresa un número entero positivo mayor que 50."
                 }
            }
            "4" { Obtener-InformeSeguridadLocal }
            "5" {
                 $apiKeyInput = Read-Host "Ingresa tu API Key de Shodan (dejar en blanco para no cambiar)"
                 if (-not [string]::IsNullOrWhiteSpace($apiKeyInput)) {
                     $Global:ShodanApiKey = $apiKeyInput.Trim()
                     Write-Host "API Key de Shodan actualizada." -ForegroundColor Green
                     Guardar-Configuracion
                 } else {
                     Write-Host "API Key de Shodan no modificada." -ForegroundColor Yellow
                 }
            }
            "0" { return }
            default { Write-Warning "Opción inválida." }
        }
    } while ($true)
}


# --- Menú Principal ---
<#
.SYNOPSIS
Muestra el menú principal de la herramienta de seguridad.

.DESCRIPTION
Presenta las opciones principales al usuario para navegar entre las funcionalidades
de Análisis de Archivos y Análisis de Red. También incluye opciones para ver la
ayuda del script y salir.

.NOTES
Este es el punto de entrada principal de la interfaz interactiva del script.
Llama a los submenús correspondientes según la opción seleccionada.
La opción 3 guía al usuario sobre cómo usar Get-Help fuera del menú interactivo.
#>
do {
    Write-Host "`n================ MENÚ PRINCIPAL ================" -ForegroundColor Cyan
    Write-Host "1. Análisis de Archivos Locales"
    Write-Host "2. Análisis de Red (Local y Remoto)"
    Write-Host "3. Ayuda (Usando Get-Help)"
    Write-Host "4. Ayuda (Información rápida en menú)"
    Write-Host "5. Salir"
    Write-Host "================================================" -ForegroundColor Cyan
    $opcion = Read-Host "Elige una opción (1, 2, 3, 4, 5)"
    switch ($opcion) {
        "1" { Mostrar-Submenu1 }
        "2" { Mostrar-Submenu2 }
        "3" {
            Write-Host "`n--- Ayuda con Get-Help ---" -ForegroundColor Green
            Write-Host "Para obtener ayuda detallada sobre este script o sus funciones:"
            Write-Host "1. Sal del menú interactivo (presiona 5)."
            Write-Host "2. Abre una nueva ventana de PowerShell o usa la actual después de salir."
            Write-Host "3. Ejecuta el siguiente comando, reemplazando '.\script definitivo.ps1' con la ruta y nombre de tu script:"
            Write-Host "   Get-Help .\\script definitivo.ps1 -Full" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "También puedes obtener ayuda de funciones específicas (si el script no está corriendo):"
            Write-Host "   Get-Help Escanear-ArchivosSospechosos" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Presiona Enter para volver al menú principal."
            Read-Host | Out-Null
        }
        "4" {
            Write-Host "`n--- AYUDA DEL SISTEMA (Información rápida) ---" -ForegroundColor Green
            Write-Host "Para ayuda completa, usa la opción '3. Ayuda (Usando Get-Help)' y sigue las instrucciones."
            Write-Host "---------------------------------------------" -ForegroundColor Green
            Write-Host "1. Análisis de Archivos Locales:"
            Write-Host "   1.1 Escanear Archivos Sospechosos: Busca archivos según criterios configurados (el listado se ve con 1.3)."
            Write-Host "   1.2 Configurar: Ajusta criterios (extensión, ubicación, tamaño), ruta y API Key de VirusTotal."
            Write-Host "   1.3 Ver Lista de Archivos Sospechosos: Muestra los archivos encontrados en el último escaneo (1.1)."
            Write-Host "   1.4 Enviar a VT: Consulta los hashes de la lista de sospechosos (1.3) en VirusTotal (requiere API Key VT)."
            Write-Host "   1.5 Eliminar: Permite borrar archivos de la lista de sospechosos (1.3) (¡con precaución!)."
            Write-Host "   1.6 Listado de Archivos Ocultos: Busca archivos ocultos en una ruta y muestra el listado (también puede guardar)."
            Write-Host "   1.7 Ver Lista de Archivos Ocultos: Muestra los archivos encontrados en el último listado (1.6)."
            Write-Host "2. Análisis de Red (Local y Remoto):"
            Write-Host "   2.1 Escaneo Puertos (Remoto): Intenta conectar a puertos comunes en una IP/host remoto."
            Write-Host "   2.2 Monitor Shodan (Remoto): Consulta info pública de una IP en Shodan (requiere API Key Shodan)."
            Write-Host "   2.3 Configurar Timeout: Ajusta el tiempo de espera para el escaneo de puertos remotos."
            Write-Host "   2.4 Informe Local: Muestra info de seguridad de la máquina actual (políticas, UAC, firewall, puertos locales)."
            Write-Host "   2.5 Configurar API Key Shodan: Establece la clave necesaria para usar la opción 2.2."
            Write-Host "3. Ayuda (Usando Get-Help): Muestra instrucciones sobre cómo usar Get-Help."
            Write-Host "4. Ayuda (Información rápida): Muestra esta explicación dentro del menú."
            Write-Host "5. Salir: Cierra la herramienta."
            Write-Host "--------------------------" -ForegroundColor Green
        }
        "5" { Write-Host "Saliendo del programa..." -ForegroundColor Green }
        default { Write-Warning "Opción inválida. Intenta de nuevo (1, 2, 3, 4, 5)." }
    }
} while ($opcion -ne "5")

Write-Host "Script finalizado."
