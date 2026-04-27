-- ============================================================
-- PARTE 2 — PROCEDURES PARA MANIPULAÇÃO DE DADOS
-- Cenários: Company + E-commerce
-- Objetivo: Uma procedure com variável de controle (opção)
--           determina a ação: 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
-- ============================================================

-- ============================================================
-- SEÇÃO A — PROCEDURES PARA COMPANY
-- ============================================================
USE company_constraints;

DELIMITER $$

-- ------------------------------------------------------------
-- PROCEDURE: manip_employee
-- Controla operações CRUD na tabela employee.
-- Parâmetros:
--   p_opcao      INT    → 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
--   p_ssn        CHAR(9)         → SSN do funcionário (PK)
--   p_fname      VARCHAR(15)     → Primeiro nome
--   p_minit      CHAR(1)         → Inicial do meio
--   p_lname      VARCHAR(15)     → Sobrenome
--   p_bdate      DATE            → Data de nascimento
--   p_address    VARCHAR(50)     → Endereço
--   p_sex        CHAR(1)         → Sexo (M/F)
--   p_salary     DECIMAL(10,2)   → Salário
--   p_super_ssn  CHAR(9)         → SSN do supervisor
--   p_dno        INT             → Número do departamento
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS manip_employee$$

CREATE PROCEDURE manip_employee(
    IN p_opcao     INT,
    IN p_ssn       CHAR(9),
    IN p_fname     VARCHAR(15),
    IN p_minit     CHAR(1),
    IN p_lname     VARCHAR(15),
    IN p_bdate     DATE,
    IN p_address   VARCHAR(50),
    IN p_sex       CHAR(1),
    IN p_salary    DECIMAL(10,2),
    IN p_super_ssn CHAR(9),
    IN p_dno       INT
)
BEGIN
    -- Variável de controle de status da operação
    DECLARE v_status VARCHAR(100) DEFAULT 'Operação não reconhecida';
    DECLARE v_count  INT DEFAULT 0;

    CASE p_opcao

        -- --------------------------------
        -- OPÇÃO 1 — SELECT
        -- --------------------------------
        WHEN 1 THEN
            IF p_ssn IS NOT NULL THEN
                -- Busca por SSN específico
                SELECT
                    e.Ssn,
                    CONCAT(e.Fname,' ',COALESCE(e.Minit,''),' ',e.Lname) AS NomeCompleto,
                    e.Bdate,
                    e.Address,
                    e.Sex,
                    e.Salary,
                    CONCAT(s.Fname,' ',s.Lname) AS Supervisor,
                    d.Dname                     AS Departamento
                FROM employee e
                LEFT JOIN employee    s ON e.Super_ssn = s.Ssn
                LEFT JOIN departament d ON e.Dno       = d.Dnumber
                WHERE e.Ssn = p_ssn;
            ELSE
                -- Lista todos os funcionários
                SELECT
                    e.Ssn,
                    CONCAT(e.Fname,' ',COALESCE(e.Minit,''),' ',e.Lname) AS NomeCompleto,
                    e.Sex,
                    e.Salary,
                    d.Dname AS Departamento
                FROM employee e
                LEFT JOIN departament d ON e.Dno = d.Dnumber
                ORDER BY d.Dname, e.Lname;
            END IF;
            SET v_status = 'SELECT executado com sucesso';

        -- --------------------------------
        -- OPÇÃO 2 — INSERT
        -- --------------------------------
        WHEN 2 THEN
            -- Valida se SSN já existe
            SELECT COUNT(*) INTO v_count FROM employee WHERE Ssn = p_ssn;

            IF v_count > 0 THEN
                SET v_status = CONCAT('ERRO: SSN ', p_ssn, ' já existe na tabela.');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SSN já cadastrado.';
            ELSE
                INSERT INTO employee
                    (Fname, Minit, Lname, Ssn, Bdate, Address, Sex, Salary, Super_ssn, Dno)
                VALUES
                    (p_fname, p_minit, p_lname, p_ssn, p_bdate,
                     p_address, p_sex, p_salary, p_super_ssn, p_dno);
                SET v_status = CONCAT('INSERT: funcionário ', p_fname,' ',p_lname,' inserido com sucesso.');
            END IF;
            SELECT v_status AS Resultado;

        -- --------------------------------
        -- OPÇÃO 3 — UPDATE
        -- --------------------------------
        WHEN 3 THEN
            SELECT COUNT(*) INTO v_count FROM employee WHERE Ssn = p_ssn;

            IF v_count = 0 THEN
                SET v_status = CONCAT('ERRO: SSN ', p_ssn, ' não encontrado.');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado para atualização.';
            ELSE
                UPDATE employee SET
                    Fname     = COALESCE(p_fname,     Fname),
                    Minit     = COALESCE(p_minit,     Minit),
                    Lname     = COALESCE(p_lname,     Lname),
                    Bdate     = COALESCE(p_bdate,     Bdate),
                    Address   = COALESCE(p_address,   Address),
                    Sex       = COALESCE(p_sex,       Sex),
                    Salary    = COALESCE(p_salary,    Salary),
                    Super_ssn = COALESCE(p_super_ssn, Super_ssn),
                    Dno       = COALESCE(p_dno,       Dno)
                WHERE Ssn = p_ssn;
                SET v_status = CONCAT('UPDATE: funcionário SSN ', p_ssn, ' atualizado com sucesso.');
            END IF;
            SELECT v_status AS Resultado;

        -- --------------------------------
        -- OPÇÃO 4 — DELETE
        -- --------------------------------
        WHEN 4 THEN
            SELECT COUNT(*) INTO v_count FROM employee WHERE Ssn = p_ssn;

            IF v_count = 0 THEN
                SET v_status = CONCAT('ERRO: SSN ', p_ssn, ' não encontrado.');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado para remoção.';
            ELSE
                DELETE FROM employee WHERE Ssn = p_ssn;
                SET v_status = CONCAT('DELETE: funcionário SSN ', p_ssn, ' removido com sucesso.');
            END IF;
            SELECT v_status AS Resultado;

        ELSE
            SELECT 'ERRO: opção inválida. Use 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE.' AS Resultado;

    END CASE;

