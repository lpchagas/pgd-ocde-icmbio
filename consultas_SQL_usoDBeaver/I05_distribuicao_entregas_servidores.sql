-- =========================================================
-- I05 — Distribuição das entregas entre os servidores
-- Eixo 3 — Carga de Trabalho
-- =========================================================
-- Tabelas : planos_trabalhos, planos_trabalhos_entregas, unidades, usuarios
-- Conexão : Denodo via DBeaver — prefixo petrvs_icmbio_ obrigatório (confirmado 23.05.2026)
-- Revisado: 23.05.2026
-- =========================================================
-- PERGUNTA: a carga de entregas está distribuída de forma equitativa entre os servidores?
-- RESULTADO: 1 linha por servidor com qtd de entregas vinculadas e média da sua unidade
-- VÍNCULO: planos_trabalhos → planos_trabalhos_entregas → entrega do plano de entregas
-- =========================================================
-- COMO USAR: ajuste data_inicio e data_fim no bloco "parametros"
-- =========================================================

WITH parametros AS (
    SELECT
        CAST('2025-01-01' AS DATE) AS data_inicio,
        CAST('2025-12-31' AS DATE) AS data_fim,
        0                          AS incluir_excluidos  -- 0=só ativos | 1=inclui excluídos
),
-- Vínculo único servidor × entrega (distinct evita dupla contagem)
vinculos_entregas AS (
    SELECT DISTINCT
        COALESCE(un.sigla, 'N.I.') AS unidade_sigla,
        COALESCE(un.nome,  'N.I.') AS unidade_nome,
        pt.usuario_id              AS id_servidor,
        COALESCE(us.nome,  'N.I.') AS nome_servidor,
        pte.plano_entrega_entrega_id AS id_entrega
    FROM petrvs_icmbio_planos_trabalhos pt
    JOIN petrvs_icmbio_planos_trabalhos_entregas pte
        ON pte.plano_trabalho_id = pt.id
    LEFT JOIN petrvs_icmbio_unidades un
        ON un.id = pt.unidade_id
    LEFT JOIN petrvs_icmbio_usuarios us
        ON us.id = pt.usuario_id
    CROSS JOIN parametros p
    WHERE CAST(pt.data_inicio AS DATE) <= p.data_fim
      AND CAST(pt.data_fim   AS DATE) >= p.data_inicio
      AND (p.incluir_excluidos = 1 OR pt.deleted_at IS NULL)
      AND pt.usuario_id IS NOT NULL
      AND pte.plano_entrega_entrega_id IS NOT NULL
),
-- Contagem de entregas por servidor dentro de cada unidade
entregas_por_servidor AS (
    SELECT
        unidade_sigla,
        MIN(unidade_nome)          AS unidade_nome,
        id_servidor,
        MIN(nome_servidor)         AS nome_servidor,
        COUNT(DISTINCT id_entrega) AS qtd_entregas_por_servidor
    FROM vinculos_entregas
    GROUP BY unidade_sigla, id_servidor
),
-- Média da unidade via window function para classificar posição relativa
com_media AS (
    SELECT
        unidade_sigla,
        unidade_nome,
        id_servidor,
        nome_servidor,
        qtd_entregas_por_servidor,
        ROUND(
            AVG(qtd_entregas_por_servidor) OVER (PARTITION BY unidade_sigla),
            2
        ) AS media_entregas_por_servidor_unidade
    FROM entregas_por_servidor
)
SELECT
    unidade_sigla,
    unidade_nome,
    id_servidor,
    nome_servidor,
    qtd_entregas_por_servidor,
    media_entregas_por_servidor_unidade,
    CASE
        WHEN qtd_entregas_por_servidor > media_entregas_por_servidor_unidade THEN 'Acima da media'
        WHEN qtd_entregas_por_servidor < media_entregas_por_servidor_unidade THEN 'Abaixo da media'
        ELSE                                                                      'Na media'
    END AS posicao_relativa_media
FROM com_media
ORDER BY unidade_sigla, qtd_entregas_por_servidor DESC, nome_servidor;
