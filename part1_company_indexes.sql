-- ============================================================
-- PARTE 1 — ÍNDICES E CONSULTAS: CENÁRIO COMPANY
-- Objetivo: Criar o schema company, inserir dados de teste,
--           definir índices estratégicos e responder às
--           perguntas de negócio com queries otimizadas.
-- ============================================================

DROP DATABASE IF EXISTS company_constraints;
CREATE DATABASE company_constraints;
USE company_constraints;

-- ============================================================
-- BLOCO 1 — CRIAÇÃO DAS TABELAS (schema company)
-- ============================================================

CREATE TABLE departament (
    Dname        VARCHAR(15)  NOT NULL,
    Dnumber      INT          NOT NULL,
    Mgr_ssn      CHAR(9)      NOT NULL,
    Mgr_start_date DATE,
    PRIMARY KEY (Dnumber),
    UNIQUE (Dname)
);

CREATE TABLE dept_locations (
    Dnumber   INT         NOT NULL,
    Dlocation VARCHAR(15) NOT NULL,
    PRIMARY KEY (Dnumber, Dlocation),
    CONSTRAINT fk_dept_loc
        FOREIGN KEY (Dnumber) REFERENCES departament(Dnumber)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE employee (
    Fname     VARCHAR(15)    NOT NULL,
    Minit     CHAR(1),
    Lname     VARCHAR(15)    NOT NULL,
    Ssn       CHAR(9)        NOT NULL,
    Bdate     DATE,
    Address   VARCHAR(50),
    Sex       CHAR(1),
    Salary    DECIMAL(10,2),
    Super_ssn CHAR(9),
    Dno       INT            NOT NULL,
    PRIMARY KEY (Ssn),
    CONSTRAINT fk_emp_dept
        FOREIGN KEY (Dno) REFERENCES departament(Dnumber)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emp_super
        FOREIGN KEY (Super_ssn) REFERENCES employee(Ssn)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Adiciona FK do gerente após criar employee
ALTER TABLE departament
    ADD CONSTRAINT fk_dept_mgr
        FOREIGN KEY (Mgr_ssn) REFERENCES employee(Ssn)
        ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE TABLE project (
    Pname    VARCHAR(25) NOT NULL,
    Pnumber  INT         NOT NULL,
    Plocation VARCHAR(15),
    Dnum     INT         NOT NULL,
    PRIMARY KEY (Pnumber),
    UNIQUE  (Pname),
    CONSTRAINT fk_proj_dept
        FOREIGN KEY (Dnum) REFERENCES departament(Dnumber)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE works_on (
    Essn  CHAR(9)        NOT NULL,
    Pno   INT            NOT NULL,
    Hours DECIMAL(3,1)   NOT NULL,
    PRIMARY KEY (Essn, Pno),
    CONSTRAINT fk_wo_emp
        FOREIGN KEY (Essn) REFERENCES employee(Ssn)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_wo_proj
        FOREIGN KEY (Pno) REFERENCES project(Pnumber)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE dependent (
    Essn           CHAR(9)     NOT NULL,
    Dependent_name VARCHAR(15) NOT NULL,
    Sex            CHAR(1),
    Bdate          DATE,
    Relationship   VARCHAR(8),
    PRIMARY KEY (Essn, Dependent_name),
    CONSTRAINT fk_dep_emp
        FOREIGN KEY (Essn) REFERENCES employee(Ssn)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================
-- BLOCO 2 — INSERÇÃO DE DADOS
-- ============================================================

-- Departamentos (sem FK de gerente por ora — inserimos depois)
INSERT INTO departament (Dname, Dnumber, Mgr_ssn, Mgr_start_date) VALUES
    ('Research',       5, '333445555', '1988-05-22'),
    ('Administration', 4, '987654321', '1995-01-01'),
    ('Headquarters',   1, '888665555', '1981-06-19');

-- Funcionários
INSERT INTO employee VALUES
    ('John',  'B', 'Smith',   '123456789', '1965-01-09', '731 Fondren, Houston TX',  'M', 30000.00, '333445555', 5),
    ('Franklin','T','Wong',   '333445555', '1955-12-08', '638 Voss,  Houston TX',    'M', 40000.00, '888665555', 5),
    ('Alicia', 'J','Zelaya',  '999887777', '1968-07-19', '3321 Castle, Spring TX',   'F', 25000.00, '987654321', 4),
    ('Jennifer','S','Wallace','987654321', '1941-06-20', '291 Berry,  Bellaire TX',  'F', 43000.00, '888665555', 4),
    ('Ramesh', 'K','Narayan', '666884444', '1962-09-15', '975 Fire Oak, Humble TX',  'M', 38000.00, '333445555', 5),
    ('Joyce',  'A','English', '453453453', '1972-07-31', '5631 Rice,  Houston TX',   'F', 25000.00, '333445555', 5),
    ('Ahmad',  'V','Jabbar',  '987987987', '1969-03-29', '980 Dallas, Houston TX',   'M', 25000.00, '987654321', 4),
    ('James',  'E','Borg',    '888665555', '1937-11-10', '450 Stone,  Houston TX',   'M', 55000.00, NULL,        1);

-- Localizações dos departamentos
INSERT INTO dept_locations VALUES
    (1,'Houston'),
    (4,'Stafford'),
    (5,'Bellaire'),
    (5,'Sugarland'),
    (5,'Houston');

-- Projetos
INSERT INTO project VALUES
    ('ProductX',     1, 'Bellaire',  5),
    ('ProductY',     2, 'Sugarland', 5),
    ('ProductZ',     3, 'Houston',   5),
    ('Computerization',10,'Stafford',4),
    ('Reorganization',  20,'Houston', 1),
    ('Newbenefits',     30,'Stafford',4);

-- Alocações em projetos
INSERT INTO works_on VALUES
    ('123456789',  1, 32.5), ('123456789',  2,  7.5),
    ('666884444',  3, 40.0), ('453453453',  1, 20.0),
    ('453453453',  2, 20.0), ('333445555',  2, 10.0),
    ('333445555',  3, 10.0), ('333445555', 10, 10.0),
    ('333445555', 20, 10.0), ('999887777', 30, 30.0),
    ('999887777', 10, 10.0), ('987987987', 10, 35.0),
    ('987987987', 30,  5.0), ('987654321', 30, 20.0),
    ('987654321', 20, 15.0), ('888665555', 20, NULL);

-- Dependentes
INSERT INTO dependent VALUES
    ('333445555','Alice',    'F','1986-04-05','Daughter'),
    ('333445555','Theodore', 'M','1983-10-25','Son'),
    ('333445555','Joy',      'F','1958-05-03','Spouse'),
    ('987654321','Abner',    'M','1942-02-28','Spouse'),
    ('123456789','Michael',  'M','1988-01-04','Son'),
    ('123456789','Alice',    'F','1988-12-30','Daughter'),
    ('123456789','Elizabeth','F','1967-05-05','Spouse');

-- ============================================================
-- BLOCO 3 — CRIAÇÃO DE ÍNDICES (com justificativa)
-- ============================================================

-- ---------------------------------------------------------------
-- ÍNDICE 1: employee(Dno)  →  B-Tree (padrão)
-- MOTIVO: A coluna Dno é chave estrangeira e aparece em TODA
--         consulta que relaciona funcionário ↔ departamento.
--         Um índice B-Tree aqui elimina full-table-scan ao
--         fazer JOIN ou WHERE Dno = ?.
--         Tipo B-Tree: ideal para igualdade E intervalo (ex: Dno IN (...)).
-- ---------------------------------------------------------------
CREATE INDEX idx_employee_dno ON employee(Dno);

-- ---------------------------------------------------------------
-- ÍNDICE 2: employee(Lname)  →  B-Tree
-- MOTIVO: Buscas por sobrenome são frequentes em sistemas de RH
--         (filtros, relatórios, tela de busca de funcionários).
--         B-Tree permite LIKE 'S%' além de igualdade exata.
-- ---------------------------------------------------------------
CREATE INDEX idx_employee_lname ON employee(Lname);

-- ---------------------------------------------------------------
-- ÍNDICE 3: employee(Super_ssn)  →  B-Tree
-- MOTIVO: FK de supervisor. Consultas hierárquicas (quem reporta
--         a quem) e JOINs de auto-relacionamento usam essa coluna.
--         Sem índice, cada nível da hierarquia exige full-scan.
-- ---------------------------------------------------------------
CREATE INDEX idx_employee_super ON employee(Super_ssn);

-- ---------------------------------------------------------------
-- ÍNDICE 4: dept_locations(Dlocation)  →  B-Tree
-- MOTIVO: A pergunta "Departamentos por cidade" filtra
--         WHERE Dlocation = 'Houston'. Sem índice a tabela
--         inteira é varrida a cada consulta por cidade.
--         B-Tree porque pode haver consultas ORDER BY Dlocation.
-- ---------------------------------------------------------------
CREATE INDEX idx_deptloc_location ON dept_locations(Dlocation);

-- ---------------------------------------------------------------
-- ÍNDICE 5: departament(Dname)  →  UNIQUE (já implícito) / B-Tree
-- MOTIVO: Buscas frequentes pelo nome do departamento em joins e
--         filtros de relatório. A constraint UNIQUE já cria um
--         índice internamente — aqui tornamos explícito para
--         documentar a intenção. (Sem re-criar se já existe.)
-- ---------------------------------------------------------------
-- (O índice UNIQUE em Dname foi criado automaticamente pelo DDL;
--  nenhuma instrução adicional necessária — documentado aqui.)

-- ---------------------------------------------------------------
-- ÍNDICE 6: works_on(Pno)  →  B-Tree
-- MOTIVO: JOIN entre works_on e project ocorre em toda consulta
--         de projetos × funcionários. Pno como FK sem índice
--         gera full-scan em works_on para cada projeto buscado.
-- ---------------------------------------------------------------
CREATE INDEX idx_workson_pno ON works_on(Pno);

-- ---------------------------------------------------------------
-- ÍNDICE 7: employee(Salary)  →  B-Tree
-- MOTIVO: Relatórios de RH frequentemente ordenam ou filtram
--         por faixa salarial (WHERE Salary BETWEEN x AND y,
--         ORDER BY Salary DESC). B-Tree suporta range scans.
-- NÃO usamos HASH aqui pois HASH não serve para intervalos.
-- ---------------------------------------------------------------
CREATE INDEX idx_employee_salary ON employee(Salary);

-- ============================================================
-- BLOCO 4 — QUERIES DE NEGÓCIO (com índices sendo aproveitados)
-- ============================================================

-- -----------------------------------------------------------
-- Q1: Qual o departamento com maior número de funcionários?
-- Índices usados: idx_employee_dno (GROUP BY/JOIN em Dno)
-- -----------------------------------------------------------
SELECT
    d.Dname                          AS Departamento,
    d.Dnumber                        AS NumeroDept,
    COUNT(e.Ssn)                     AS TotalFuncionarios,
    CONCAT(mgr.Fname,' ',mgr.Lname)  AS Gerente,
    AVG(e.Salary)                    AS SalarioMedio,
    MAX(e.Salary)                    AS MaiorSalario,
    MIN(e.Salary)                    AS MenorSalario
FROM departament d
INNER JOIN employee e   ON d.Dnumber = e.Dno         -- → idx_employee_dno
INNER JOIN employee mgr ON d.Mgr_ssn = mgr.Ssn
GROUP BY d.Dnumber
ORDER BY TotalFuncionarios DESC
LIMIT 1;

-- Versão ampliada: ranking completo de departamentos por headcount
SELECT
    d.Dname                          AS Departamento,
    COUNT(e.Ssn)                     AS TotalFuncionarios,
    CONCAT(mgr.Fname,' ',mgr.Lname)  AS Gerente,
    ROUND(AVG(e.Salary), 2)          AS SalarioMedio,
    RANK() OVER (ORDER BY COUNT(e.Ssn) DESC) AS Ranking
FROM departament d
INNER JOIN employee e   ON d.Dnumber = e.Dno
INNER JOIN employee mgr ON d.Mgr_ssn = mgr.Ssn
GROUP BY d.Dnumber
ORDER BY TotalFuncionarios DESC;

-- -----------------------------------------------------------
-- Q2: Quais são os departamentos por cidade?
-- Índices usados: idx_deptloc_location (WHERE / GROUP BY em Dlocation)
-- -----------------------------------------------------------
SELECT
    dl.Dlocation                              AS Cidade,
    d.Dname                                   AS Departamento,
    d.Dnumber                                 AS NumeroDept,
    CONCAT(mgr.Fname,' ',mgr.Lname)           AS Gerente,
    COUNT(DISTINCT e.Ssn)                     AS FuncionariosNaCidade
FROM dept_locations dl
INNER JOIN departament d   ON dl.Dnumber  = d.Dnumber
INNER JOIN employee    mgr ON d.Mgr_ssn   = mgr.Ssn
LEFT  JOIN employee    e   ON e.Dno       = d.Dnumber
GROUP BY dl.Dlocation, d.Dnumber
ORDER BY dl.Dlocation, d.Dname;            -- → idx_deptloc_location

-- Agrupado apenas por cidade (quantos departamentos por cidade)
SELECT
    dl.Dlocation                              AS Cidade,
    COUNT(DISTINCT dl.Dnumber)                AS QtdDepartamentos,
    GROUP_CONCAT(DISTINCT d.Dname ORDER BY d.Dname SEPARATOR ', ') AS Departamentos
FROM dept_locations dl
INNER JOIN departament d ON dl.Dnumber = d.Dnumber
GROUP BY dl.Dlocation
ORDER BY QtdDepartamentos DESC, dl.Dlocation;

-- -----------------------------------------------------------
-- Q3: Relação de empregados por departamento
-- Índices usados: idx_employee_dno, idx_employee_lname
-- -----------------------------------------------------------
SELECT
    d.Dname                                                 AS Departamento,
    d.Dnumber                                               AS NumeroDept,
    CONCAT(e.Fname,' ',COALESCE(e.Minit,''),' ',e.Lname)   AS Funcionario,
    e.Ssn,
    e.Sex,
    e.Salary,
    e.Bdate,
    TIMESTAMPDIFF(YEAR, e.Bdate, CURDATE())                 AS Idade,
    CONCAT(sup.Fname,' ',sup.Lname)                         AS Supervisor
FROM departament d
INNER JOIN employee e    ON d.Dnumber  = e.Dno           -- → idx_employee_dno
LEFT  JOIN employee sup  ON e.Super_ssn = sup.Ssn        -- → idx_employee_super
ORDER BY d.Dname, e.Lname, e.Fname;                      -- → idx_employee_lname

-- Versão resumida: contagem + salário médio por departamento
SELECT
    d.Dname                    AS Departamento,
    COUNT(e.Ssn)               AS TotalFuncionarios,
    ROUND(AVG(e.Salary), 2)    AS SalarioMedio,
    SUM(e.Salary)              AS FolhaSalarial,
    SUM(CASE WHEN e.Sex = 'M' THEN 1 ELSE 0 END) AS Masculino,
    SUM(CASE WHEN e.Sex = 'F' THEN 1 ELSE 0 END) AS Feminino
FROM departament d
INNER JOIN employee e ON d.Dnumber = e.Dno               -- → idx_employee_dno
GROUP BY d.Dnumber
ORDER BY TotalFuncionarios DESC;

-- -----------------------------------------------------------
-- Q4 (bônus): Funcionários e seus projetos com horas trabalhadas
-- Índices usados: idx_workson_pno, idx_employee_dno
-- -----------------------------------------------------------
SELECT
    CONCAT(e.Fname,' ',e.Lname)  AS Funcionario,
    d.Dname                      AS Departamento,
    p.Pname                      AS Projeto,
    p.Plocation                  AS LocalProjeto,
    wo.Hours                     AS HorasTrabalhadas,
    CASE
        WHEN wo.Hours IS NULL     THEN 'Sem registro'
        WHEN wo.Hours < 10        THEN 'Parcial'
        WHEN wo.Hours < 30        THEN 'Regular'
        ELSE 'Integral'
    END                          AS RegimeTrabalho
FROM employee e
INNER JOIN departament d ON e.Dno    = d.Dnumber          -- → idx_employee_dno
INNER JOIN works_on    wo ON e.Ssn   = wo.Essn
INNER JOIN project     p  ON wo.Pno  = p.Pnumber           -- → idx_workson_pno
ORDER BY d.Dname, e.Lname, p.Pname;

-- -----------------------------------------------------------
-- Q5 (bônus): Faixa salarial por departamento – HAVING
-- Índices usados: idx_employee_dno, idx_employee_salary
-- -----------------------------------------------------------
SELECT
    d.Dname                    AS Departamento,
    COUNT(e.Ssn)               AS TotalFuncionarios,
    MIN(e.Salary)              AS MenorSalario,
    MAX(e.Salary)              AS MaiorSalario,
    ROUND(AVG(e.Salary),2)     AS SalarioMedio,
    SUM(e.Salary)              AS TotalFolha
FROM departament d
INNER JOIN employee e ON d.Dnumber = e.Dno
GROUP BY d.Dnumber
HAVING AVG(e.Salary) > 25000
ORDER BY SalarioMedio DESC;
