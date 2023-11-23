CREATE TABLE produto(
	idproduto SERIAL PRIMARY KEY,
	nome VARCHAR(150) NOT NULL,
	descracao TEXT,
	preco NUMERIC(10, 2) NOT NULL,
	qnt_estoque INTEGER NOT NULL,
	validade DATE
);

CREATE TABLE cliente(
	idcliente SERIAL PRIMARY KEY,
	nome VARCHAR(250) NOT NULL,
	telefone VARCHAR(30),
	email VARCHAR(255) UNIQUE,
	endereco TEXT,
	alergias TEXT[]
);

CREATE TABLE remedios_prescritos(
	idremedios_prescritos SERIAL PRIMARY KEY,
	id_cliente INTEGER,
	data_recebimento DATE,
	nome VARCHAR(255) NOT NULL,
	CONSTRAINT fk_cliente_remedios_prescritos
	FOREIGN KEY (id_cliente) REFERENCES cliente(idcliente)
);


CREATE TABLE venda(
	idvenda SERIAL PRIMARY KEY,
	id_cliente INTEGER,
	id_produto INTEGER,
	quantidade INTEGER NOT NULL,
	total NUMERIC(10, 2) NOT NULL,
	data_venda DATE NOT NULL,
	CONSTRAINT fk_cliente_venda
	FOREIGN KEY (id_cliente) REFERENCES cliente(idcliente),
	CONSTRAINT fk_produto_venda
	FOREIGN KEY (id_produto) REFERENCES produto(idproduto)
);

CREATE TABLE bkp_cliente AS 
SELECT * FROM cliente;

CREATE OR REPLACE FUNCTION backup_cliente()
RETURNS TRIGGER AS $$
BEGIN 
	INSERT INTO bkp_cliente VALUES (OLD.*);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_backup_cliente
BEFORE DELETE ON cliente
FOR EACH ROW EXECUTE FUNCTION backup_cliente();

CREATE TABLE bkp_produt AS 
SELECT * FROM produto;

CREATE OR REPLACE FUNCTION backup_produto()
RETURNS TRIGGER AS $$
BEGIN 
	INSERT INTO bkp_produto VALUES (OLD.*);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_backup_produto
BEFORE DELETE ON produto
FOR EACH ROW EXECUTE FUNCTION backup_produto();

CREATE TABLE bkp_venda AS 
SELECT * FROM venda;

CREATE OR REPLACE FUNCTION backup_venda()
RETURNS TRIGGER AS $$
BEGIN 
	INSERT INTO bkp_venda VALUES (OLD.*);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_backup_venda
BEFORE DELETE ON venda
FOR EACH ROW EXECUTE FUNCTION backup_venda();

ALTER TABLE bkp_produt RENAME TO bkp_produto;

INSERT INTO cliente(nome, telefone, email, endereco, alergias)
VALUES
	('João', '123456789', 'joao@gmail.com', 
	 'Rua A, 123', ARRAY['Paracetamol', 'Ovo']),
	('Maria', '98765432', 'maria@gmail.com',
	 'Rua B 456', ARRAY['Ibuprofeno']),
	('Carlos', '123654789', 'carlos@gmail.com',
	 'Rua C, 789', ARRAY['Nenhuma']);
	 
SELECT * FROM cliente;

ALTER TABLE produto
RENAME COLUMN descracao TO descricao;

INSERT INTO produto(nome, descricao, preco, qnt_estoque, validade)
VALUES 
	('Paracetamol', 'Analgésico e antipirético',
	 5.99, 100, '2025-02-12'),
	('Ibuprofeno', 'Analgésico e anti-inflamatório',
	 8.50, 30, '2027-03-05');
	 
SELECT * FROM produto;


CALL realizar_venda('João', 'Ibuprofeno', 10);

CALL realizar_venda(NULL, 'Paracetamol', 3);

DROP PROCEDURE dar_desconto(integer,integer,integer,numeric);

DROP PROCEDURE dar_desconto(integer, integer, integer, numeric);

CREATE OR REPLACE PROCEDURE realizar_venda(
    IN cliente_nome VARCHAR(250),
    IN produto_nome VARCHAR(150),
    IN quantidade INTEGER
)
AS $$
DECLARE
    cliente_id INTEGER;
    produto_id INTEGER;
    preco_produto NUMERIC(10, 2);
    total NUMERIC(10, 2);
BEGIN
    SELECT idcliente INTO cliente_id
    FROM cliente
    WHERE nome = cliente_nome;

    SELECT idproduto, preco INTO produto_id, preco_produto
    FROM produto
    WHERE nome = produto_nome;

    IF produto_id IS NULL THEN
        RAISE EXCEPTION 'Produto não cadastrado: %', produto_nome;
    END IF;

    total := quantidade * preco_produto;

    IF cliente_id IS NOT NULL THEN
        total := total * 0.9;
    END IF;

    INSERT INTO venda (id_cliente, id_produto, quantidade, total, data_venda)
    VALUES (cliente_id, produto_id, quantidade, total, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

CALL realizar_venda(NULL, 'Ibuprofeno', 2);

SELECT * FROM venda;

DELETE FROM venda
WHERE id_cliente = 1;

SELECT * FROM bkp_venda;
