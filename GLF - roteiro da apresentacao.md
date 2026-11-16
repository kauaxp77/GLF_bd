# GLF – Roteiro Operacional da Apresentação (5 minutos)

Guia prático para execução no **DBeaver** conectado ao container Docker com demonstrações de **ANTES** e **DEPOIS**.

---

## 1. Preparação (Antes de Chamar a Banca)

1. **Certifique-se de que o container está ativo:**
   * No terminal: `docker compose up -d`
2. **Conexão no DBeaver:**
   * **Host:** `localhost` | **Porta:** `3306` | **Banco:** `glf_loja_ferramentas`
   * **Usuário:** `root` | **Senha:** `root`
   * Em **Driver Properties** (Propriedades do driver):
     * `allowPublicKeyRetrieval` = `TRUE`
     * `useSSL` = `FALSE`
     * `allowMultiQueries` = `TRUE`
3. **Limpeza da base (Estado Inicial Garantido):**
   * Abra o arquivo `GLF - 01 script completo (MySQL).sql`.
   * Pressione **`Alt+X`** (Executar script completo) e aguarde concluir.
4. **Abrir a demonstração:**
   * Abra o arquivo `GLF - 02 demonstracao (apresentacao).sql` em **apenas uma aba** de editor SQL.

---

## 2. Passo a Passo Durante a Apresentação (≈ 5 min)

### Bloco 0: Abertura (0:00 – 0:30)
* **Ação:** Mostre a lista de 12 tabelas no painel esquerdo do DBeaver.
* **O que falar:** 
  > *"Este é o GLF, sistema de gestão para loja de ferramentas com 12 tabelas normalizadas. As regras de negócio críticas não estão na camada de aplicação, mas blindadas no próprio SGBD através de 7 triggers, 3 procedures e 4 functions."*

---

### Bloco 1: Functions de Negócio (0:30 – 1:00)
* **Código no arquivo 02:** Linhas 10 a 16.
* **Ação no DBeaver:** Selecione as linhas 10 a 16 e pressione **`Ctrl+Enter`**.
* **O que apontar na tela:** As 3 linhas retornadas com as colunas `margem_pct` e `situacao`.
* **O que falar:** 
  > *"Aqui vemos duas functions em tempo real aplicadas sobre produtos-chave: a `fn_margem_lucro` calcula a margem percentual com base em custo e venda. E a `fn_situacao_estoque` compara a quantidade física com o estoque mínimo, classificando a furadeira como 'OK' e a parafusadeira e o nível a laser como 'REPOR ESTOQUE'."*

---

### Bloco 2: Procedure de Cotação e Reposição (1:00 – 1:30)
* **Código no arquivo 02:** Linha 20 (`CALL sp_relatorio_estoque_baixo();`).
* **Ação no DBeaver:** Posicione o cursor na linha 20 e pressione **`Ctrl+Enter`**.
* **O que apontar na tela:** As colunas mostrando exatamente os dois itens deficitários e o fornecedor mais barato (`Distribuidora Ferramax`).
* **O que falar:** 
  > *"A procedure `sp_relatorio_estoque_baixo` cruza os produtos deficitários com a cotação de fornecedores e entrega para compras o menor preço cotado para cada item."*

---

### Bloco 3: Triggers de Pedido e Total Automático (1:30 – 2:15)
* **Código no arquivo 02:** Linhas 24 a 37.
* **Ação no DBeaver:** Selecione da linha 24 até a 37 e pressione **`Ctrl+Enter`** (ou execute em etapas: 3a, 3b e 3c).
* **O que apontar na tela:** O resultado do SELECT mostrando `valor_total = 709.50` e `status = 'ABERTO'`.
* **O que falar:** 
  > *"Inserimos um pedido com 2 furadeiras e 3 trenas e R$ 10 de desconto. O campo `valor_total` (R$ 709,50) foi calculado e gravado automaticamente pela trigger de item de pedido (`trg_item_pedido_ai`), sem cálculo no cliente."*

---

### Bloco 4: Pagamento Parcial (2:15 – 2:45)
* **Código no arquivo 02:** Linhas 40 a 44.
* **Ação no DBeaver:** Selecione e pressione **`Ctrl+Enter`**.
* **O que apontar na tela:** `status` continua `ABERTO`, `total_pago = 300.00`.
* **O que falar:** 
  > *"Registramos R$ 300 via PIX pela procedure `sp_registrar_pagamento`. O status continua ABERTO porque faltam R$ 409,50. O estoque ainda não foi baixado."*

