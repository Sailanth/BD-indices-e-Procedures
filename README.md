# 🗄️ Índices e Procedures em Banco de Dados — Company & E-Commerce

## 📋 Descrição do Projeto

Este repositório cobre dois desafios de banco de dados relacional da formação **SQL Database Specialist (DIO)**, aplicados sobre dois cenários distintos:

| Cenário | Contexto |
|---|---|
| **Company** | Empresa com funcionários, departamentos, projetos e dependentes |
| **E-Commerce** | Loja virtual com clientes, produtos e pedidos |

---

## 🗂 Estrutura dos Arquivos

```
├── part1_company_indexes.sql   # Schema company + índices + queries analíticas
├── part2_procedures.sql        # Procedures CRUD para company e e-commerce
└── README.md
```

---

## PARTE 1 — Índices no Banco de Dados (Company)

### Esquema company

O cenário **company** contém as seguintes tabelas:

| Tabela | Descrição |
|---|---|
| `employee` | Funcionários com salário, supervisor e departamento |
| `departament` | Departamentos com gerente e data de início |
| `dept_locations` | Localizações físicas de cada departamento |
| `project` | Projetos vinculados a departamentos |
| `works_on` | Alocação de funcionários em projetos com horas |
| `dependent` | Dependentes dos funcionários |

---

### Índices Criados

#### `idx_employee_dno` — B-Tree em `employee(Dno)`

```sql
CREATE INDEX idx_employee_dno ON employee(Dno);
```

**Motivo:** `Dno` é chave estrangeira e aparece em **toda** query que relaciona funcionário ↔ departamento (`JOIN`, `WHERE Dno = ?`, `GROUP BY`). Sem esse índice, cada consulta de headcount por departamento exige um full-scan da tabela employee. B-Tree foi escolhido pois suporta tanto igualdade quanto `IN (...)`.

---

#### `idx_employee_lname` — B-Tree em `employee(Lname)`

```sql
CREATE INDEX idx_employee_lname ON employee(Lname);
```

**Motivo:** Buscas por sobrenome são frequentes em sistemas de RH (tela de busca, relatórios de listagem). B-Tree viabiliza `LIKE 'S%'` além de igualdade exata. HASH foi descartado por não suportar buscas por prefixo.

---

#### `idx_employee_super` — B-Tree em `employee(Super_ssn)`

```sql
CREATE INDEX idx_employee_super ON employee(Super_ssn);
```

**Motivo:** FK de auto-relacionamento (supervisor). Consultas hierárquicas ("quem reporta a quem") e JOINs de `employee e ON e.Super_ssn = s.Ssn` usam essa coluna como ponto de junção. Sem índice, cada nível da árvore hierárquica dispara um full-scan.

---

#### `idx_deptloc_location` — B-Tree em `dept_locations(Dlocation)`

```sql
CREATE INDEX idx_deptloc_location ON dept_locations(Dlocation);
```

**Motivo:** A pergunta *"departamentos por cidade"* filtra `WHERE Dlocation = 'Houston'` e pode ordenar por cidade. B-Tree foi escolhido (não HASH) porque `ORDER BY Dlocation` e buscas por intervalo de cidades também se beneficiam de B-Tree. HASH só serve para igualdade exata.

---

#### `idx_workson_pno` — B-Tree em `works_on(Pno)`

```sql
CREATE INDEX idx_workson_pno ON works_on(Pno);
```

**Motivo:** `Pno` é FK em `works_on`. Todo JOIN entre `works_on` e `project` usa essa coluna. Sem índice, para cada projeto buscado ocorre um full-scan em `works_on`.

---

#### `idx_employee_salary` — B-Tree em `employee(Salary)`

```sql
CREATE INDEX idx_employee_salary ON employee(Salary);
```

**Motivo:** Relatórios de RH frequentemente fazem `WHERE Salary BETWEEN x AND y` e `ORDER BY Salary DESC`. B-Tree suporta **range scans**, o que HASH não faz. Índice HASH foi explicitamente descartado aqui.

---

### Por que B-Tree e não HASH?

