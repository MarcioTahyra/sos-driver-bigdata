# SOS Driver – Projeto Big Data | Global Solution FIAP

### Integrantes
- Márcio Hitoshi Tahyra - RM552511
- Jéssica Witzler Costacurta - RM99068

## 1. Sobre o projeto

O **SOS Driver** é uma proposta de marketplace de assistência veicular sob demanda. Este projeto utiliza conceitos de Big Data para coletar, processar e analisar dados de solicitações de assistência e condições climáticas.

O objetivo é demonstrar como informações meteorológicas podem ser integradas aos registros de atendimento para gerar análises que auxiliem na compreensão da demanda por serviços.

## 2. Objetivos

- Automatizar a coleta de dados utilizando Apache Airflow.
- Integrar dados meteorológicos externos e dados internos simulados.
- Implementar uma arquitetura de processamento baseada nas camadas Bronze, Prata e Ouro.
- Utilizar Databricks e Delta Lake para armazenamento e processamento.
- Desenvolver consultas analíticas para identificar padrões nas solicitações de assistência.

## 3. Tecnologias utilizadas

| Tecnologia | Aplicação |
|---|---|
| Python | Coleta e geração de dados |
| Apache Airflow | Orquestração e agendamento |
| Open-Meteo API | Fonte externa de dados climáticos |
| Docker | Execução do ambiente Airflow |
| Databricks | Processamento e análise dos dados |
| Delta Lake | Armazenamento das tabelas |
| SQL | Transformação e consultas analíticas |
| GitHub | Versionamento e documentação |

## 4. Arquitetura do projeto

O fluxo de processamento é dividido nas seguintes etapas:

1. **Coleta:** obtenção dos dados climáticos pela API Open-Meteo e geração de registros simulados de solicitações SOS Driver.
2. **Orquestração:** execução das tarefas pelo Apache Airflow.
3. **Armazenamento:** disponibilização dos arquivos JSON no Volume do Databricks.
4. **Processamento:** transformação dos dados nas camadas Bronze, Prata e Ouro.
5. **Análise:** execução de consultas SQL para extração de informações relevantes.

### Fluxo de dados

```text
       OPEN-METEO API
              |
              v
       COLETA DE CLIMA
              |
              |
       DADOS SOS DRIVER
              |
              v
        APACHE AIRFLOW
              |
              v
         ARQUIVOS JSON
              |
              v
          DATABRICKS
              |
       +------+------+
       |             |
       v             v
     BRONZE        BRONZE
     CLIMA       OCORRÊNCIAS
       |             |
       +------+------+
              |
              v
            PRATA
       LIMPEZA E TRATAMENTO
              |
              v
             OURO
       DIMENSÕES E FATO
              |
              v
       CONSULTAS ANALÍTICAS
```

## 5. Organização dos arquivos

```text
sos-driver-bigdata/
│
├── dags/
│   └── sos_driver_coleta.py
│
├── chegada/
│   ├── clima/
│   └── ocorrencias/
│
├── evidencias/
│   ├── 01_airflow_dag.png
│   ├── 02_airflow_execucao.png
│   └── ...
│
├── sql/
│   ├── 01_bronze.sql
│   ├── 02_prata.sql
│   ├── 03_ouro.sql
│   └── 04_consultas_analiticas.sql
│
├── coletar_dados.py
├── gerar_ocorrencias.py
└── README.md
```

## 6. Fontes de dados

### Dados climáticos

Obtidos por meio da API Open-Meteo, contendo:

- Data e horário;
- Temperatura;
- Precipitação;
- Cidade.

### Solicitações SOS Driver

Dados simulados em Python, sem utilização de informações pessoais reais, contendo:

- Identificador da ocorrência;
- Data e horário;
- Região;
- Tipo de serviço;
- Status da solicitação.

Foram utilizados 300 registros simulados de ocorrências e 72 registros climáticos brutos, provenientes de três coletas.

## 7. Processamento dos dados

### Bronze – Dados brutos

Armazena os dados recebidos das fontes externas e internas em formato Delta, preservando os registros coletados.

### Prata – Dados tratados

Realiza:
- Conversão e padronização de datas;
- Limpeza de campos textuais;
- Tratamento de valores inválidos;
- Deduplicação de registros;
- Agregação dos dados climáticos por horário.

### Ouro – Dados analíticos

Organiza os dados em um modelo dimensional composto por:

- `dim_regiao`: regiões atendidas;
- `dim_servico`: tipos de assistência;
- `dim_data`: informações de calendário;
- `fato_ocorrencias`: registros de ocorrências integrados às informações climáticas.

## 8. Consultas analíticas e resultados

Foram desenvolvidas cinco consultas SQL para analisar os dados processados.

### Ocorrências por região

| Região | Ocorrências |
|---|---:|
| Centro | 76 |
| Zona Leste | 68 |
| Zona Sul | 57 |
| Zona Norte | 51 |
| Zona Oeste | 48 |

### Ocorrências por serviço

| Serviço | Ocorrências |
|---|---:|
| Pane seca | 81 |
| Guincho | 76 |
| Pneu | 74 |
| Bateria | 69 |

### Ocorrências por dia

- 15/11/2026: 300 ocorrências.

### Ocorrências por horário

A maior concentração foi identificada às **6h**, com 20 solicitações.

### Ocorrências por condição climática

| Condição | Ocorrências |
|---|---:|
| Sem chuva | 180 |
| Com chuva | 120 |

A integração entre as tabelas apresentou 300 ocorrências com informações climáticas disponíveis.

## 9. Resultados gerais

- 300 ocorrências processadas na camada Prata.
- 24 registros horários de clima tratados.
- 5 regiões identificadas.
- 4 categorias de serviços identificadas.
- 1 dimensão de data.
- 300 registros na tabela fato.
- 100% das ocorrências da tabela fato associadas a informações climáticas.

Os resultados representam uma simulação baseada em dados de um único dia e não devem ser interpretados como tendências históricas ou evidência de causalidade entre chuva e demanda.

## 10. Como executar o projeto

### Pré-requisitos

- Python instalado;
- Docker Desktop;
- Apache Airflow;
- Conta no Databricks.

### Coleta de dados

Execute os scripts Python:

```bash
python coletar_dados.py
python gerar_ocorrencias.py
```

Os arquivos JSON serão gerados nas respectivas pastas dentro de `chegada/`.

### Orquestração

Com o ambiente Docker do Airflow iniciado, acesse:

```text
http://localhost:8080
```

Localize a DAG `sos_driver_coleta` e execute-a para realizar a coleta e validação dos arquivos.

### Processamento no Databricks

Envie os arquivos JSON para o Volume configurado no Databricks e execute os scripts SQL na seguinte ordem:

1. `01_bronze.sql`
2. `02_prata.sql`
3. `03_ouro.sql`
4. `04_consultas_analiticas.sql`

## 11. Considerações finais

O projeto demonstra a aplicação de uma arquitetura de Big Data para integrar dados operacionais e meteorológicos, utilizando ferramentas de coleta, orquestração, armazenamento e processamento analítico.

A solução permite explorar a distribuição das solicitações por região, serviço, horário e condição climática, oferecendo uma base para futuras melhorias na análise e no planejamento operacional do SOS Driver.

---

**Projeto acadêmico – Global Solution FIAP 2026**