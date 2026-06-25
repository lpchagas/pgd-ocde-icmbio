"""Lightweight checks for generated monthly indicator CSV files."""
from __future__ import annotations

import csv
from pathlib import Path


def audit_csv(path: Path) -> list[str]:
    messages: list[str] = []
    if not path.exists():
        return [f"ERRO: arquivo nao encontrado: {path}"]

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle, delimiter="|")
        try:
            header = next(reader)
        except StopIteration:
            return ["ERRO: CSV vazio."]
        row_count = 0
        bad_width = 0
        for row in reader:
            row_count += 1
            if len(row) != len(header):
                bad_width += 1

    messages.append(f"Linhas de dados: {row_count}")
    messages.append(f"Colunas: {len(header)}")
    if bad_width:
        messages.append(f"ALERTA: {bad_width} linhas com quantidade de colunas divergente.")
    else:
        messages.append("Estrutura CSV OK: todas as linhas tem a mesma quantidade de colunas.")
    return messages