| Critério | B-Tree ✅ | HASH ❌ |
|---|---|---|
| Igualdade (`=`) | Sim | Sim |
| Intervalo (`BETWEEN`, `>`, `<`) | **Sim** | Não |
| Prefixo (`LIKE 'S%'`) | **Sim** | Não |
| `ORDER BY` | **Sim** | Não |
| Hierarquia / JOIN em FK | **Sim** | Não |

> HASH seria indicado apenas para colunas com busca exclusiva por igualdade exata em tabelas muito grandes, como um campo `status ENUM` com poucos valores distintos e sem necessidade de range.

---

### Queries respondidas

| # | Pergunta | Índices aproveitados |
|---|---|---|
| Q1 | Departamento com maior número de pessoas | `idx_employee_dno` |
| Q2 | Departamentos por cidade | `idx_deptloc_location` |
| Q3 | Relação de empregados por departamento | `idx_employee_dno`, `idx_employee_lname`, `idx_employee_super` |
| Q4 | Funcionários e seus projetos com horas | `idx_workson_pno`, `idx_employee_dno` |
| Q5 | Faixa salarial por departamento (HAVING) | `idx_employee_dno`, `idx_employee_salary` |

---

## PARTE 2 — Procedures para Manipulação de Dados

### Estrutura das Procedures

Cada procedure recebe uma **variável de controle `p_opcao`** que determina a ação:

| Valor | Ação |
|---|---|
| `1` | SELECT (busca / listagem) |
| `2` | INSERT (inserção) |
| `3` | UPDATE (atualização) |
| `4` | DELETE (remoção) |

Internamente, a lógica usa `CASE p_opcao WHEN 1 THEN ... WHEN 2 THEN ...` com validações (`DECLARE v_count`, `SIGNAL SQLSTATE`) antes de cada operação destrutiva.

---

### Procedures — Company

#### `manip_employee(p_opcao, p_ssn, p_fname, ...)`
CRUD completo na tabela `employee`. O SELECT aceita SSN específico ou lista todos. UPDATE usa `COALESCE` para atualizar apenas os campos fornecidos (campos NULL são mantidos).

#### `manip_departament(p_opcao, p_dnumber, p_dname, ...)`
CRUD completo na tabela `departament`. Validações impedem remoção de departamentos inexistentes e inserção de números duplicados.

---

### Procedures — E-Commerce

#### `manip_client(p_opcao, p_id, p_fname, ...)`
CRUD na tabela `clients`. SELECT aceita busca por ID ou por CPF. INSERT valida CPF duplicado antes de inserir.

#### `manip_product(p_opcao, p_id, p_pname, ...)`
CRUD na tabela `product`. SELECT aceita busca por ID ou filtragem por categoria inteira.

#### `manip_order(p_opcao, p_idOrder, p_idClient, ...)`
CRUD na tabela `orders`. SELECT aceita pedido específico, todos os pedidos de um cliente, ou listagem geral com JOIN em `clients`.

---

### Padrão de Segurança nas Procedures

Todas as procedures seguem o padrão:

```
1. DECLARE variáveis de controle (v_count, v_status)
2. CASE na variável de opção
3. Nas opções 2/3/4: verificar existência antes de agir
4. Em caso de erro: SIGNAL SQLSTATE '45000'
5. Em caso de sucesso: SELECT com mensagem de resultado
```

---

## 🚀 Como Executar

```bash
# MySQL 8.0+
mysql -u root -p

# Parte 1
source part1_company_indexes.sql;

# Parte 2 (requer part1 e o schema ecommerce já criados)
source part2_procedures.sql;
```

---

## 🧩 Tecnologias

- **MySQL 8.0** — SGBD relacional
- **SQL DDL** — `CREATE TABLE`, `CREATE INDEX`, `ALTER TABLE`
- **SQL DML** — `INSERT`, `UPDATE`, `DELETE`
- **SQL Procedures** — `CREATE PROCEDURE`, `DELIMITER`, `CASE`, `SIGNAL`

---

## 👤 Autor

### **[Sailanth](https://github.com/Sailanth)**

Desafio de Projeto — Formação SQL Database Specialist | DIO
