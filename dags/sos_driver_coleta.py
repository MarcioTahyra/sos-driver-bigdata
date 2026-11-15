
import json
import random
import urllib.request
import uuid
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from airflow.sdk import dag, task

FUSO = ZoneInfo("America/Sao_Paulo")
PASTA = Path("/opt/airflow/chegada")


@dag(
    dag_id="sos_driver_coleta",
    schedule="0 8 * * *",
    start_date=datetime(2026, 11, 15, tzinfo=FUSO),
    catchup=False,
    tags=["sos-driver", "big-data"],
)
def sos_driver_coleta():

    @task
    def coletar_clima():
        url = (
            "https://api.open-meteo.com/v1/forecast"
            "?latitude=-23.5505"
            "&longitude=-46.6333"
            "&hourly=temperature_2m,precipitation"
            "&forecast_days=1"
            "&timezone=America%2FSao_Paulo"
        )

        with urllib.request.urlopen(url, timeout=30) as resposta:
            dados = json.loads(resposta.read().decode("utf-8"))

        registros = []

        horas = dados["hourly"]["time"]

        for i, hora in enumerate(horas):
            registros.append({
                "data_hora": hora.replace("T", " "),
                "temperatura": dados["hourly"]["temperature_2m"][i],
                "precipitacao": dados["hourly"]["precipitation"][i],
                "cidade": "São Paulo"
            })

        pasta = PASTA / "clima"
        pasta.mkdir(parents=True, exist_ok=True)

        arquivo = pasta / f"clima_{datetime.now(FUSO):%Y%m%d_%H%M%S}.json"

        with open(arquivo, "w", encoding="utf-8") as f:
            json.dump(registros, f, ensure_ascii=False, indent=4)

        return str(arquivo)

    @task
    def gerar_ocorrencias():
        regioes = [
            "Centro", "Zona Norte", "Zona Sul",
            "Zona Leste", "Zona Oeste"
        ]

        servicos = ["guincho", "pneu", "bateria", "pane_seca"]
        status = ["concluida", "em_andamento", "pendente"]

        agora = datetime.now(FUSO)
        registros = []

        for i in range(100):
            hora = random.randint(0, 23)
            minuto = random.randint(0, 59)

            data_hora = agora.replace(
                hour=hora,
                minute=minuto,
                second=0,
                microsecond=0
            )

            registros.append({
                "id_ocorrencia": uuid.uuid4().int & ((1 << 63) - 1),
                "data_hora": data_hora.strftime("%Y-%m-%d %H:%M:%S"),
                "regiao": random.choice(regioes),
                "servico": random.choice(servicos),
                "status": random.choice(status)
            })

        pasta = PASTA / "ocorrencias"
        pasta.mkdir(parents=True, exist_ok=True)

        arquivo = pasta / f"ocorrencias_{datetime.now(FUSO):%Y%m%d_%H%M%S}.json"

        with open(arquivo, "w", encoding="utf-8") as f:
            json.dump(registros, f, ensure_ascii=False, indent=4)

        return str(arquivo)

    @task
    def validar_arquivos(arquivo_clima, arquivo_ocorrencias):
        for caminho in [arquivo_clima, arquivo_ocorrencias]:
            arquivo = Path(caminho)

            if not arquivo.exists():
                raise FileNotFoundError(caminho)

            with open(arquivo, "r", encoding="utf-8") as f:
                dados = json.load(f)

            if not dados:
                raise ValueError(f"Arquivo vazio: {caminho}")

            print(f"Arquivo validado: {caminho}")
            print(f"Registros encontrados: {len(dados)}")

    clima = coletar_clima()
    ocorrencias = gerar_ocorrencias()

    validar_arquivos(clima, ocorrencias)


sos_driver_coleta()
