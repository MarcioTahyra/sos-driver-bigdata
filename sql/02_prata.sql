
-- ==========================================
-- CAMADA PRATA - TRATAMENTO DOS DADOS
-- ==========================================

CREATE TABLE IF NOT EXISTS workspace.gs.prata_ocorrencias (
    id_ocorrencia BIGINT,
    data_hora TIMESTAMP,
    regiao STRING,
    servico STRING,
    status STRING
) USING DELTA;

TRUNCATE TABLE workspace.gs.prata_ocorrencias;

MERGE INTO workspace.gs.prata_ocorrencias AS destino
USING (
    SELECT
        id_ocorrencia,
        TRY_TO_TIMESTAMP(
            REPLACE(TRIM(data_hora), 'T', ' '),
            'yyyy-MM-dd HH:mm:ss'
        ) AS data_hora,
        INITCAP(TRIM(regiao)) AS regiao,
        LOWER(TRIM(servico)) AS servico,
        LOWER(TRIM(status)) AS status
    FROM workspace.gs.bronze_ocorrencias
    WHERE id_ocorrencia IS NOT NULL
      AND TRY_TO_TIMESTAMP(
          REPLACE(TRIM(data_hora), 'T', ' '),
          'yyyy-MM-dd HH:mm:ss'
      ) IS NOT NULL
      AND regiao IS NOT NULL
      AND servico IS NOT NULL
      AND status IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id_ocorrencia
        ORDER BY data_hora DESC
    ) = 1
) origem
ON destino.id_ocorrencia = origem.id_ocorrencia

WHEN MATCHED THEN UPDATE SET
    destino.data_hora = origem.data_hora,
    destino.regiao = origem.regiao,
    destino.servico = origem.servico,
    destino.status = origem.status

WHEN NOT MATCHED THEN INSERT (
    id_ocorrencia,
    data_hora,
    regiao,
    servico,
    status
)
VALUES (
    origem.id_ocorrencia,
    origem.data_hora,
    origem.regiao,
    origem.servico,
    origem.status
);

-- Tabela Prata de clima
CREATE TABLE IF NOT EXISTS workspace.gs.prata_clima (
    data_hora TIMESTAMP,
    temperatura DOUBLE,
    precipitacao DOUBLE,
    cidade STRING
) USING DELTA;

TRUNCATE TABLE workspace.gs.prata_clima;

INSERT INTO workspace.gs.prata_clima
SELECT
    TRY_TO_TIMESTAMP(
        REPLACE(TRIM(data_hora), 'T', ' '),
        'yyyy-MM-dd HH:mm'
    ) AS data_hora,
    AVG(temperatura) AS temperatura,
    AVG(precipitacao) AS precipitacao,
    INITCAP(TRIM(cidade)) AS cidade
FROM workspace.gs.bronze_clima
WHERE TRY_TO_TIMESTAMP(
    REPLACE(TRIM(data_hora), 'T', ' '),
    'yyyy-MM-dd HH:mm'
) IS NOT NULL
GROUP BY
    TRY_TO_TIMESTAMP(
        REPLACE(TRIM(data_hora), 'T', ' '),
        'yyyy-MM-dd HH:mm'
    ),
    INITCAP(TRIM(cidade));

DELETE FROM workspace.gs.prata_clima
WHERE data_hora IS NULL;

-- Validação das ocorrências
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT id_ocorrencia) AS ids_unicos
FROM workspace.gs.prata_ocorrencias;

-- Validação do clima
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT data_hora) AS horarios_unicos,
    COUNT(*) - COUNT(data_hora) AS datas_nulas
FROM workspace.gs.prata_clima;
