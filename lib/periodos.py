"""ICMBio period rules for monthly indicator exports.

Two distinct functions cover the bifurcation confirmed on 14.06.2026:
  build_periods_pe() — Plano de Entregas: 2025 quarterly, 2026+ four-monthly (Q1–Q3).
  build_periods_pt() — Plano de Trabalho:  2025 quarterly, 2026+ monthly (M01–M12).

The legacy alias build_periods() maps to build_periods_pe() for backward compatibility.

Indicator classification:
  PE (build_periods_pe): I02, I03, I04, I07, I08, I12
  PT (build_periods_pt): I01, I05, I06, I09, I10, I11
"""
from __future__ import annotations

import calendar
from datetime import date


def build_periods_pe(today: date | None = None) -> list[tuple[str, str, date, date, str]]:
    """Return ICMBio Plano de Entregas periods up to today.

    2025: quarterly (T1–T4). 2026 onward: four-monthly (Q1–Q3).
    Future periods are omitted. Open periods are marked ``em_andamento``.
    Used by: I02, I03, I04, I07, I08, I12.
    """
    current = today or date.today()
    raw: list[tuple[str, str, date, date]] = [
        ("T1-2025", "trimestral", date(2025, 1, 1), date(2025, 3, 31)),
        ("T2-2025", "trimestral", date(2025, 4, 1), date(2025, 6, 30)),
        ("T3-2025", "trimestral", date(2025, 7, 1), date(2025, 9, 30)),
        ("T4-2025", "trimestral", date(2025, 10, 1), date(2025, 12, 31)),
    ]
    for year in range(2026, current.year + 1):
        raw.extend(
            [
                (f"Q1-{year}", "quadrimestral", date(year, 1, 1), date(year, 4, 30)),
                (f"Q2-{year}", "quadrimestral", date(year, 5, 1), date(year, 8, 31)),
                (f"Q3-{year}", "quadrimestral", date(year, 9, 1), date(year, 12, 31)),
            ]
        )

    periods: list[tuple[str, str, date, date, str]] = []
    for label, kind, start, end in raw:
        if start > current:
            continue
        status = "em_andamento" if end >= current else "encerrado"
        periods.append((label, kind, start, end, status))
    return periods


def build_periods_pt(today: date | None = None) -> list[tuple[str, str, date, date, str]]:
    """Return ICMBio Plano de Trabalho periods up to today.

    2025: quarterly (T1–T4). 2026 onward: monthly (M01–M12).
    Future periods are omitted. Open periods are marked ``em_andamento``.
    Used by: I01, I05, I06, I09, I10, I11.
    """
    current = today or date.today()
    raw: list[tuple[str, str, date, date]] = [
        ("T1-2025", "trimestral", date(2025, 1, 1), date(2025, 3, 31)),
        ("T2-2025", "trimestral", date(2025, 4, 1), date(2025, 6, 30)),
        ("T3-2025", "trimestral", date(2025, 7, 1), date(2025, 9, 30)),
        ("T4-2025", "trimestral", date(2025, 10, 1), date(2025, 12, 31)),
    ]
    for year in range(2026, current.year + 1):
        for month in range(1, 13):
            last_day = calendar.monthrange(year, month)[1]
            raw.append(
                (f"M{month:02d}-{year}", "mensal", date(year, month, 1), date(year, month, last_day))
            )

    periods: list[tuple[str, str, date, date, str]] = []
    for label, kind, start, end in raw:
        if start > current:
            continue
        status = "em_andamento" if end >= current else "encerrado"
        periods.append((label, kind, start, end, status))
    return periods


# Backward-compatible alias — PE logic (quadrimestral from 2026).
build_periods = build_periods_pe


def period_metadata() -> list[str]:
    return [
        "ciclo_tipo",
        "periodo",
        "periodo_inicio",
        "periodo_fim",
        "periodo_status",
        "duracao_dias",
    ]
