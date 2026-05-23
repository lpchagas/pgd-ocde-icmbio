-- =========================================================
-- I08 — Proporção de horas planejadas por entrega (%)
-- Eixo 3 — Carga de Trabalho
-- =========================================================
-- Tabelas : planos_trabalhos, planos_trabalhos_entregas,
--           planos_entregas_entregas, unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Revisado: 23.05.2026
-- =========================================================
-- RELAÇÃO COM O I07:
--   I07 → horas absolutas por entrega
--   I08 → % das horas totais da unidade que cada entrega representa
-- REESCRITA SEM WITH RECURSIVE (mesma abordagem do I07):
--   GETDAYSBETWEEN + fator 5/7 para dias úteis aproximados.
--   Ver comentários do I07_horas_por_entrega_absoluto.sql para detalhes.
-- =========================================================
-- COMO USAR: ajuste data_inicio, data_fim e horas_por_dia no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        8.0                        AS horas_por_dia,    -- horas por dia útil (padrão APF: 8h)
        0                          AS incluir_excluidos -- 0=só ativos | 1=inclui excluídos
),
-- Horas planejadas por plano de trabalho no período filtrado
planos_horas AS (
    SELECT
        pt.id         AS plano_trabalho_id,
        pt.unidade_id,
        GREATEST(
            GETDAYSBETWEEN(
                GREATEST(CAST(pt.data_inicio AS DATE), p.data_inicio),
                LEAST(CAST(pt.data_fim   AS DATE), p.data_fim)
            ) + 1,
            0
        ) * 5.0 / 7.0 * p.horas_por_dia AS horas_planejadas_plano
    FROM petrvs_icmbio_planos_trabalhos pt
    CROSS JOIN parametros p
    WHERE CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
),
-- Horas alocadas por entrega via força de trabalho
horas_por_entrega AS (
    SELECT
        COALESCE(un.sigla, 'N.I.')   AS unidade_sigla,
        COALESCE(un.nome,  'N.I.')   AS unidade_nome,
        COALESCE(
            NULLIF(TRIM(pee.descricao), ''),
            NULLIF(TRIM(pee.descricao_entrega), ''),
            'N.I.'
        )                            AS nome_entrega,
        COALESCE(NULLIF(TRIM(pee.descricao_entrega), ''), 'N.I.') AS descricao_entrega,
        ph.horas_planejadas_plano * (COALESCE(pte.forca_trabalho, 0) / 100.0) AS horas_alocadas
    FROM petrvs_icmbio_planos_trabalhos_entregas pte
    JOIN planos_horas ph
        ON ph.plano_trabalho_id = pte.plano_trabalho_id
    LEFT JOIN petrvs_icmbio_planos_entregas_entregas pee
        ON pee.id = pte.plano_entrega_entrega_id
    LEFT JOIN petrvs_icmbio_unidades un
        ON un.id = ph.unidade_id
    WHERE pte.plano_entrega_entrega_id IS NOT NULL
),
-- Total de horas disponíveis por unidade (denominador do percentual)
capacidade_unidade AS (
    SELECT
        COALESCE(un.sigla, 'N.I.')      AS unidade_sigla,
        SUM(ph.horas_planejadas_plano)  AS total_horas_disponiveis_unidade
    FROM planos_horas ph
    LEFT JOIN petrvs_icmbio_unidades un
        ON un.id = ph.unidade_id
    GROUP BY COALESCE(un.sigla, 'N.I.')
)
SELECT
    h.unidade_sigla,
    MIN(h.unidade_nome)                                                         AS unidade_nome,
    h.nome_entrega,
    MIN(h.descricao_entrega)                                                    AS descricao_entrega,
    ROUND(SUM(h.horas_alocadas), 2)                                             AS horas_planejadas_entrega,
    ROUND(c.total_horas_disponiveis_unidade, 2)                                 AS total_horas_disponiveis_unidade,
    ROUND(
        SUM(h.horas_alocadas) / NULLIF(c.total_horas_disponiveis_unidade, 0) * 100,
        2
    )                                                                           AS proporcao_horas_perc
FROM horas_por_entrega h
JOIN capacidade_unidade c
    ON c.unidade_sigla = h.unidade_sigla
GROUP BY h.unidade_sigla, h.nome_entrega, c.total_horas_disponiveis_unidade
ORDER BY h.unidade_sigla, proporcao_horas_perc DESC;
