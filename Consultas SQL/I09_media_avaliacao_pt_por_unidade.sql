-- =========================================================
-- I09 — Média da avaliação do Plano de Trabalho por unidade
-- Eixo 4 — Desempenho e Avaliação
-- =========================================================
-- Tabelas : avaliacoes, planos_trabalhos_consolidacoes,
--           planos_trabalhos, tipos_avaliacoes_notas, unidades
-- Conexão : Denodo via DBeaver (sem prefixo petrvs_icmbio_)
-- Revisado: 23.05.2026
-- =========================================================
-- VÍNCULO: avaliacoes → planos_trabalhos_consolidacoes → planos_trabalhos
--   (apenas avaliações de PT; campo plano_trabalho_consolidacao_id NOT NULL)
-- NOTA: campo numérico da avaliação = tipos_avaliacoes_notas.nota (escala 1–5)
--   Verificar se a coluna se chama "nota", "valor" ou "pontuacao" no banco atual.
-- FAIXAS DE DESEMPENHO:
--   >= 4.5 Excepcional | >= 3.5 Alto desempenho | >= 2.5 Adequado
--   >= 1.5 Inadequado  | < 1.5 Nao executado
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Avaliações de PT com nota numérica, filtradas pelo período do PT
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
-- Média, distribuição e extremos por unidade
media_por_unidade AS (
    SELECT
        COALESCE(un.sigla, 'N.I.')                           AS unidade_sigla,
        COALESCE(un.nome,  'N.I.')                           AS unidade_nome,
        COUNT(avpt.id_avaliacao)                             AS total_avaliacoes_pt,
        ROUND(AVG(avpt.valor_nota), 2)                       AS media_nota_pt,
        MIN(avpt.valor_nota)                                 AS nota_minima,
        MAX(avpt.valor_nota)                                 AS nota_maxima,
        SUM(CASE WHEN avpt.valor_nota = 1 THEN 1 ELSE 0 END) AS qtd_nota_1,
        SUM(CASE WHEN avpt.valor_nota = 2 THEN 1 ELSE 0 END) AS qtd_nota_2,
        SUM(CASE WHEN avpt.valor_nota = 3 THEN 1 ELSE 0 END) AS qtd_nota_3,
        SUM(CASE WHEN avpt.valor_nota = 4 THEN 1 ELSE 0 END) AS qtd_nota_4,
        SUM(CASE WHEN avpt.valor_nota = 5 THEN 1 ELSE 0 END) AS qtd_nota_5
    FROM avaliacoes_pt avpt
    LEFT JOIN unidades un
        ON un.id = avpt.unidade_id
    GROUP BY COALESCE(un.sigla, 'N.I.'), COALESCE(un.nome, 'N.I.')
)
SELECT
    unidade_sigla,
    unidade_nome,
    total_avaliacoes_pt,
    media_nota_pt,
    nota_minima,
    nota_maxima,
    qtd_nota_1,
    qtd_nota_2,
    qtd_nota_3,
    qtd_nota_4,
    qtd_nota_5,
    CASE
        WHEN media_nota_pt >= 4.5 THEN 'Excepcional'
        WHEN media_nota_pt >= 3.5 THEN 'Alto desempenho'
        WHEN media_nota_pt >= 2.5 THEN 'Adequado'
        WHEN media_nota_pt >= 1.5 THEN 'Inadequado'
        ELSE                          'Nao executado'
    END AS faixa_desempenho
FROM media_por_unidade
ORDER BY media_nota_pt DESC, unidade_sigla;
