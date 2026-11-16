-- =============================================================
-- GLF - Sistema de Gestão de Loja de Ferramentas
-- Script completo: criação, dados, triggers, procedures e functions
-- SGBD: MySQL 8.0 - execute o arquivo inteiro de uma vez:
--   DBeaver: Alt+X (Executar script) | Workbench: Ctrl+Shift+Enter
-- Autor: Wendson Kauã Carvalho da Silva - 202511894
-- =============================================================

-- 4.4.1 Criando o DATABASE/SCHEMA
DROP DATABASE IF EXISTS glf_loja_ferramentas;

CREATE DATABASE glf_loja_ferramentas
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE glf_loja_ferramentas;

-- 4.4.2 Criando as tabelas / relacionamentos

CREATE TABLE categoria (
  id_categoria INT          NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(60)  NOT NULL,
  descricao    VARCHAR(255) NULL,
  CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
  CONSTRAINT uq_categoria_nome UNIQUE (nome)
) ENGINE = InnoDB;

CREATE TABLE marca (
  id_marca    INT         NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(60) NOT NULL,
  pais_origem VARCHAR(50) NULL,
  CONSTRAINT pk_marca PRIMARY KEY (id_marca),
  CONSTRAINT uq_marca_nome UNIQUE (nome)
) ENGINE = InnoDB;

CREATE TABLE fornecedor (
  id_fornecedor INT          NOT NULL AUTO_INCREMENT,
  razao_social  VARCHAR(120) NOT NULL,
  cnpj          CHAR(14)     NOT NULL,
  telefone      VARCHAR(15)  NULL,
  email         VARCHAR(100) NULL,
  CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor),
  CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj)
) ENGINE = InnoDB;

