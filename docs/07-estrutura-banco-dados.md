# Estrutura do Banco de Dados PETRVS — Denodo (Tempo Real)

**Última atualização:** 15 de maio de 2026
**Fonte:** Banco `petrvs_icmbio` via Denodo (MGI/Dataprev) — introspecção JDBC em tempo real
**Total de views:** 123
**Conexão:** `denodo-pgd.dataprev.gov.br:443`

> **Convenção de nomenclatura Denodo:** todas as views têm o prefixo `petrvs_icmbio_`.
> O DBeaver resolve o schema automaticamente; no Jupyter (JDBC direto) use o nome completo,
> ex.: `petrvs_icmbio_planos_entregas_entregas`.

---

## 1. Visão Geral: Arquitetura em Camadas

O banco PETRVS é organizado em **4 camadas de abstração** que representam o fluxo do sistema de gestão de desempenho do ICMBio:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. CAMADA DE REFERÊNCIA                                     │
│    (usuários, unidades, tipos de dados, programas PGD)     │
├─────────────────────────────────────────────────────────────┤
│ 2. CAMADA DE PLANEJAMENTO                                   │
│    (planos de entregas, planos de trabalho, metas)         │
├─────────────────────────────────────────────────────────────┤
│ 3. CAMADA DE EXECUÇÃO                                       │
│    (atividades, consolidações, afastamentos, ocorrências)  │
├─────────────────────────────────────────────────────────────┤
│ 4. CAMADA DE AVALIAÇÃO & RESULTADO                          │
│    (avaliações, progressos, resultados, checklist)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Camada 1: Referência

Tabelas que servem como base para todo o sistema. Mudam raramente.

### 2.1 Usuários e Autorização

| Tabela | Descrição | Total | Ativos |
| --- | --- | --- | --- |
| `usuarios` | Cadastro de todos os servidores/usuários | 7.403 | 7.403 |
| `perfis` | Perfis de acesso (permissões) | — | — |
| `personal_access_tokens` | Tokens de API por usuário | — | — |
| `unidades_integrantes` | Composição de unidades (lotação) | — | — |
| `unidades_integrantes_atribuicoes` | Atribuições de cada integrante | — | — |

**Campos completos de `usuarios` (44 colunas):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID — chave primária |
| `nome` | VARCHAR(256) | NÃO | Nome completo |
| `email` | VARCHAR(100) | NÃO | E-mail corporativo |
| `cpf` | VARCHAR(11) | NÃO | CPF sem formatação |
| `matricula` | VARCHAR(50) | SIM | Matrícula SIAPE |
| `ident_unica` | VARCHAR(50) | SIM | Identificador único no SIAPE |
| `apelido` | VARCHAR(255) | SIM | Nome social/apelido |
| `telefone` | VARCHAR(50) | SIM | Telefone |
| `data_nascimento` | TIMESTAMP | SIM | Data de nascimento |
| `sexo` | CHAR(9) | SIM | Sexo declarado |
| `uf` | CHAR(2) | SIM | UF de lotação |
| `situacao_funcional` | CHAR(34) | NÃO | Situação detalhada (50+ estados) |
| `situacao_siape` | CHAR(16) | NÃO | ATIVO \| INATIVO \| ATIVO_TEMPORARIO |
| `participa_pgd` | CHAR(3) | NÃO | `sim` ou `não` |
| `tipo_modalidade_id` | CHAR(36) | NÃO | FK → `tipos_modalidades` |
| `perfil_id` | CHAR(36) | SIM | FK → `perfis` |
| `nome_jornada` | VARCHAR(100) | SIM | Descrição da jornada de trabalho |
| `cod_jornada` | INTEGER | SIM | Código da jornada no SIAPE |
| `tipo_pedagio` | TINYINT | SIM | Fase do período de adaptação (pedagio) |
| `data_inicial_pedagio` | DATE | SIM | Início do período de adaptação |
| `data_final_pedagio` | DATE | SIM | Fim do período de adaptação |
| `is_admin` | BIT(1) | NÃO | Flag de administrador do sistema |
| `usuario_externo` | BIT(1) | NÃO | Usuário fora do quadro permanente |
| `config` | LONGVARCHAR | SIM | Configurações pessoais (JSON) |
| `notificacoes` | LONGVARCHAR | SIM | Preferências de notificação (JSON) |
| `metadados` | LONGVARCHAR | SIM | Campos extras via integração (JSON) |
| `texto_complementar_plano` | LONGVARCHAR | SIM | Texto padrão nos planos de trabalho |
| `data_envio_api_pgd` | TIMESTAMP | SIM | Última sincronização com API PGD/MGI |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Distribuição por `situacao_siape`:** ATIVO: 7.355 · INATIVO: 48
**Distribuição por `participa_pgd`:** sim: 3.002 · não: 4.401

---

### 2.2 Estrutura Organizacional

| Tabela | Descrição | Total |
| --- | --- | --- |
| `unidades` | Departamentos, coordenações, diretorias | 811 |
| `cidades` | Cidades brasileiras (referência) | — |
| `entidades` | Órgãos/entidades vinculadas | — |

