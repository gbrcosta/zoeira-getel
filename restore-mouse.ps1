# ==========================================================
# DESFAZER - volta os botoes do mouse ao normal
# Mesmo formato do script que funcionou (tarefa na sessao do usuario)
# ==========================================================

# Inner command (decodificado):
#   [W.U]::SwapMouseButton($false)
#   SwapMouseButtons = '0'  -> apaga a inversao permanente no registro
$cmd = 'QQBkAGQALQBUAHkAcABlACAALQBOAGEAbQBlACAAVQAgAC0ATgBhAG0AZQBzAHAAYQBjAGUAIABXACAALQBNAGUAbQBiAGUAcgBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJwBbAEQAbABsAEkAbQBwAG8AcgB0ACgAIgB1AHMAZQByADMAMgAuAGQAbABsACIAKQBdACAAcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAAYgBvAG8AbAAgAFMAdwBhAHAATQBvAHUAcwBlAEIAdQB0AHQAbwBuACgAYgBvAG8AbAAgAGYAKQA7ACcAOwAgAFsAVwAuAFUAXQA6ADoAUwB3AGEAcABNAG8AdQBzAGUAQgB1AHQAdABvAG4AKAAkAGYAYQBsAHMAZQApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAA7ACAAUwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACcASABLAEMAVQA6AFwAQwBvAG4AdAByAG8AbAAgAFAAYQBuAGUAbABcAE0AbwB1AHMAZQAnACAALQBOAGEAbQBlACAAUwB3AGEAcABNAG8AdQBzAGUAQgB1AHQAdABvAG4AcwAgAC0AVgBhAGwAdQBlACAAJwAwACcA'
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $cmd"
$p = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545' -RunLevel Limited
Register-ScheduledTask -TaskName 'SwapMouseTemp' -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName 'SwapMouseTemp'
Start-Sleep 10
Unregister-ScheduledTask -TaskName 'SwapMouseTemp' -Confirm:$false