---

### Bloco 5: DEMONSTRAÇÃO 1 – Quitação e Baixa de Estoque (2:45 – 3:30)
1. **Verificar ANTES (Linhas 49 a 51):**
   * Execute o SELECT do ANTES.
   * **Mostre na tela:** Coluna `momento: ANTES` com estoque da furadeira em **14** e trena em **38**.
2. **Quitar no Cartão (Linha 54):**
   * Execute o `CALL sp_registrar_pagamento(@pedido, 'CARTAO_CREDITO', 409.50, 3);`.
3. **Verificar DEPOIS (Linhas 57 a 63):**
   * Execute os SELECTs do DEPOIS.
   * **Mostre na tela:** Status mudou para **`PAGO`** e a coluna `momento: DEPOIS` mostra a furadeira baixada de **14 para 12** e a trena de **38 para 35**.
4. **Verificar Histórico Fiscal (Linhas 66 a 68):**
   * Execute a consulta da tabela `movimentacao_estoque`.
   * **Mostre na tela:** As 2 saídas geradas pela trigger `trg_pedido_au`.

---

### Bloco 6: Regras Barrando Operações Inválidas (3:30 – 4:00)
> **Aviso:** Avise a banca que os 3 comandos abaixo devem gerar **erro vermelho**.

1. **6a - Bloqueio de item em pedido pago (Linha 75):**
   * Execute a linha 75. 
   * **O que falar:** *"A trigger `trg_item_pedido_bi` bloqueia a adição de itens em pedido já pago."*
2. **6b - Bloqueio de saída sem estoque (Linhas 78 a 79):**
   * Execute as linhas 78 a 79.
   * **O que falar:** *"A trigger `trg_movimentacao_bi` impede saída maior que o saldo em estoque."*
3. **6c - Bloqueio de pagamento excedente (Linha 82):**
   * Execute a linha 82.
   * **O que falar:** *"A procedure `sp_registrar_pagamento` rejeita pagamentos com valor superior ao saldo em aberto."*

---

### Bloco 7: DEMONSTRAÇÃO 2 – Entrada de Mercadoria Repõe Estoque (4:00 – 4:30)
1. **Verificar ANTES (Linhas 88 a 91):**
   * Execute o SELECT do ANTES.
   * **Mostre na tela:** `momento: ANTES`, nível a laser com estoque **2** e situação **'REPOR ESTOQUE'**.
2. **Registrar Entrada (Linhas 94 a 95):**
   * Execute o INSERT de 5 unidades.
3. **Verificar DEPOIS (Linhas 98 a 101):**
   * Execute o SELECT do DEPOIS.
   * **Mostre na tela:** `momento: DEPOIS`, estoque subiu de **2 para 7** e a situation virou **'OK'**.
   * **O que falar:** *"A trigger `trg_movimentacao_ai` aumentou o estoque e a function recalculou a situação para regular."*

---

### Bloco 8: DEMONSTRAÇÃO 3 – Cancelamento Devolve Estoque (4:30 – 4:50)
1. **Verificar ANTES (Linhas 107 a 109):**
   * Execute o SELECT do ANTES.
   * **Mostre na tela:** `momento: ANTES`, estoque atual do pedido pago está em **12** e **35**.
2. **Cancelar o Pedido (Linha 112):**
   * Execute o `UPDATE pedido SET status = 'CANCELADO' ...`.
3. **Verificar DEPOIS (Linhas 115 a 117):**
   * Execute o SELECT do DEPOIS.
   * **Mostre na tela:** `momento: DEPOIS`, estoque da furadeira voltou para **14** e da trena para **38**.
   * **O que falar:** *"A trigger `trg_pedido_au` detectou o cancelamento e estornou automaticamente as quantidades ao estoque."*

---

### Conclusão (4:50 – 5:00)
> *"Conclusão: Toda a integridade transacional, cálculo fiscal e controle de estoque foram encapsulados no SGBD. Qualquer front-end (web, PDV ou app móvel) respeitará essas regras obrigatoriamente."*

---

## 3. Botão de Pânico (Reset Rápido)
Se houver qualquer clique fora de ordem:
1. Abra o arquivo `GLF - 01 script completo (MySQL).sql`.
2. Pressione **`Alt+X`**.
3. Em 3 segundos a base é restaurada para o estado zero.
