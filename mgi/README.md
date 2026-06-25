# mgi/ — Indicadores de Gestão de Pessoas (MGI)

> Em construção. Os scripts MGI serão implementados aqui, seguindo o mesmo padrão
> dos scripts OCDE em `ocde/indicadores/`.

## Estrutura prevista

- `indicadores/` — scripts `MGI_XX.1_run.py` para cada indicador MGI
- Módulos compartilhados: `lib/` (raiz do repositório — mesmos módulos usados pela iniciativa OCDE)
- Documentação técnica: `docs/mgi/`

## Modelo de referência

Seguir o padrão canônico estabelecido em `ocde/`:

- Script de indicador: `ocde/indicadores/IND_02.1_run.py`
- Ficha técnica: `docs/ocde/06.2.1-i02.md`
- Módulos compartilhados: `lib/denodo_config.py`, `lib/periodos.py`, `lib/csv_utils.py`
