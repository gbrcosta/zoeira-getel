<#
  ZOEIRA.PS1 - pegadinhas inofensivas e 100% reversíveis para o Windows.

  Uso:
    powershell -ExecutionPolicy Bypass -File .\zoeira.ps1            # menu
    powershell -ExecutionPolicy Bypass -File .\zoeira.ps1 -Tudo      # dispara tudo
    powershell -ExecutionPolicy Bypass -File .\zoeira.ps1 -Desfazer  # volta tudo ao normal

  Opções extras:
    -Mensagem "TEXTO"       texto do papel de parede / popup
    -Imagem "C:\foto.jpg"   usa uma imagem sua como papel de parede

  Antes de mexer em qualquer coisa, o script guarda o estado original em
  %TEMP%\zoeira-backup.json. Botões e velocidade do mouse também voltam
  sozinhos se a máquina reiniciar.
#>
param(
    [switch]$Tudo,
    [switch]$Desfazer,
    [string]$Mensagem = "VOCÊ FOI ZOADO 🤡",
    [string]$Imagem
)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Zoeira {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, string pvParam, int fWinIni);
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref int pvParam, int fWinIni);
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, IntPtr pvParam, int fWinIni);
    [DllImport("user32.dll")]
    public static extern bool SwapMouseButton(bool fSwap);
    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);
}
"@

$SPI_SETDESKWALLPAPER = 20
$SPI_GETMOUSESPEED    = 112
$SPI_SETMOUSESPEED    = 113
$SPIF_UPDATEINIFILE   = 1
$SPIF_SENDCHANGE      = 2
$SM_SWAPBUTTON        = 23

$BackupPath = Join-Path $env:TEMP 'zoeira-backup.json'

# ---------------------------------------------------------------- backup

function Get-Backup {
    if (Test-Path $BackupPath) { return Get-Content $BackupPath -Raw | ConvertFrom-Json }
    return $null
}

