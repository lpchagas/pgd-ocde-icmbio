# =============================================================================
# criar_links_privados.ps1
# Recria as pontes (Junctions e HardLinks) entre o projeto publico e a pasta
# privada no OneDrive. Executar ao configurar o projeto em um computador novo.
#
# Quando usar:
#   - Ao instalar o projeto em um segundo computador (notebook ou desktop)
#   - Apos reinstalar o Windows ou mover a pasta do projeto
#   - Quando as pastas do projeto aparecerem vazias apos clonar o repositorio
#
# Como executar (PowerShell na raiz do projeto):
#   .\scripts\setup_local\criar_links_privados.ps1
#
# Nao e necessario rodar como Administrador para Junctions.
# Para HardLinks (arquivos .md), tambem nao e necessario — funciona porque
# o projeto e a pasta do OneDrive estao no mesmo disco (C:).
#
# O que este script FAZ:
#   - Cria pontes da pasta publica do projeto para a pasta privada no OneDrive
#   - Verifica se as pastas de destino existem antes de criar qualquer link
#   - Nao apaga nem move arquivos existentes
#
# O que este script NAO FAZ:
#   - Nao move arquivos (isso e feito uma unica vez manualmente ou na primeira
#     instalacao pelo responsavel do projeto)
#   - Nao cria o arquivo .env (use configurar_env.ps1 para isso)
#   - Nao faz push nem commit no Git
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------
# CONFIGURACAO — ajuste se a pasta privada estiver em local diferente
# ------------------------------------------------------------------
$PUBLICO = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PRIVADO = Join-Path $env:USERPROFILE "OneDrive - ICMBio\projetos\pgd-ocde-icmbio-privado"

# Descomentar e ajustar se o OneDrive tiver nome diferente nesta maquina:
# $PRIVADO = "C:\Users\SEU_USUARIO\OneDrive\pgd-ocde-icmbio-privado"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Criador de links — pgd-ocde-icmbio"
Write-Host "============================================================"
Write-Host "  Projeto publico : $PUBLICO"
Write-Host "  Pasta privada   : $PRIVADO"
Write-Host ""

# ------------------------------------------------------------------
# Verificar se a pasta privada existe
# ------------------------------------------------------------------
if (-not (Test-Path $PRIVADO)) {
    Write-Host "ERRO: A pasta privada nao foi encontrada:"
    Write-Host "  $PRIVADO"
    Write-Host ""
    Write-Host "Verifique se:"
    Write-Host "  1. O OneDrive esta instalado e sincronizado nesta maquina"
    Write-Host "  2. A pasta 'pgd-ocde-icmbio-privado' existe dentro de"
    Write-Host "     OneDrive - ICMBio\projetos\"
    Write-Host "  3. O nome do OneDrive esta correto (pode variar entre maquinas)"
    exit 1
}

# ------------------------------------------------------------------
# Funcao auxiliar — cria Junction ou HardLink com verificacoes
# ------------------------------------------------------------------
function New-Link {
    param(
        [string]$Tipo,       # "Junction" ou "HardLink"
        [string]$Origem,     # caminho que sera criado no projeto publico
        [string]$Destino     # caminho real na pasta privada (OneDrive)
    )

    $nome = Split-Path $Origem -Leaf

    if (-not (Test-Path $Destino)) {
        Write-Host "  IGNORADO ($nome): destino nao existe ainda em $Destino"
        return
    }

    if (Test-Path $Origem) {
        $item = Get-Item $Origem -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "  JA EXISTE ($nome): junction/link ja configurado"
        } else {
            Write-Host "  ATENCAO ($nome): ja existe um arquivo/pasta real em $Origem"
            Write-Host "    Mova-o para $Destino antes de criar o link."
        }
        return
    }

    New-Item -ItemType $Tipo -Path $Origem -Target $Destino | Out-Null
    Write-Host "  OK $Tipo`: $nome"
}

# ------------------------------------------------------------------
# Criar Junctions para PASTAS
# ------------------------------------------------------------------
Write-Host "--- Pastas (Junctions) ---"
New-Link "Junction" "$PUBLICO\artefatos_local" "$PRIVADO\artefatos_local"
New-Link "Junction" "$PUBLICO\.claude"         "$PRIVADO\assistentes\.claude"
New-Link "Junction" "$PUBLICO\.codex"          "$PRIVADO\assistentes\.codex"
New-Link "Junction" "$PUBLICO\.agents"         "$PRIVADO\assistentes\.agents"

# ------------------------------------------------------------------
# Criar HardLinks para ARQUIVOS de contexto dos assistentes de IA
# (HardLink exige mesmo disco — C: para C: neste projeto)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "--- Arquivos de contexto de IA (HardLinks) ---"
New-Link "HardLink" "$PUBLICO\CLAUDE.md"  "$PRIVADO\assistentes\CLAUDE.md"
New-Link "HardLink" "$PUBLICO\AGENTS.md"  "$PRIVADO\assistentes\AGENTS.md"
New-Link "HardLink" "$PUBLICO\PROJECT.md" "$PRIVADO\assistentes\PROJECT.md"

# ------------------------------------------------------------------
# Verificacao final
# ------------------------------------------------------------------
Write-Host ""
Write-Host "--- Verificacao ---"
$itens = @(
    @{ Nome = "artefatos_local\entregas"; Caminho = "$PUBLICO\artefatos_local\entregas" },
    @{ Nome = ".claude\settings.local.json"; Caminho = "$PUBLICO\.claude\settings.local.json" },
    @{ Nome = "CLAUDE.md"; Caminho = "$PUBLICO\CLAUDE.md" }
)
foreach ($item in $itens) {
    $ok = Test-Path $item.Caminho
    $status = if ($ok) { "acessivel" } else { "NAO encontrado" }
    Write-Host "  $($item.Nome): $status"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Proximo passo: execute configurar_env.ps1 para gerar o"
Write-Host "  arquivo .env com os caminhos corretos desta maquina."
Write-Host "============================================================"
Write-Host ""
