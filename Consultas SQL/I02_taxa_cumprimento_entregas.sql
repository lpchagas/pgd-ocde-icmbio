-- =========================================================
-- I02 — Taxa de cumprimento das entregas (por unidade)
-- Eixo 2 — Execução
-- =========================================================
-- Tabelas : planos_entregas, planos_entregas_entregas, unidades
-- Conexão : Denodo via DBeaver (sem prefixo petrvs_icmbio_)
-- Validado: 11.05.2026 — IND_02_resposta_tecnica_11.05.2026.md
-- Revisado: 23.05.2026
-- =========================================================
-- CRITÉRIO OCDE: concluída = progresso_realizado >= progresso_esperado
-- ESCOPO: entregas de PE com SOBREPOSIÇÃO ao período filtrado
--         (diferente do I03, que filtra por pee.data_fim — prazo individual)
-- DENOMINADOR: entregas com progresso_esperado > 0 e NOT NULL
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Universo total por unidade (inclui entregas sem meta) — para rastreabilidade
universo_bruto AS (
    SELECT
        u.sigla     AS unidade_sigla,
        MIN(u.nome) AS unidade_nome,
        COUNT(*)    AS total_cadastradas
    FROM planos_entregas pe
    JOIN planos_entregas_entregas pee
        ON pee.plano_entrega_id = pe.id
    JOIN unidades u
        ON u.id = pe.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pe.data_inicio AS DATE) <= p.data_fim
      AND CAST(pe.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pe.deleted_at  IS NULL)
      AND (p.incluir_excluidos = 1 OR pee.deleted_at IS NULL)
    GROUP BY u.sigla
),
-- Entregas com meta válida: base do indicador
entregas_ciclo AS (
    SELECT
        u.sigla                              AS unidade_sigla,
        u.nome                               AS unidade_nome,
        pee.id                               AS id_entrega,
        pee.progresso_esperado               AS meta_planejada,
        COALESCE(pee.progresso_realizado, 0) AS meta_executada,
        CASE
            WHEN CAST(pee.data_fim AS DATE) BETWEEN p.data_inicio AND p.data_fim
            THEN 1 ELSE 0
        END                                  AS vence_no_periodo
    FROM planos_entregas pe
    JOIN planos_entregas_entregas pee
        ON pee.plano_entrega_id = pe.id
    JOIN unidades u
        ON u.id = pe.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pe.data_inicio AS DATE) <= p.data_fim
      AND CAST(pe.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pe.deleted_at  IS NULL)
      AND (p.incluir_excluidos = 1 OR pee.deleted_at IS NULL)
      AND pee.progresso_esperado IS NOT NULL
      AND pee.progresso_esperado > 0
),
-- Agregação por unidade
resumo AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)                                                 AS unidade_nome,
        COUNT(*)                                                          AS total_no_ciclo,
        SUM(vence_no_periodo)                                             AS total_vence_no_periodo,
        SUM(CASE WHEN meta_executada >= meta_planejada THEN 1 ELSE 0 END) AS total_concluidas,
        ROUND(
            SUM(CASE WHEN meta_executada >= meta_planejada THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0) * 100,
            2
        )                                                                 AS taxa_cumprimento_perc
    FROM entregas_ciclo
    GROUP BY unidade_sigla
)
SELECT
    r.unidade_sigla,
    r.unidade_nome,
    b.total_cadastradas,
    r.total_no_ciclo,
    r.total_vence_no_periodo,
    ROUND(r.total_vence_no_periodo * 100.0 / NULLIF(r.total_no_ciclo, 0), 1) AS proporcao_vence_no_periodo_perc,
    r.total_concluidas,
    r.taxa_cumprimento_perc,
    CASE
        WHEN r.taxa_cumprimento_perc >= 90 THEN 'A - Alto desempenho'
        WHEN r.taxa_cumprimento_perc >= 70 THEN 'B - Bom desempenho'
        WHEN r.taxa_cumprimento_perc >= 50 THEN 'C - Desempenho intermediario'
        ELSE                                    'D - Baixo desempenho'
    END AS grupo_performance
FROM resumo r
LEFT JOIN universo_bruto b
    ON b.unidade_sigla = r.unidade_sigla
ORDER BY r.taxa_cumprimento_perc DESC, r.unidade_sigla;
