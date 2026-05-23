-- =========================================================
-- I07 — Horas planejadas por entrega (absoluto)
-- Eixo 3 — Carga de Trabalho
-- =========================================================
-- Tabelas : planos_trabalhos, planos_trabalhos_entregas,
--           planos_entregas_entregas, planos_entregas, unidades
-- Conexão : Denodo via DBeaver (sem prefixo petrvs_icmbio_)
-- Revisado: 23.05.2026
-- =========================================================
-- REESCRITA SEM WITH RECURSIVE
--   A versão anterior usava WITH RECURSIVE + date_add + dayofweek (MySQL 8.0+),
--   incompatíveis com Denodo VQL. Esta versão usa GETDAYSBETWEEN para
--   calcular a sobreposição em dias calendário e aplica fator 5/7 para
--   estimar dias úteis (sem desconto de feriados, precisão ±5%).
--
-- FUNÇÃO DE DATA: GETDAYSBETWEEN(date1, date2)
--   Função nativa do Denodo VQL — retorna (date2 - date1) em dias.
--   Se retornar erro, substitua por: CAST(date2 AS BIGINT) - CAST(date1 AS BIGINT)
--   ou consulte o suporte Dataprev para a função equivalente no driver instalado.
--
-- FÓRMULA:
--   dias_calendario = GREATEST(0, GETDAYSBETWEEN(inicio_overlap, fim_overlap) + 1)
--   dias_uteis_aprox = ROUND(dias_calendario * 5.0 / 7.0)
--   horas_plano = dias_uteis_aprox * horas_por_dia
--   horas_entrega = horas_plano * (forca_trabalho / 100)
--
-- CAMPO forca_trabalho: percentual (0–100) do tempo do servidor dedicado à entrega
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
-- Horas planejadas por plano de trabalho no período filtrado (aproximação sem feriados)
planos_horas AS (
    SELECT
        pt.id         AS plano_trabalho_id,
        pt.unidade_id,
        -- Dias de sobreposição entre o PT e o período de análise
        GREATEST(
            GETDAYSBETWEEN(
                GREATEST(CAST(pt.data_inicio AS DATE), p.data_inicio),
                LEAST(CAST(pt.data_fim   AS DATE), p.data_fim)
            ) + 1,
            0
        ) * 5.0 / 7.0 * p.horas_por_dia AS horas_planejadas_plano
        -- Nota: fator 5/7 aproxima dias úteis sem gerar calendário recursivo
    FROM planos_trabalhos pt
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
        pte.plano_entrega_entrega_id AS id_entrega,
        COALESCE(
            NULLIF(TRIM(pee.descricao), ''),
            NULLIF(TRIM(pee.descricao_entrega), ''),
            'N.I.'
        )                            AS nome_entrega,
        pe.id                        AS id_plano_entrega,
        CAST(pe.data_inicio AS DATE) AS inicio_vigencia_pe,
        CAST(pe.data_fim    AS DATE) AS fim_vigencia_pe,
        ph.horas_planejadas_plano * (COALESCE(pte.forca_trabalho, 0) / 100.0) AS horas_alocadas
    FROM planos_trabalhos_entregas pte
    JOIN planos_horas ph
        ON ph.plano_trabalho_id = pte.plano_trabalho_id
    LEFT JOIN planos_entregas_entregas pee
        ON pee.id = pte.plano_entrega_entrega_id
    LEFT JOIN planos_entregas pe
        ON pe.id = pee.plano_entrega_id
    LEFT JOIN unidades un
        ON un.id = ph.unidade_id
    WHERE pte.plano_entrega_entrega_id IS NOT NULL
)
SELECT
    unidade_sigla,
    unidade_nome,
    id_entrega,
    nome_entrega,
    id_plano_entrega,
    inicio_vigencia_pe,
    fim_vigencia_pe,
    ROUND(SUM(horas_alocadas), 2) AS total_horas_planejadas_entrega
FROM horas_por_entrega
GROUP BY
    unidade_sigla, unidade_nome, id_entrega, nome_entrega,
    id_plano_entrega, inicio_vigencia_pe, fim_vigencia_pe
ORDER BY unidade_sigla, total_horas_planejadas_entrega DESC;
