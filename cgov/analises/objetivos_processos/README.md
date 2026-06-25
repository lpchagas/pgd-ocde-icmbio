# Análise: I03 Enriquecido com Objetivos Estratégicos e Processos

**Tipo:** Análise ad-hoc CGOV  
**Base:** Indicador OCDE I03 (Taxa de Cumprimento por Entrega)  
**Enriquecimento:** cadeias_valores, planejamentos_objetivos, cadeias_valores_processos

## Como usar

```powershell
python cgov/analises/objetivos_processos/run.py
python cgov/analises/objetivos_processos/run.py --dry-run
python cgov/analises/objetivos_processos/run.py --month 2026-06
```

## Saída

CSV salvo em `artefatos_local/entregas/YYYY-MM/`

## Status

> Script `run.py` em desenvolvimento. Quando criado, aplicar o ROOT finder padrão:
> ```python
> ROOT = next(p for p in Path(__file__).resolve().parents if (p / "lib" / "__init__.py").exists())
> sys.path.insert(0, str(ROOT))
> ```
