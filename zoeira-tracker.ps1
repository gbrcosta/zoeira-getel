# ==========================================================
#  ZOEIRA GETEL - comando unico para o Tracker (roda como SYSTEM)
#
#  COMO USAR:
#   1) Troque $OPCAO abaixo pela pegadinha que quer.
#   2) Se for WALLPAPER (1), cole o link da imagem em $LINK.
#   3) Cole TUDO isso como comando personalizado no Tracker e envie.
#
#  OPCOES:
#   1 = Trocar wallpaper (usa $LINK)     [reversivel: R]
#   2 = Inverter botoes do mouse         [reversivel: R]
#   3 = PC fala uma frase                [sem persistencia]
#   4 = Popup falso do Windows           [sem persistencia]
#   5 = Caps Lock piscando               [sem persistencia]
#   6 = Mouse foguete (rapido)           [reversivel: R]
#   7 = Mouse lesma (lento)              [reversivel: R]
#   8 = Mouse bebado (treme 15s)         [sem persistencia]
#   R = RESTAURAR (mouse normal + velocidade + wallpaper original)
# ==========================================================

param(
    [string]$OPCAO = "1",
    [string]$LINK  = "https://cdn.jornaldebrasilia.com.br/wp-content/uploads/2024/10/02161149/gretchen7.jpeg",
    [string]$FRASE = "Ola humano. Seu chefe acabou de ver sua tela. Brincadeira... ou nao.",
    [string]$MSG   = "Atualizacao critica: instalando pastel.exe (99%). Nao desligue o computador."
)

