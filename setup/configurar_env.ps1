# =============================================================================
# configurar_env.ps1
# Detecta automaticamente os caminhos desta maquina e gera o arquivo .env
# pronto para uso — so e necessario preencher CPF e senha ao final.
#
# Quando usar:
#   - Ao configurar o projeto em um computador pela primeira vez
#   - Quando o DBeaver for atualizado e o driver mudar de versao
#   - Quando o .env estiver com caminho errado apos trocar de maquina
#
# Como executar (PowerShell na raiz do projeto):
#   .\setup\configurar_env.ps1
#
# Nao e necessario rodar como Administrador.
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJETO = Split-Path -Parent $PSScriptRoot
$ENV_DESTINO = Join-Path $PROJETO ".env"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Configurador automatico do .env — pgd-ocde-icmbio"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------------
# 1. Detectar usuario Windows
# ------------------------------------------------------------------
$usuario = $env:USERNAME
Write-Host "[1/4] Usuario Windows detectado: $usuario"

# ------------------------------------------------------------------
# 2. Localizar o driver JAR do Denodo no DBeaver
#    (funciona mesmo se o numero de versao mudar de /9/ para /10/)
# ------------------------------------------------------------------
Write-Host "[2/4] Procurando driver JAR do Denodo..."
$driverBase = Join-Path $env:APPDATA "DBeaverData\drivers\remote\drivers\jdbc"
$jar = $null

if (Test-Path $driverBase) {
    $jar = Get-ChildItem -Path $driverBase -Recurse -Filter "denodo-vdp-jdbcdriver.jar" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending |
           Select-Object -First 1 -ExpandProperty FullName
}

if (-not $jar) {
    Write-Host "    AVISO: driver .jar nao encontrado. Verifique se o DBeaver ja se conectou ao"
    Write-Host "    Denodo pelo menos uma vez (ele baixa o driver automaticamente na primeira conexao)."
    Write-Host "    Apos conectar, rode este script novamente."
    $driverPath = "C:/Users/$usuario/AppData/Roaming/DBeaverData/drivers/remote/drivers/jdbc/VERSAO/denodo-vdp-jdbcdriver.jar"
    Write-Host "    Caminho provisorio: $driverPath"
} else {
    $driverPath = $jar -replace "\\", "/"
    Write-Host "    Encontrado: $driverPath"
}

# ------------------------------------------------------------------
# 3. Localizar o jvm.dll do Java embutido no DBeaver
# ------------------------------------------------------------------
Write-Host "[3/4] Verificando instalacao do Java (DBeaver)..."
$jvmCandidatos = @(
    "C:\Program Files\DBeaver\jre",
    "C:\Program Files (x86)\DBeaver\jre"
)

$javaHome = $null
foreach ($c in $jvmCandidatos) {
    if (Test-Path "$c\bin\server\jvm.dll") {
        $javaHome = $c -replace "\\", "/"
        break
    }
}

if (-not $javaHome) {
    Write-Host "    AVISO: DBeaver nao encontrado nos caminhos padrao."
    Write-Host "    Instale o DBeaver (https://dbeaver.io) e rode este script novamente."
    $javaHome = "C:/Program Files/DBeaver/jre"
} else {
    Write-Host "    Encontrado: $javaHome"
}

# ------------------------------------------------------------------
# 4. Verificar se .env ja existe e fazer backup se necessario
# ------------------------------------------------------------------
Write-Host "[4/4] Gerando arquivo .env..."
if (Test-Path $ENV_DESTINO) {
    $backup = "$ENV_DESTINO.backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    Copy-Item $ENV_DESTINO $backup
    Write-Host "    .env existente preservado em: $backup"
}

# ------------------------------------------------------------------
# 5. Escrever o .env
# ------------------------------------------------------------------
$conteudo = @"
# Gerado automaticamente por configurar_env.ps1 em $(Get-Date -Format 'dd/MM/yyyy HH:mm')
# Maquina: $env:COMPUTERNAME | Usuario: $usuario
# NUNCA commitar este arquivo — ele contem sua senha pessoal.

# ─── Java (instalado junto com o DBeaver) ────────────────────────
JAVA_HOME=$javaHome

# ─── Driver Denodo (baixado pelo DBeaver automaticamente) ─────────
DENODO_DRIVER_PATH=$driverPath

# ─── Conexao Denodo (dados fixos do servidor — nao alterar) ───────
DENODO_HOST=denodo-pgd.dataprev.gov.br
DENODO_PORT=443
DENODO_DATABASE=petrvs_icmbio

# ─── PREENCHA ABAIXO: suas credenciais individuais ────────────────
# DENODO_USER: seu CPF sem pontos nem tracos (11 digitos)
DENODO_USER=seu_cpf_aqui
DENODO_PASSWORD=sua_senha_aqui
"@

Set-Content -Path $ENV_DESTINO -Value $conteudo -Encoding UTF8
Write-Host "    Arquivo .env criado em: $ENV_DESTINO"

# ------------------------------------------------------------------
# 6. Instrucoes finais
# ------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================"
Write-Host "  PROXIMO PASSO — abra o arquivo .env no Bloco de Notas:"
Write-Host ""
Write-Host "     notepad $ENV_DESTINO"
Write-Host ""
Write-Host "  Substitua os dois campos abaixo e salve:"
Write-Host "     DENODO_USER    -> seu CPF (11 digitos, sem pontos)"
Write-Host "     DENODO_PASSWORD -> sua senha do Denodo"
Write-Host ""
Write-Host "  O arquivo .env NAO vai para o GitHub (bloqueado pelo"
Write-Host "  .gitignore). Ele fica apenas neste computador."
Write-Host "============================================================"
Write-Host ""
