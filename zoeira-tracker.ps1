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
#   9  = Tela de atualizacao falsa       [fecha em $DUR s ou digitando: sair]
#   10 = Tela de "Reiniciando" falsa      [fecha em $DUR s ou digitando: sair]
#   R  = RESTAURAR (mouse normal + velocidade + wallpaper original)
# ==========================================================

param(
    [string]$OPCAO = "1",
    [string]$LINK  = "https://cdn.jornaldebrasilia.com.br/wp-content/uploads/2024/10/02161149/gretchen7.jpeg",
    [string]$FRASE = "Ola humano. Seu chefe acabou de ver sua tela. Brincadeira... ou nao.",
    [string]$MSG   = "Atualizacao critica: instalando pastel.exe (99%). Nao desligue o computador.",
    [int]$DUR      = 60
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

# tela falsa (atualizando/reiniciando): grava o script que desenha a tela (roda na sessao do usuario)
if ("$OPCAO" -eq "9" -or "$OPCAO" -eq "10") {
@'
param([int]$DUR = 60, [string]$MODO = 'update')
if ($DUR -lt 5)   { $DUR = 60 }
if ($DUR -gt 600) { $DUR = 600 }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$azul   = [System.Drawing.Color]::FromArgb(0,103,192)
$forms  = New-Object System.Collections.ArrayList
$labels = New-Object System.Collections.ArrayList
$spins  = New-Object System.Collections.ArrayList
$script:fase = 0
$script:buf  = ''
$script:prim = $null

# saida secreta: digitar  sair
$teclar = {
    param($s,$e)
    $script:buf = ($script:buf + $e.KeyChar).ToLower()
    if ($script:buf.Length -gt 12) { $script:buf = $script:buf.Substring($script:buf.Length - 12) }
    if ($script:buf.EndsWith('sair')) { [System.Windows.Forms.Application]::Exit() }
}
# bloqueia fechar pela pessoa (Alt+F4 etc); so o timeout ou "sair" fecham
$travar = {
    param($s,$e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) { $e.Cancel = $true }
}

foreach ($scr in [System.Windows.Forms.Screen]::AllScreens) {
    $f = New-Object System.Windows.Forms.Form
    $f.FormBorderStyle = 'None'
    $f.StartPosition   = 'Manual'
    $f.Bounds          = $scr.Bounds
    $f.TopMost         = $true
    $f.ShowInTaskbar   = $false
    $f.KeyPreview      = $true
    $f.Add_KeyPress($teclar)
    $f.Add_FormClosing($travar)

    if ($scr.Primary) {
        $script:prim = $f
        $f.BackColor = $azul
        $f.Cursor    = [System.Windows.Forms.Cursors]::WaitCursor
        $w = $scr.Bounds.Width
        $h = $scr.Bounds.Height

        $spin = New-Object System.Windows.Forms.Panel
        $spin.Size      = New-Object System.Drawing.Size(60,60)
        $spin.Location  = New-Object System.Drawing.Point([int]($w/2 - 30), [int]($h/2 - 120))
        $spin.BackColor = [System.Drawing.Color]::Transparent
        $spin.Add_Paint({
            param($s,$e)
            $g = $e.Graphics
            $g.SmoothingMode = 'AntiAlias'
            $n = 6; $raio = 18
            for ($i = 0; $i -lt $n; $i++) {
                $ang = [Math]::PI * 2 * $i / $n - [Math]::PI / 2
                $x = 30 + $raio * [Math]::Cos($ang) - 3.5
                $y = 30 + $raio * [Math]::Sin($ang) - 3.5
                $d = ($i - $script:fase) % $n; if ($d -lt 0) { $d += $n }
                $alpha = [int](30 + 225 * (($n - $d) / $n))
                $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha,255,255,255))
                $g.FillEllipse($br, $x, $y, 7, 7)
                $br.Dispose()
            }
        })
        $f.Controls.Add($spin)
        [void]$spins.Add($spin)

        $fonteG = New-Object System.Drawing.Font('Segoe UI Light', 21)
        $fonteP = New-Object System.Drawing.Font('Segoe UI Light', 12)

        $lb = New-Object System.Windows.Forms.Label
        $lb.AutoSize  = $false
        $lb.Size      = New-Object System.Drawing.Size($w, 90)
        $lb.Location  = New-Object System.Drawing.Point(0, [int]($h/2 - 35))
        $lb.ForeColor = [System.Drawing.Color]::White
        $lb.TextAlign = 'TopCenter'
        $lb.BackColor = [System.Drawing.Color]::Transparent
        $lb.Font      = $fonteG
        if ($MODO -eq 'restart') { $lb.Text = "Reiniciando" } else { $lb.Text = "Trabalhando nas atualizações`r`n0% concluído" }
        $f.Controls.Add($lb)
        [void]$labels.Add($lb)

        if ($MODO -ne 'restart') {
            $l2 = New-Object System.Windows.Forms.Label
            $l2.AutoSize  = $false
            $l2.Size      = New-Object System.Drawing.Size($w, 30)
            $l2.Location  = New-Object System.Drawing.Point(0, [int]($h/2 + 55))
            $l2.ForeColor = [System.Drawing.Color]::White
            $l2.TextAlign = 'TopCenter'
            $l2.BackColor = [System.Drawing.Color]::Transparent
            $l2.Font      = $fonteP
            $l2.Text      = "Não desligue o computador"
            $f.Controls.Add($l2)
        }
    } else {
        $f.BackColor = [System.Drawing.Color]::Black
    }
    [void]$forms.Add($f)
}

