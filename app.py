
import os
import pandas as pd
import streamlit as st
from databricks import sql


# =============================================
# CONFIGURACAO DA PAGINA
# =============================================

st.set_page_config(
    page_title="SOS Driver",
    page_icon="🚗",
    layout="wide",
    initial_sidebar_state="expanded"
)


# =============================================
# ESTILO VISUAL
# =============================================

st.markdown("""
<style>
    .main {
        background-color: #101820;
    }

    h1, h2, h3 {
        color: #FFFFFF;
    }

    div[data-testid="stMetric"] {
        background-color: #1C2B36;
        padding: 18px;
        border-radius: 10px;
        border: 1px solid #344955;
    }

    div[data-testid="stMetricLabel"] {
        color: #B8C7D1;
    }

    div[data-testid="stMetricValue"] {
        color: #FFFFFF;
    }
</style>
""", unsafe_allow_html=True)


# =============================================
# CABECALHO
# =============================================

st.title("SOS Driver")
st.subheader("Painel de análise de assistência veicular")

st.write(
    "Acompanhe as solicitações de assistência, "
    "os serviços mais procurados e as condições climáticas."
)

st.divider()


# =============================================
# CREDENCIAIS DATABRICKS
# =============================================

HOST = os.getenv("DATABRICKS_SERVER_HOSTNAME")
HTTP_PATH = os.getenv("DATABRICKS_HTTP_PATH")
TOKEN = os.getenv("DATABRICKS_TOKEN")


# =============================================
# CONEXAO
# =============================================

@st.cache_resource
def conectar_databricks():
    return sql.connect(
        server_hostname=HOST,
        http_path=HTTP_PATH,
        access_token=TOKEN
    )


# =============================================
# CARREGAMENTO DOS DADOS
# =============================================

@st.cache_data(ttl=300)
def carregar_dados():

    conexao = conectar_databricks()
    cursor = conexao.cursor()

    try:
        cursor.execute("""
            SELECT
                data_key,
                data_hora,
                regiao,
                servico,
                status,
                temperatura,
                precipitacao,
                cidade,
                clima_disponivel
            FROM workspace.gs.vw_mvp_ocorrencias
        """)

        registros = cursor.fetchall()

        colunas = [
            coluna[0]
            for coluna in cursor.description
        ]

        return pd.DataFrame(
            registros,
            columns=colunas
        )

    finally:
        cursor.close()


# =============================================
# VALIDACAO DAS CREDENCIAIS
# =============================================

if not HOST or not HTTP_PATH or not TOKEN:

    st.error(
        "Credenciais do Databricks não encontradas. "
        "Verifique as variáveis de ambiente do PyCharm."
    )

    st.stop()


# =============================================
# CONSULTA
# =============================================

try:

    with st.spinner("Carregando dados do Databricks..."):
        df = carregar_dados()

    if df.empty:
        st.warning("Nenhuma ocorrência encontrada.")
        st.stop()

    st.success(
        "Conectado ao Databricks! "
        "Dados carregados pela View segura do MVP."
    )

except Exception as erro:

    st.error("Erro ao consultar os dados do Databricks.")

    with st.expander("Detalhes do erro"):
        st.code(str(erro))

    st.stop()


# =============================================
# TRATAMENTO DOS DADOS
# =============================================

df["data_hora"] = pd.to_datetime(
    df["data_hora"],
    errors="coerce"
)

df["temperatura"] = pd.to_numeric(
    df["temperatura"],
    errors="coerce"
)

df["precipitacao"] = pd.to_numeric(
    df["precipitacao"],
    errors="coerce"
)

df["regiao"] = df["regiao"].fillna("Não informada")
df["servico"] = df["servico"].fillna("Não informado")
df["status"] = df["status"].fillna("Não informado")
df["cidade"] = df["cidade"].fillna("Não informada")

df["clima_disponivel"] = (
    df["clima_disponivel"]
    .fillna(False)
    .astype(bool)
)

df["data"] = df["data_hora"].dt.date
df["horario"] = df["data_hora"].dt.hour

df = df.dropna(subset=["data_hora"])


# =============================================
# FILTROS
# =============================================

st.sidebar.title("🔎 Filtros")
st.sidebar.write("Personalize os dados apresentados no painel.")

regioes = sorted(df["regiao"].unique().tolist())
servicos = sorted(df["servico"].unique().tolist())

regioes_selecionadas = st.sidebar.multiselect(
    "Regiões",
    options=regioes,
    default=regioes
)

servicos_selecionados = st.sidebar.multiselect(
    "Serviços",
    options=servicos,
    default=servicos
)

data_minima = df["data"].min()
data_maxima = df["data"].max()

periodo = st.sidebar.date_input(
    "Período das ocorrências",
    value=(data_minima, data_maxima),
    min_value=data_minima,
    max_value=data_maxima
)

if st.sidebar.button("Atualizar dados"):

    st.cache_data.clear()
    st.rerun()


# =============================================
# APLICACAO DOS FILTROS
# =============================================

