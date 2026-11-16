# SOS Driver – Projeto Big Data | Global Solution FIAP 2026

## Integrantes
- Márcio Hitoshi Tahyra – RM552511
- Jéssica Witzler Costacurta – RM99068

## 1. Sobre o projeto

O **SOS Driver** é uma proposta de marketplace de assistência veicular sob demanda. O projeto utiliza conceitos de Big Data para coletar, processar e analisar dados de solicitações de assistência e condições climáticas.

O objetivo é integrar informações meteorológicas aos registros de atendimento, permitindo analisar padrões de demanda e apoiar o planejamento operacional.

## 2. Objetivos

- Automatizar a coleta de dados utilizando Apache Airflow.
- Integrar dados meteorológicos externos e dados internos simulados.
- Implementar uma arquitetura de processamento com as camadas Bronze, Prata e Ouro.
- Utilizar Databricks e Delta Lake para armazenamento e processamento.
- Desenvolver consultas analíticas para identificar padrões nas solicitações.
- Disponibilizar os resultados por meio de um dashboard interativo.

## 3. Tecnologias utilizadas

| Tecnologia | Aplicação |
|---|---|
| Python | Coleta, geração e aplicação do MVP |
| Apache Airflow | Orquestração e agendamento |
| Open-Meteo API | Fonte externa de dados climáticos |
| Docker | Execução do ambiente Airflow |
| Databricks | Processamento e análise |
| Delta Lake | Armazenamento das tabelas |
| SQL | Transformação e consultas analíticas |
| Streamlit | Dashboard do MVP |
| GitHub | Versionamento e documentação |

## 4. Arquitetura do projeto

O fluxo de processamento é dividido nas seguintes etapas:

1. **Coleta:** obtenção dos dados climáticos pela API Open-Meteo e geração de registros simulados de solicitações SOS Driver.
2. **Orquestração:** execução das tarefas pelo Apache Airflow.
3. **Armazenamento:** disponibilização dos arquivos JSON no Volume do Databricks.
4. **Processamento:** transformação dos dados nas camadas Bronze, Prata e Ouro.
5. **Análise:** execução de consultas SQL para extração de informações.
6. **Visualização:** apresentação dos resultados em um dashboard desenvolvido com Streamlit.

### Fluxo de dados

```text
       OPEN-METEO API       DADOS SOS DRIVER
              |                    |
              v                    v
        COLETA DE CLIMA      GERAÇÃO DE DADOS
              |                    |
              +---------+----------+
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
               CLIMA      OCORRÊNCIAS
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
                        |
                        v
                 DASHBOARD STREAMLIT
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
│
├── coletar_dados.py
├── gerar_ocorrencias.py
├── app.py
├── 02_prata_sos_driver.ipynb
├── README.md
└── ...
```

Os notebooks e demais arquivos utilizados no processamento devem ser mantidos no repositório conforme a organização final do projeto.

## 6. Fontes de dados

### Dados climáticos

Obtidos por meio da API pública Open-Meteo, contendo:

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

Foram processados dados de duas datas:

- **15/11/2026:** 300 ocorrências e 72 registros climáticos brutos.
- **16/11/2026:** 100 ocorrências e 24 registros climáticos brutos.

Total: **400 ocorrências e 96 registros climáticos brutos**.

## 7. Processamento dos dados

### Bronze – Dados brutos

Armazena os dados recebidos das fontes em formato Delta.

Foram utilizadas tabelas distintas para ocorrências e clima. Também foi realizado um teste isolado de ingestão incremental com `COPY INTO`, demonstrando que novos arquivos são carregados sem inserir novamente arquivos já processados.

### Prata – Dados tratados

Realiza:

- Conversão e padronização de datas;
- Padronização de campos textuais;
- Tratamento de valores inválidos;
- Validação de identificadores;
- Deduplicação de registros;
- Integração dos dados climáticos por horário;
- Registro das validações de qualidade.

Resultados:

- 400 ocorrências tratadas;
- 400 identificadores distintos;
- 48 registros climáticos tratados;
- Nenhum registro rejeitado nas três regras de qualidade executadas.

