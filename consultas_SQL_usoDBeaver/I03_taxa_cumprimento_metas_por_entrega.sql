-- =========================================================
-- I03 — Taxa de cumprimento de metas por entrega
-- Eixo 2 — Execução
-- =========================================================
-- Tabelas : planos_entregas, planos_entregas_entregas, unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Validado: 17.05.2026 — IND_03.5_relatorio_validacao_17.05.2026.md
-- Revisado: 23.05.2026
-- =========================================================
-- FILTRO DE DATA: pee.data_fim (prazo individual da entrega)
--   Responde: "como foram as entregas que VENCERAM neste período?"
--   Diferente do I02/I04 que usam sobreposição do ciclo PE completo.
--   Não comparar taxas entre períodos de durações diferentes (trimestre vs. quadrimestre).
-- DENOMINADOR: entregas com pee.data_fim no período E progresso_esperado > 0
-- APROVAÇÃO CGOV (17.05.2026): dupla abordagem registrada — denominador padrão OCDE mantido
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Entregas cujo prazo individual cai dentro do período
entregas_base AS (
    SELECT
        u.sigla                                                    AS unidade_sigla,
        u.nome                                                     AS unidade_nome,
        pee.id                                                     AS id_entrega,
        COALESCE(
            NULLIF(TRIM(pee.descricao), ''),
            NULLIF(TRIM(pee.descricao_entrega), ''),
            'N.I.'
        )                                                          AS nome_entrega,
        COALESCE(NULLIF(TRIM(pee.descricao_entrega), ''), 'N.I.') AS descricao_entrega,
        pee.progresso_esperado                                     AS meta_planejada,
        COALESCE(pee.progresso_realizado, 0)                       AS meta_executada
    FROM petrvs_icmbio_planos_entregas pe
    JOIN petrvs_icmbio_planos_entregas_entregas pee
        ON pee.plano_entrega_id = pe.id
    JOIN petrvs_icmbio_unidades u
        ON u.id = pe.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pee.data_fim AS DATE) BETWEEN p.data_inicio AND p.data_fim
      AND (p.incluir_excluidos = 1 OR pe.deleted_at  IS NULL)
      AND (p.incluir_excluidos = 1 OR pee.deleted_at IS NULL)
      AND pee.progresso_esperado IS NOT NULL
      AND pee.progresso_esperado > 0
),
-- Taxa de atingimento por entrega
entregas_com_taxa AS (
    SELECT
        unidade_sigla,
        unidade_nome,
        id_entrega,
        nome_entrega,
        descricao_entrega,
        meta_planejada,
        meta_executada,
        ROUND(
            meta_executada / NULLIF(meta_planejada, 0) * 100,
            2
        ) AS taxa_atingimento_perc
    FROM entregas_base
)
SELECT
    unidade_sigla,
    unidade_nome,
    id_entrega,
    nome_entrega,
    descricao_entrega,
    meta_planejada,
    meta_executada,
    taxa_atingimento_perc,
    CASE
        WHEN taxa_atingimento_perc >  100 THEN 'Superexecutada'
        WHEN taxa_atingimento_perc =  100 THEN 'Concluida'
        WHEN taxa_atingimento_perc >=  70 THEN 'Parcialmente cumprida'
        WHEN taxa_atingimento_perc >    0 THEN 'Em andamento'
        ELSE                                   'Nao executada'
    END AS status_entrega
FROM entregas_com_taxa
ORDER BY unidade_sigla, taxa_atingimento_perc DESC;