$script:pct  = 0
$script:tick = 0
$script:ini  = Get-Date
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 90
$timer.Add_Tick({
    $script:fase = ($script:fase + 1) % 6
    foreach ($sp in $spins) { $sp.Invalidate() }
    $script:tick++
    if ($MODO -eq 'update' -and $script:tick % 16 -eq 0) {
        $script:pct = [Math]::Min(99, $script:pct + (Get-Random -Minimum 1 -Maximum 4))
        foreach ($l in $labels) { $l.Text = "Trabalhando nas atualizações`r`n$($script:pct)% concluído" }
    }
    if (((Get-Date) - $script:ini).TotalSeconds -ge $DUR) { [System.Windows.Forms.Application]::Exit() }
})
foreach ($f in $forms) { $f.Show() }
if ($script:prim) { $script:prim.Activate() }
$timer.Start()
[System.Windows.Forms.Application]::Run()
foreach ($f in $forms) { try { $f.Dispose() } catch {} }
'@ | Set-Content "$BasePath\fakeupdate.ps1" -Encoding UTF8
    Log "fakeupdate.ps1 gravado."
}

# ---------------------------------------------------------- corpo que roda NA SESSAO DO USUARIO
$apiWall = @'
Add-Type @"
using System;using System.Runtime.InteropServices;
public class NW{[DllImport("user32.dll",CharSet=CharSet.Auto,SetLastError=true)]public static extern bool SystemParametersInfo(int a,int b,string c,int d);}
"@
'@