### Ouro – Dados analíticos

Organiza os dados em um modelo dimensional composto por:

- `dim_regiao`: regiões atendidas;
- `dim_servico`: tipos de assistência;
- `dim_data`: informações de calendário;
- `fato_ocorrencias`: registros de ocorrências integrados às informações climáticas.

Resultados:

- 5 regiões;
- 4 categorias de serviços;
- 2 registros de calendário;
- 400 registros na tabela fato.

A visualização disponibilizada ao MVP utiliza a view `workspace.gs.vw_mvp_ocorrencias`, sem exposição do identificador interno da ocorrência.

## 8. Consultas analíticas e resultados

Foram desenvolvidas cinco consultas SQL para analisar os dados processados.

### 8.1 Ocorrências por região

| Região | Ocorrências |
|---|---:|
| Centro | 98 |
| Zona Leste | 88 |
| Zona Norte | 74 |
| Zona Sul | 72 |
| Zona Oeste | 68 |

O Centro apresentou a maior quantidade de solicitações, enquanto a Zona Oeste apresentou a menor.

### 8.2 Ocorrências por serviço

| Serviço | Ocorrências |
|---|---:|
| Pane seca | 111 |
| Guincho | 98 |
| Bateria | 97 |
| Pneu | 94 |

Pane seca foi o serviço com maior quantidade de solicitações.

### 8.3 Ocorrências por dia

| Data | Ocorrências |
|---|---:|
| 15/11/2026 | 300 |
| 16/11/2026 | 100 |

Os dados representam duas datas de coleta, sem permitir conclusões sobre tendências históricas.

### 8.4 Ocorrências por horário

A maior concentração foi identificada às **4h**, com 25 solicitações.

A menor quantidade ocorreu às **7h e 23h**, com 11 solicitações em cada horário.

### 8.5 Ocorrências por condição climática

| Condição | Ocorrências | Precipitação média |
|---|---:|---:|
| Com chuva | 204 | 1,11 |
| Sem chuva | 196 | 0 |

A distribuição ficou relativamente equilibrada entre as duas condições climáticas. Os resultados não demonstram causalidade entre chuva e demanda.

## 9. MVP – Dashboard

Foi desenvolvido um dashboard utilizando Streamlit, conectado à view analítica do Databricks.

O MVP apresenta:

- Total de ocorrências;
- Distribuição por região;
- Distribuição por tipo de serviço;
- Solicitações por horário;
- Indicadores climáticos;
- Filtros para exploração dos dados;
- Tabela de registros;
- Exportação dos dados em CSV.

O dashboard utiliza a view `workspace.gs.vw_mvp_ocorrencias` como fonte de dados.

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

Envie os arquivos JSON para o Volume configurado no Databricks e execute os notebooks de processamento na seguinte ordem:

1. Ingestão na camada Bronze;
2. Transformação e validação na camada Prata;
3. Modelagem dimensional na camada Ouro;
4. Consultas analíticas.

O teste de ingestão incremental pode ser reproduzido na tabela isolada `workspace.gs.bronze_teste_incremental`.

### Dashboard

Configure as variáveis de ambiente necessárias para a conexão com o Databricks SQL Warehouse e execute:

```bash
python -m streamlit run app.py
```

O dashboard será disponibilizado localmente em:

```text
http://localhost:8501
```

## 11. Considerações finais

O projeto demonstra a aplicação de uma arquitetura de Big Data para integrar dados operacionais e meteorológicos, utilizando ferramentas de coleta, orquestração, armazenamento e processamento analítico.

A solução permite explorar a distribuição das solicitações por região, serviço, horário e condição climática, oferecendo uma base para futuras melhorias na análise e no planejamento operacional do SOS Driver.

Os resultados apresentados são provenientes de dados simulados e de coletas realizadas em duas datas, não devendo ser interpretados como tendências históricas ou evidência de causalidade.

---

**Projeto acadêmico – Global Solution FIAP 2026**

**Repositório:** https://github.com/MarcioTahyra/sos-driver-bigdata