CREATE TABLE produto (
  id_produto     INT           NOT NULL AUTO_INCREMENT,
  id_categoria   INT           NOT NULL,
  id_marca       INT           NOT NULL,
  sku            VARCHAR(30)   NOT NULL,
  nome           VARCHAR(120)  NOT NULL,
  descricao      TEXT          NULL,
  preco_custo    DECIMAL(10,2) NOT NULL,
  preco_venda    DECIMAL(10,2) NOT NULL,
  qtd_estoque    INT           NOT NULL DEFAULT 0,
  estoque_minimo INT           NOT NULL DEFAULT 0,
  CONSTRAINT pk_produto PRIMARY KEY (id_produto),
  CONSTRAINT uq_produto_sku UNIQUE (sku),
  CONSTRAINT ck_produto_precos
    CHECK (preco_custo >= 0 AND preco_venda >= 0),
  CONSTRAINT ck_produto_estoque
    CHECK (qtd_estoque >= 0 AND estoque_minimo >= 0),
  CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria (id_categoria)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_produto_marca FOREIGN KEY (id_marca)
    REFERENCES marca (id_marca)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE produto_fornecedor (
  id_produto    INT           NOT NULL,
  id_fornecedor INT           NOT NULL,
  preco_compra  DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_produto_fornecedor PRIMARY KEY (id_produto, id_fornecedor),
  CONSTRAINT ck_pf_preco CHECK (preco_compra >= 0),
  CONSTRAINT fk_pf_produto FOREIGN KEY (id_produto)
    REFERENCES produto (id_produto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pf_fornecedor FOREIGN KEY (id_fornecedor)
    REFERENCES fornecedor (id_fornecedor)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE cliente (
  id_cliente  INT          NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(120) NOT NULL,
  cpf_cnpj    VARCHAR(14)  NOT NULL,
  tipo_pessoa CHAR(1)      NOT NULL,
  email       VARCHAR(100) NULL,
  telefone    VARCHAR(15)  NULL,
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_cpf_cnpj UNIQUE (cpf_cnpj),
  CONSTRAINT ck_cliente_tipo CHECK (tipo_pessoa IN ('F', 'J'))
) ENGINE = InnoDB;

CREATE TABLE endereco (
  id_endereco INT          NOT NULL AUTO_INCREMENT,
  id_cliente  INT          NOT NULL,
  logradouro  VARCHAR(120) NOT NULL,
  numero      VARCHAR(10)  NOT NULL,
  bairro      VARCHAR(60)  NOT NULL,
  cidade      VARCHAR(60)  NOT NULL,
  uf          CHAR(2)      NOT NULL,
  cep         CHAR(8)      NOT NULL,
  CONSTRAINT pk_endereco PRIMARY KEY (id_endereco),
  CONSTRAINT fk_endereco_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE funcionario (
  id_funcionario INT           NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(120)  NOT NULL,
  cpf            CHAR(11)      NOT NULL,
  cargo          VARCHAR(50)   NOT NULL,
  salario        DECIMAL(10,2) NOT NULL,
  data_admissao  DATE          NOT NULL,
  CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
  CONSTRAINT uq_funcionario_cpf UNIQUE (cpf),
  CONSTRAINT ck_funcionario_salario CHECK (salario > 0)
) ENGINE = InnoDB;

CREATE TABLE pedido (
  id_pedido           INT           NOT NULL AUTO_INCREMENT,
  id_cliente          INT           NOT NULL,
  id_funcionario      INT           NOT NULL,
  id_endereco_entrega INT           NULL,
  data_pedido         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status              VARCHAR(20)   NOT NULL DEFAULT 'ABERTO',
  valor_total         DECIMAL(10,2) NOT NULL DEFAULT 0,
  desconto            DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT pk_pedido PRIMARY KEY (id_pedido),
  CONSTRAINT ck_pedido_status CHECK (status IN
    ('ABERTO', 'PAGO', 'ENVIADO', 'ENTREGUE', 'CANCELADO')),
  CONSTRAINT ck_pedido_valores CHECK (valor_total >= 0 AND desconto >= 0),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES funcionario (id_funcionario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_endereco FOREIGN KEY (id_endereco_entrega)
    REFERENCES endereco (id_endereco)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;

CREATE TABLE item_pedido (
  id_pedido      INT           NOT NULL,
  id_produto     INT           NOT NULL,
  quantidade     INT           NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_item_pedido PRIMARY KEY (id_pedido, id_produto),
  CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_item_preco CHECK (preco_unitario >= 0),
  CONSTRAINT fk_item_pedido FOREIGN KEY (id_pedido)
    REFERENCES pedido (id_pedido)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_item_produto FOREIGN KEY (id_produto)
    REFERENCES produto (id_produto)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE pagamento (
  id_pagamento    INT           NOT NULL AUTO_INCREMENT,
  id_pedido       INT           NOT NULL,
  forma_pagamento VARCHAR(20)   NOT NULL,
  valor           DECIMAL(10,2) NOT NULL,
  qtd_parcelas    TINYINT       NOT NULL DEFAULT 1,
  data_pagamento  DATETIME      NULL,
  status          VARCHAR(20)   NOT NULL DEFAULT 'PENDENTE',
  CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
  CONSTRAINT ck_pagamento_forma CHECK (forma_pagamento IN
    ('DINHEIRO', 'PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO', 'BOLETO')),
  CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
  CONSTRAINT ck_pagamento_parcelas CHECK (qtd_parcelas BETWEEN 1 AND 12),
  CONSTRAINT ck_pagamento_status CHECK (status IN
    ('PENDENTE', 'APROVADO', 'RECUSADO', 'ESTORNADO')),
  CONSTRAINT fk_pagamento_pedido FOREIGN KEY (id_pedido)
    REFERENCES pedido (id_pedido)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE movimentacao_estoque (
  id_movimentacao   INT          NOT NULL AUTO_INCREMENT,
  id_produto        INT          NOT NULL,
  id_funcionario    INT          NOT NULL,
  tipo              VARCHAR(10)  NOT NULL,
  quantidade        INT          NOT NULL,
  data_movimentacao DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  motivo            VARCHAR(150) NULL,
  CONSTRAINT pk_movimentacao_estoque PRIMARY KEY (id_movimentacao),
  CONSTRAINT ck_movimentacao_tipo
    CHECK (tipo IN ('ENTRADA', 'SAIDA', 'AJUSTE')),
  CONSTRAINT ck_movimentacao_qtd CHECK (quantidade > 0),
  CONSTRAINT fk_movimentacao_produto FOREIGN KEY (id_produto)
    REFERENCES produto (id_produto)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_movimentacao_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES funcionario (id_funcionario)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 4.4.3 Inserindo dados nas tabelas

INSERT INTO categoria (id_categoria, nome, descricao) VALUES
  (1, 'Ferramentas Elétricas', 'Furadeiras, parafusadeiras e afins'),
  (2, 'Ferramentas Manuais', 'Chaves, martelos e alicates'),
  (3, 'Medição', 'Trenas, níveis e instrumentos de medida'),
  (4, 'Fixação', 'Parafusos, buchas e pregos'),
  (5, 'EPI', 'Equipamentos de proteção individual');

INSERT INTO marca (id_marca, nome, pais_origem) VALUES
  (1, 'Bosch', 'Alemanha'),
  (2, 'Makita', 'Japão'),
  (3, 'Tramontina', 'Brasil'),
  (4, 'Vonder', 'Brasil'),
  (5, '3M', 'Estados Unidos');

INSERT INTO fornecedor (id_fornecedor, razao_social, cnpj, telefone, email)
VALUES
  (1, 'Distribuidora Ferramax Ltda', '12345678000190', '6133330001',
   'vendas@ferramax.example.com'),
  (2, 'Comercial Parafusos Brasil Ltda', '23456789000101', '6133330002',
   'contato@parafusosbrasil.example.com'),
  (3, 'Atacado Proteção Total Ltda', '34567890000112', '6133330003',
   'pedidos@protecaototal.example.com');

INSERT INTO produto (id_produto, id_categoria, id_marca, sku, nome,
                     preco_custo, preco_venda, qtd_estoque, estoque_minimo)
VALUES
  (1, 1, 1, 'ELE-0001', 'Furadeira de Impacto 650W', 210.00, 329.90, 14, 5),
  (2, 1, 2, 'ELE-0002', 'Parafusadeira a Bateria 12V', 320.00, 499.90, 3, 3),
  (3, 1, 1, 'ELE-0003', 'Esmerilhadeira Angular 850W', 180.00, 289.90, 6, 4),
  (4, 2, 3, 'MAN-0001', 'Jogo de Chaves 12 peças', 65.00, 119.90, 20, 5),
  (5, 2, 3, 'MAN-0002', 'Martelo de Unha 27mm', 22.00, 39.90, 30, 10),
  (6, 2, 4, 'MAN-0003', 'Alicate Universal 8"', 18.50, 34.90, 25, 10),
  (7, 3, 4, 'MED-0001', 'Trena de Aço 5m', 9.80, 19.90, 38, 15),
  (8, 3, 1, 'MED-0002', 'Nível a Laser de Linhas', 390.00, 649.90, 2, 2),
  (9, 4, 4, 'FIX-0001', 'Parafuso Philips 4x40mm 500un', 24.00, 44.90, 46, 20),
  (10, 5, 5, 'EPI-0001', 'Óculos de Proteção Incolor', 4.50, 12.90, 90, 30),
  (11, 5, 5, 'EPI-0002', 'Protetor Auricular Tipo Concha', 22.00, 45.90, 12, 10);

INSERT INTO produto_fornecedor (id_produto, id_fornecedor, preco_compra)
VALUES
  (1, 1, 210.00), (2, 1, 320.00), (3, 1, 180.00), (4, 1, 65.00),
  (8, 1, 390.00), (7, 1, 10.20),  (4, 2, 66.00),  (5, 2, 22.00),
  (6, 2, 18.50),  (7, 2, 9.80),   (9, 2, 24.00),  (10, 3, 4.50),
  (11, 3, 22.00);

INSERT INTO cliente (id_cliente, nome, cpf_cnpj, tipo_pessoa, email,
                     telefone)
VALUES
  (1, 'Carlos Eduardo Pereira', '12345678909', 'F',
   'carlos.pereira@example.com', '61999990001'),
  (2, 'Mariana Souza Lima', '98765432100', 'F',
   'mariana.lima@example.com', '61999990002'),
  (3, 'Construtora Alvorada Ltda', '11222333000181', 'J',
   'compras@alvorada.example.com', '6134440003'),
  (4, 'João Batista Ferreira', '45678912300', 'F',
   NULL, '61999990004');

INSERT INTO endereco (id_endereco, id_cliente, logradouro, numero, bairro,
                      cidade, uf, cep)
VALUES
  (1, 1, 'QNA 12', '15', 'Taguatinga Norte', 'Brasília', 'DF', '72110120'),
  (2, 1, 'Rua das Pitangueiras', '40', 'Águas Claras', 'Brasília', 'DF',
   '71936250'),
  (3, 2, 'QS 07 Rua 800', '22', 'Areal', 'Brasília', 'DF', '71964000'),
  (4, 3, 'SIA Trecho 3', '625', 'Setor de Indústria', 'Brasília', 'DF',
   '71200030'),
  (5, 4, 'Rua 5 Chácara 12', 'S/N', 'Vicente Pires', 'Brasília', 'DF',
   '72005005');

INSERT INTO funcionario (id_funcionario, nome, cpf, cargo, salario,
                         data_admissao)
VALUES
  (1, 'Ana Paula Ribeiro', '11122233344', 'Gerente', 5200.00, '2022-03-01'),
  (2, 'Bruno Henrique Costa', '22233344455', 'Vendedor', 2600.00,
   '2023-06-15'),
  (3, 'Fernanda Alves Rocha', '33344455566', 'Estoquista', 2300.00,
   '2024-02-05');

-- Histórico: estoque inicial (entradas) e vendas já realizadas (saídas)
INSERT INTO movimentacao_estoque (id_produto, id_funcionario, tipo,
                                  quantidade, data_movimentacao, motivo)
VALUES
  (1, 3, 'ENTRADA', 15, '2026-10-01 08:00:00', 'Estoque inicial'),
  (2, 3, 'ENTRADA', 3, '2026-10-01 08:00:00', 'Estoque inicial'),
  (3, 3, 'ENTRADA', 8, '2026-10-01 08:00:00', 'Estoque inicial'),
  (4, 3, 'ENTRADA', 20, '2026-10-01 08:00:00', 'Estoque inicial'),
  (5, 3, 'ENTRADA', 30, '2026-10-01 08:00:00', 'Estoque inicial'),
  (6, 3, 'ENTRADA', 25, '2026-10-01 08:00:00', 'Estoque inicial'),
  (7, 3, 'ENTRADA', 40, '2026-10-01 08:00:00', 'Estoque inicial'),
  (8, 3, 'ENTRADA', 2, '2026-10-01 08:00:00', 'Estoque inicial'),
  (9, 3, 'ENTRADA', 50, '2026-10-01 08:00:00', 'Estoque inicial'),
  (10, 3, 'ENTRADA', 100, '2026-10-01 08:00:00', 'Estoque inicial'),
  (11, 3, 'ENTRADA', 12, '2026-10-01 08:00:00', 'Estoque inicial'),
  (1, 2, 'SAIDA', 1, '2026-10-20 10:20:00', 'Venda - pedido 1'),
  (7, 2, 'SAIDA', 2, '2026-10-20 10:20:00', 'Venda - pedido 1'),
  (3, 2, 'SAIDA', 2, '2026-11-03 14:40:00', 'Venda - pedido 2'),
  (9, 2, 'SAIDA', 4, '2026-11-03 14:40:00', 'Venda - pedido 2'),
  (10, 2, 'SAIDA', 10, '2026-11-03 14:40:00', 'Venda - pedido 2');

INSERT INTO pedido (id_pedido, id_cliente, id_funcionario,
                    id_endereco_entrega, data_pedido, status, valor_total,
                    desconto)
VALUES
  (1, 1, 2, 1, '2026-10-20 10:15:00', 'ENTREGUE', 369.70, 0.00),
  (2, 3, 2, 4, '2026-11-03 14:30:00', 'PAGO', 838.40, 50.00),
  (3, 2, 1, NULL, '2026-11-08 09:00:00', 'ABERTO', 74.80, 0.00);

INSERT INTO item_pedido (id_pedido, id_produto, quantidade, preco_unitario)
VALUES
  (1, 1, 1, 329.90), (1, 7, 2, 19.90),
  (2, 3, 2, 289.90), (2, 9, 4, 44.90), (2, 10, 10, 12.90),
  (3, 5, 1, 39.90),  (3, 6, 1, 34.90);

INSERT INTO pagamento (id_pedido, forma_pagamento, valor, qtd_parcelas,
                       data_pagamento, status)
VALUES
  (1, 'CARTAO_CREDITO', 369.70, 3, '2026-10-20 10:20:00', 'APROVADO'),
  (2, 'PIX', 400.00, 1, '2026-11-03 14:35:00', 'APROVADO'),
  (2, 'BOLETO', 438.40, 1, '2026-11-03 14:40:00', 'APROVADO');

-- 5. Anexos (Triggers, Procedures e Functions)

DELIMITER $$

-- 5.1 Triggers ------------------------------------------------

-- T1: impede saída de estoque maior que a quantidade disponível
CREATE TRIGGER trg_movimentacao_bi
BEFORE INSERT ON movimentacao_estoque
FOR EACH ROW
BEGIN
  DECLARE v_estoque INT;
  SELECT qtd_estoque INTO v_estoque
    FROM produto WHERE id_produto = NEW.id_produto;
  IF NEW.tipo = 'SAIDA' AND NEW.quantidade > v_estoque THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Estoque insuficiente para a saída.';
  END IF;
END$$

-- T2: atualiza o estoque do produto a cada movimentação
CREATE TRIGGER trg_movimentacao_ai
AFTER INSERT ON movimentacao_estoque
FOR EACH ROW
BEGIN
  IF NEW.tipo = 'ENTRADA' THEN
    UPDATE produto SET qtd_estoque = qtd_estoque + NEW.quantidade
     WHERE id_produto = NEW.id_produto;
  ELSEIF NEW.tipo = 'SAIDA' THEN
    UPDATE produto SET qtd_estoque = qtd_estoque - NEW.quantidade
     WHERE id_produto = NEW.id_produto;
  ELSE -- AJUSTE: quantidade contada no inventário
    UPDATE produto SET qtd_estoque = NEW.quantidade
     WHERE id_produto = NEW.id_produto;
  END IF;
END$$

-- T3: só permite alterar itens de pedidos com status ABERTO
CREATE TRIGGER trg_item_pedido_bi
BEFORE INSERT ON item_pedido
FOR EACH ROW
BEGIN
  IF (SELECT status FROM pedido WHERE id_pedido = NEW.id_pedido)
     <> 'ABERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Só é possível incluir itens em pedido ABERTO.';
  END IF;
END$$

-- T4, T5 e T6: recalculam o valor total do pedido
CREATE TRIGGER trg_item_pedido_ai
AFTER INSERT ON item_pedido
FOR EACH ROW
BEGIN
  CALL sp_recalcular_total_pedido(NEW.id_pedido);
END$$

CREATE TRIGGER trg_item_pedido_au
AFTER UPDATE ON item_pedido
FOR EACH ROW
BEGIN
  CALL sp_recalcular_total_pedido(NEW.id_pedido);
END$$

CREATE TRIGGER trg_item_pedido_ad
AFTER DELETE ON item_pedido
FOR EACH ROW
BEGIN
  CALL sp_recalcular_total_pedido(OLD.id_pedido);
END$$

-- T7: dá baixa no estoque quando o pedido é pago e devolve os
--     produtos ao estoque quando um pedido pago é cancelado
CREATE TRIGGER trg_pedido_au
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
  IF OLD.status = 'ABERTO' AND NEW.status = 'PAGO' THEN
    INSERT INTO movimentacao_estoque
      (id_produto, id_funcionario, tipo, quantidade, motivo)
    SELECT id_produto, NEW.id_funcionario, 'SAIDA', quantidade,
           CONCAT('Venda - pedido ', NEW.id_pedido)
      FROM item_pedido WHERE id_pedido = NEW.id_pedido;
  ELSEIF OLD.status IN ('PAGO', 'ENVIADO')
         AND NEW.status = 'CANCELADO' THEN
    INSERT INTO movimentacao_estoque
      (id_produto, id_funcionario, tipo, quantidade, motivo)
    SELECT id_produto, NEW.id_funcionario, 'ENTRADA', quantidade,
           CONCAT('Cancelamento - pedido ', NEW.id_pedido)
      FROM item_pedido WHERE id_pedido = NEW.id_pedido;
  END IF;
END$$

-- 5.2 Procedures ----------------------------------------------

-- P1: recalcula e grava o valor total de um pedido
CREATE PROCEDURE sp_recalcular_total_pedido(IN p_id_pedido INT)
BEGIN
  UPDATE pedido
     SET valor_total = fn_total_pedido(p_id_pedido)
   WHERE id_pedido = p_id_pedido;
END$$

-- P2: registra um pagamento (total ou parcial); quando o pedido
--     fica quitado, muda o status para PAGO (o que dispara a T7)
CREATE PROCEDURE sp_registrar_pagamento(
  IN p_id_pedido INT,
  IN p_forma     VARCHAR(20),
  IN p_valor     DECIMAL(10,2),
  IN p_parcelas  TINYINT)
BEGIN
  DECLARE v_status   VARCHAR(20);
  DECLARE v_restante DECIMAL(10,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT status INTO v_status
    FROM pedido WHERE id_pedido = p_id_pedido FOR UPDATE;
  IF v_status IS NULL OR v_status <> 'ABERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Pedido inexistente ou que não está ABERTO.';
  END IF;
  SET v_restante = fn_total_pedido(p_id_pedido)
                 - fn_valor_pago(p_id_pedido);
  IF p_valor > v_restante THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Valor maior que o saldo devedor do pedido.';
  END IF;
  INSERT INTO pagamento (id_pedido, forma_pagamento, valor,
                         qtd_parcelas, data_pagamento, status)
  VALUES (p_id_pedido, p_forma, p_valor, p_parcelas, NOW(), 'APROVADO');
  IF fn_valor_pago(p_id_pedido) >= fn_total_pedido(p_id_pedido) THEN
    UPDATE pedido SET status = 'PAGO' WHERE id_pedido = p_id_pedido;
  END IF;
  COMMIT;
END$$

-- P3: lista os produtos com estoque igual ou abaixo do mínimo
CREATE PROCEDURE sp_relatorio_estoque_baixo()
BEGIN
  SELECT p.sku, p.nome, p.qtd_estoque, p.estoque_minimo,
         fn_situacao_estoque(p.id_produto) AS situacao,
         (SELECT f.razao_social
            FROM produto_fornecedor pf
            JOIN fornecedor f ON f.id_fornecedor = pf.id_fornecedor
           WHERE pf.id_produto = p.id_produto
           ORDER BY pf.preco_compra
           LIMIT 1) AS fornecedor_mais_barato
    FROM produto p
   WHERE p.qtd_estoque <= p.estoque_minimo
   ORDER BY p.qtd_estoque;
END$$

-- 5.3 Functions -----------------------------------------------

-- F1: valor total do pedido (soma dos itens menos o desconto)
CREATE FUNCTION fn_total_pedido(p_id_pedido INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
  DECLARE v_itens    DECIMAL(10,2);
  DECLARE v_desconto DECIMAL(10,2);
  SELECT COALESCE(SUM(quantidade * preco_unitario), 0) INTO v_itens
    FROM item_pedido WHERE id_pedido = p_id_pedido;
  SELECT desconto INTO v_desconto
    FROM pedido WHERE id_pedido = p_id_pedido;
  RETURN GREATEST(v_itens - COALESCE(v_desconto, 0), 0);
END$$

-- F2: soma dos pagamentos aprovados de um pedido
CREATE FUNCTION fn_valor_pago(p_id_pedido INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
  RETURN (SELECT COALESCE(SUM(valor), 0)
            FROM pagamento
           WHERE id_pedido = p_id_pedido AND status = 'APROVADO');
END$$

-- F3: margem de lucro do produto, em porcentagem
CREATE FUNCTION fn_margem_lucro(p_id_produto INT)
RETURNS DECIMAL(6,2)
READS SQL DATA
BEGIN
  DECLARE v_custo DECIMAL(10,2);
  DECLARE v_venda DECIMAL(10,2);
  SELECT preco_custo, preco_venda INTO v_custo, v_venda
    FROM produto WHERE id_produto = p_id_produto;
  IF v_venda IS NULL OR v_venda = 0 THEN
    RETURN NULL;
  END IF;
  RETURN ROUND((v_venda - v_custo) / v_venda * 100, 2);
END$$

-- F4: situação do estoque do produto
CREATE FUNCTION fn_situacao_estoque(p_id_produto INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
  DECLARE v_qtd INT;
  DECLARE v_min INT;
  SELECT qtd_estoque, estoque_minimo INTO v_qtd, v_min
    FROM produto WHERE id_produto = p_id_produto;
  RETURN CASE
           WHEN v_qtd = 0 THEN 'SEM ESTOQUE'
           WHEN v_qtd <= v_min THEN 'REPOR ESTOQUE'
           ELSE 'OK'
         END;
END$$

DELIMITER ;
