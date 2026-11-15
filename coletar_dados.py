import requests
import json
import os
from datetime import datetime, timezone

# Pasta onde os arquivos serão salvos
PASTA_CLIMA = "chegada/clima"
os.makedirs(PASTA_CLIMA, exist_ok=True)

# Localização de São Paulo
latitude = -23.5505
longitude = -46.6333

# Consulta à API Open-Meteo
url = "https://api.open-meteo.com/v1/forecast"

parametros = {
    "latitude": latitude,
    "longitude": longitude,
    "hourly": "temperature_2m,precipitation",
    "forecast_days": 1,
    "timezone": "America/Sao_Paulo"
}

resposta = requests.get(url, params=parametros, timeout=30)
resposta.raise_for_status()

dados = resposta.json()

# Organiza os dados por horário
registros = []

for i, horario in enumerate(dados["hourly"]["time"]):
    registros.append({
        "data_hora": horario,
        "temperatura": dados["hourly"]["temperature_2m"][i],
        "precipitacao": dados["hourly"]["precipitation"][i],
        "cidade": "São Paulo"
    })

# Salva o arquivo JSON
nome_arquivo = datetime.now().strftime("clima_%Y%m%d_%H%M%S.json")
caminho = os.path.join(PASTA_CLIMA, nome_arquivo)

with open(caminho, "w", encoding="utf-8") as arquivo:
    json.dump(registros, arquivo, ensure_ascii=False, indent=4)

print(f"Coleta concluída! {len(registros)} registros salvos.")
print(f"Arquivo: {caminho}")
