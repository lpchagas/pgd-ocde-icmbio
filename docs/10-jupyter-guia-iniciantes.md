# Guia para iniciantes — Consultas ao Denodo pelo VS Code com Jupyter Notebook

Este guia explica, do zero, como executar consultas SQL no banco PETRVS diretamente pelo VS Code, usando um arquivo chamado `consultas_denodo.ipynb`. Não é necessário nenhum conhecimento prévio de Python.

---

## O que é um Notebook Jupyter? E o arquivo `.ipynb`?

Pense no Notebook como uma **planilha do Excel interativa para código**. Assim como no Excel você tem células onde digita fórmulas e vê os resultados logo abaixo, no Notebook você tem **células onde escreve código Python ou SQL** e o resultado aparece imediatamente abaixo de cada célula.

O arquivo `.ipynb` (abreviação de *IPython Notebook*) é simplesmente o formato de arquivo usado para salvar esse documento. Ele fica gravado no seu computador como qualquer outro arquivo, e você abre direto pelo VS Code.

**Por que usar isso em vez do DBeaver?**

| DBeaver | Notebook no VS Code |
|---|---|
| Executa SQL, mostra tabela | Executa SQL, mostra tabela |
| Exporta para CSV manualmente | Exporta para CSV com uma linha de código |
| Não faz cálculos adicionais | Pode calcular médias, gerar gráficos, filtrar |
| Interface separada | Tudo dentro do VS Code |

---

## Pré-requisito: extensão Jupyter no VS Code

Antes de abrir o notebook pela primeira vez, você precisa instalar a extensão Jupyter no VS Code. Faça isso uma única vez.

**Passo 1** — Na barra lateral esquerda do VS Code, clique no ícone de quatro quadradinhos (Extensions):

```
[ícone de bloco na barra lateral esquerda]
```

**Passo 2** — Na caixa de pesquisa que aparece, digite:

```
Jupyter
```

**Passo 3** — Clique na extensão chamada **"Jupyter"** publicada pela **Microsoft** (é a primeira da lista).

**Passo 4** — Clique no botão azul **"Install"**.

Aguarde a instalação terminar. Isso precisa ser feito apenas uma vez.

---

## Abrindo o notebook

**Passo 1** — No VS Code, vá ao menu **File > Open Folder** e selecione a pasta do projeto:

```
C:\Projetos\DM_Petrvs_icmbio_mysql
```

**Passo 2** — No painel lateral (Explorer), localize e clique no arquivo:

```
consultas_denodo.ipynb
```

O notebook vai abrir. Você verá uma série de blocos (células) com texto explicativo e código.

---

## Selecionando o "kernel" (o motor Python)

Quando você abrir o notebook pela primeira vez, o VS Code vai perguntar qual "kernel" usar. Kernel é simplesmente **qual versão do Python vai executar o código**. Pense nele como o motor do carro — você precisa ligar o motor antes de dirigir.

**O que fazer:**

1. No canto superior direito da tela, você verá um botão escrito algo como **"Select Kernel"** ou **"Python 3"**.
2. Clique nesse botão.
3. Uma lista vai aparecer. Selecione a opção que contenha **Python 3.14** ou **Python 3**.

Se aparecer uma mensagem perguntando se deseja instalar extensões adicionais, clique em **"Install"**.

---

## Entendendo a estrutura do notebook

O arquivo `consultas_denodo.ipynb` está organizado em seções. Veja o que cada parte faz:

### Seção 1 — Configuração da conexão (2 células de código)

Estas células configuram a "ponte" entre o Python e o banco Denodo. É como configurar uma nova conexão no DBeaver — você faz uma vez e não precisa mexer mais.

- **Célula 1:** Carrega as bibliotecas necessárias e aponta para o driver Denodo e o Java.
- **Célula 2:** Cria a função `run_query()` — é ela que você vai usar para executar qualquer consulta SQL.

