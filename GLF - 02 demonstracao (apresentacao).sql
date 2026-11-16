-- =============================================================
-- GLF - Roteiro de Demonstração (Apresentação Prática)
-- Requisito: Container Docker ativo (docker compose up -d).
-- Para resetar a base antes da apresentação: execute o arquivo 01 (Alt+X).
-- Execute cada bloco selecionando o trecho e usando Ctrl+Enter.
-- =============================================================
USE glf_loja_ferramentas;

-- 1) FUNCTIONS: margem de lucro e situação do estoque ------------
-- Filtra 3 produtos-chave: um com estoque regular e dois em alerta
SELECT sku, nome, preco_custo, preco_venda,
       fn_margem_lucro(id_produto)     AS margem_pct,
       qtd_estoque, estoque_minimo,
       fn_situacao_estoque(id_produto) AS situacao
  FROM produto
 WHERE id_produto IN (1, 2, 8);

-- 2) PROCEDURE: relatório de produtos que precisam de reposição ---
-- Cruza produtos deficitários com o catálogo do fornecedor mais barato
CALL sp_relatorio_estoque_baixo();

-- 3) TRIGGERS T3-T6: criação de pedido e total calculado sozinho --
-- 3a) Criar novo pedido com R$ 10,00 de desconto
INSERT INTO pedido (id_cliente, id_funcionario, id_endereco_entrega, desconto)
VALUES (4, 2, 5, 10.00);
SET @pedido = LAST_INSERT_ID();

-- 3b) Inserir itens (2 furadeiras a 329,90 e 3 trenas a 19,90)
INSERT INTO item_pedido (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (@pedido, 1, 2, 329.90),
       (@pedido, 7, 3, 19.90);

-- 3c) Conferir pedido: total calculado pela trigger (2*329,90 + 3*19,90 - 10 = 709,50)
SELECT id_pedido, status, desconto, valor_total
  FROM pedido 
 WHERE id_pedido = @pedido;

-- 4) PROCEDURE: pagamento parcial no PIX (continua ABERTO) --------
CALL sp_registrar_pagamento(@pedido, 'PIX', 300.00, 1);

SELECT id_pedido, status, valor_total, fn_valor_pago(id_pedido) AS total_pago
  FROM pedido 
 WHERE id_pedido = @pedido;

-- =============================================================
-- DEMONSTRAÇÃO 1: BAIXA AUTOMÁTICA DE ESTOQUE APÓS QUITAÇÃO
-- =============================================================
-- 5a) ANTES: Estoque dos produtos do pedido (14 furadeiras e 38 trenas)
SELECT 'ANTES' AS momento, id_produto, nome, qtd_estoque
  FROM produto
 WHERE id_produto IN (1, 7);

-- 5b) Quitar o saldo restante no Cartão de Crédito (R$ 409,50)
CALL sp_registrar_pagamento(@pedido, 'CARTAO_CREDITO', 409.50, 3);

-- 5c) DEPOIS: Pedido virou PAGO e estoque baixou automaticamente (14->12 e 38->35)
SELECT id_pedido, status, valor_total, fn_valor_pago(id_pedido) AS total_pago
  FROM pedido 
 WHERE id_pedido = @pedido;

SELECT 'DEPOIS' AS momento, id_produto, nome, qtd_estoque
  FROM produto
 WHERE id_produto IN (1, 7);

-- 5d) Conferir saídas fiscais registradas pela trigger no histórico
SELECT id_movimentacao, id_produto, tipo, quantidade, motivo
  FROM movimentacao_estoque
 ORDER BY id_movimentacao DESC LIMIT 2;

-- =============================================================
-- 6) REGRAS DE NEGÓCIO BARRANDO OPERAÇÕES INVÁLIDAS (ERROS ESPERADOS)
-- Execute cada linha individualmente. O erro vermelho prova a trigger funcionando.
-- =============================================================
-- 6a) Trigger T3: Bloqueia incluir item em pedido já pago
INSERT INTO item_pedido VALUES (@pedido, 5, 1, 39.90);

-- 6b) Trigger T1: Bloqueia saída de estoque maior que o disponível (nível só tem 2)
INSERT INTO movimentacao_estoque (id_produto, id_funcionario, tipo, quantidade, motivo)
VALUES (8, 3, 'SAIDA', 5, 'Teste de saída indevida');

-- 6c) Procedure P2: Bloqueia pagar valor maior que o saldo em aberto (pedido 3 deve 74,80)
CALL sp_registrar_pagamento(3, 'PIX', 100.00, 1);

-- =============================================================
-- DEMONSTRAÇÃO 2: ENTRADA DE MERCADORIA REPÕE ESTOQUE
-- =============================================================
-- 7a) ANTES: Nível a laser tem apenas 2 unidades e situação 'REPOR ESTOQUE'
SELECT 'ANTES' AS momento, id_produto, nome, qtd_estoque,
       fn_situacao_estoque(id_produto) AS situacao
  FROM produto 
 WHERE id_produto = 8;

-- 7b) Registrar entrada de 5 unidades via nota fiscal de compra
INSERT INTO movimentacao_estoque (id_produto, id_funcionario, tipo, quantidade, motivo)
VALUES (8, 3, 'ENTRADA', 5, 'Compra - Distribuidora Ferramax');

-- 7c) DEPOIS: Estoque subiu de 2 para 7 e situação recalculada para 'OK'
SELECT 'DEPOIS' AS momento, id_produto, nome, qtd_estoque,
       fn_situacao_estoque(id_produto) AS situacao
  FROM produto 
 WHERE id_produto = 8;

-- =============================================================
-- DEMONSTRAÇÃO 3: CANCELAMENTO DO PEDIDO DEVOLVE ESTOQUE (ESTORNO)
-- =============================================================
-- 8a) ANTES: Estoque atual com pedido pago (12 furadeiras e 35 trenas)
SELECT 'ANTES' AS momento, id_produto, nome, qtd_estoque
  FROM produto 
 WHERE id_produto IN (1, 7);

-- 8b) Cancelar o pedido
UPDATE pedido SET status = 'CANCELADO' WHERE id_pedido = @pedido;

-- 8c) DEPOIS: Trigger T7 estornou os produtos de volta ao estoque (volta a 14 e 38)
SELECT 'DEPOIS' AS momento, id_produto, nome, qtd_estoque
  FROM produto 
 WHERE id_produto IN (1, 7);
