-- =========================================================
-- I01 — Proporção de servidores por regime de trabalho
-- Eixo 1 — Trabalho Remoto
-- =========================================================
-- Tabelas : planos_trabalhos, usuarios, integracao_servidores, unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Datas   : CAST('...' AS DATE) — DATE() não funciona no Denodo
-- Revisado: 23.05.2026
-- =========================================================
-- NOTA TÉCNICA (confirmada em 23.05.2026)
--   A view tipos_modalidades está inacessível no Denodo.
--   O campo de modalidade é obtido via integracao_servidores.modalidade_pgd
--   (campo SIAPE/PGD), acessado pelo join: planos_trabalhos → usuarios (id=usuario_id)
--   → integracao_servidores (cpf=cpf). Os valores retornados são os códigos
--   do PGD Nacional — verificar os valores reais no banco antes de interpretar.
-- =========================================================
-- COMO USAR
-- 1. Ajuste data_inicio e data_fim no bloco "parametros"
-- 2. Execute a VARIANTE 1 OU a VARIANTE 2 separadamente (Ctrl+A Ctrl+Enter)
-- incluir_excluidos: 0 = só ativos | 1 = inclui deleted_at
-- =========================================================


-- ---------------------------------------------------------
-- VARIANTE 1 — Visão geral do órgão
-- Pergunta: qual a proporção de servidores por regime no ICMBio?
-- Resultado: 1 linha por modalidade; proporção sobre o total geral
-- ---------------------------------------------------------

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CURRENT_DATE               AS data_fim,
        0                          AS incluir_excluidos
),
-- Servidor distinto por modalidade (evita dupla contagem se tiver 2 PTs no período)
servidores_no_periodo AS (
    SELECT DISTINCT
        pt.usuario_id,
        COALESCE(ins.modalidade_pgd, 'N.I.') AS modalidade
    FROM petrvs_icmbio_planos_trabalhos pt
    JOIN  petrvs_icmbio_usuarios u
        ON  u.id  = pt.usuario_id
    JOIN  petrvs_icmbio_integracao_servidores ins
        ON  ins.cpf = u.cpf
    CROSS JOIN parametros p
    WHERE CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
      AND pt.usuario_id IS NOT NULL
),
contagem_por_regime AS (
    SELECT
        modalidade,
        COUNT(DISTINCT usuario_id) AS total_servidores
    FROM servidores_no_periodo
    GROUP BY modalidade
)
SELECT
    modalidade,
    total_servidores,
    ROUND(
        total_servidores * 100.0
            / NULLIF(SUM(total_servidores) OVER (), 0),
        2
    ) AS proporcao_perc
FROM contagem_por_regime
ORDER BY total_servidores DESC;


-- ---------------------------------------------------------
-- VARIANTE 2 — Por unidade organizacional
-- Pergunta: como o perfil de regime varia entre unidades?
-- Resultado: 1 linha por unidade × modalidade; proporção dentro de cada unidade
-- ---------------------------------------------------------

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CURRENT_DATE               AS data_fim,
        0                          AS incluir_excluidos
),
servidores_por_unidade AS (
    SELECT DISTINCT
        COALESCE(un.sigla, 'N.I.') AS unidade_sigla,
        COALESCE(un.nome,  'N.I.') AS unidade_nome,
        pt.usuario_id,
        COALESCE(ins.modalidade_pgd, 'N.I.') AS modalidade
    FROM petrvs_icmbio_planos_trabalhos pt
    JOIN  petrvs_icmbio_usuarios u
        ON  u.id  = pt.usuario_id
    JOIN  petrvs_icmbio_integracao_servidores ins
        ON  ins.cpf = u.cpf
    LEFT JOIN petrvs_icmbio_unidades un
        ON  un.id = pt.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
      AND pt.usuario_id IS NOT NULL
),
contagem AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)          AS unidade_nome,
        modalidade,
        COUNT(DISTINCT usuario_id) AS total_servidores
    FROM servidores_por_unidade
    GROUP BY unidade_sigla, modalidade
)
SELECT
    unidade_sigla,
    unidade_nome,
    modalidade,
    total_servidores,
    ROUND(
        total_servidores * 100.0
            / NULLIF(SUM(total_servidores) OVER (PARTITION BY unidade_sigla), 0),
        2
    ) AS proporcao_na_unidade_perc
FROM contagem
ORDER BY unidade_sigla, total_servidores DESC;
