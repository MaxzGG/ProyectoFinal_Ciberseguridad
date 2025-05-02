Set-StrictMode -Version Latest

function Get-HiddenFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "HiddenFilesReport.txt"
    )

    if (-Not (Test-Path $Path)) {
        Write-Error "La ruta especificada no existe."
        return
    }

    $files = Get-ChildItem -Path $Path -Force -File | Where-Object { $_.Attributes -match "Hidden" }

    if ($files.Count -eq 0) {
        Write-Output "No se encontraron archivos ocultos."
    } else {
        try {
            $lines = @()
            $lines += "FullName`tName`tLength (bytes)`tLastWriteTime"
            foreach ($file in $files) {
                $lines += "$($file.FullName)`t$($file.Name)`t$($file.Length)`t$($file.LastWriteTime)"
            }
            $lines | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Output "Reporte generado en: $OutputPath"
        } catch {
            Write-Error "No se pudo generar el reporte: $_"
        }
    }
}
