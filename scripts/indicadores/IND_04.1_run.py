"""Public sanitized runner for I04."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("04", "docs/06.2.3-i04.md", "score_atingimento_metas")
