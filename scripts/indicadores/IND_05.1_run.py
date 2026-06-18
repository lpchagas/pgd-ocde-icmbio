"""Public sanitized runner for I05."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("05", "docs/06.3.1-i05.md", "distribuicao_entregas_servidores", period_type="pt")