# ---------------------------------------------------------- infra
$BasePath   = "C:\ProgramData\Getel"
$WallPath   = "$BasePath\wallpaper.jpg"
$UserScript = "$BasePath\zoeira-user.ps1"
$LogPath    = "$BasePath\zoeira.log"
$TaskName   = "GetelZoeira"
New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
function Log($m) { "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m | Out-File $LogPath -Append }

# ---------------------------------------------------------- usuario logado
$Explorer = Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue |
    Where-Object { $_.UserName -and $_.SessionId -ne 0 } | Select-Object -First 1
if (-not $Explorer) { Log "Nenhum usuario interativo."; Write-Host "Sem usuario logado."; exit 1 }
$LoggedUser = $Explorer.UserName
Log "Opcao=$OPCAO  Usuario=$LoggedUser"

# ---------------------------------------------------------- download (so wallpaper)
if ($OPCAO -eq "1") {
    try {
        $ProgressPreference = 'SilentlyContinue'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $LINK -OutFile $WallPath -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
        $tam = (Get-Item $WallPath).Length
        if ($tam -lt 2048) { throw "arquivo muito pequeno ($tam bytes) - o link provavelmente nao e uma imagem direta" }
        Log "Imagem baixada ($tam bytes)."
    } catch { Log "Erro download: $($_.Exception.Message)"; Write-Host "Falha ao baixar a imagem: $($_.Exception.Message)"; exit 1 }
}

# ---------------------------------------------------------- corpo que roda NA SESSAO DO USUARIO
$apiWall = @'
Add-Type @"
using System;using System.Runtime.InteropServices;
public class NW{[DllImport("user32.dll",CharSet=CharSet.Auto,SetLastError=true)]public static extern bool SystemParametersInfo(int a,int b,string c,int d);}
"@
'@

switch ("$OPCAO".ToUpper()) {
    "1" { $body = $apiWall + @'

(Get-ItemProperty 'HKCU:\Control Panel\Desktop').Wallpaper | Set-Content 'C:\ProgramData\Getel\wallpaper-original.txt'
$wp = 'C:\ProgramData\Getel\wallpaper.jpg'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper      -Value $wp
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper  -Value '0'
[NW]::SystemParametersInfo(20,0,$wp,(0x01 -bor 0x02)) | Out-Null
Start-Process rundll32.exe 'user32.dll,UpdatePerUserSystemParameters' -WindowStyle Hidden
'@ }

    "2" { $body = @'
Add-Type -Name U -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SwapMouseButton(bool f);'
[W.U]::SwapMouseButton($true) | Out-Null
Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name SwapMouseButtons -Value '1'
'@ }

    "3" { $body = @"
Add-Type -AssemblyName System.Speech
`$v = New-Object System.Speech.Synthesis.SpeechSynthesizer
`$vozes = `$v.GetInstalledVoices() | Where-Object { `$_.Enabled }
`$pt = `$vozes | Where-Object { `$_.VoiceInfo.Culture.Name -eq 'pt-BR' } | Select-Object -First 1
if (-not `$pt) { `$pt = `$vozes | Where-Object { `$_.VoiceInfo.Culture.TwoLetterISOLanguageName -eq 'pt' } | Select-Object -First 1 }
if (`$pt) { `$v.SelectVoice(`$pt.VoiceInfo.Name) }
"Voz usada: `$(`$v.Voice.Name) | Disponiveis: `$((`$vozes | ForEach-Object { `$_.VoiceInfo.Name + ' (' + `$_.VoiceInfo.Culture.Name + ')' }) -join ', ')" | Out-File 'C:\ProgramData\Getel\fala.log'
`$v.Volume = 100
`$v.Speak('$($FRASE -replace "'", "''")')
"@ }

    "4" { $m = $MSG -replace "'", "''"; $body = @"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('$m','Windows Update','OK','Information') | Out-Null
"@ }

    "5" { $body = @'
$sh = New-Object -ComObject WScript.Shell
1..14 | ForEach-Object { $sh.SendKeys('{CAPSLOCK}'); Start-Sleep -Milliseconds 250 }
'@ }

    "6" { $body = @'
$o = (Get-ItemProperty 'HKCU:\Control Panel\Mouse').MouseSensitivity
if ($o) { $o | Set-Content 'C:\ProgramData\Getel\mousespeed-original.txt' }
Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseSensitivity -Value '20'
Add-Type -Name M -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(int a,int b,System.IntPtr c,int d);'
[W.M]::SystemParametersInfo(113,0,[IntPtr]20,3) | Out-Null
'@ }

    "7" { $body = @'
$o = (Get-ItemProperty 'HKCU:\Control Panel\Mouse').MouseSensitivity
if ($o) { $o | Set-Content 'C:\ProgramData\Getel\mousespeed-original.txt' }
Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseSensitivity -Value '1'
Add-Type -Name M -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(int a,int b,System.IntPtr c,int d);'
[W.M]::SystemParametersInfo(113,0,[IntPtr]1,3) | Out-Null
'@ }

    "8" { $body = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$rnd = New-Object System.Random
$fim = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $fim) {
    $p = [System.Windows.Forms.Cursor]::Position
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point (($p.X + $rnd.Next(-30,31)), ($p.Y + $rnd.Next(-30,31)))
    Start-Sleep -Milliseconds 110
}
'@ }

    "R" { $body = $apiWall + @'

Add-Type -Name U -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SwapMouseButton(bool f);'
[W.U]::SwapMouseButton($false) | Out-Null
Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name SwapMouseButtons -Value '0'
$spd = 'C:\ProgramData\Getel\mousespeed-original.txt'
$sv = if (Test-Path $spd) { (Get-Content $spd -Raw).Trim() } else { '10' }
if (-not ($sv -as [int])) { $sv = '10' }
Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseSensitivity -Value $sv
Add-Type -Name M -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(int a,int b,System.IntPtr c,int d);'
[W.M]::SystemParametersInfo(113,0,[IntPtr][int]$sv,3) | Out-Null
$bk = 'C:\ProgramData\Getel\wallpaper-original.txt'
if (Test-Path $bk) { $alvo = (Get-Content $bk -Raw).Trim() } else { $alvo = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg' }
if (-not (Test-Path $alvo)) { $alvo = '' }
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $alvo
[NW]::SystemParametersInfo(20,0,$alvo,(0x01 -bor 0x02)) | Out-Null
Start-Process rundll32.exe 'user32.dll,UpdatePerUserSystemParameters' -WindowStyle Hidden
'@ }

    default { Log "Opcao invalida: $OPCAO"; Write-Host "Opcao invalida."; exit 1 }
}

$body | Set-Content -Path $UserScript -Encoding UTF8

# ---------------------------------------------------------- tarefa na sessao do usuario
$TaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Zoeira Getel</Description></RegistrationInfo>
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
$wait = if ("$OPCAO".ToUpper() -eq "8") { 20 } else { 8 }
Start-Sleep -Seconds $wait
$info = Get-ScheduledTaskInfo -TaskName $TaskName
Log "LastTaskResult=$($info.LastTaskResult)"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Zoeira '$OPCAO' disparada para $LoggedUser (result=$($info.LastTaskResult))"
Write-Host "Log: $LogPath"
