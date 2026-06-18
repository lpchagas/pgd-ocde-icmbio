"""Public sanitized runner for I06."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("06", "docs/06.3.2-i06.md", "grau_responsabilidade_entregas", period_type="pt")
