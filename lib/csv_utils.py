"""CSV and local artifact helpers."""
from __future__ import annotations

import csv
import re
from datetime import date
from pathlib import Path
from typing import Iterable, Sequence


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def clean(value: object, default: str = "") -> str:
    if value is None:
        return default
    text = re.sub(r"[\r\n]+", " / ", str(value)).strip()
    return text or default


def artifact_month(today: date | None = None) -> str:
    current = today or date.today()
    return f"{current.year:04d}-{current.month:02d}"


def indicator_csv_dir(month: str | None = None) -> Path:
    """Pasta de entrega mensal — todos os CSVs de indicadores num único diretório por mês.
    Exemplo: artefatos_local/entregas/2026-06/
    """
    return PROJECT_ROOT / "artefatos_local" / "entregas" / (month or artifact_month())


def diagnostic_csv_dir(month: str | None = None) -> Path:
    """Pasta de CSVs diagnósticos (uso interno — não enviar à COCAGE)."""
    return PROJECT_ROOT / "artefatos_local" / "diagnosticos" / (month or artifact_month())


def write_pipe_csv(path: Path, columns: Sequence[str], rows: Iterable[Sequence[object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle, delimiter="|")
        writer.writerow([clean(col) for col in columns])
        for row in rows:
            writer.writerow([clean(value) for value in row])
