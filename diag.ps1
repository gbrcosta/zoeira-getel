# diag.ps1 - diagnostico instrumentado da zoeira (saida em texto limpo)
$ErrorActionPreference = 'SilentlyContinue'
function L($m) { [Console]::Out.WriteLine([string]$m) }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Diag {
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
        } else { sb.AppendLine("  WTSEnumerateSessions FALHOU err=" + Marshal.GetLastWin32Error()); }
        return sb.ToString().TrimEnd();
    }

    public static string TryLaunch(int sid, string cmdLine) {
        IntPtr tok;
        if (!WTSQueryUserToken(sid, out tok)) return "QueryUserToken sess " + sid + " FALHOU err=" + Marshal.GetLastWin32Error();
        IntPtr dup;
        if (!DuplicateTokenEx(tok, 0xF01FF, IntPtr.Zero, SEC_IMP.Impersonation, TOK_TYPE.Primary, out dup)) { CloseHandle(tok); return "DuplicateToken FALHOU err=" + Marshal.GetLastWin32Error(); }
        IntPtr env = IntPtr.Zero; CreateEnvironmentBlock(out env, dup, false);
        STARTUPINFO si = new STARTUPINFO(); si.cb = Marshal.SizeOf(si); si.lpDesktop = "winsta0\\default";
        PROCESS_INFORMATION pi;
        bool ok = CreateProcessAsUser(dup, null, cmdLine, IntPtr.Zero, IntPtr.Zero, false, 0x00000400 | 0x08000000, env, null, ref si, out pi);
        int err = Marshal.GetLastWin32Error();
        if (env != IntPtr.Zero) DestroyEnvironmentBlock(env);
        CloseHandle(tok); CloseHandle(dup);
        if (!ok) return "CreateProcessAsUser sess " + sid + " FALHOU err=" + err;
        int p = pi.dwProcessId; CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
        return "CreateProcessAsUser sess " + sid + " OK pid=" + p;
    }
}
'@

L "=============== DIAGNOSTICO ZOEIRA ==============="
L ("WHOAMI (quem roda): " + [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
L ""
L "SESSOES (state: 0=Ativa 4=Desconectada):"
L ([Diag]::Sessions())
L ""
L "EXPLORER.EXE (usuarios logados):"
$exps = Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue
if ($exps) { foreach ($e in $exps) { L ("  sess=" + $e.SessionId + " user=" + $e.UserName) } } else { L "  NENHUM explorer (ninguem logado na area de trabalho)" }

$alvo = ($exps | Where-Object { $_.SessionId -ne 0 } | Select-Object -First 1).SessionId
L ""
L ("SESSAO ALVO (explorer): " + $alvo)

New-Item -ItemType Directory -Force -Path 'C:\ProgramData\Getel' | Out-Null
$proof = @'
$n = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$sid = (Get-Process -Id $PID).SessionId
Set-Content 'C:\ProgramData\Getel\proof.txt' ("rodou como: $n | sessao: $sid | $(Get-Date -Format 'HH:mm:ss')")
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('ZOEIRA TESTE - se voce esta vendo isto, a sessao esta certa!','Teste') | Out-Null
'@
Set-Content 'C:\ProgramData\Getel\proof.ps1' $proof -Encoding UTF8
Remove-Item 'C:\ProgramData\Getel\proof.txt' -ErrorAction SilentlyContinue

if ($alvo -ne $null) {
    $cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\ProgramData\Getel\proof.ps1"'
    L ("LAUNCH: " + [Diag]::TryLaunch([int]$alvo, $cmd))
    Start-Sleep -Seconds 3
    L ""
    if (Test-Path 'C:\ProgramData\Getel\proof.txt') { L ("PROOF.TXT: " + (Get-Content 'C:\ProgramData\Getel\proof.txt' -Raw).Trim()) }
    else { L "PROOF.TXT: (vazio - o processo-prova NAO rodou como o usuario)" }
} else { L "Sem sessao alvo - nao da pra testar o launch." }
L "================================================="
