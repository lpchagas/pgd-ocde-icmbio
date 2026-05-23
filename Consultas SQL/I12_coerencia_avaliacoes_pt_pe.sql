-- =========================================================
-- I12 — Coerência entre avaliação do PT e do PE
-- Eixo 4 — Desempenho e Avaliação
-- =========================================================
-- Tabelas : avaliacoes, planos_trabalhos_consolidacoes,
--           planos_trabalhos, planos_entregas,
--           tipos_avaliacoes_notas, unidades
-- Conexão : Denodo via DBeaver (sem prefixo petrvs_icmbio_)
-- Revisado: 23.05.2026
-- =========================================================
-- PERGUNTA: a nota dos servidores (PT) é coerente com a nota da unidade (PE)?
-- DOIS CAMINHOS PARALELOS:
--   PT → avaliacoes.plano_trabalho_consolidacao_id (avaliação individual)
--   PE → avaliacoes.plano_entrega_id (avaliação da entrega da unidade)
-- PRÉ-REQUISITO: confirmar que ambos os campos estão populados no banco.
--   Uma unidade só aparece no resultado se tiver avaliações nos DOIS tipos (INNER JOIN).
-- CLASSIFICAÇÃO DE COERÊNCIA:
--   diferença <= 1.0 → Coerente (variação esperada)
--   diferença <= 2.0 → Divergência moderada (merece investigação)
--   diferença >  2.0 → Alta divergência (desalinhamento sistemático)
-- DIREÇÃO DA DIVERGÊNCIA:
--   PT > PE → servidores avaliados melhor que a entrega da unidade
--   PE > PT → entrega da unidade avaliada melhor que os servidores
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Avaliações de PT (caminho: consolidacao → plano_trabalho)
avaliacoes_pt AS (
    SELECT
        pt.unidade_id,
        tan.nota AS valor_nota
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
-- Avaliações de PE (caminho direto: plano_entrega)
avaliacoes_pe AS (
    SELECT
        pe.unidade_id,
        tan.nota AS valor_nota
    FROM avaliacoes av
    JOIN planos_entregas pe
        ON pe.id = av.plano_entrega_id
    JOIN tipos_avaliacoes_notas tan
        ON tan.id = av.tipo_avaliacao_nota_id
    CROSS JOIN parametros p
    WHERE av.plano_entrega_id IS NOT NULL
      AND (p.incluir_excluidos = 1 OR av.deleted_at IS NULL)
      AND CAST(pe.data_inicio AS DATE) <= p.data_fim
      AND CAST(pe.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pe.deleted_at IS NULL)
),
-- Média por unidade — PT
media_pt AS (
    SELECT
        unidade_id,
        COUNT(*)                  AS total_avaliacoes_pt,
        ROUND(AVG(valor_nota), 2) AS media_nota_pt
    FROM avaliacoes_pt
    GROUP BY unidade_id
),
-- Média por unidade — PE
media_pe AS (
    SELECT
        unidade_id,
        COUNT(*)                  AS total_avaliacoes_pe,
        ROUND(AVG(valor_nota), 2) AS media_nota_pe
    FROM avaliacoes_pe
    GROUP BY unidade_id
),
-- Cruzamento e cálculo de coerência (INNER JOIN: só unidades com os dois tipos)
coerencia AS (
    SELECT
        COALESCE(un.sigla, 'N.I.')                            AS unidade_sigla,
        COALESCE(un.nome,  'N.I.')                            AS unidade_nome,
        mpt.total_avaliacoes_pt,
        mpt.media_nota_pt,
        mpe.total_avaliacoes_pe,
        mpe.media_nota_pe,
        ROUND(ABS(mpt.media_nota_pt - mpe.media_nota_pe), 2)  AS diferenca_absoluta,
        ROUND(mpt.media_nota_pt - mpe.media_nota_pe, 2)       AS diferenca_direcional
    FROM media_pt mpt
    JOIN media_pe mpe
        ON mpe.unidade_id = mpt.unidade_id
    LEFT JOIN unidades un
        ON un.id = mpt.unidade_id
)
SELECT
    unidade_sigla,
    unidade_nome,
    total_avaliacoes_pt,
    media_nota_pt,
    total_avaliacoes_pe,
    media_nota_pe,
    diferenca_absoluta,
    diferenca_direcional,
    CASE
        WHEN diferenca_absoluta <= 1.0 THEN 'Coerente'
        WHEN diferenca_absoluta <= 2.0 THEN 'Divergencia moderada'
        ELSE                                'Alta divergencia'
    END AS classificacao_coerencia,
    CASE
        WHEN diferenca_direcional > 0 THEN 'PT > PE'
        WHEN diferenca_direcional < 0 THEN 'PE > PT'
        ELSE                              'Sem diferenca'
    END AS direcao_divergencia
FROM coerencia
ORDER BY diferenca_absoluta DESC, unidade_sigla;