### Seção 2 — Teste de conexão (1 célula)

Executa uma consulta simples para confirmar que a conexão com o banco está funcionando. Retorna o número de entregas ativas no sistema.

### Seção 3 — Exemplos de indicadores

Contém a query completa do I02 (Taxa de cumprimento das entregas) pronta para executar.

### Consulta livre

Uma célula em branco onde você cola qualquer query do manual técnico para executar.

### Seção 4 — Exportar para CSV

Código pronto para salvar o resultado de qualquer consulta em um arquivo `.csv` na pasta `Tabelas CSV/`.

---

## Executando o teste de conexão — passo a passo

Siga rigorosamente esta ordem. **Cada célula precisa ser executada antes da próxima.**

---

### Passo 1 — Executar a Célula 1 (configuração)

Localize a primeira célula de código (começa com `import os`). Clique dentro dela para selecioná-la.

Para executar, use um destes métodos:

- **Teclado:** pressione `Shift + Enter`
- **Mouse:** clique no botão ▶ (triângulo) que aparece à esquerda da célula

**O que vai acontecer:**

Você verá um círculo girando à esquerda da célula enquanto ela executa. Quando terminar, aparece um número entre colchetes, por exemplo `[1]`, e a mensagem:

```
JVM iniciada: C:\Program Files\DBeaver\jre\bin\server\jvm.dll
Configuração OK.
```

> **O que é "JVM"?** É a máquina virtual Java — o motor que permite ao Python conversar com o banco Denodo. O DBeaver já tem o Java instalado; estamos apenas reutilizando-o.

