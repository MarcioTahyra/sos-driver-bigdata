
-- ==========================================
-- CAMADA OURO - MODELAGEM ANALITICA
-- ==========================================

-- Dimensão região
CREATE OR REPLACE TABLE workspace.gs.dim_regiao
USING DELTA AS
SELECT DISTINCT
    regiao
FROM workspace.gs.prata_ocorrencias
WHERE regiao IS NOT NULL;

-- Dimensão serviço
CREATE OR REPLACE TABLE workspace.gs.dim_servico
USING DELTA AS
SELECT DISTINCT
    servico
FROM workspace.gs.prata_ocorrencias
WHERE servico IS NOT NULL;

-- Dimensão data
CREATE OR REPLACE TABLE workspace.gs.dim_data
USING DELTA AS
SELECT DISTINCT
    CAST(DATE_FORMAT(TO_DATE(data_hora), 'yyyyMMdd') AS INT) AS data_key,
    TO_DATE(data_hora) AS data,
    YEAR(data_hora) AS ano,
    MONTH(data_hora) AS mes,
    DAY(data_hora) AS dia,
    DAYOFWEEK(data_hora) AS dia_semana
FROM workspace.gs.prata_ocorrencias;

-- Tabela fato integrando ocorrências e clima
CREATE OR REPLACE TABLE workspace.gs.fato_ocorrencias
USING DELTA AS
SELECT
    o.id_ocorrencia,
    CAST(DATE_FORMAT(TO_DATE(o.data_hora), 'yyyyMMdd') AS INT) AS data_key,
    o.data_hora,
    r.regiao,
    s.servico,
    o.status,
    c.temperatura,
    c.precipitacao,
    c.cidade,
    CASE
        WHEN c.data_hora IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS clima_disponivel
FROM workspace.gs.prata_ocorrencias o

LEFT JOIN workspace.gs.dim_regiao r
    ON o.regiao = r.regiao

LEFT JOIN workspace.gs.dim_servico s
    ON o.servico = s.servico

LEFT JOIN workspace.gs.prata_clima c
    ON DATE_TRUNC('HOUR', o.data_hora) = c.data_hora;

-- Validação das dimensões
SELECT 'dim_regiao' AS tabela, COUNT(*) AS registros
FROM workspace.gs.dim_regiao

UNION ALL

SELECT 'dim_servico', COUNT(*)
FROM workspace.gs.dim_servico

UNION ALL

SELECT 'dim_data', COUNT(*)
FROM workspace.gs.dim_data;

-- Validação da tabela fato
SELECT COUNT(*) AS total_registros
FROM workspace.gs.fato_ocorrencias;
