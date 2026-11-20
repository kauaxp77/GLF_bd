<p align="center">
  <img src="docs/banner.png" alt="GLF - Sistema de Gestão de Loja de Ferramentas" width="100%">
</p>

<h1 align="center">🛠️ GLF — Sistema de Gestão de Loja de Ferramentas</h1>

<p align="center">
  Banco de dados relacional para a gestão de uma loja de ferramentas, materiais de construção e ferragens,
  com as regras de negócio implementadas <b>dentro do SGBD</b> por meio de <b>triggers</b>, <b>stored procedures</b>
  e <b>functions</b>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL 8.0">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Compose">
  <img src="https://img.shields.io/badge/Normaliza%C3%A7%C3%A3o-3FN-1e8f3e?style=for-the-badge" alt="3ª Forma Normal">
  <img src="https://img.shields.io/badge/Triggers%20%26%20Procedures-SGBD-f59e0b?style=for-the-badge" alt="Triggers e Procedures">
</p>

<p align="center">
  <a href="#-sobre-o-projeto">Sobre</a> •
  <a href="#-problema-de-negócio-e-solução">Problema</a> •
  <a href="#-como-executar-o-projeto">Como executar</a> •
  <a href="#-diagramas-de-banco-de-dados">Diagramas</a> •
  <a href="#-dicionário-de-dados">Dicionário</a> •
  <a href="#-regras-de-negócio-no-sgbd">Regras no SGBD</a> •
  <a href="#-roteiro-de-demonstração-e-validação">Demonstração</a> •
  <a href="#-estrutura-de-arquivos">Estrutura</a>
</p>

---

## 📌 Sobre o Projeto

O **GLF (Gestão de Loja de Ferramentas)** foi desenvolvido como projeto prático da disciplina de **Tópicos Avançados em Banco de Dados (TABD)**. O objetivo foi projetar um banco de dados relacional robusto, com integridade referencial estrita e total encapsulamento da lógica de negócio na camada de persistência.

### Princípio da Soberania do Banco de Dados
Diferente de sistemas que delegam cálculos e validações unicamente ao backend (Node, Python, Java), no GLF as regras mais sensíveis residem **dentro do próprio SGBD**:
* Nenhum cliente (seja um app web, mobile, PDV ou acesso direto via DBeaver) consegue vender produtos sem estoque ou adulterar pedidos fechados.
* Totais de pedidos, cálculos de margem de lucro e baixas fiscais são disparados automaticamente pelo motor relacional.

---

## 🎯 Problema de Negócio e Solução

Lojas de ferramentas operam com alto volume de itens (SKUs), múltiplos fornecedores por peça com cotações concorrentes e fluxo de caixa com múltiplos pagamentos parciais (PIX + Cartão).

| Desafio Operacional | Solução no GLF (SGBD) |
|---|---|
| **Venda sem estoque físico** | Trigger `trg_movimentacao_bi` impede saída maior que o saldo em loja com `SIGNAL SQLSTATE '45000'`. |
| **Cotação de fornecedores dispersa** | Tabela associativa `produto_fornecedor` guarda cotações e a procedure `sp_relatorio_estoque_baixo` elege automaticamente o menor custo de reposição. |
| **Divergência de valores no carrinho** | Trigger `trg_item_pedido_ai/au/ad` recalcula o total do pedido dinamicamente a cada inclusão, edição ou exclusão de item. |
| **Baixa indevida de estoque em vendas não pagas** | Procedure `sp_registrar_pagamento` e Trigger `trg_pedido_au` só efetuam a baixa física quando o valor acumulado quita 100% da compra. |
| **Cancelamento de compra sem devolução de mercadoria** | Trigger `trg_pedido_au` gera entrada automática de estorno se o pedido for cancelado. |

---

## 🚀 Como Executar o Projeto

O projeto conta com ambiente completo e reprodutível via **Docker Compose**. O script de estrutura e carga inicial (`sql/01_script_completo.sql`) é executado automaticamente na inicialização do container.