function Save-Backup {
    if (Test-Path $BackupPath) { return }   # nunca sobrescreve o estado original
    $speed = 0
    [Zoeira]::SystemParametersInfo($SPI_GETMOUSESPEED, 0, [ref]$speed, 0) | Out-Null
    $estado = [ordered]@{
        Wallpaper    = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper
        MouseSpeed   = $speed
        BotoesTrocados = ([Zoeira]::GetSystemMetrics($SM_SWAPBUTTON) -ne 0)
    }
    $estado | ConvertTo-Json | Set-Content $BackupPath -Encoding UTF8
    Write-Host "💾 Estado original salvo em $BackupPath" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- pegadinhas

function Set-WallpaperZoeira {
    if ($Imagem -and (Test-Path $Imagem)) {
        $arquivo = (Resolve-Path $Imagem).Path
    } else {
        $tela = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bmp  = New-Object System.Drawing.Bitmap $tela.Width, $tela.Height
        $g    = [System.Drawing.Graphics]::FromImage($bmp)
        $g.TextRenderingHint = 'AntiAlias'
        $g.Clear([System.Drawing.Color]::FromArgb(255, 20, 147))

        $rnd = New-Object System.Random
        $emojis = '🤡','😂','🐔','🦆','💩','🍌','🙃'
        $fontePeq = New-Object System.Drawing.Font 'Segoe UI Emoji', 48
        for ($i = 0; $i -lt 60; $i++) {
            $g.DrawString($emojis[$rnd.Next($emojis.Count)], $fontePeq, [System.Drawing.Brushes]::White,
                $rnd.Next($tela.Width), $rnd.Next($tela.Height))
        }

        $fonte = New-Object System.Drawing.Font 'Segoe UI Emoji', ([int]($tela.Width / 22)), ([System.Drawing.FontStyle]::Bold)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
        $rect = New-Object System.Drawing.RectangleF 0, 0, $tela.Width, $tela.Height
        $sombra = New-Object System.Drawing.RectangleF 6, 6, $tela.Width, $tela.Height
        $g.DrawString($Mensagem, $fonte, [System.Drawing.Brushes]::Black, $sombra, $fmt)
        $g.DrawString($Mensagem, $fonte, [System.Drawing.Brushes]::Yellow, $rect, $fmt)

        $arquivo = Join-Path $env:TEMP 'zoeira-wallpaper.bmp'
        $bmp.Save($arquivo, [System.Drawing.Imaging.ImageFormat]::Bmp)
        $g.Dispose(); $bmp.Dispose()
    }
    [Zoeira]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $arquivo, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
    Write-Host "🖼️  Papel de parede trocado" -ForegroundColor Magenta
}

function Invoke-InverterMouse {
    # Só na sessão atual (sem gravar no registro): reiniciar também desfaz.
    $atual = [Zoeira]::GetSystemMetrics($SM_SWAPBUTTON) -ne 0
    [Zoeira]::SwapMouseButton(-not $atual) | Out-Null
    Write-Host "🖱️  Botões do mouse invertidos" -ForegroundColor Magenta
}

function Invoke-MouseFoguete {
    [Zoeira]::SystemParametersInfo($SPI_SETMOUSESPEED, 0, [IntPtr]20, $SPIF_SENDCHANGE) | Out-Null
    Write-Host "🚀 Mouse em velocidade máxima" -ForegroundColor Magenta
}

function Invoke-MouseLesma {
    [Zoeira]::SystemParametersInfo($SPI_SETMOUSESPEED, 0, [IntPtr]1, $SPIF_SENDCHANGE) | Out-Null
    Write-Host "🐌 Mouse em câmera lenta" -ForegroundColor Magenta
}

function Invoke-MouseBebado([int]$Segundos = 15) {
    Write-Host "🍺 Mouse bêbado por $Segundos s..." -ForegroundColor Magenta
    $rnd = New-Object System.Random
    $fim = (Get-Date).AddSeconds($Segundos)
    while ((Get-Date) -lt $fim) {
        $p = [System.Windows.Forms.Cursor]::Position
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point ($p.X + $rnd.Next(-25, 26)), ($p.Y + $rnd.Next(-25, 26))
        Start-Sleep -Milliseconds 120
    }
}

function Invoke-Falar {
    Add-Type -AssemblyName System.Speech
    $voz = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $pt = $voz.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -eq 'pt-BR' } | Select-Object -First 1
    if ($pt) { $voz.SelectVoice($pt.VoiceInfo.Name) }
    $frases = @(
        "Atenção. Este computador detectou excesso de preguiça.",
        "Olá humano. Eu estou te observando.",
        "Seu chefe acabou de ver sua tela.",
        "Erro quarenta e dois. Café insuficiente no sistema.",
        "Parabéns, você ganhou um pastel. Retire na copa."
    )
    $frase = $frases | Get-Random
    Write-Host "🗣️  Falando: $frase" -ForegroundColor Magenta
    $voz.Speak($frase)
    $voz.Dispose()
}

function Invoke-Musiquinha {
    Write-Host "🎵 Tocando musiquinha" -ForegroundColor Magenta
    $notas = @(
        @(523,150),@(523,150),@(587,300),@(523,300),@(698,300),@(659,600),
        @(523,150),@(523,150),@(587,300),@(523,300),@(784,300),@(698,600)
    )
    foreach ($n in $notas) { [Console]::Beep($n[0], $n[1]) }
}

function Invoke-PopupFalso {
    $msgs = @(
        @("Windows detectou que você está trabalhando demais.`nDeseja tirar uma soneca?", "Windows Bem-Estar"),
        @("Seu mouse está cansado e pediu férias.`nOs botões foram trocados como protesto.", "Sindicato dos Periféricos"),
        @("Atualização crítica: instalando pastel.exe (99%)", "Windows Update")
    )
    $m = $msgs | Get-Random
    [System.Windows.Forms.MessageBox]::Show($m[0], $m[1], 'OK', 'Information') | Out-Null
}

function Invoke-CapsLockMaluco([int]$Vezes = 7) {
    Write-Host "🔠 Caps Lock piscando" -ForegroundColor Magenta
    $sh = New-Object -ComObject WScript.Shell
    for ($i = 0; $i -lt $Vezes * 2; $i++) { $sh.SendKeys('{CAPSLOCK}'); Start-Sleep -Milliseconds 250 }
}

