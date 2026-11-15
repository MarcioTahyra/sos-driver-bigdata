
-- ==========================================
-- CAMADA BRONZE - DADOS BRUTOS
-- ==========================================

CREATE TABLE IF NOT EXISTS workspace.gs.bronze_ocorrencias (
    id_ocorrencia BIGINT,
    data_hora STRING,
    regiao STRING,
    servico STRING,
    status STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS workspace.gs.bronze_clima (
    data_hora STRING,
    temperatura DOUBLE,
    precipitacao DOUBLE,
    cidade STRING
) USING DELTA;

-- Importação das ocorrências
COPY INTO workspace.gs.bronze_ocorrencias
FROM '/Volumes/workspace/gs/chegada/ocorrencias'
FILEFORMAT = JSON
FORMAT_OPTIONS ('multiLine' = 'true');

-- Importação dos dados climáticos
COPY INTO workspace.gs.bronze_clima
FROM '/Volumes/workspace/gs/chegada/clima'
FILEFORMAT = JSON
FORMAT_OPTIONS ('multiLine' = 'true');

-- Correção dos identificadores duplicados
CREATE OR REPLACE TABLE workspace.gs.bronze_ocorrencias_corrigida
USING DELTA AS
SELECT
    CAST(ROW_NUMBER() OVER (
        ORDER BY data_hora, regiao, servico, status
    ) AS BIGINT) AS id_ocorrencia,
    data_hora,
    regiao,
    servico,
    status
FROM workspace.gs.bronze_ocorrencias;

DROP TABLE workspace.gs.bronze_ocorrencias;

CREATE TABLE workspace.gs.bronze_ocorrencias
USING DELTA AS
SELECT * FROM workspace.gs.bronze_ocorrencias_corrigida;

DROP TABLE workspace.gs.bronze_ocorrencias_corrigida;

-- Validação
SELECT COUNT(*) AS total_ocorrencias
FROM workspace.gs.bronze_ocorrencias;

SELECT COUNT(*) AS total_clima
FROM workspace.gs.bronze_clima;