**Campos completos de `unidades` (31 colunas):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `sigla` | VARCHAR(100) | NÃO | Código curto (ex: CGOV, AUDIT) |
| `nome` | VARCHAR(256) | NÃO | Nome completo da unidade |
| `codigo` | VARCHAR(12) | SIM | Código SIORG/SIAPE |
| `path` | LONGVARCHAR | SIM | Caminho hierárquico (ex: `/ICMBio/DISAT/CGOF/`) |
| `unidade_pai_id` | CHAR(36) | SIM | FK → `unidades` (autorreferência hierárquica) |
| `entidade_id` | CHAR(36) | NÃO | FK → `entidades` |
| `cidade_id` | CHAR(36) | SIM | FK → `cidades` |
| `instituidora` | TINYINT | NÃO | 1 se é a unidade raiz/instituidora (apenas 1 no banco) |
| `executora` | BIT(1) | NÃO | 1 se é unidade executora de PGD |
| `informal` | TINYINT | NÃO | 1 se é unidade informal (não SIORG) |
| `distribuicao_forma_contagem_prazos` | CHAR(51) | NÃO | Como contabiliza prazos de distribuição |
| `entrega_forma_contagem_prazos` | CHAR(26) | NÃO | Como contabiliza prazos de entrega |
| `planos_prazo_comparecimento` | INTEGER | NÃO | Prazo mínimo de comparecimento |
| `planos_tipo_prazo_comparecimento` | VARCHAR(255) | NÃO | Unidade do prazo (HORAS, DIAS) |
| `atividades_arquivamento_automatico` | TINYINT | NÃO | Arquiva atividades automaticamente |
| `atividades_avaliacao_automatico` | TINYINT | NÃO | Avalia atividades automaticamente |
| `autoedicao_subordinadas` | TINYINT | NÃO | Permite subordinadas editarem |
| `expediente` | LONGVARCHAR | SIM | Configuração de horário/expediente (JSON) |
| `etiquetas` | LONGVARCHAR | SIM | Etiquetas customizadas (JSON) |
| `checklist` | LONGVARCHAR | SIM | Checklist padrão (JSON) |
| `notificacoes` | LONGVARCHAR | SIM | Configuração de notificações (JSON) |
| `texto_complementar_plano` | LONGVARCHAR | SIM | Texto padrão inserido nos planos |
| `data_inativacao` | TIMESTAMP | SIM | Data de inativação |
| `data_inicio_inativacao` | TIMESTAMP | SIM | Início do período de inativação |
| `data_ativacao_temporaria` | TIMESTAMP | SIM | Reativação temporária |
| `justificativa_ativacao_temporaria` | LONGVARCHAR | SIM | Motivo da reativação |
| `data_modificacao` | TIMESTAMP | SIM | Última alteração |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

---

### 2.3 Programas PGD

A tabela `programas` define as regras e parâmetros de cada programa de gestão de desempenho. É o elo entre configuração institucional e os planos de trabalho/entrega.

**Campos de `programas` (35 colunas — seleção dos principais):**

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | CHAR(36) | UUID |
| `nome` | VARCHAR(255) | Nome do programa (ex: "PGD ICMBio 2025") |
| `normativa` | VARCHAR(255) | Portaria ou ato normativo que institui |
| `link_normativa` | VARCHAR(255) | URL da norma |
| `data_inicio` / `data_fim` | TIMESTAMP | Vigência do programa |
| `periodicidade_consolidacao` | CHAR(10) | MENSAL, BIMESTRAL, TRIMESTRAL, etc. |
| `periodicidade_valor` | INTEGER | Valor numérico da periodicidade |
| `dias_tolerancia_consolidacao` | INTEGER | Dias extras para consolidar |
| `dias_tolerancia_avaliacao` | INTEGER | Dias extras para avaliar |
| `dias_tolerancia_recurso_avaliacao` | INTEGER | Dias extras para recurso |
| `prazo_max_plano_entrega` | INTEGER | Prazo máximo para envio do PE |
| `registra_comparecimento` | TINYINT | Se registra comparecimento |
| `tipo_avaliacao_plano_trabalho_id` | CHAR(36) | FK → `tipos_avaliacoes` |
| `tipo_avaliacao_plano_entrega_id` | CHAR(36) | FK → `tipos_avaliacoes` |
| `unidade_id` | CHAR(36) | Unidade gestora do programa |
| `unidade_autorizadora_id` | CHAR(36) | Unidade que autoriza participações |
| `config` | LONGVARCHAR | Configurações avançadas (JSON) |
| `plano_trabalho_criterios_avaliacao` | LONGVARCHAR | Critérios padrão de avaliação (JSON) |

---

### 2.4 Tipos e Catálogos

Tabelas de enumeração/referência. Prefixadas por `tipos_*`:

| Tabela | Descrição | Uso principal |
| --- | --- | --- |
| `tipos_modalidades` | Regimes de trabalho | `planos_trabalhos`, `usuarios` |
| `tipos_avaliacoes` | Tipos de avaliação | `avaliacoes`, `programas` |
| `tipos_avaliacoes_notas` | Escala de conceitos (1–5) | `avaliacoes` |
| `tipos_avaliacoes_justificativas` | Justificativas pré-definidas | `avaliacoes` |
| `tipos_atividades` | Categorias de atividades | `atividades` |
| `tipos_justificativas` | Motivos de desvio | Consolidações |
| `tipos_motivos_afastamentos` | Tipos de afastamento | `afastamentos` |
| `tipos_tarefas` | Categorias de tarefas | `atividades_tarefas` |
| `tipos_documentos` | Categorias de documentos | `documentos` |
| `tipos_modalidades_siape` | Modalidades conforme SIAPE | Integração |
| `tipos_processos` | Tipos de processo | `cadeias_valores_processos` |
| `tipos_projetos` | Categorias de projeto | `projetos` |
| `tipos_cursos` | Categorias de cursos | `cursos` |
| `tipos_clientes` | Categorias de clientes | `clientes` |
| `tipos_capacidades` | Categorias de capacidade | `capacidades` |