END$$


-- ------------------------------------------------------------
-- PROCEDURE: manip_departament
-- Controla operações CRUD na tabela departament.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS manip_departament$$

CREATE PROCEDURE manip_departament(
    IN p_opcao          INT,
    IN p_dnumber        INT,
    IN p_dname          VARCHAR(15),
    IN p_mgr_ssn        CHAR(9),
    IN p_mgr_start_date DATE
)
BEGIN
    DECLARE v_status VARCHAR(100);
    DECLARE v_count  INT DEFAULT 0;

    CASE p_opcao

        WHEN 1 THEN   -- SELECT
            IF p_dnumber IS NOT NULL THEN
                SELECT d.*, CONCAT(e.Fname,' ',e.Lname) AS Gerente
                FROM departament d
                JOIN employee e ON d.Mgr_ssn = e.Ssn
                WHERE d.Dnumber = p_dnumber;
            ELSE
                SELECT d.*, CONCAT(e.Fname,' ',e.Lname) AS Gerente
                FROM departament d
                JOIN employee e ON d.Mgr_ssn = e.Ssn
                ORDER BY d.Dname;
            END IF;

        WHEN 2 THEN   -- INSERT
            SELECT COUNT(*) INTO v_count FROM departament WHERE Dnumber = p_dnumber;
            IF v_count > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Departamento já existe.';
            ELSE
                INSERT INTO departament (Dname, Dnumber, Mgr_ssn, Mgr_start_date)
                VALUES (p_dname, p_dnumber, p_mgr_ssn, p_mgr_start_date);
                SELECT CONCAT('Departamento ', p_dname, ' criado com sucesso.') AS Resultado;
            END IF;

        WHEN 3 THEN   -- UPDATE
            SELECT COUNT(*) INTO v_count FROM departament WHERE Dnumber = p_dnumber;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Departamento não encontrado.';
            ELSE
                UPDATE departament SET
                    Dname          = COALESCE(p_dname,          Dname),
                    Mgr_ssn        = COALESCE(p_mgr_ssn,        Mgr_ssn),
                    Mgr_start_date = COALESCE(p_mgr_start_date, Mgr_start_date)
                WHERE Dnumber = p_dnumber;
                SELECT CONCAT('Departamento ', p_dnumber, ' atualizado.') AS Resultado;
            END IF;

        WHEN 4 THEN   -- DELETE
            SELECT COUNT(*) INTO v_count FROM departament WHERE Dnumber = p_dnumber;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Departamento não encontrado.';
            ELSE
                DELETE FROM departament WHERE Dnumber = p_dnumber;
                SELECT CONCAT('Departamento ', p_dnumber, ' removido.') AS Resultado;
            END IF;

        ELSE
            SELECT 'Opção inválida: 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE.' AS Resultado;

    END CASE;

END$$

DELIMITER ;


