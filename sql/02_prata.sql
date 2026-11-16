
-- ==========================================
-- CAMADA PRATA - TRATAMENTO DOS DADOS
-- SOS DRIVER
-- ==========================================

-- ==========================================
-- 1. TABELA DE AUDITORIA DE QUALIDADE
-- ==========================================

CREATE TABLE IF NOT EXISTS workspace.gs.auditoria_qualidade (
    data_execucao TIMESTAMP,
    regra STRING,
    registros_rejeitados BIGINT
) USING DELTA;

TRUNCATE TABLE workspace.gs.auditoria_qualidade;


-- ==========================================
-- 2. PREPARACAO DAS OCORRENCIAS
-- ==========================================

CREATE OR REPLACE TEMP VIEW ocorrencias_tratadas AS
SELECT
    id_ocorrencia,

    COALESCE(
        TRY_TO_TIMESTAMP(
            REPLACE(TRIM(data_hora), 'T', ' '),
            'yyyy-MM-dd HH:mm:ss'
        ),
        TRY_TO_TIMESTAMP(
            REPLACE(TRIM(data_hora), 'T', ' '),
            'yyyy-MM-dd HH:mm'
        )
    ) AS data_hora,

    INITCAP(TRIM(regiao)) AS regiao,
    LOWER(TRIM(servico)) AS servico,
    LOWER(TRIM(status)) AS status

FROM workspace.gs.bronze_ocorrencias;


-- ==========================================
-- 3. TRES REGRAS DE QUALIDADE
-- ==========================================

-- Regra 1: identificador nulo ou invalido
INSERT INTO workspace.gs.auditoria_qualidade
SELECT
    CURRENT_TIMESTAMP(),
    'ID nulo ou invalido',
    COUNT(*)
FROM workspace.gs.bronze_ocorrencias
WHERE id_ocorrencia IS NULL
   OR id_ocorrencia <= 0;

-- Regra 2: data e hora invalidas
INSERT INTO workspace.gs.auditoria_qualidade
SELECT
    CURRENT_TIMESTAMP(),
    'Data e hora invalidas',
    COUNT(*)
FROM ocorrencias_tratadas
WHERE data_hora IS NULL;

-- Regra 3: campos obrigatorios ausentes
INSERT INTO workspace.gs.auditoria_qualidade
SELECT
    CURRENT_TIMESTAMP(),
    'Regiao, servico ou status ausentes',
    COUNT(*)
FROM workspace.gs.bronze_ocorrencias
WHERE regiao IS NULL OR TRIM(regiao) = ''
   OR servico IS NULL OR TRIM(servico) = ''
   OR status IS NULL OR TRIM(status) = '';


-- ==========================================
-- 4. TABELA PRATA DE OCORRENCIAS
-- ==========================================

CREATE TABLE IF NOT EXISTS workspace.gs.prata_ocorrencias (
    id_ocorrencia BIGINT,
    data_hora TIMESTAMP,
    regiao STRING,
    servico STRING,
    status STRING
) USING DELTA;

MERGE INTO workspace.gs.prata_ocorrencias AS destino

USING (
    SELECT
        id_ocorrencia,
        data_hora,
        regiao,
        servico,
        status

    FROM ocorrencias_tratadas

    WHERE id_ocorrencia IS NOT NULL
      AND id_ocorrencia > 0
      AND data_hora IS NOT NULL
      AND regiao IS NOT NULL
      AND TRIM(regiao) <> ''
      AND servico IS NOT NULL
      AND TRIM(servico) <> ''
      AND status IS NOT NULL
      AND TRIM(status) <> ''

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id_ocorrencia
        ORDER BY data_hora DESC
    ) = 1

) AS origem

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


-- ==========================================
-- 5. TABELA PRATA DE CLIMA
-- ==========================================

CREATE TABLE IF NOT EXISTS workspace.gs.prata_clima (
    data_hora TIMESTAMP,
    temperatura DOUBLE,
    precipitacao DOUBLE,
    cidade STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW clima_tratado AS
SELECT
    TRY_TO_TIMESTAMP(
        REPLACE(TRIM(data_hora), 'T', ' '),
        'yyyy-MM-dd HH:mm'
    ) AS data_hora,

    AVG(TRY_CAST(temperatura AS DOUBLE)) AS temperatura,
    AVG(TRY_CAST(precipitacao AS DOUBLE)) AS precipitacao,
    INITCAP(TRIM(cidade)) AS cidade

FROM workspace.gs.bronze_clima

WHERE TRY_TO_TIMESTAMP(
    REPLACE(TRIM(data_hora), 'T', ' '),
    'yyyy-MM-dd HH:mm'
) IS NOT NULL

  AND cidade IS NOT NULL
  AND TRIM(cidade) <> ''

GROUP BY
    TRY_TO_TIMESTAMP(
        REPLACE(TRIM(data_hora), 'T', ' '),
        'yyyy-MM-dd HH:mm'
    ),
    INITCAP(TRIM(cidade));


MERGE INTO workspace.gs.prata_clima AS destino

USING clima_tratado AS origem

ON destino.data_hora = origem.data_hora
AND destino.cidade = origem.cidade

WHEN MATCHED THEN UPDATE SET
    destino.temperatura = origem.temperatura,
    destino.precipitacao = origem.precipitacao

WHEN NOT MATCHED THEN INSERT (
    data_hora,
    temperatura,
    precipitacao,
    cidade
)
VALUES (
    origem.data_hora,
    origem.temperatura,
    origem.precipitacao,
    origem.cidade
);


-- ==========================================
-- 6. CONSULTAS DE VALIDACAO
-- ==========================================

-- Total de ocorrencias e IDs unicos
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT id_ocorrencia) AS ids_unicos
FROM workspace.gs.prata_ocorrencias;


-- Quantidade de rejeicoes por regra
SELECT
    regra,
    registros_rejeitados
FROM workspace.gs.auditoria_qualidade
ORDER BY regra;


-- Total de registros de clima
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT data_hora) AS horarios_unicos,
    COUNT(*) - COUNT(data_hora) AS datas_nulas
FROM workspace.gs.prata_clima;