**`tipos_modalidades` (9 colunas):**

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | CHAR(36) | UUID |
| `nome` | VARCHAR(256) | Ex: "Presencial", "Híbrido", "Teletrabalho" |
| `exige_pedagio` | BIT(1) | Exige período de adaptação |
| `plano_trabalho_calcula_horas` | TINYINT | Se calcula horas no plano de trabalho |
| `atividade_tempo_despendido` | TINYINT | Registra tempo despendido |
| `atividade_esforco` | TINYINT | Registra esforço |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | Auditoria |

**`tipos_avaliacoes` — valores reais no banco:**

| `nome` | `tipo` |
| --- | --- |
| Execução de Plano de Trabalho | QUALITATIVO |
| Execução do Plano de Entrega | QUALITATIVO |

**`tipos_avaliacoes_notas` — escala de conceitos (aplicada a PT e PE):**

| Sequência | Conceito | Descrição (PT) | Descrição (PE) |
| --- | --- | --- | --- |
| 1 | Excepcional | Plano de trabalho executado muito acima do esperado | Plano de entregas executado com desempenho muito acima do esperado |
| 2 | Alto desempenho | Plano de trabalho executado acima do esperado | Plano de entregas executado com desempenho acima do esperado |
| 3 | Adequado | Plano de trabalho executado dentro do esperado | Plano de entregas executado dentro do esperado |
| 4 | Inadequado | Plano de trabalho executado abaixo do esperado ou parcialmente executado | Plano de entregas executado abaixo do esperado |
| 5 | Não executado | Plano de trabalho integralmente não executado | Plano de entregas não executado |

> Há um registro por conceito para cada tipo de avaliação (PT e PE), totalizando 10 registros.
> O campo `aprova` é 0 em todos os registros (nenhuma nota é automaticamente aprovativa).

---

### 2.5 Catálogo de Entregas

| Tabela | Descrição | Colunas |
| --- | --- | --- |
| `entregas` | Catálogo de tipos de entrega (templates) | 11 |

**`entregas` (11 colunas):**

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | CHAR(36) | UUID |
| `nome` | LONGVARCHAR | Nome do tipo de entrega |
| `descricao` | LONGVARCHAR | Descrição detalhada |
| `tipo_indicador` | CHAR | Tipo de indicador de progresso |
| `lista_qualitativos` | LONGVARCHAR | Opções qualitativas (JSON) |
| `unidade_id` | CHAR(36) | Unidade dona do catálogo |
| `checklist` | LONGVARCHAR | Checklist padrão (JSON) |
| `etiquetas` | LONGVARCHAR | Etiquetas (JSON) |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | Auditoria |

> Esta tabela é referenciada por `planos_entregas_entregas.entrega_id` — indica que cada entrega planejada pode ser derivada de um template do catálogo.

---

## 3. Camada 2: Planejamento

### 3.1 Planejamento Estratégico

| Tabela | Descrição | Colunas |
| --- | --- | --- |
| `planejamentos` | Ciclos de planejamento estratégico | 15 |
| `planejamentos_objetivos` | Objetivos estratégicos do ciclo | — |
| `cadeias_valores` | Cadeias de valor institucionais | — |
| `cadeias_valores_processos` | Processos dentro de cadeias de valor | — |
| `okrs` | OKRs vinculados ao planejamento | — |
| `okrs_objetivos` | Objetivos dos OKRs | — |
| `okrs_objetivos_resultados_chaves` | KRs dos OKRs | — |

**Campos de `planejamentos` (15 colunas — principais):**

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | CHAR(36) | UUID |
| `nome` | VARCHAR(256) | Nome do ciclo (ex: "Planejamento Estratégico ICMBio 2025-2030") |
| `missao` | LONGVARCHAR | Missão institucional |
| `visao` | LONGVARCHAR | Visão institucional |
| `valores` | LONGVARCHAR | Valores (JSON) |
| `data_inicio` / `data_fim` | TIMESTAMP | Vigência |
| `entidade_id` / `unidade_id` | CHAR(36) | Escopo organizacional |
| `planejamento_superior_id` | CHAR(36) | FK → `planejamentos` (hierarquia de planos) |

---

### 3.2 Planos de Entregas (PE)

#### `planos_entregas` (20 colunas)

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `numero` | INTEGER | NÃO | Número sequencial do plano |
| `nome` | VARCHAR(256) | NÃO | Nome do plano de entrega |
| `status` | CHAR(11) | NÃO | Estado atual (ver distribuição abaixo) |
| `data_inicio` | TIMESTAMP | NÃO | Início da vigência |
| `data_fim` | TIMESTAMP | SIM | Fim da vigência |
| `data_arquivamento` | TIMESTAMP | SIM | Quando foi arquivado |
| `avaliado_at` | DATE | SIM | Data de avaliação conclusiva |
| `unidade_id` | CHAR(36) | NÃO | FK → `unidades` |
| `programa_id` | CHAR(36) | NÃO | FK → `programas` |
| `planejamento_id` | CHAR(36) | SIM | FK → `planejamentos` |
| `cadeia_valor_id` | CHAR(36) | SIM | FK → `cadeias_valores` |
| `okr_id` | CHAR(36) | SIM | FK → `okrs` |
| `plano_entrega_id` | CHAR(36) | SIM | FK → `planos_entregas` (PE pai) |
| `criacao_usuario_id` | CHAR(36) | NÃO | Quem criou |
| `avaliacao_id` | CHAR(36) | SIM | FK → `avaliacoes` |
| `data_envio_api_pgd` | TIMESTAMP | SIM | Última sincronização com API PGD/MGI |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Distribuição por `status` (total: 1.634):**