function Invoke-NotepadFantasma {
    Write-Host "👻 Notepad fantasma digitando" -ForegroundColor Magenta
    $proc = Start-Process notepad -PassThru
    Start-Sleep -Seconds 1
    $sh = New-Object -ComObject WScript.Shell
    $sh.AppActivate($proc.Id) | Out-Null
    Start-Sleep -Milliseconds 400
    foreach ($c in "Ola... eu sou o fantasma do computador. Nao olhe para tras. Brincadeira, so foi zoeira :)".ToCharArray()) {
        $sh.SendKeys([string]$c -replace '([+^%~(){}\[\]])', '{$1}')
        Start-Sleep -Milliseconds (Get-Random -Minimum 40 -Maximum 160)
    }
}

# ---------------------------------------------------------------- desfazer

function Invoke-Desfazer {
    $b = Get-Backup
    if (-not $b) {
        Write-Host "Nenhum backup encontrado. Restaurando só o padrão do mouse." -ForegroundColor Yellow
        [Zoeira]::SwapMouseButton($false) | Out-Null
        [Zoeira]::SystemParametersInfo($SPI_SETMOUSESPEED, 0, [IntPtr]10, $SPIF_SENDCHANGE) | Out-Null
        return
    }
    [Zoeira]::SwapMouseButton([bool]$b.BotoesTrocados) | Out-Null
    [Zoeira]::SystemParametersInfo($SPI_SETMOUSESPEED, 0, [IntPtr][int]$b.MouseSpeed, $SPIF_SENDCHANGE) | Out-Null
    [Zoeira]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, [string]$b.Wallpaper, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
    Remove-Item $BackupPath -Force
    Remove-Item (Join-Path $env:TEMP 'zoeira-wallpaper.bmp') -ErrorAction SilentlyContinue
    Write-Host "✅ Tudo de volta ao normal. Ninguém se machucou." -ForegroundColor Green
}

# ---------------------------------------------------------------- execução

if ($Desfazer) { Invoke-Desfazer; return }

Save-Backup

if ($Tudo) {
    Set-WallpaperZoeira
    Invoke-InverterMouse
    Invoke-MouseFoguete
    Invoke-Musiquinha
    Invoke-Falar
    Invoke-CapsLockMaluco
    Invoke-MouseBebado 10
    Invoke-PopupFalso
    Write-Host "`nPara desfazer: .\zoeira.ps1 -Desfazer" -ForegroundColor Cyan
    return
}

$menu = [ordered]@{
    '1' = @('Trocar papel de parede',      { Set-WallpaperZoeira })
    '2' = @('Inverter botões do mouse',    { Invoke-InverterMouse })
    '3' = @('Mouse foguete (rápido)',      { Invoke-MouseFoguete })
    '4' = @('Mouse lesma (lento)',         { Invoke-MouseLesma })
    '5' = @('Mouse bêbado (15 s)',         { Invoke-MouseBebado 15 })
    '6' = @('PC fala uma frase',           { Invoke-Falar })
    '7' = @('Musiquinha de beep',          { Invoke-Musiquinha })
    '8' = @('Popup falso do Windows',      { Invoke-PopupFalso })
    '9' = @('Caps Lock piscando',          { Invoke-CapsLockMaluco })
    '10'= @('Notepad fantasma',            { Invoke-NotepadFantasma })
    'D' = @('DESFAZER TUDO',               { Invoke-Desfazer })
}

while ($true) {
    Write-Host "`n===== 🤡 ZOEIRA 🤡 =====" -ForegroundColor Yellow
    foreach ($k in $menu.Keys) { Write-Host (" {0,2}) {1}" -f $k, $menu[$k][0]) }
    Write-Host "  0) Sair"
    $op = (Read-Host "Escolha").ToUpper()
    if ($op -eq '0') { break }
    if ($menu.Contains($op)) { & $menu[$op][1] } else { Write-Host "Opção inválida" -ForegroundColor Red }
}
