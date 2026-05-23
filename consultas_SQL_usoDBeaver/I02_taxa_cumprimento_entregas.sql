-- =========================================================
-- I02 — Taxa de cumprimento das entregas (por unidade)
-- Eixo 2 — Execução
-- =========================================================
-- Tabelas : petrvs_icmbio_planos_entregas, petrvs_icmbio_planos_entregas_entregas, petrvs_icmbio_unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Validado: 11.05.2026 — IND_02.5_relatorio_validacao_11.05.2026.md
-- Revisado: 23.05.2026
-- =========================================================
-- CRITÉRIO OCDE: concluída = progresso_realizado >= progresso_esperado
-- ESCOPO: entregas de PE com SOBREPOSIÇÃO ao período filtrado
--         (diferente do I03, que filtra por pee.data_fim — prazo individual)
-- DENOMINADOR: entregas com progresso_esperado > 0 e NOT NULL
-- =========================================================
-- NOTA TEMPORAL (confirmada em 18.05.2026):
--   2025 → ciclos TRIMESTRAIS (T1: Jan–Mar | T2: Abr–Jun | T3: Jul–Set | T4: Out–Dez)
--   2026+ → ciclos QUADRIMESTRAIS (Q1: Jan–Abr | Q2: Mai–Ago | Q3: Set–Dez)
--   Com data_inicio=2025-01-01 e data_fim=CURRENT_DATE a consulta agrega TODOS
--   os ciclos em um único resultado por unidade (visão histórica acumulada).
--   Para análise por ciclo específico, ajuste data_inicio e data_fim manualmente.
--   Não compare taxas entre ciclos de durações diferentes sem ponderação.
-- =========================================================
-- COLUNAS DE TRANSPARÊNCIA (recomendação IND_02.5_relatorio_validacao_11.05.2026.md §6):
--   total_em_plano_avaliado      — entregas em PEs com status AVALIADO ou CONCLUIDO
--   concluidas_em_plano_avaliado — concluídas restritas a PEs avaliados ("visão formal")
--   alerta_avaliacao             — sinaliza quando há entregas em PEs ainda em ATIVO
-- NOTA: a taxa principal (taxa_cumprimento_perc) usa o critério OCDE e inclui
--   entregas de planos ATIVO. Use concluidas_em_plano_avaliado para a visão formal.
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CURRENT_DATE               AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Universo total por unidade (inclui entregas sem meta) — para rastreabilidade
universo_bruto AS (
    SELECT
        u.sigla     AS unidade_sigla,
        MIN(u.nome) AS unidade_nome,
        COUNT(*)    AS total_cadastradas
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
    GROUP BY u.sigla
),
-- Entregas com meta válida: base do indicador
-- plano_avaliado: flag 1 quando PE está em AVALIADO ou CONCLUIDO (visão formal do sistema)
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
        END                                  AS vence_no_periodo,
        CASE
            WHEN pe.status IN ('AVALIADO', 'CONCLUIDO') THEN 1 ELSE 0
        END                                  AS plano_avaliado
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
-- Agregação por unidade
resumo AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)                                                           AS unidade_nome,
        COUNT(*)                                                                    AS total_no_ciclo,
        SUM(vence_no_periodo)                                                       AS total_vence_no_periodo,
        SUM(CASE WHEN meta_executada >= meta_planejada THEN 1 ELSE 0 END)           AS total_concluidas,
        -- * 100.0 antes da divisão força aritmética de ponto flutuante no Denodo VQL
        ROUND(
            SUM(CASE WHEN meta_executada >= meta_planejada THEN 1 ELSE 0 END)
                * 100.0 / NULLIF(COUNT(*), 0),
            2
        )                                                                           AS taxa_cumprimento_perc,
        SUM(plano_avaliado)                                                         AS total_em_plano_avaliado,
        SUM(CASE WHEN plano_avaliado = 1 AND meta_executada >= meta_planejada
                 THEN 1 ELSE 0 END)                                                 AS concluidas_em_plano_avaliado
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
    r.total_em_plano_avaliado,
    r.concluidas_em_plano_avaliado,
    CASE
        WHEN r.taxa_cumprimento_perc >= 90 THEN 'A - Alto desempenho'
        WHEN r.taxa_cumprimento_perc >= 70 THEN 'B - Bom desempenho'
        WHEN r.taxa_cumprimento_perc >= 50 THEN 'C - Desempenho intermediario'
        ELSE                                    'D - Baixo desempenho'
    END AS grupo_performance,
    CASE
        WHEN r.total_no_ciclo > r.total_em_plano_avaliado
        THEN 'atencao: ha entregas em planos nao avaliados'
        ELSE 'ciclo avaliado'
    END AS alerta_avaliacao
FROM resumo r
LEFT JOIN universo_bruto b
    ON b.unidade_sigla = r.unidade_sigla
ORDER BY r.taxa_cumprimento_perc DESC, r.unidade_sigla;
