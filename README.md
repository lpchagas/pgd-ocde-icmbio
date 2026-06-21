# pgd-ocde-icmbio — Indicadores OCDE/PGD via Denodo

Consultas SQL e documentação para calcular os **12 indicadores OCDE/PGD** do ICMBio diretamente do banco PETRVS em tempo real, via Denodo (MGI/Dataprev). Sem Docker, sem ETL, sem instalação de banco de dados local.

Desenvolvido pela Coordenação de Governança (CGOV/ICMBio) no âmbito do piloto OCDE/MGI para transformação do PGD em instrumento de gestão de desempenho.

> **Para outros órgãos da APF:** este repositório pode ser reutilizado por qualquer instituição que utilize o PETRVS e tenha acesso ao Denodo do MGI/Dataprev. As queries funcionam sem modificação — basta apontar para o schema do seu órgão.

---

## Pré-requisitos

| Ferramenta | Para quê | Como obter |
| --- | --- | --- |
| DBeaver Community | Executar as queries SQL | [dbeaver.io/download](https://dbeaver.io/download/) — gratuito |
| Acesso ao Denodo | Credenciais + IP liberado | Solicitar ao gestor responsável pelo PGD no seu órgão |
| VS Code + Python | Apenas para o Notebook Jupyter | Opcional — só se quiser usar a Opção B |

Não é necessário MySQL, Docker, PostgreSQL ou qualquer banco de dados local.

---

## Início rápido

### Para gestores (sem SQL)

Leia [docs/08-guia-rapido-gestores.md](docs/08-guia-rapido-gestores.md) — entenda os indicadores e interprete os resultados sem precisar executar código.

---

### Para analistas — Opção A: DBeaver (recomendado)

1. Configure a conexão Denodo no DBeaver seguindo [docs/03-acesso-direto-denodo-dbeaver.md](docs/03-acesso-direto-denodo-dbeaver.md)
2. Abra o índice do manual: [docs/06-indicadores-ocde-mysql.md](docs/06-indicadores-ocde-mysql.md)
3. Navegue até o indicador desejado e copie a query para um SQL Editor
4. Ajuste as datas no bloco `parametros` e execute com `Ctrl + A` > `Ctrl + Enter`

---

### Para analistas — Opção B: Jupyter Notebook no VS Code

#### Passo 1 — Clone ou baixe este repositório

```bash
git clone https://github.com/lpchagas/pgd-ocde-icmbio.git
```

Ou clique em **Code > Download ZIP** no GitHub e extraia a pasta.

#### Passo 2 — Copie o arquivo de configuração

Na pasta do projeto, localize o arquivo `.env.example`. Faça uma cópia e renomeie para `.env`:

```text
.env.example  →  .env
```

#### Passo 3 — Preencha suas credenciais

Abra o arquivo `.env` com o Bloco de Notas e preencha com as credenciais fornecidas pelo gestor responsável pelo PGD no seu órgão:

```ini
DENODO_USER=seu_cpf_aqui
DENODO_PASSWORD=sua_senha_aqui
DENODO_DRIVER_PATH=C:/Users/SEU_USUARIO/AppData/Roaming/DBeaverData/...
```

> O arquivo `.env` fica apenas no seu computador. Ele não vai para o GitHub. Sua senha nunca sai da sua máquina.

#### Passo 4 — Execute o notebook

Abra o arquivo `consultas_denodo_template.ipynb` no VS Code e execute as células em ordem.

Guia completo para quem nunca usou Python: [docs/10-jupyter-guia-iniciantes.md](docs/10-jupyter-guia-iniciantes.md)

---

### Para rotina mensal — Scripts Python sanitizados

Os scripts publicos em `scripts/indicadores/` geram os CSVs mensais dos
indicadores sem armazenar credenciais no codigo. Eles leem a conexao do arquivo
local `.env` e salvam as saidas em `artefatos_local/`, pasta ignorada pelo git.

Exemplo:

```powershell
python scripts/indicadores/IND_02.1_run.py --dry-run
python scripts/indicadores/IND_02.1_run.py
```

Fluxo completo: [docs/11-guia-extracao-mensal.md](docs/11-guia-extracao-mensal.md)

Checklist de seguranca antes de publicar: [docs/12-seguranca-publicacao.md](docs/12-seguranca-publicacao.md)

---

## Indicadores disponíveis

| # | Indicador | Eixo | Documento |
| --- | --- | --- | --- |
| I01 | Proporção de servidores por regime de trabalho | Trabalho Remoto | [06.1.1-i01.md](docs/06.1.1-i01.md) |
| I02 | Taxa de cumprimento das entregas por unidade | Execução | [06.2.1-i02.md](docs/06.2.1-i02.md) |
| I03 | Taxa de cumprimento de metas por entrega | Execução | [06.2.2-i03.md](docs/06.2.2-i03.md) |
| I04 | Índice de atingimento de metas — score médio | Execução | [06.2.3-i04.md](docs/06.2.3-i04.md) |
| I05 | Distribuição das entregas entre os servidores | Carga de Trabalho | [06.3.1-i05.md](docs/06.3.1-i05.md) |
| I06 | Grau de responsabilidade pelas entregas | Carga de Trabalho | [06.3.2-i06.md](docs/06.3.2-i06.md) |
| I07 | Horas por entrega — planejadas (absoluto) | Carga de Trabalho | [06.3.3-i07.md](docs/06.3.3-i07.md) |
| I08 | Proporção de horas por entrega — planejadas (%) | Carga de Trabalho | [06.3.4-i08.md](docs/06.3.4-i08.md) |
| I09 | Média da avaliação do Plano de Trabalho por unidade | Desempenho | [06.4.1-i09.md](docs/06.4.1-i09.md) |
| I10 | Percentual de avaliações inadequadas (nota 2) | Desempenho | [06.4.2-i10.md](docs/06.4.2-i10.md) |
| I11 | Percentual de avaliações excepcionais (nota 5) | Desempenho | [06.4.3-i11.md](docs/06.4.3-i11.md) |
| I12 | Coerência entre avaliação do PT e do PE | Desempenho | [06.4.4-i12.md](docs/06.4.4-i12.md) |

Índice navegável com descrição completa de cada indicador: [docs/06-indicadores-ocde-mysql.md](docs/06-indicadores-ocde-mysql.md)

---

## Estrutura do projeto

```text
.env.example                        Modelo de configuração — copie como .env e preencha
consultas_denodo_template.ipynb     Notebook Jupyter para análises via Python/JDBC

Consultas SQL/
  indicadores_ocde_pgd_icmbio_mysql_direto.sql   Todas as queries para o DBeaver
  indicadores_ocde_pgd_icmbio_mysql_guiado.sql   Mesmo conteúdo com comentários explicativos

docs/
  01-visao-geral.md                 Conceito, fluxo Denodo e comparativo com o projeto postgre
  03-acesso-direto-denodo-dbeaver.md Como conectar no Denodo via DBeaver
  04-configuracao-dbeaver.md        Configuração detalhada do DBeaver
  05-contexto-ocde-pgd.md          Contexto OCDE/PGD, perfil ICMBio e achados quantitativos
  06-indicadores-ocde-mysql.md     Índice navegável — ponto de entrada do manual técnico
  07-estrutura-banco-dados.md      Schema real do banco: 123 views, campos e contagens
  08-guia-rapido-gestores.md       Guia sem SQL para gestores e tomadores de decisão
  09-protocolo-validacao-indicadores.md  Protocolo de validação manual dos indicadores (4 fases)
  10-jupyter-guia-iniciantes.md    Passo a passo para usar o Notebook sem experiência em Python
  11-guia-extracao-mensal.md       Guia operacional: calendário, comandos, troubleshooting e prompts IA
  12-seguranca-publicacao.md       Checklist para evitar vazamento de credenciais e dados

  docs/06.x-eixoX.md               Documentação por eixo (4 arquivos)
  docs/06.x.x-iXX.md               Documentação por indicador (12 arquivos)

scripts/
  README.md                        Como executar os scripts publicos
  indicadores/                     IND_XX.1_run.py sanitizados
  diagnosticos/                    Template publico para diagnosticos locais
  lib/                             Configuracao, CSV, periodos e auditoria comuns

artefatos_local/                   [LOCAL — nao versionar] CSVs, validacoes e scripts executados
```

---

## Projeto relacionado

[DM_Petrvs_icmbio_postgre](https://github.com/lpchagas/DM_Petrvs_icmbio_postgre) — fluxo completo com ETL, datamart PostgreSQL e dashboards Apache Superset. Indicado quando o objetivo é monitoramento contínuo com visualizações prontas, em vez de análise ad hoc via SQL.
