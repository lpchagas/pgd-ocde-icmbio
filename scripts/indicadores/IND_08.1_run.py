"""Public sanitized runner for I08."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("08", "docs/06.3.4-i08.md", "proporcao_horas_entrega")