switch ("$OPCAO".ToUpper()) {
    "DIAG" { $body = @'
$n = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$sid = (Get-Process -Id $PID).SessionId
Set-Content 'C:\ProgramData\Getel\proof.txt' ("rodou como: $n | sessao: $sid | $(Get-Date -Format 'HH:mm:ss')")
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('ZOEIRA TESTE - se vc ve isto a sessao esta certa','Teste') | Out-Null
'@ }

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

    "9" { $body = @"
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File','C:\ProgramData\Getel\fakeupdate.ps1','-DUR','$DUR','-MODO','update'
"@ }

    "10" { $body = @"
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File','C:\ProgramData\Getel\fakeupdate.ps1','-DUR','$DUR','-MODO','restart'
"@ }

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
if ("$OPCAO".ToUpper() -eq "DIAG") { Remove-Item "$BasePath\proof.txt" -ErrorAction SilentlyContinue }

# ---------------------------------------------------------- metodo 1: lancar direto na sessao ativa (robusto: Azure AD, RDP, etc.)
$UserCmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $UserScript + '"'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public class SessLaunch {
    [StructLayout(LayoutKind.Sequential)] public struct STARTUPINFO { public int cb; public string lpReserved; public string lpDesktop; public string lpTitle; public int dwX; public int dwY; public int dwXSize; public int dwYSize; public int dwXCountChars; public int dwYCountChars; public int dwFillAttribute; public int dwFlags; public short wShowWindow; public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError; }
    [StructLayout(LayoutKind.Sequential)] public struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }
    [StructLayout(LayoutKind.Sequential)] public struct WTS_SESSION_INFO { public int SessionID; public IntPtr pWinStationName; public int State; }
    public enum SEC_IMP { Anonymous, Identification, Impersonation, Delegation }
    public enum TOK_TYPE { Primary = 1, Impersonation }
    [DllImport("wtsapi32.dll", SetLastError=true)] public static extern int WTSEnumerateSessions(IntPtr h, int r, int v, ref IntPtr ppSI, ref int pC);
    [DllImport("wtsapi32.dll")] public static extern void WTSFreeMemory(IntPtr p);
    [DllImport("wtsapi32.dll", SetLastError=true)] public static extern bool WTSQueryUserToken(int sid, out IntPtr tok);
    [DllImport("wtsapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool WTSQuerySessionInformation(IntPtr h, int sid, int infoClass, out IntPtr ppBuffer, out int bytes);
    [DllImport("advapi32.dll", SetLastError=true)] public static extern bool DuplicateTokenEx(IntPtr t, uint a, IntPtr sa, SEC_IMP il, TOK_TYPE tt, out IntPtr nt);
    [DllImport("userenv.dll", SetLastError=true)] public static extern bool CreateEnvironmentBlock(out IntPtr env, IntPtr tok, bool inh);
    [DllImport("userenv.dll", SetLastError=true)] public static extern bool DestroyEnvironmentBlock(IntPtr env);
    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern bool CreateProcessAsUser(IntPtr tok, string app, string cmd, IntPtr pa, IntPtr ta, bool inh, uint flags, IntPtr env, string dir, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern bool CloseHandle(IntPtr h);
    public static int Launch(string cmdLine, int preferred) {
        System.Collections.Generic.List<int> cand = new System.Collections.Generic.List<int>();
        if (preferred > 0) cand.Add(preferred);
        IntPtr pSI = IntPtr.Zero; int cnt = 0;
        if (WTSEnumerateSessions(IntPtr.Zero, 0, 1, ref pSI, ref cnt) != 0) {
            int sz = Marshal.SizeOf(typeof(WTS_SESSION_INFO)); IntPtr cur = pSI;
            for (int i = 0; i < cnt; i++) {
                WTS_SESSION_INFO s = (WTS_SESSION_INFO)Marshal.PtrToStructure(cur, typeof(WTS_SESSION_INFO));
                if (s.State == 0 && s.SessionID != 0 && !cand.Contains(s.SessionID)) cand.Add(s.SessionID);
                cur = (IntPtr)((long)cur + sz);
            }
            WTSFreeMemory(pSI);
        }
        IntPtr tok = IntPtr.Zero; int used = -1;
        foreach (int sid in cand) { if (WTSQueryUserToken(sid, out tok)) { used = sid; break; } }
        if (used < 0) return -2;
        IntPtr dup; if (!DuplicateTokenEx(tok, 0xF01FF, IntPtr.Zero, SEC_IMP.Impersonation, TOK_TYPE.Primary, out dup)) { CloseHandle(tok); return -3; }
        IntPtr env = IntPtr.Zero; CreateEnvironmentBlock(out env, dup, false);
        STARTUPINFO si = new STARTUPINFO(); si.cb = Marshal.SizeOf(si); si.lpDesktop = "winsta0\\default";
        PROCESS_INFORMATION pi;
        bool ok = CreateProcessAsUser(dup, null, cmdLine, IntPtr.Zero, IntPtr.Zero, false, 0x00000400 | 0x08000000, env, null, ref si, out pi);
        int rc = ok ? pi.dwProcessId : -4;
        if (env != IntPtr.Zero) DestroyEnvironmentBlock(env);
        CloseHandle(tok); CloseHandle(dup);
        if (ok) { CloseHandle(pi.hProcess); CloseHandle(pi.hThread); }
        return rc;
    }
    public static string Sessions() {
        StringBuilder sb = new StringBuilder();
        IntPtr pSI = IntPtr.Zero; int cnt = 0;
        if (WTSEnumerateSessions(IntPtr.Zero, 0, 1, ref pSI, ref cnt) != 0) {
            int sz = Marshal.SizeOf(typeof(WTS_SESSION_INFO)); IntPtr cur = pSI;
            for (int i = 0; i < cnt; i++) {
                WTS_SESSION_INFO s = (WTS_SESSION_INFO)Marshal.PtrToStructure(cur, typeof(WTS_SESSION_INFO));
                string user = ""; string dom = ""; IntPtr pb; int bytes;
                if (WTSQuerySessionInformation(IntPtr.Zero, s.SessionID, 5, out pb, out bytes)) { user = Marshal.PtrToStringUni(pb); WTSFreeMemory(pb); }
                if (WTSQuerySessionInformation(IntPtr.Zero, s.SessionID, 7, out pb, out bytes)) { dom = Marshal.PtrToStringUni(pb); WTSFreeMemory(pb); }
                sb.AppendLine("  sess=" + s.SessionID + " state=" + s.State + " user=" + dom + "\\" + user);
                cur = (IntPtr)((long)cur + sz);
            }
            WTSFreeMemory(pSI);
        }
        return sb.ToString().TrimEnd();
    }
}
'@

$launchPid = -999
try { $launchPid = [SessLaunch]::Launch($UserCmd, [int]$Explorer.SessionId) } catch { Log "Launch nativo erro: $($_.Exception.Message)" }
Log "Sessao explorer=$($Explorer.SessionId) | Launch => $launchPid"

if ("$OPCAO".ToUpper() -eq "DIAG") {
    Log "WHOAMI (quem roda) = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    Log "--- SESSOES (state: 0=Ativa 4=Desconectada) ---"
    try { Log ([SessLaunch]::Sessions()) } catch { Log "Sessions() erro: $($_.Exception.Message)" }
    foreach ($e in (Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue)) { Log ("  explorer sess=$($e.SessionId) user=$($e.UserName)") }
    Start-Sleep -Seconds 3
    if (Test-Path "$BasePath\proof.txt") { Log ("PROOF: " + (Get-Content "$BasePath\proof.txt" -Raw).Trim()) } else { Log "PROOF: vazio (o processo-prova NAO rodou como o usuario)" }
    Log "--- fim diag ---"
}

# ---------------------------------------------------------- metodo 2 (fallback): tarefa agendada
if ($launchPid -le 0) {
$TaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Zoeira Getel</Description></RegistrationInfo>
  <Triggers />
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
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
}

Write-Host "Zoeira '$OPCAO' disparada (pid=$launchPid) para $LoggedUser"
Write-Host "Log: $LogPath"
