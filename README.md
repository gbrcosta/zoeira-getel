# zoeira-getel

Pegadinhas inofensivas e **100% reversíveis** para Windows, feitas pra rodar via
ferramenta de gestão remota (Tracker GT) na frota da empresa — só entre colegas que topam a brincadeira.

## Arquivos

| Arquivo | Pra quê |
|---|---|
| `zoeira-tracker.ps1` | Script principal. **Hospede este** e chame por parâmetro. |
| `chamar-no-tracker.ps1` | Comando curto que você cola no Tracker (baixa, roda, apaga). |
| `restore-mouse.ps1` | Desfaz só o mouse (formato tarefa agendada). |
| `restore-wallpaper.ps1` | Desfaz só o wallpaper (como SYSTEM). |
| `zoeira.ps1` + `ZOEIRA.bat` | Versão local interativa (menu), pra testar na sua máquina. |

## Opções (`-OPCAO`)

| Valor | Faz | Reversível |
|---|---|---|
| `1` | Troca o wallpaper (usa `-LINK`) | sim (`R`) |
| `2` | Inverte os botões do mouse | sim (`R`) |
| `3` | PC fala uma frase | — |
| `4` | Popup falso do Windows | — |
| `5` | Caps Lock piscando | — |
| `6` | Mouse foguete (rápido) | sim (`R`) |
| `7` | Mouse lesma (lento) | sim (`R`) |
| `8` | Mouse bêbado (treme 15s) | — |
| `9` | Tela de atualização falsa (monitor principal atualizando + spinner; os outros ficam pretos; clique/tecla não fecham; sai em `$DUR`s ou digitando `sair`) | — |
| `10` | Tela de "Reiniciando" falsa (mesmo estilo, sem %; sai em `$DUR`s ou digitando `sair`) | — |
| `R` | **Restaura** mouse + velocidade + wallpaper | — |

## Uso

1. Hospede `zoeira-tracker.ps1` num link público (ex.: asset deste release).
2. No `chamar-no-tracker.ps1`, ajuste `$OPCAO`, `$LINK` (se opção 1) e `$URL`.
3. Cole o chamador no Terminal PowerShell do Tracker e envie.
4. Pra desfazer: mesmo chamador com `$OPCAO = "R"`.

> ⚠️ O script roda como SYSTEM na máquina alvo. Use só em equipamentos da própria
> empresa, com quem está no combinado, e tenha o `R` à mão.