### 1. Pré-requisitos
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e em execução.
* Um cliente SQL (recomendado: [DBeaver Community](https://dbeaver.io/) ou [MySQL Workbench](https://www.mysql.com/products/workbench/)).

### 2. Subir o Banco de Dados
Abra o terminal na pasta do projeto e execute:

```bash
docker compose up -d
```

O container inicializará o MySQL 8.0, criará o banco `glf_loja_ferramentas` e aplicará a carga das 12 tabelas, dados de teste, functions, procedures e triggers.

### 3. Parâmetros de Conexão

| Parâmetro | Valor |
|---|---|
| **Host** | `localhost` ou `127.0.0.1` |
| **Porta** | `3306` |
| **Database** | `glf_loja_ferramentas` |
| **Usuário** | `root` |
| **Senha** | `root` |

### 4. Configuração Obrigatória no DBeaver
Para evitar erros de handshake com o MySQL 8 no Docker:
1. Ao criar a conexão, clique na aba **Driver Properties** (Propriedades do driver).
2. Configure os seguintes parâmetros:
   * `allowPublicKeyRetrieval` = `true`
   * `useSSL` = `false`
   * `allowMultiQueries` = `true`
3. Clique em **Testar Conexão** e finalize.

---

## 📐 Diagramas de Banco de Dados

### 4.1. Diagrama de Entidade e Relacionamento (DER Conceitual)

O modelo conceitual descreve as entidades do domínio, atributos-chave e as relações de negócio.

![Diagrama de Entidade e Relacionamento](docs/diagramas/der_conceitual.png)

#### Mapeamento de Cardinalidades:
* **`CLIENTE` possui `ENDERECO` (1:N):** Um cliente pode possuir múltiplos endereços cadastrados para entrega ou faturamento; cada endereço pertence exclusivamente a um cliente (`ON DELETE CASCADE`).
* **`CLIENTE` realiza `PEDIDO` (1:N):** Um cliente pode abrir diversos pedidos ao longo do tempo.
* **`FUNCIONARIO` atende `PEDIDO` (1:N):** Cada pedido possui um funcionário responsável pelo atendimento e comissão.
* **`PEDIDO` entrega em `ENDERECO` (N:1, opcional):** O pedido pode vincular um endereço de entrega do cliente ou ser nulo em caso de retirada presencial em balcão.
* **`PEDIDO` contém `PRODUTO` (N:N via `ITEM_PEDIDO`):** Relacionamento associativo contendo atributos próprios da venda (`quantidade` e `preco_unitario` praticado no momento da compra).
* **`PEDIDO` gera `PAGAMENTO` (1:N):** Permite pagamentos múltiplos e fracionados (ex.: entrada de R$ 300 via PIX e o saldo restante em 3x no cartão de crédito).
* **`CATEGORIA` classifica `PRODUTO` (1:N) & `MARCA` fabrica `PRODUTO` (1:N):** Classificação dimensional do catálogo de ferragens.
* **`FORNECEDOR` fornece `PRODUTO` (N:N via `PRODUTO_FORNECEDOR`):** Múltiplos fornecedores podem cotar o mesmo produto; armazena o histórico do `preco_compra`.
* **`PRODUTO` movimenta `MOVIMENTACAO_ESTOQUE` (1:N) & `FUNCIONARIO` registra (1:N):** Toda alteração física (entrada, saída de venda ou ajuste de inventário) fica auditada com data, hora, tipo e funcionário responsável.

---

### 4.2. Modelo Lógico / Físico Relacional

Representação normalizada até a **Terceira Forma Normal (3FN)** com chaves primárias, estrangeiras e restrições de integridade física.

![Modelo Físico](docs/diagramas/modelo_fisico.png)

---

## 🗄 Dicionário de Dados

O banco de dados é composto por 12 tabelas normalizadas com engine **InnoDB** e codificação `utf8mb4_0900_ai_ci`.

```mermaid
erDiagram
    CATEGORIA ||--o{ PRODUTO : classifica
    MARCA ||--o{ PRODUTO : fabrica
    PRODUTO ||--o{ PRODUTO_FORNECEDOR : cotado
    FORNECEDOR ||--o{ PRODUTO_FORNECEDOR : fornece
    CLIENTE ||--o{ ENDERECO : reside
    CLIENTE ||--o{ PEDIDO : realiza
    FUNCIONARIO ||--o{ PEDIDO : atende
    ENDERECO ||--o{ PEDIDO : entrega
    PEDIDO ||--|{ ITEM_PEDIDO : contem
    PRODUTO ||--o{ ITEM_PEDIDO : compoe
    PEDIDO ||--o{ PAGAMENTO : quitado_por
    PRODUTO ||--o{ MOVIMENTACAO_ESTOQUE : registra
    FUNCIONARIO ||--o{ MOVIMENTACAO_ESTOQUE : opera
```

### Resumo das Tabelas e Constraints:

| Tabela | Função | Chave Primária (PK) | Chaves Estrangeiras (FK) | Constraints de Validação |
|---|---|---|---|---|
| **`categoria`** | Categorização de produtos | `id_categoria` | - | `UNIQUE (nome)` |
| **`marca`** | Fabricantes das ferramentas | `id_marca` | - | `UNIQUE (nome)` |
| **`fornecedor`** | Distribuidores e fabricantes parceiros | `id_fornecedor` | - | `UNIQUE (cnpj)` |
| **`produto`** | Cadastro principal de itens | `id_produto` | `id_categoria`, `id_marca` | `UNIQUE (sku)`, `preco_custo >= 0`, `preco_venda >= 0`, `qtd_estoque >= 0` |
| **`produto_fornecedor`** | Cotações de fornecedores | `(id_produto, id_fornecedor)` | `id_produto`, `id_fornecedor` | `preco_compra >= 0` |
| **`cliente`** | Clientes PF ou PJ | `id_cliente` | - | `UNIQUE (cpf_cnpj)`, `tipo_pessoa IN ('F', 'J')` |
| **`endereco`** | Endereços vinculados ao cliente | `id_endereco` | `id_cliente` | `ON DELETE CASCADE` com o cliente |
| **`funcionario`** | Colaboradores da loja | `id_funcionario` | - | `UNIQUE (cpf)`, `salario > 0` |
| **`pedido`** | Cabeçalho de compras e status | `id_pedido` | `id_cliente`, `id_funcionario`, `id_endereco_entrega` | `status IN ('ABERTO', 'PAGO', 'ENVIADO', 'ENTREGUE', 'CANCELADO')` |
| **`item_pedido`** | Produtos vinculados ao pedido | `(id_pedido, id_produto)` | `id_pedido`, `id_produto` | `quantidade > 0`, `preco_unitario >= 0` |
| **`pagamento`** | Transações financeiras | `id_pagamento` | `id_pedido` | `valor > 0`, `qtd_parcelas BETWEEN 1 AND 12`, formas válidas |
| **`movimentacao_estoque`**| Auditoria de estoque | `id_movimentacao` | `id_produto`, `id_funcionario` | `tipo IN ('ENTRADA', 'SAIDA', 'AJUSTE')`, `quantidade > 0` |

---

## ⚙ Regras de Negócio no SGBD

O diferencial técnico do projeto é a implementação nativa de lógica procedural e reativa no MySQL.

### 6.1. User-Defined Functions (UDFs)
*Consultas e cálculos puros sem efeito colateral:*

* **`fn_total_pedido(id_pedido) -> DECIMAL(10,2)`**: Calcula a soma de `(quantidade × preco_unitario)` de todos os itens do pedido e desconta o abatimento, retornando o valor líquido final.
* **`fn_valor_pago(id_pedido) -> DECIMAL(10,2)`**: Retorna o montante total de pagamentos já registrados com status `APROVADO`.
* **`fn_margem_lucro(id_produto) -> DECIMAL(6,2)`**: Retorna a margem percentual de lucro da loja naquele item: `ROUND((preco_venda - preco_custo) / preco_venda * 100, 2)`.
* **`fn_situacao_estoque(id_produto) -> VARCHAR(20)`**: Classifica dinamicamente a situação do produto em:
  * `'SEM ESTOQUE'` (se `qtd_estoque = 0`).
  * `'REPOR ESTOQUE'` (se `qtd_estoque <= estoque_minimo`).
  * `'OK'` (se acima do estoque de segurança).

### 6.2. Stored Procedures
*Orquestração de transações atômicas:*

* **`sp_registrar_pagamento(p_id_pedido, p_forma, p_valor, p_parcelas)`**:
  * Executa sob bloco transacional seguro (`START TRANSACTION` / `COMMIT` / `ROLLBACK`).
  * Bloqueia o registro do pedido com trava de concorrência (`FOR UPDATE`).
  * Valida se o pedido está `ABERTO` e bloqueia valores superiores ao saldo devedor restante.
  * Registra o pagamento na tabela `pagamento`.
  * Se o valor acumulado quitar integralmente a dívida, atualiza o status do pedido para **`PAGO`** (o que dispara a trigger de baixa física).
* **`sp_recalcular_total_pedido(p_id_pedido)`**:
  * Atualiza a coluna `valor_total` na tabela `pedido` invocando `fn_total_pedido`.
* **`sp_relatorio_estoque_baixo()`**:
  * Consulta os itens deficitários e realiza subquery analítica elegendo o fornecedor com o menor preço cotado para cada item.

### 6.3. Triggers
*Policiamento preventivo e automações em cascata:*

```
[Cliente Adiciona Item] ──► trg_item_pedido_bi (Valida se pedido está ABERTO)
                        ──► trg_item_pedido_ai (Recalcula total via procedure)

[Quitação do Pedido]    ──► trg_pedido_au (Identifica status PAGO)
                        ──► Gera SAIDA em movimentacao_estoque
                        ──► trg_movimentacao_bi (Verifica se há estoque físico)
                        ──► trg_movimentacao_ai (Baixa qtd_estoque do produto)

[Cancelamento do Pedido]──► trg_pedido_au (Identifica status CANCELADO)
                        ──► Gera ENTRADA de estorno em movimentacao_estoque
                        ──► trg_movimentacao_ai (Devolve itens ao estoque)
```

1. **`trg_movimentacao_bi`** (*BEFORE INSERT em movimentacao_estoque*): Impede estoque negativo. Cancela qualquer saída que exceda a quantidade física atual.
2. **`trg_movimentacao_ai`** (*AFTER INSERT em movimentacao_estoque*): Atualiza fisicamente a coluna `qtd_estoque` na tabela `produto` (soma na entrada, subtrai na saída ou define no ajuste).
3. **`trg_item_pedido_bi`** (*BEFORE INSERT em item_pedido*): Bloqueia alteração ou inclusão de itens caso o pedido não esteja com status `ABERTO`.
4. **`trg_item_pedido_ai`** (*AFTER INSERT em item_pedido*): Dispara recálculo automático do valor total do pedido.
5. **`trg_item_pedido_au`** (*AFTER UPDATE em item_pedido*): Recalcula total caso haja alteração de quantidade ou preço.
6. **`trg_item_pedido_ad`** (*AFTER DELETE em item_pedido*): Recalcula total caso algum item seja excluído.
7. **`trg_pedido_au`** (*AFTER UPDATE em pedido*):
   * Quando o status vai para `PAGO`, gera as movimentações de `SAIDA` correspondentes aos itens comprados.
   * Quando o pedido pago/enviado é alterado para `CANCELADO`, gera as movimentações de `ENTRADA` correspondentes para estorno do estoque.

---

## 🧪 Roteiro de Demonstração e Validação

O arquivo [`sql/02_demonstracao.sql`](sql/02_demonstracao.sql) contém o roteiro prático com comprovações de **ANTES** e **DEPOIS**:

### Fluxo da Demonstração:
1. **Blocos 1 e 2:** Exibição das functions de cálculo de margem e da procedure de cotação de fornecedores.
2. **Bloco 3:** Criação do pedido com 2 furadeiras e 3 trenas com R$ 10 de desconto — o `valor_total` de R$ 709,50 é calculado pelas triggers.
3. **Bloco 4:** Pagamento parcial de R$ 300 via PIX — o pedido permanece `ABERTO` e o estoque não se altera.
4. **Bloco 5 (ANTES e DEPOIS da Baixa):**
   * *ANTES:* Furadeira com 14 unidades, trena com 38.
   * *Ação:* Quitação no cartão de crédito de R$ 409,50.
   * *DEPOIS:* Status vira `PAGO`, estoque da furadeira cai para 12 e da trena para 35.
5. **Bloco 6 (Erros Esperados):**
   * Tentativa de inserir item em pedido pago (barrado por trigger).
   * Tentativa de saída maior que estoque (barrado por trigger).
   * Tentativa de pagamento acima do saldo devedor (barrado por procedure).
6. **Bloco 7 (Reposição):** Entrada via compra repõe nível a laser de 2 para 7 unidades e a situação muda de `'REPOR ESTOQUE'` para `'OK'`.
7. **Bloco 8 (Cancelamento):** Cancelamento do pedido estorna automaticamente as furadeiras de volta a 14 e trenas a 38.

Para refazer a demonstração do zero, execute de novo o `sql/01_script_completo.sql` (no DBeaver, **Alt+X**) e depois
o `sql/02_demonstracao.sql`.

---

## 📁 Estrutura de Arquivos

```text
GLF_bd/
├── sql/
│   ├── 01_script_completo.sql          # Tabelas, dados de teste, functions, procedures e triggers
│   └── 02_demonstracao.sql             # Roteiro prático da apresentação (antes e depois)
├── docs/
│   ├── diagramas/
│   │   ├── der_conceitual.png          # Modelo conceitual (DER)
│   │   └── modelo_fisico.png           # Modelo lógico/físico relacional
│   ├── documentacao_glf.pdf            # Documentação acadêmica completa
│   ├── documentacao_glf.docx           # Versão editável da documentação
│   ├── funcoes_procedures_triggers.txt # Resumo dos objetos do banco
│   └── banner.png                      # Banner deste README
├── docker-compose.yml                  # MySQL 8.0 com carga automática do script
└── README.md
```

---

## 👨‍💻 Autor e Informações Acadêmicas

* **Autor:** Wendson Kauã Carvalho da Silva
* **Matrícula:** `202511894`
* **Disciplina:** Tópicos Avançados em Banco de Dados (TABD)
* **SGBD Utilizado:** MySQL Community Server 8.0
* **Local e Data:** Taguatinga-DF, Novembro de 2026
