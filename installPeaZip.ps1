
$temp = Get-ChildItem -Path Env:\TEMP

cd $temp.Value

$installexe = "peazip-8.8.0.WIN64.exe"
$serverip = Get-ItemPropertyValue -Path HKCU:\Software\TKCS -Name server
$url = "http://"+$serverip+":3000/download"


$jsonBase = @{}
$list = New-Object System.Collections.ArrayList
$hdr_list = New-Object System.Collections.ArrayList
$hdr_list.Add(@{"file2download"="$installexe"})

$jsonBase.Add("Header",$hdr_list)
$json = $jsonBase | ConvertTo-Json -Depth 10

$dest = $temp.Value + "\peazip-8.8.0.WIN64.exe"
Invoke-WebRequest -Method 'Post' -Uri $url -OutFile $dest -UseBasicParsing -Body ($json) -ContentType "application/json"

$msiBatch = @"
@echo off

::Launch our installer
start /w "" "%TEMP%\peazip-8.8.0.WIN64.exe"


"@

$installPath = $temp.Value + "\msiInstaller.bat"
$msiBatch | Out-File -Encoding Ascii -FilePath $installPath
$FullFilePath = $installPath

powershell "start-process powershell $FullFilePath -verb runas"
