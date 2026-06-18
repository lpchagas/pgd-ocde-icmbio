"""Public sanitized runner for I07."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("07", "docs/06.3.3-i07.md", "horas_por_entrega")
