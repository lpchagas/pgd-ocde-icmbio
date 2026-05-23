-- =========================================================
-- I06 — Grau de responsabilidade pelas entregas
-- Eixo 3 — Carga de Trabalho
-- =========================================================
-- Tabelas : planos_trabalhos, planos_trabalhos_entregas, unidades
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Revisado: 23.05.2026
-- =========================================================
-- PERGUNTA: quantos servidores são responsáveis por cada entrega?
-- PERSPECTIVA INVERSA AO I05:
--   I05 → quantas entregas tem cada servidor?
--   I06 → quantos servidores tem cada entrega?
-- RESULTADO: 1 linha por unidade × faixa de responsáveis
--   (1 servidor | 2 servidores | 3 servidores | 4+ servidores)
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Vínculo único unidade × entrega × servidor
vinculos AS (
    SELECT DISTINCT
        COALESCE(un.sigla, 'N.I.')       AS unidade_sigla,
        COALESCE(un.nome,  'N.I.')       AS unidade_nome,
        pte.plano_entrega_entrega_id     AS id_entrega,
        pt.usuario_id                    AS id_servidor
    FROM petrvs_icmbio_planos_trabalhos pt
    JOIN petrvs_icmbio_planos_trabalhos_entregas pte
        ON pte.plano_trabalho_id = pt.id
    LEFT JOIN petrvs_icmbio_unidades un
        ON un.id = pt.unidade_id
    CROSS JOIN parametros p
    WHERE CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
      AND pt.usuario_id IS NOT NULL
      AND pte.plano_entrega_entrega_id IS NOT NULL
),
-- Contagem de responsáveis distintos por entrega
responsaveis_por_entrega AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)           AS unidade_nome,
        id_entrega,
        COUNT(DISTINCT id_servidor) AS qtd_responsaveis
    FROM vinculos
    GROUP BY unidade_sigla, id_entrega
),
-- Classificação por faixa de responsáveis
com_classificacao AS (
    SELECT
        unidade_sigla,
        unidade_nome,
        id_entrega,
        qtd_responsaveis,
        CASE
            WHEN qtd_responsaveis = 1 THEN '1 servidor'
            WHEN qtd_responsaveis = 2 THEN '2 servidores'
            WHEN qtd_responsaveis = 3 THEN '3 servidores'
            ELSE                          '4+ servidores'
        END AS tamanho_grupo_responsavel
    FROM responsaveis_por_entrega
)
SELECT
    unidade_sigla,
    MIN(unidade_nome)             AS unidade_nome,
    tamanho_grupo_responsavel,
    COUNT(id_entrega)             AS total_entregas_na_categoria
FROM com_classificacao
GROUP BY unidade_sigla, tamanho_grupo_responsavel
ORDER BY unidade_sigla, tamanho_grupo_responsavel;