| Status | Count | % |
| --- | --- | --- |
| AVALIADO | 868 | 53% |
| ATIVO | 446 | 27% |
| INCLUIDO | 211 | 13% |
| HOMOLOGANDO | 45 | 3% |
| CANCELADO | 36 | 2% |
| CONCLUIDO | 27 | 2% |
| SUSPENSO | 1 | <1% |

> **Achado relevante para I02:** somente 27 PEs com status CONCLUIDO e 868 com AVALIADO. O critério OCDE da query (`progresso_realizado >= progresso_esperado`) é diferente do fluxo formal do PETRVS (exige status AVALIADO + aprovação). Ver [09-protocolo-validacao-indicadores.md](09-protocolo-validacao-indicadores.md).

---

#### `planos_entregas_entregas` (21 colunas) — CRÍTICA PARA I02, I03, I04

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `descricao` | LONGVARCHAR | NÃO | Nome/descrição principal da entrega |
| `descricao_entrega` | LONGVARCHAR | NÃO | Descrição alternativa (versões antigas do PETRVS) |
| `descricao_meta` | LONGVARCHAR | NÃO | Descrição textual da meta |
| `destinatario` | VARCHAR(255) | SIM | Beneficiário/público-alvo da entrega |
| `progresso_esperado` | DECIMAL(5,2) | SIM | Meta planejada (ex: 100.00) |
| `progresso_realizado` | DECIMAL(5,2) | SIM | Meta executada (ex: 75.00) |
| `data_inicio` | TIMESTAMP | NÃO | Início da entrega |
| `data_fim` | TIMESTAMP | SIM | Prazo final da entrega |
| `homologado` | TINYINT | NÃO | Flag de homologação (0 para todo o ciclo 2025) |
| `meta` | LONGVARCHAR | NÃO | Estrutura completa da meta (JSON) |
| `realizado` | LONGVARCHAR | SIM | Estrutura do realizado (JSON) |
| `checklist` | LONGVARCHAR | SIM | Checklist de avaliação (JSON) |
| `etiquetas` | LONGVARCHAR | SIM | Etiquetas customizadas (JSON) |
| `plano_entrega_id` | CHAR(36) | NÃO | FK → `planos_entregas` |
| `entrega_id` | CHAR(36) | NÃO | FK → `entregas` (template do catálogo) |
| `entrega_pai_id` | CHAR(36) | SIM | FK → `planos_entregas_entregas` (hierarquia) |
| `unidade_id` | CHAR(36) | NÃO | FK → `unidades` |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Totais:** 18.831 registros · 18.060 ativos (`deleted_at IS NULL`)

> **Nome da entrega:** usar `COALESCE(NULLIF(TRIM(descricao),''), NULLIF(TRIM(descricao_entrega),''))` — ambos os campos existem e podem conter o nome dependendo da versão do PETRVS.
> **Critério de conclusão OCDE:** `progresso_realizado >= progresso_esperado`
> **Campo `homologado`:** zerado (0) para todo o ciclo 2025 — não usar como critério de conclusão.

---

#### Vinculações estratégicas dos PE

| Tabela | Descrição |
| --- | --- |
| `planos_entregas_entregas_objetivos` | Entrega → Objetivo estratégico |
| `planos_entregas_entregas_processos` | Entrega → Processo (cadeia de valor) |
| `planos_entregas_entregas_produtos` | Entrega → Produto |
| `planos_entregas_entregas_resultados_chaves` | Entrega → KR (OKR) |
| `planos_entregas_entregas_progressos` | Histórico de registros de progresso |

---

### 3.3 Planos de Trabalho (PT)

#### `planos_trabalhos` (22 colunas)

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `numero` | INTEGER | NÃO | Número sequencial |
| `status` | CHAR(21) | NÃO | Estado atual (ver distribuição abaixo) |
| `carga_horaria` | DOUBLE | NÃO | Horas totais do período contratual |
| `tempo_total` | DOUBLE | NÃO | Horas totais apuradas |
| `tempo_proporcional` | DOUBLE | NÃO | Horas ajustadas proporcionalmente |
| `forma_contagem_carga_horaria` | CHAR(6) | NÃO | `DIAS` ou `HORAS` |
| `data_inicio` | TIMESTAMP | NÃO | Início do plano |
| `data_fim` | TIMESTAMP | NÃO | Fim do plano |
| `data_arquivamento` | TIMESTAMP | SIM | Quando foi arquivado |
| `avaliado_at` | DATE | SIM | Data de avaliação conclusiva |
| `usuario_id` | CHAR(36) | NÃO | FK → `usuarios` (servidor) |
| `unidade_id` | CHAR(36) | NÃO | FK → `unidades` |
| `programa_id` | CHAR(36) | NÃO | FK → `programas` |
| `tipo_modalidade_id` | CHAR(36) | NÃO | FK → `tipos_modalidades` |
| `criacao_usuario_id` | CHAR(36) | NÃO | Quem criou |
| `documento_id` | CHAR(36) | SIM | FK → `documentos` (TCR) |
| `criterios_avaliacao` | LONGVARCHAR | NÃO | Critérios de avaliação preenchidos (JSON) |
| `data_envio_api_pgd` | TIMESTAMP | SIM | Última sincronização com API PGD/MGI |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Distribuição por `status` (total: 14.168 — nenhum excluído):**

