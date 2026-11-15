
-- ==========================================
-- CONSULTA 1 - OCORRENCIAS POR REGIAO
-- ==========================================

SELECT
    regiao,
    COUNT(*) AS total_ocorrencias
FROM workspace.gs.fato_ocorrencias
GROUP BY regiao
ORDER BY total_ocorrencias DESC;


-- ==========================================
-- CONSULTA 2 - OCORRENCIAS POR SERVICO
-- ==========================================

SELECT
    servico,
    COUNT(*) AS total_ocorrencias
FROM workspace.gs.fato_ocorrencias
GROUP BY servico
ORDER BY total_ocorrencias DESC;


-- ==========================================
-- CONSULTA 3 - OCORRENCIAS POR DIA
-- ==========================================

SELECT
    TO_DATE(data_hora) AS data,
    COUNT(*) AS total_ocorrencias
FROM workspace.gs.fato_ocorrencias
GROUP BY TO_DATE(data_hora)
ORDER BY data;


-- ==========================================
-- CONSULTA 4 - OCORRENCIAS POR HORARIO
-- ==========================================

SELECT
    HOUR(data_hora) AS hora,
    COUNT(*) AS total_ocorrencias
FROM workspace.gs.fato_ocorrencias
GROUP BY HOUR(data_hora)
ORDER BY hora;


-- ==========================================
-- CONSULTA 5 - OCORRENCIAS POR CONDICAO
-- CLIMATICA
-- ==========================================

SELECT
    CASE
        WHEN precipitacao > 0 THEN 'Com chuva'
        ELSE 'Sem chuva'
    END AS condicao_climatica,
    COUNT(*) AS total_ocorrencias,
    ROUND(AVG(precipitacao), 2) AS precipitacao_media
FROM workspace.gs.fato_ocorrencias
GROUP BY
    CASE
        WHEN precipitacao > 0 THEN 'Com chuva'
        ELSE 'Sem chuva'
    END
ORDER BY total_ocorrencias DESC;


-- ==========================================
-- ANALISE COMPLEMENTAR - INTEGRACAO CLIMA
-- ==========================================

SELECT
    COUNT(*) AS total_ocorrencias,
    SUM(CASE WHEN clima_disponivel THEN 1 ELSE 0 END)
        AS ocorrencias_com_clima,
    SUM(CASE WHEN NOT clima_disponivel THEN 1 ELSE 0 END)
        AS ocorrencias_sem_clima,
    ROUND(AVG(temperatura), 2) AS temperatura_media,
    ROUND(AVG(precipitacao), 2) AS precipitacao_media
FROM workspace.gs.fato_ocorrencias;
