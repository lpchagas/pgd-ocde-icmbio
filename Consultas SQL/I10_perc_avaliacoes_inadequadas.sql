-- =========================================================
-- I10 — Percentual de avaliações inadequadas (nota 2)
-- Eixo 4 — Desempenho e Avaliação
-- =========================================================
-- Tabelas : avaliacoes, planos_trabalhos_consolidacoes,
--           planos_trabalhos, tipos_avaliacoes_notas, unidades
-- Conexão : Denodo via DBeaver (sem prefixo petrvs_icmbio_)
-- Revisado: 23.05.2026
-- =========================================================
-- PRÉ-REQUISITO: confirmar que nota = 2 corresponde a 'Inadequado'
--   no banco (verificar tipos_avaliacoes_notas).
-- MESMA ESTRUTURA DO I09; o filtro muda para nota = 2.
-- LEITURA CONJUNTA COM I11 (excepcionais):
--   alta prevalência de nota 2 + baixa de nota 5 → sinal de alerta.
-- NÍVEIS DE ALERTA:
--   >= 30% Atenção crítica | >= 15% Atenção moderada
--   >=  5% Observação      | <  5% Baixa prevalência
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
avaliacoes_pt AS (
    SELECT
        av.id       AS id_avaliacao,
        pt.unidade_id,
        tan.nota    AS valor_nota
    FROM avaliacoes av
    JOIN planos_trabalhos_consolidacoes ptc
        ON ptc.id = av.plano_trabalho_consolidacao_id
    JOIN planos_trabalhos pt
        ON pt.id = ptc.plano_trabalho_id
    JOIN tipos_avaliacoes_notas tan
        ON tan.id = av.tipo_avaliacao_nota_id
    CROSS JOIN parametros p
    WHERE av.plano_trabalho_consolidacao_id IS NOT NULL
      AND (p.incluir_excluidos = 1 OR av.deleted_at IS NULL)
      AND CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
),
proporcao_por_unidade AS (
    SELECT
        COALESCE(un.sigla, 'N.I.')                                   AS unidade_sigla,
        COALESCE(un.nome,  'N.I.')                                   AS unidade_nome,
        COUNT(avpt.id_avaliacao)                                     AS total_avaliacoes_pt,
        SUM(CASE WHEN avpt.valor_nota = 2 THEN 1 ELSE 0 END)         AS qtd_inadequado,
        ROUND(
            SUM(CASE WHEN avpt.valor_nota = 2 THEN 1 ELSE 0 END)
                / NULLIF(COUNT(avpt.id_avaliacao), 0) * 100,
            2
        )                                                            AS perc_inadequado
    FROM avaliacoes_pt avpt
    LEFT JOIN unidades un
        ON un.id = avpt.unidade_id
    GROUP BY COALESCE(un.sigla, 'N.I.'), COALESCE(un.nome, 'N.I.')
)
SELECT
    unidade_sigla,
    unidade_nome,
    total_avaliacoes_pt,
    qtd_inadequado,
    perc_inadequado,
    CASE
        WHEN perc_inadequado >= 30 THEN 'Atencao critica'
        WHEN perc_inadequado >= 15 THEN 'Atencao moderada'
        WHEN perc_inadequado >=  5 THEN 'Observacao'
        ELSE                           'Baixa prevalencia'
    END AS nivel_alerta
FROM proporcao_por_unidade
ORDER BY perc_inadequado DESC, unidade_sigla;