| Status | Count | % |
| --- | --- | --- |
| CONCLUIDO | 11.516 | 81% |
| ATIVO | 1.482 | 10% |
| CANCELADO | 569 | 4% |
| AGUARDANDO_ASSINATURA | 391 | 3% |
| INCLUIDO | 207 | 1% |
| SUSPENSO | 3 | <1% |

---

#### `planos_trabalhos_entregas` (10 colunas) — CRÍTICA PARA I05, I06, I07, I08

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `forca_trabalho` | DECIMAL(5,2) | NÃO | % de dedicação do servidor à entrega (ex: 20.00 = 20%) |
| `descricao` | LONGVARCHAR | NÃO | Atividades a realizar pelo servidor nesta entrega |
| `meta` | LONGVARCHAR | SIM | Detalhes da meta individual (JSON) |
| `orgao` | VARCHAR(256) | SIM | Órgão externo (quando envolver parceiros) |
| `plano_trabalho_id` | CHAR(36) | NÃO | FK → `planos_trabalhos` |
| `plano_entrega_entrega_id` | CHAR(36) | SIM | FK → `planos_entregas_entregas` (nullable) |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Totais:** 69.208 registros · 64.925 ativos

> **Campo `forca_trabalho`:** único campo numérico nesta tabela. Representa o percentual de dedicação (0–100). Para calcular horas, combine com `planos_trabalhos.carga_horaria` e o período do plano. Não existem campos `quantidade` ou `horas_por_unidade` nesta tabela — a referência no CLAUDE.md é um achado a verificar nas queries de I07/I08.

---

## 4. Camada 3: Execução

### 4.1 Atividades

| Tabela | Descrição | Total | Ativos |
| --- | --- | --- | --- |
| `atividades` | Atividades atribuídas e realizadas | 141.724 | 139.607 |
| `atividades_tarefas` | Tarefas dentro de atividades | — | — |
| `atividades_pausas` | Pausas registradas em atividades | — | — |

**Campos de `atividades` (29 colunas — principais):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `numero` | INTEGER | NÃO | Número sequencial |
| `descricao` | LONGVARCHAR | NÃO | Descrição da atividade |
| `status` | CHAR(9) | NÃO | INCLUIDO \| INICIADO \| CONCLUIDO |
| `progresso` | DECIMAL(5,2) | NÃO | Percentual de conclusão (0–100) |
| `carga_horaria` | DOUBLE | SIM | Carga horária prevista |
| `tempo_planejado` | DOUBLE | NÃO | Horas planejadas |
| `tempo_despendido` | DOUBLE | SIM | Horas efetivamente gastas |
| `esforco` | DOUBLE | NÃO | Esforço (pontos de função / complexidade) |
| `prioridade` | INTEGER | SIM | Nível de prioridade |
| `data_distribuicao` | TIMESTAMP | NÃO | Quando foi distribuída |
| `data_estipulada_entrega` | TIMESTAMP | NÃO | Prazo estipulado |
| `data_inicio` | TIMESTAMP | SIM | Quando foi iniciada |
| `data_entrega` | TIMESTAMP | SIM | Quando foi entregue |
| `data_arquivamento` | TIMESTAMP | SIM | Quando foi arquivada |
| `plano_trabalho_id` | CHAR(36) | SIM | FK → `planos_trabalhos` |
| `plano_trabalho_entrega_id` | CHAR(36) | SIM | FK → `planos_trabalhos_entregas` |
| `plano_trabalho_consolidacao_id` | CHAR(36) | SIM | FK → `planos_trabalhos_consolidacoes` |
| `tipo_atividade_id` | CHAR(36) | SIM | FK → `tipos_atividades` |
| `demandante_id` | CHAR(36) | NÃO | Quem demandou |
| `usuario_id` | CHAR(36) | SIM | Quem executa |
| `unidade_id` | CHAR(36) | NÃO | Unidade responsável |
| `etiquetas` / `checklist` | LONGVARCHAR | SIM | JSON |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Distribuição por `status`:** CONCLUIDO: 139.450 · INCLUIDO: 2.155 · INICIADO: 119

---

### 4.2 Consolidações de Plano de Trabalho

| Tabela | Descrição | Total | Ativos |
| --- | --- | --- | --- |
| `planos_trabalhos_consolidacoes` | Consolidação periódica do PT | 40.880 | 28.302 |
| `planos_trabalhos_consolidacoes_atividades` | Atividades incluídas na consolidação | — | — |
| `planos_trabalhos_consolidacoes_afastamentos` | Afastamentos no período consolidado | — | — |
| `planos_trabalhos_consolidacoes_ocorrencias` | Ocorrências no período consolidado | — | — |

**Campos de `planos_trabalhos_consolidacoes` (11 colunas):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `status` | CHAR(9) | NÃO | INCLUIDO \| CONCLUIDO \| AVALIADO |
| `data_inicio` | DATE | NÃO | Início do período consolidado |
| `data_fim` | DATE | NÃO | Fim do período consolidado |
| `data_conclusao` | TIMESTAMP | SIM | Data de conclusão |
| `justificativa_conclusao` | LONGVARCHAR | SIM | Justificativa do período |
| `plano_trabalho_id` | CHAR(36) | NÃO | FK → `planos_trabalhos` |
| `avaliacao_id` | CHAR(36) | SIM | FK → `avaliacoes` |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