-- ============================================================
-- CHAMADAS DE TESTE — COMPANY
-- ============================================================

-- 1. SELECT — lista todos os funcionários
CALL manip_employee(1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 2. SELECT — busca por SSN específico
CALL manip_employee(1, '333445555', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 3. INSERT — novo funcionário
CALL manip_employee(
    2,
    '111223333',
    'Carlos', 'A', 'Mendez',
    '1990-04-10',
    '123 Oak St, Houston TX',
    'M',
    32000.00,
    '333445555',
    5
);

-- 4. SELECT — confirma inserção
CALL manip_employee(1, '111223333', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 5. UPDATE — ajusta salário do novo funcionário
CALL manip_employee(
    3,
    '111223333',
    NULL, NULL, NULL, NULL, NULL, NULL,
    35000.00,   -- novo salário
    NULL, NULL
);

-- 6. SELECT — confirma atualização
CALL manip_employee(1, '111223333', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 7. DELETE — remove funcionário inserido
CALL manip_employee(4, '111223333', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 8. SELECT — lista departamentos
CALL manip_departament(1, NULL, NULL, NULL, NULL);

-- 9. INSERT — novo departamento
CALL manip_departament(2, 6, 'Marketing', '333445555', '2024-01-15');

-- 10. UPDATE — troca gerente do novo departamento
CALL manip_departament(3, 6, NULL, '987654321', '2024-06-01');

-- 11. DELETE — remove o departamento inserido
CALL manip_departament(4, 6, NULL, NULL, NULL);


-- ============================================================
-- SEÇÃO B — PROCEDURES PARA E-COMMERCE
-- ============================================================
USE ecommerce;

DELIMITER $$

-- ------------------------------------------------------------
-- PROCEDURE: manip_client
-- Controla operações CRUD na tabela clients (e-commerce).
-- Parâmetros:
--   p_opcao   INT        → 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE
--   p_id      INT        → idClient (PK, usado em UPDATE/DELETE/SELECT por id)
--   p_fname   VARCHAR    → Primeiro nome
--   p_minit   CHAR(3)    → Inicial do meio
--   p_lname   VARCHAR    → Sobrenome
--   p_cpf     CHAR(11)   → CPF único
--   p_address VARCHAR    → Endereço
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS manip_client$$

CREATE PROCEDURE manip_client(
    IN p_opcao   INT,
    IN p_id      INT,
    IN p_fname   VARCHAR(10),
    IN p_minit   CHAR(3),
    IN p_lname   VARCHAR(20),
    IN p_cpf     CHAR(11),
    IN p_address VARCHAR(255)
)
BEGIN
    DECLARE v_count  INT DEFAULT 0;
    DECLARE v_status VARCHAR(200);

    CASE p_opcao

        -- --------------------------------
        -- OPÇÃO 1 — SELECT
        -- --------------------------------
        WHEN 1 THEN
            IF p_id IS NOT NULL THEN
                SELECT * FROM clients WHERE idClient = p_id;
            ELSEIF p_cpf IS NOT NULL THEN
                SELECT * FROM clients WHERE CPF = p_cpf;
            ELSE
                SELECT * FROM clients ORDER BY Lname, Fname;
            END IF;

        -- --------------------------------
        -- OPÇÃO 2 — INSERT
        -- --------------------------------
        WHEN 2 THEN
            SELECT COUNT(*) INTO v_count FROM clients WHERE CPF = p_cpf;
            IF v_count > 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'CPF já cadastrado na base de clientes.';
            ELSE
                INSERT INTO clients (Fname, Minit, Lname, CPF, Address)
                VALUES (p_fname, p_minit, p_lname, p_cpf, p_address);
                SET v_status = CONCAT('Cliente ', p_fname,' ',p_lname,' inserido. ID: ', LAST_INSERT_ID());
                SELECT v_status AS Resultado;
            END IF;

        -- --------------------------------
        -- OPÇÃO 3 — UPDATE
        -- --------------------------------
        WHEN 3 THEN
            SELECT COUNT(*) INTO v_count FROM clients WHERE idClient = p_id;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Cliente não encontrado para atualização.';
            ELSE
                UPDATE clients SET
                    Fname   = COALESCE(p_fname,   Fname),
                    Minit   = COALESCE(p_minit,   Minit),
                    Lname   = COALESCE(p_lname,   Lname),
                    Address = COALESCE(p_address, Address)
                WHERE idClient = p_id;
                SELECT CONCAT('Cliente ID ', p_id, ' atualizado com sucesso.') AS Resultado;
            END IF;

        -- --------------------------------
        -- OPÇÃO 4 — DELETE
        -- --------------------------------
        WHEN 4 THEN
            SELECT COUNT(*) INTO v_count FROM clients WHERE idClient = p_id;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Cliente não encontrado para remoção.';
            ELSE
                DELETE FROM clients WHERE idClient = p_id;
                SELECT CONCAT('Cliente ID ', p_id, ' removido com sucesso.') AS Resultado;
            END IF;

        ELSE
            SELECT 'Opção inválida: 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE.' AS Resultado;

    END CASE;

END$$


-- ------------------------------------------------------------
-- PROCEDURE: manip_product
-- Controla operações CRUD na tabela product (e-commerce).
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS manip_product$$

CREATE PROCEDURE manip_product(
    IN p_opcao    INT,
    IN p_id       INT,
    IN p_pname    VARCHAR(255),
    IN p_kids     BOOLEAN,
    IN p_category ENUM('Eletrônico','Vestimenta','Brinquedos','Alimentos','Móveis'),
    IN p_aval     FLOAT,
    IN p_size     VARCHAR(10)
)
BEGIN
    DECLARE v_count  INT DEFAULT 0;
    DECLARE v_status VARCHAR(200);

    CASE p_opcao

        WHEN 1 THEN   -- SELECT
            IF p_id IS NOT NULL THEN
                SELECT * FROM product WHERE idProduct = p_id;
            ELSEIF p_category IS NOT NULL THEN
                SELECT * FROM product WHERE category = p_category ORDER BY avaliação DESC;
            ELSE
                SELECT * FROM product ORDER BY category, Pname;
            END IF;

        WHEN 2 THEN   -- INSERT
            INSERT INTO product (Pname, classification_kids, category, avaliação, size)
            VALUES (p_pname, COALESCE(p_kids, FALSE), p_category, COALESCE(p_aval, 0), p_size);
            SET v_status = CONCAT('Produto "', p_pname, '" inserido. ID: ', LAST_INSERT_ID());
            SELECT v_status AS Resultado;

        WHEN 3 THEN   -- UPDATE
            SELECT COUNT(*) INTO v_count FROM product WHERE idProduct = p_id;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto não encontrado.';
            ELSE
                UPDATE product SET
                    Pname               = COALESCE(p_pname,    Pname),
                    classification_kids = COALESCE(p_kids,     classification_kids),
                    category            = COALESCE(p_category, category),
                    avaliação           = COALESCE(p_aval,     avaliação),
                    size                = COALESCE(p_size,     size)
                WHERE idProduct = p_id;
                SELECT CONCAT('Produto ID ', p_id, ' atualizado.') AS Resultado;
            END IF;

        WHEN 4 THEN   -- DELETE
            SELECT COUNT(*) INTO v_count FROM product WHERE idProduct = p_id;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto não encontrado.';
            ELSE
                DELETE FROM product WHERE idProduct = p_id;
                SELECT CONCAT('Produto ID ', p_id, ' removido.') AS Resultado;
            END IF;

        ELSE
            SELECT 'Opção inválida: 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE.' AS Resultado;

    END CASE;

END$$


-- ------------------------------------------------------------
-- PROCEDURE: manip_order
-- Controla operações CRUD na tabela orders (e-commerce).
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS manip_order$$

CREATE PROCEDURE manip_order(
    IN p_opcao       INT,
    IN p_idOrder     INT,
    IN p_idClient    INT,
    IN p_status      ENUM('Cancelado','Confirmado','Em processamento'),
    IN p_description VARCHAR(255),
    IN p_sendValue   FLOAT,
    IN p_paymentCash BOOLEAN
)
BEGIN
    DECLARE v_count  INT DEFAULT 0;
    DECLARE v_status VARCHAR(200);

    CASE p_opcao

        WHEN 1 THEN   -- SELECT
            IF p_idOrder IS NOT NULL THEN
                SELECT
                    o.*,
                    CONCAT(c.Fname,' ',c.Lname) AS Cliente
                FROM orders o
                JOIN clients c ON o.idOrderClient = c.idClient
                WHERE o.idOrder = p_idOrder;
            ELSEIF p_idClient IS NOT NULL THEN
                -- Todos os pedidos de um cliente
                SELECT
                    o.*,
                    CONCAT(c.Fname,' ',c.Lname) AS Cliente
                FROM orders o
                JOIN clients c ON o.idOrderClient = c.idClient
                WHERE o.idOrderClient = p_idClient
                ORDER BY o.idOrder DESC;
            ELSE
                SELECT
                    o.*,
                    CONCAT(c.Fname,' ',c.Lname) AS Cliente
                FROM orders o
                JOIN clients c ON o.idOrderClient = c.idClient
                ORDER BY o.idOrder DESC;
            END IF;

        WHEN 2 THEN   -- INSERT
            INSERT INTO orders (idOrderClient, orderStatus, orderDescription, sendValue, paymentCash)
            VALUES (p_idClient, COALESCE(p_status,'Em processamento'),
                    p_description, COALESCE(p_sendValue, 10), COALESCE(p_paymentCash, FALSE));
            SET v_status = CONCAT('Pedido criado. ID: ', LAST_INSERT_ID(), ' | Cliente: ', p_idClient);
            SELECT v_status AS Resultado;

        WHEN 3 THEN   -- UPDATE (atualiza status e descrição)
            SELECT COUNT(*) INTO v_count FROM orders WHERE idOrder = p_idOrder;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido não encontrado.';
            ELSE
                UPDATE orders SET
                    orderStatus      = COALESCE(p_status,      orderStatus),
                    orderDescription = COALESCE(p_description, orderDescription),
                    sendValue        = COALESCE(p_sendValue,   sendValue),
                    paymentCash      = COALESCE(p_paymentCash, paymentCash)
                WHERE idOrder = p_idOrder;
                SELECT CONCAT('Pedido ID ', p_idOrder, ' atualizado.') AS Resultado;
            END IF;

        WHEN 4 THEN   -- DELETE
            SELECT COUNT(*) INTO v_count FROM orders WHERE idOrder = p_idOrder;
            IF v_count = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido não encontrado.';
            ELSE
                DELETE FROM orders WHERE idOrder = p_idOrder;
                SELECT CONCAT('Pedido ID ', p_idOrder, ' removido.') AS Resultado;
            END IF;

        ELSE
            SELECT 'Opção inválida: 1=SELECT, 2=INSERT, 3=UPDATE, 4=DELETE.' AS Resultado;

    END CASE;

END$$

DELIMITER ;


-- ============================================================
-- CHAMADAS DE TESTE — E-COMMERCE
-- ============================================================

-- 1. SELECT — lista todos os clientes
CALL manip_client(1, NULL, NULL, NULL, NULL, NULL, NULL);

-- 2. INSERT — novo cliente
CALL manip_client(2, NULL, 'Lucas', 'T', 'Ramos', '11199988877', 'Rua Nova 100, SP');

-- 3. SELECT — busca pelo CPF inserido
CALL manip_client(1, NULL, NULL, NULL, NULL, '11199988877', NULL);

-- 4. UPDATE — atualiza endereço (pegamos o último ID inserido como exemplo: 7)
CALL manip_client(3, 7, NULL, NULL, NULL, NULL, 'Av. Reformada 200, SP');

-- 5. DELETE — remove o cliente inserido
CALL manip_client(4, 7, NULL, NULL, NULL, NULL, NULL);

-- 6. SELECT — todos os produtos
CALL manip_product(1, NULL, NULL, NULL, NULL, NULL, NULL);

-- 7. SELECT — produtos da categoria Eletrônico
CALL manip_product(1, NULL, NULL, NULL, 'Eletrônico', NULL, NULL);

-- 8. INSERT — novo produto
CALL manip_product(2, NULL, 'Smartwatch Pro', FALSE, 'Eletrônico', 4.5, NULL);

-- 9. UPDATE — atualiza avaliação do produto recém inserido (ID=8)
CALL manip_product(3, 8, NULL, NULL, NULL, 5.0, NULL);

-- 10. DELETE — remove produto inserido
CALL manip_product(4, 8, NULL, NULL, NULL, NULL, NULL);

-- 11. SELECT — todos os pedidos
CALL manip_order(1, NULL, NULL, NULL, NULL, NULL, NULL);

-- 12. INSERT — novo pedido para cliente 1
CALL manip_order(2, NULL, 1, 'Em processamento', 'Compra via app', 12.50, FALSE);

-- 13. UPDATE — atualiza status do pedido para Confirmado
CALL manip_order(3, 5, NULL, 'Confirmado', NULL, NULL, NULL);

-- 14. SELECT — pedidos do cliente 2
CALL manip_order(1, NULL, 2, NULL, NULL, NULL, NULL);

-- 15. DELETE — remove pedido inserido no teste (ajuste o ID se necessário)
CALL manip_order(4, 5, NULL, NULL, NULL, NULL, NULL);