df_filtrado = df[
    df["regiao"].isin(regioes_selecionadas)
    & df["servico"].isin(servicos_selecionados)
].copy()

if isinstance(periodo, (tuple, list)) and len(periodo) == 2:

    data_inicio, data_fim = periodo

    df_filtrado = df_filtrado[
        (df_filtrado["data"] >= data_inicio)
        & (df_filtrado["data"] <= data_fim)
    ]


if df_filtrado.empty:

    st.warning("Nenhuma ocorrência encontrada com os filtros selecionados.")
    st.stop()


# =============================================
# INDICADORES
# =============================================

st.header("Indicadores gerais")

total_ocorrencias = len(df_filtrado)
total_regioes = df_filtrado["regiao"].nunique()

dados_clima = df_filtrado[
    df_filtrado["clima_disponivel"]
    & df_filtrado["temperatura"].notna()
]

temperatura_media = dados_clima["temperatura"].mean()
precipitacao_media = dados_clima["precipitacao"].mean()

col1, col2, col3, col4 = st.columns(4)

col1.metric("Total de ocorrências", total_ocorrencias)
col2.metric("Regiões atendidas", total_regioes)

col3.metric(
    "Temperatura média",
    f"{temperatura_media:.1f} °C"
    if pd.notna(temperatura_media)
    else "Sem dados"
)

col4.metric(
    "Precipitação média",
    f"{precipitacao_media:.2f} mm"
    if pd.notna(precipitacao_media)
    else "Sem dados"
)

st.divider()


# =============================================
# GRAFICOS
# =============================================

st.header("Análise das ocorrências")

coluna1, coluna2 = st.columns(2)

with coluna1:

    st.subheader("Ocorrências por região")

    dados_regiao = (
        df_filtrado
        .groupby("regiao")
        .size()
        .sort_values(ascending=False)
    )

    st.bar_chart(dados_regiao)


with coluna2:

    st.subheader("Serviços mais solicitados")

    dados_servicos = (
        df_filtrado
        .groupby("servico")
        .size()
        .sort_values(ascending=False)
    )

    st.bar_chart(dados_servicos)


# =============================================
# DEMANDA POR HORARIO
# =============================================

st.subheader("Demanda por horário")

dados_horarios = (
    df_filtrado
    .groupby("horario")
    .size()
    .reindex(range(24), fill_value=0)
)

st.line_chart(dados_horarios)


st.divider()


# =============================================
# ANALISE CLIMATICA
# =============================================

st.header("Análise climática")

dados_clima_grafico = df_filtrado[
    df_filtrado["clima_disponivel"]
].copy()

if not dados_clima_grafico.empty:

    col_clima1, col_clima2 = st.columns(2)

    with col_clima1:

        st.subheader("Temperatura média por região")

        temperatura_regiao = (
            dados_clima_grafico
            .groupby("regiao")["temperatura"]
            .mean()
            .dropna()
        )

        st.bar_chart(temperatura_regiao)


    with col_clima2:

        st.subheader("Precipitação média por região")

        precipitacao_regiao = (
            dados_clima_grafico
            .groupby("regiao")["precipitacao"]
            .mean()
            .dropna()
        )

        st.bar_chart(precipitacao_regiao)


    st.metric(
        "Ocorrências com dados climáticos disponíveis",
        f"{len(dados_clima_grafico)} de {total_ocorrencias}"
    )

else:

    st.info("Não existem dados climáticos para os filtros selecionados.")


st.divider()


# =============================================
# TABELA SEM IDENTIFICADORES INTERNOS
# =============================================

st.header("Detalhamento das ocorrências")

colunas_exibidas = [
    "data_hora",
    "regiao",
    "servico",
    "status",
    "temperatura",
    "precipitacao",
    "cidade",
    "clima_disponivel"
]

tabela = df_filtrado[colunas_exibidas].copy()

tabela = tabela.rename(columns={
    "data_hora": "Data e hora",
    "regiao": "Região",
    "servico": "Serviço",
    "status": "Status",
    "temperatura": "Temperatura (°C)",
    "precipitacao": "Precipitação (mm)",
    "cidade": "Cidade",
    "clima_disponivel": "Clima disponível"
})

st.dataframe(
    tabela,
    use_container_width=True,
    hide_index=True
)


# =============================================
# EXPORTACAO CSV
# =============================================

arquivo_csv = tabela.to_csv(
    index=False
).encode("utf-8-sig")

st.download_button(
    label="📥 Exportar ocorrências em CSV",
    data=arquivo_csv,
    file_name="sos_driver_ocorrencias.csv",
    mime="text/csv"
)


# =============================================
# RODAPE
# =============================================

st.divider()

st.caption("SOS Driver | FIAP Global Solution 2026")

st.caption(
    "Fonte: workspace.gs.vw_mvp_ocorrencias "
    "(View da camada Ouro do Databricks)."
)

st.caption(
    "O MVP utiliza dados operacionais agregados e não "
    "disponibiliza identificadores internos de ocorrências."
)