**Distribuição por `status`:** AVALIADO: 23.247 · INCLUIDO: 16.852 · CONCLUIDO: 781

---

### 4.3 Afastamentos e Ocorrências

| Tabela | Descrição | Total | Ativos |
| --- | --- | --- | --- |
| `afastamentos` | Ausências do servidor | 7.456 | 7.159 |
| `ocorrencias` | Eventos de desvio/impedimento | — | — |
| `comparecimentos` | Registros de presença | — | — |

**Campos de `afastamentos` (10 colunas):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `data_inicio` | TIMESTAMP | NÃO | Início do afastamento |
| `data_fim` | TIMESTAMP | NÃO | Fim do afastamento |
| `horas` | INTEGER | SIM | Horas de afastamento (quando parcial) |
| `observacoes` | LONGVARCHAR | SIM | Observações |
| `usuario_id` | CHAR(36) | NÃO | FK → `usuarios` |
| `tipo_motivo_afastamento_id` | CHAR(36) | NÃO | FK → `tipos_motivos_afastamentos` |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

---

### 4.4 Feriados

| Tabela | Descrição | Total |
| --- | --- | --- |
| `feriados` | Feriados nacionais cadastrados | 9 |

**Campos de `feriados` (15 colunas):**

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `id` | CHAR(36) | UUID |
| `nome` | VARCHAR(250) | Nome do feriado |
| `dia` | INTEGER | Dia do mês |
| `mes` | INTEGER | Mês |
| `ano` | INTEGER | Ano (NULL = feriado recorrente anualmente) |
| `tipodia` | CHAR(6) | `MES` para todos os nacionais |
| `recorrente` | TINYINT | 0 para todos (usa `ano=NULL` para indicar recorrência) |
| `abrangencia` | CHAR(9) | NACIONAL \| ESTADUAL \| MUNICIPAL |
| `uf` | VARCHAR(2) | UF (para feriados estaduais) |
| `codigo_ibge` | VARCHAR(8) | Código IBGE da cidade (para municipais) |
| `entidade_id` / `cidade_id` | CHAR(36) | Escopo do feriado |

**Feriados cadastrados:**

| Feriado | Dia/Mês |
| --- | --- |
| Confraternização Universal | 01/01 |
| Tiradentes | 21/04 |
| Dia Mundial do Trabalho | 01/05 |
| Independência do Brasil | 07/09 |
| Nossa Senhora Aparecida | 12/10 |
| Finados | 02/11 |
| Proclamação da República | 15/11 |
| Natal | 25/12 |
| Natal2 _(registro duplicado)_ | 25/12 |

> **Atenção:** apenas 8 feriados únicos (Natal aparece duplicado). Feriados móveis (Carnaval, Corpus Christi, Sexta-feira Santa) **não estão cadastrados**. Considere isso nas queries de I07/I08 que calculam dias úteis.

---

## 5. Camada 4: Avaliação & Resultado

### 5.1 Avaliações

| Tabela | Descrição | Total |
| --- | --- | --- |
| `avaliacoes` | Avaliação de PT ou PE | 26.931 |
| `avaliacoes_entregas_checklist` | Checklist de avaliação de entrega | — |

**Campos de `avaliacoes` (15 colunas):**

| Campo | Tipo | Nulo | Descrição |
| --- | --- | --- | --- |
| `id` | CHAR(36) | NÃO | UUID |
| `data_avaliacao` | TIMESTAMP | NÃO | Data da avaliação |
| `nota` | LONGVARCHAR | NÃO | Nota/conceito atribuído (JSON ou texto) |
| `justificativa` | LONGVARCHAR | SIM | Justificativa narrativa |
| `justificativas` | LONGVARCHAR | NÃO | Justificativas estruturadas (JSON) |
| `recurso` | LONGVARCHAR | SIM | Texto do recurso (se houver) |
| `data_recurso` | TIMESTAMP | SIM | Data do recurso |
| `avaliador_id` | CHAR(36) | NÃO | FK → `usuarios` (quem avaliou) |
| `plano_trabalho_consolidacao_id` | CHAR(36) | SIM | FK → `planos_trabalhos_consolidacoes` (se avaliação de PT) |
| `plano_entrega_id` | CHAR(36) | SIM | FK → `planos_entregas` (se avaliação de PE) |
| `tipo_avaliacao_id` | CHAR(36) | NÃO | FK → `tipos_avaliacoes` |
| `tipo_avaliacao_nota_id` | CHAR(36) | SIM | FK → `tipos_avaliacoes_notas` (conceito estruturado) |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | SIM | Auditoria |

> O campo `nota` é LONGVARCHAR — pode conter JSON com a nota ou texto livre. Para os indicadores I09–I12, use o join com `tipos_avaliacoes_notas` via `tipo_avaliacao_nota_id` para obter o conceito estruturado (`sequencia`: 1–5).

---

## 6. Padrões de Design do Banco

### 6.1 Soft-Delete

Quase todas as tabelas de negócio têm `deleted_at` (TIMESTAMP):

```sql
deleted_at IS NULL        -- registros ativos
deleted_at IS NOT NULL    -- excluídos logicamente
```

