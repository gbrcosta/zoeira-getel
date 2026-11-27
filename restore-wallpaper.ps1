# ==========================================================
# DESFAZER WALLPAPER - restaura o papel de parede
# Executar como SYSTEM pelo Tracker (igual ao deploy do wallpaper)
#
# Se o deploy tiver salvo o original em C:\ProgramData\Getel\wallpaper-original.txt
# volta exatamente o que a pessoa tinha. Senao, cai no padrao do Windows (img0.jpg).
# ==========================================================

$BasePath   = "C:\ProgramData\Getel"
$UserScript = "$BasePath\Restore-Wallpaper-User.ps1"
$TaskName   = "GetelWallpaperRestore"

New-Item -Path $BasePath -ItemType Directory -Force | Out-Null

$Explorer = Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue |
    Where-Object { $_.UserName -and $_.SessionId -ne 0 } |
    Select-Object -First 1
if (-not $Explorer) { exit 1 }
$LoggedUser = $Explorer.UserName

$UserScriptContent = @'
$ErrorActionPreference = "Continue"
$BasePath = "C:\ProgramData\Getel"
$backup   = "$BasePath\wallpaper-original.txt"

if (Test-Path $backup) {
    $alvo = (Get-Content $backup -Raw).Trim()
} else {
    $alvo = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
}
if (-not (Test-Path $alvo)) { $alvo = "" }   # vazio = fundo liso

Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $alvo

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NW {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool SystemParametersInfo(int a,int b,string c,int d);
}
"@
[NW]::SystemParametersInfo(20, 0, $alvo, (0x01 -bor 0x02)) | Out-Null
Start-Process rundll32.exe "user32.dll,UpdatePerUserSystemParameters" -WindowStyle Hidden
'@

$UserScriptContent | Set-Content -Path $UserScript -Encoding UTF8

$TaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Restaura wallpaper Getel</Description></RegistrationInfo>
  <Triggers />
  <Principals>
    <Principal id="Author">
      <UserId>$LoggedUser</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "$UserScript"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -Xml $TaskXml -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 5
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Restore disparado para: $LoggedUser"
