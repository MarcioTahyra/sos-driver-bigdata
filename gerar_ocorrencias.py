
import json
import os
import random
from datetime import datetime, timedelta

PASTA = "chegada/ocorrencias"
os.makedirs(PASTA, exist_ok=True)

regioes = [
    "Centro",
    "Zona Sul",
    "Zona Norte",
    "Zona Leste",
    "Zona Oeste"
]

servicos = [
    "guincho",
    "pneu",
    "bateria",
    "pane_seca"
]

status_disponiveis = [
    "concluida",
    "em_andamento",
    "cancelada",
    "aberta"
]

registros = []

# Gera 100 ocorrências distribuídas ao longo do dia atual
inicio_dia = datetime.now().replace(
    hour=0, minute=0, second=0, microsecond=0
)

for i in range(1, 101):
    horario = inicio_dia + timedelta(
        minutes=random.randint(0, 1439)
    )

    registros.append({
        "id_ocorrencia": i,
        "data_hora": horario.strftime("%Y-%m-%dT%H:%M:%S"),
        "regiao": random.choice(regioes),
        "servico": random.choice(servicos),
        "status": random.choice(status_disponiveis)
    })

nome_arquivo = datetime.now().strftime(
    "ocorrencias_%Y%m%d_%H%M%S.json"
)

caminho = os.path.join(PASTA, nome_arquivo)

with open(caminho, "w", encoding="utf-8") as arquivo:
    json.dump(registros, arquivo, ensure_ascii=False, indent=4)

print(f"Geração concluída! {len(registros)} ocorrências criadas.")
print(f"Arquivo: {caminho}")