Dados nunca são apagados fisicamente. **Sempre filtrar** `deleted_at IS NULL` nas queries de indicadores.

---

### 6.2 Timestamps de Auditoria

Padrão universal em todas as tabelas:

```text
created_at  TIMESTAMP NULL    -- quando foi criado
updated_at  TIMESTAMP NULL    -- última modificação
deleted_at  TIMESTAMP NULL    -- quando foi excluído (soft-delete)
```

Exceção: `planos_trabalhos_consolidacoes` usa `DATE` (não `TIMESTAMP`) para `data_inicio` e `data_fim`.

---

### 6.3 UUID como Chave Primária

Todas as tabelas usam `id CHAR(36)` em formato UUID:

```text
550e8400-e29b-41d4-a716-446655440000
```

Não há chaves primárias numéricas auto-incrementadas — os relacionamentos são sempre por UUID.

---

### 6.4 Status como CHAR (não ENUM)

O Denodo expõe os campos de status como `CHAR`, mas os valores seguem enumerações fixas:

| Tabela | Valores de `status` |
| --- | --- |
| `planos_entregas` | INCLUIDO, HOMOLOGANDO, ATIVO, CONCLUIDO, AVALIADO, SUSPENSO, CANCELADO |
| `planos_trabalhos` | INCLUIDO, AGUARDANDO_ASSINATURA, ATIVO, CONCLUIDO, AVALIADO, SUSPENSO, CANCELADO |
| `planos_trabalhos_consolidacoes` | INCLUIDO, CONCLUIDO, AVALIADO |
| `atividades` | INCLUIDO, INICIADO, CONCLUIDO |

---

### 6.5 Campos JSON (LONGVARCHAR)

Vários campos armazenam estruturas JSON em LONGVARCHAR. **Não fazer parse desses campos nas queries de indicadores** — use apenas os campos escalares:

| Tabela | Campos JSON |
| --- | --- |
| `planos_entregas_entregas` | `meta`, `realizado`, `checklist`, `etiquetas` |
| `planos_trabalhos` | `criterios_avaliacao` |
| `planos_trabalhos_entregas` | `meta` |
| `avaliacoes` | `nota`, `justificativas` |
| `programas` | `config`, `plano_trabalho_criterios_avaliacao` |
| `unidades` | `expediente`, `etiquetas`, `checklist`, `notificacoes` |
| `usuarios` | `config`, `notificacoes`, `metadados` |

---

### 6.6 DECIMAL(5,2) para Métricas

Campos de progresso e dedicação usam precisão de 2 casas decimais:

| Campo | Tabela | Escala | Exemplo |
| --- | --- | --- | --- |
| `progresso_esperado` | `planos_entregas_entregas` | 0–100+ | 100.00 |
| `progresso_realizado` | `planos_entregas_entregas` | 0–100+ | 75.00 |
| `forca_trabalho` | `planos_trabalhos_entregas` | 0–100 | 20.00 |
| `progresso` | `atividades` | 0–100 | 50.00 |

---

## 7. Tabelas Críticas para os Indicadores OCDE/PGD

```text
I01 — Proporção por regime de trabalho
└── planos_trabalhos
    ├── tipo_modalidade_id (FK → tipos_modalidades)
    ├── usuario_id (FK → usuarios)
    ├── unidade_id
    └── data_inicio, data_fim, status, deleted_at

I02, I03, I04 — Cumprimento de entregas e atingimento de metas
└── planos_entregas_entregas
    ├── progresso_esperado (meta planejada)
    ├── progresso_realizado (meta executada)
    ├── plano_entrega_id (FK → planos_entregas → unidade_id)
    └── deleted_at
    JOIN planos_entregas (status, data_inicio, data_fim)
    JOIN unidades (sigla)

I05, I06 — Distribuição de entregas entre servidores
└── planos_trabalhos_entregas
    ├── forca_trabalho (% dedicação)
    ├── plano_trabalho_id (FK → planos_trabalhos → usuario_id, unidade_id)
    └── plano_entrega_entrega_id (FK → planos_entregas_entregas)

I07, I08 — Horas por entrega (VERIFICAR COMPATIBILIDADE COM DENODO VQL)
└── planos_trabalhos_entregas
    ├── forca_trabalho (% dedicação)
    └── plano_trabalho_id (FK → planos_trabalhos → carga_horaria, data_inicio, data_fim)
    ⚠ Não existem campos quantidade/horas_por_unidade — calcular via carga_horaria × forca_trabalho
    ⚠ CTEs recursivas (usadas nas queries atuais) precisam de verificação no Denodo VQL

I09, I10, I11, I12 — Avaliações
└── avaliacoes
    ├── tipo_avaliacao_nota_id (FK → tipos_avaliacoes_notas → sequencia 1–5)
    ├── tipo_avaliacao_id (FK → tipos_avaliacoes → PT ou PE)
    ├── plano_trabalho_consolidacao_id (FK → planos_trabalhos_consolidacoes → plano_trabalho_id)
    └── plano_entrega_id (FK → planos_entregas → unidade_id)
```

---

## 8. Contagem de Registros — Dados em Tempo Real (15.05.2026)