Se aparecer uma mensagem de erro em vermelho, leia a seção [Resolução de problemas](#resolução-de-problemas) no final deste guia.

---

### Passo 2 — Executar a Célula 2 (funções)

Clique na segunda célula de código (começa com `def get_connection()`). Pressione `Shift + Enter`.

**O que vai acontecer:**

A célula executa rapidamente e mostra:

```
Funções run_query() e get_connection() prontas.
```

Nenhuma conexão com o banco foi feita ainda. Esta célula apenas **define** a função — como criar um atalho no teclado antes de usá-lo.

---

### Passo 3 — Executar o Teste de Conexão

Clique na célula de teste (começa com `df_teste = run_query(...)`). Pressione `Shift + Enter`.

**Esta célula faz a primeira conexão real com o Denodo.** Pode demorar entre 5 e 20 segundos na primeira vez.

**Se a conexão funcionar**, o resultado aparece como uma tabela logo abaixo da célula:

```
   total_entregas_ativas
0                  14727
```

O número pode ser diferente (os dados são em tempo real). Isso significa que tudo está funcionando.

**Se aparecer erro**, veja a seção [Resolução de problemas](#resolução-de-problemas).

---

## Executando uma query completa — exemplo com o I02

Com a conexão funcionando, você pode executar qualquer indicador.

**Passo 1** — Role a tela até a seção **"I02 — Taxa de cumprimento das entregas por unidade"**.

**Passo 2** — Se quiser mudar o período de análise, altere as datas na linha:

```python
DATE('2025-01-01') AS data_inicio,
DATE('2025-12-31') AS data_fim,
```

Substitua `2025-01-01` e `2025-12-31` pelas datas desejadas, mantendo o formato `AAAA-MM-DD`.

**Passo 3** — Pressione `Shift + Enter` para executar.

O resultado aparece como uma tabela com as colunas:

| unidade | total_entregas | entregas_concluidas | taxa_cumprimento_perc |
|---|---|---|---|
| CGOV | 120 | 98 | 81.7 |
| CGOF | 85 | 71 | 83.5 |
| ... | ... | ... | ... |

---

## Executando uma query do manual técnico

Para usar qualquer query dos documentos `docs/06.x-ixxx.md`:

**Passo 1** — Abra o documento do indicador desejado (ex.: [06.2.2-i03.md](06.2.2-i03.md)).

**Passo 2** — Copie o bloco de código SQL completo (começa com `WITH parametros AS` e vai até o `ORDER BY` final).

**Passo 3** — No notebook, role até a seção **"Consulta livre"**.

**Passo 4** — Apague o conteúdo atual da variável `sql_livre` e cole a query copiada entre as aspas triplas `"""`:

```python
sql_livre = """
COLE AQUI A QUERY
"""
```

**Passo 5** — Pressione `Shift + Enter`.

---

## Exportando o resultado para CSV

Após executar uma query, você pode salvar o resultado. Role até a seção **"Exportar resultado para CSV"**.

**Passo 1** — Na linha abaixo, substitua `df_i02` pelo nome do DataFrame que deseja exportar:

```python
# Se quiser exportar o resultado da consulta livre:
output_path = r"Tabelas CSV\minha_consulta.csv"
df.to_csv(output_path, ...)
```

Os nomes disponíveis são:
- `df_i02` — resultado do I02
- `df_teste` — resultado do teste de conexão
- `df` — resultado da consulta livre

**Passo 2** — Altere o nome do arquivo em `output_path` para identificar o que foi exportado.

**Passo 3** — Pressione `Shift + Enter`.

O arquivo será salvo automaticamente na pasta `Tabelas CSV/` do projeto.

---

## Executando todas as células de uma vez

Se quiser executar o notebook inteiro de uma vez (por exemplo, ao reabrir o VS Code no dia seguinte):

- Vá ao menu **Run > Run All Cells** (ou use o botão **"Run All"** no topo do notebook)

As células executam na ordem de cima para baixo automaticamente.

> **Importante:** sempre que você fechar e reabrir o VS Code, o kernel é desligado. Você precisa executar as células de configuração (Células 1 e 2) novamente antes de fazer consultas.

---

## Resolução de problemas

### Erro: "JVM não encontrada" ou "java.exe not found"

O Java embutido no DBeaver não foi localizado. Verifique se o DBeaver está instalado em `C:\Program Files\DBeaver`. Se estiver em outro local, abra o notebook e ajuste o caminho na linha:

```python
JAVA_HOME = r"C:\Program Files\DBeaver\jre"
```

---

### Erro: "Connection refused" ou "Unable to connect"

Significa que o banco Denodo recusou a conexão. Causas possíveis:

1. **IP não liberado** — o IP da sua máquina (`192.168.0.37`) precisa estar na lista de permissões do Dataprev. Entre em contato com o Dataprev para liberar o acesso.
2. **VPN desconectada** — se a sua instituição usa VPN para acessar o Denodo, verifique se ela está ativa.
3. **Sem internet** — verifique a conexão de rede.

---

### Erro: "ModuleNotFoundError: No module named 'jaydebeapi'"

As bibliotecas Python não foram instaladas corretamente. Abra um terminal no VS Code (**Terminal > New Terminal**) e execute:

```
pip install jpype1 jaydebeapi pandas ipykernel
```

---

### O resultado aparece vazio (DataFrame sem linhas)

Verifique se as datas no bloco `parametros` da query cobrem um período com dados. Tente ampliar o intervalo, por exemplo de `2024-01-01` a `2025-12-31`.

---

### A célula fica executando indefinidamente (círculo girando por mais de 2 minutos)

Pode ser que a conexão com o Denodo travou. Clique no botão **"Interrupt Kernel"** (ícone de quadrado ■ ao lado do botão ▶) para interromper. Verifique a conectividade de rede e tente novamente.

---

## Referências

- Notebook de consultas: [consultas_denodo.ipynb](../consultas_denodo.ipynb)
- Manual técnico dos indicadores: [06-indicadores-ocde-mysql.md](06-indicadores-ocde-mysql.md)
- Configuração da conexão Denodo: [03-acesso-direto-denodo-dbeaver.md](03-acesso-direto-denodo-dbeaver.md)
