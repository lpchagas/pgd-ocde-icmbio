-- =========================================================
-- I04 — Índice de atingimento de metas (score médio por unidade)
-- Eixo 2 — Execução
-- =========================================================
-- Tabelas : planos_entregas, planos_entregas_entregas, unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Revisado: 23.05.2026
-- =========================================================
-- DIFERENÇA EM RELAÇÃO AO I03:
--   I03 — taxa por entrega individual (filtra por pee.data_fim)
--   I04 — score médio por unidade (mesmo escopo do I02: sobreposição do ciclo PE)
--   Portanto total_no_ciclo do I04 deve coincidir com total_no_ciclo do I02.
-- USO DE ABS(): garante que metas expressas como redução (valor negativo)
--   sejam tratadas corretamente na proporção.
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Proporção de atingimento por entrega (0.0 = não executada; 1.0 = 100%; >1 = superexecutada)
entregas_ciclo AS (
    SELECT
        u.sigla                                      AS unidade_sigla,
        u.nome                                       AS unidade_nome,
        pee.id                                       AS id_entrega,
        ABS(COALESCE(pee.progresso_realizado, 0))
            / NULLIF(ABS(pee.progresso_esperado), 0) AS proporcao_atingimento
    FROM petrvs_icmbio_planos_entregas pe
    JOIN petrvs_icmbio_planos_entregas_entregas pee
        ON pee.plano_entrega_id = pe.id
    JOIN petrvs_icmbio_unidades u
        ON u.id = pe.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pe.data_inicio AS DATE) <= p.data_fim
      AND CAST(pe.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pe.deleted_at  IS NULL)
      AND (p.incluir_excluidos = 1 OR pee.deleted_at IS NULL)
      AND pee.progresso_esperado IS NOT NULL
      AND pee.progresso_esperado > 0
),
-- Score médio por unidade (média das proporções × 100)
resumo AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)                          AS unidade_nome,
        COUNT(id_entrega)                          AS total_no_ciclo,
        ROUND(AVG(proporcao_atingimento) * 100, 2) AS score_atingimento_perc
    FROM entregas_ciclo
    GROUP BY unidade_sigla
)
SELECT
    unidade_sigla,
    unidade_nome,
    total_no_ciclo,
    score_atingimento_perc,
    CASE
        WHEN score_atingimento_perc >= 90 THEN 'A - Alto desempenho'
        WHEN score_atingimento_perc >= 70 THEN 'B - Bom desempenho'
        WHEN score_atingimento_perc >= 50 THEN 'C - Desempenho intermediario'
        ELSE                                   'D - Baixo desempenho'
    END AS grupo_performance
FROM resumo
ORDER BY score_atingimento_perc DESC, unidade_sigla;