| Tabela | Total | Ativos (`deleted_at IS NULL`) | Δ vs. dump fev/2026 |
| --- | --- | --- | --- |
| `planos_entregas_entregas` | 18.831 | 18.060 | +3.333 ativos (+23%) |
| `planos_entregas` | 1.634 | 1.436 | — |
| `planos_trabalhos` | 14.168 | 14.168 | — |
| `planos_trabalhos_entregas` | 69.208 | 64.925 | — |
| `usuarios` | 7.403 | 7.403 | — |
| `unidades` | 811 | 811 | — |
| `avaliacoes` | 26.931 | 26.931 | — |
| `atividades` | 141.724 | 139.607 | — |
| `afastamentos` | 7.456 | 7.159 | — |
| `planos_trabalhos_consolidacoes` | 40.880 | 28.302 | — |
| `feriados` | 9 | 9 | — |

---

## 9. Diagrama ER — Tabelas Críticas

```text
programas ──────────────────────────────────────────────────────────┐
├── id (PK)                                                         │
├── nome, normativa, data_inicio, data_fim                          │
├── periodicidade_consolidacao, dias_tolerancia_*                   │
└── unidade_id (FK → unidades)                    ┌── referenciado ─┘
                                                   │
usuarios                                           │
├── id (PK)                                        │
├── nome, cpf, matricula, ident_unica              │
├── situacao_siape, situacao_funcional              │
├── participa_pgd                                  │
└── tipo_modalidade_id (FK → tipos_modalidades)    │
                                                   │
unidades ──────────────────────────────────────────┘
├── id (PK)
├── sigla, nome, path (hierarquia)
├── unidade_pai_id (FK → unidades) [AUTORREFERÊNCIA]
├── executora, informal
└── entidade_id (FK → entidades)

planos_entregas
├── id (PK)
├── numero, nome, status
├── data_inicio, data_fim, avaliado_at
├── unidade_id (FK → unidades)
├── programa_id (FK → programas)
├── planejamento_id (FK → planejamentos)
└── deleted_at

planos_entregas_entregas  ← METAS
├── id (PK)
├── descricao, descricao_entrega, descricao_meta
├── progresso_esperado, progresso_realizado   ← CRITÉRIO OCDE
├── destinatario
├── data_inicio, data_fim, homologado
├── meta, realizado (JSON)
├── plano_entrega_id (FK → planos_entregas)
├── entrega_id (FK → entregas)               ← template de catálogo
├── entrega_pai_id (FK → planos_entregas_entregas) [HIERARQUIA]
├── unidade_id (FK → unidades)
└── deleted_at

planos_trabalhos
├── id (PK)
├── numero, status, forma_contagem_carga_horaria
├── carga_horaria, tempo_total, tempo_proporcional
├── data_inicio, data_fim, avaliado_at
├── usuario_id (FK → usuarios)
├── unidade_id (FK → unidades)
├── programa_id (FK → programas)
├── tipo_modalidade_id (FK → tipos_modalidades)
└── deleted_at

planos_trabalhos_entregas  ← VÍNCULO SERVIDOR × ENTREGA
├── id (PK)
├── forca_trabalho (% dedicação 0–100)
├── descricao, meta (JSON), orgao
├── plano_trabalho_id (FK → planos_trabalhos)
├── plano_entrega_entrega_id (FK → planos_entregas_entregas) [nullable]
└── deleted_at

planos_trabalhos_consolidacoes
├── id (PK)
├── status, data_inicio (DATE), data_fim (DATE)
├── data_conclusao, justificativa_conclusao
├── plano_trabalho_id (FK → planos_trabalhos)
├── avaliacao_id (FK → avaliacoes)
└── deleted_at

avaliacoes
├── id (PK)
├── data_avaliacao
├── nota (LONGVARCHAR — JSON)
├── justificativa, justificativas (JSON), recurso
├── avaliador_id (FK → usuarios)
├── plano_trabalho_consolidacao_id (FK → planos_trabalhos_consolidacoes) [nullable]
├── plano_entrega_id (FK → planos_entregas) [nullable]
├── tipo_avaliacao_id (FK → tipos_avaliacoes)
├── tipo_avaliacao_nota_id (FK → tipos_avaliacoes_notas) [nullable]
└── deleted_at
```

---

## 10. Descobertas vs. Versão Dump (mudanças relevantes)

| Aspecto | Versão dump (até 14.05.2026) | Versão Denodo (atual) |
| --- | --- | --- |
| Total de tabelas | 130+ | **123** |
| Nome das tabelas | `planos_entregas_entregas` | `petrvs_icmbio_planos_entregas_entregas` |
| Ativos em `planos_entregas_entregas` | 14.727 | **18.060** (+23%) |
| Campo `descricao_entrega` | Sem certeza de existência | Confirmado: LONGVARCHAR NOT NULL |
| Campo `descricao_meta` | Não documentado | **Novo:** LONGVARCHAR NOT NULL |
| Campo `entrega_id` em PEE | Não documentado | **Confirmado:** FK → catálogo `entregas` |
| `planos_trabalhos_entregas` | Mencionava `quantidade × horas_por_unidade` | Apenas `forca_trabalho` (10 colunas total) |
| Função `DATE()` em SQL | Compatível com MySQL | **Incompatível com Denodo** — usar `CAST('...' AS DATE)` |
| `SET SESSION cte_max_recursion_depth` | Necessário no MySQL | **Não existe no Denodo VQL** |
| `progresso_esperado` / `progresso_realizado` | DECIMAL(5,2) | DECIMAL(5,2) — confirmado |
| Coluna `data_inicio`/`data_fim` em PEE | Tipo inferido | **TIMESTAMP** (não DATE) |
| Coluna `data_inicio`/`data_fim` em consolidações | Não documentado | **DATE** (não TIMESTAMP) |
