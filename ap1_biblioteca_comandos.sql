Create table Cidades(
	id int auto_increment primary key,
    nome varchar(45) not null
);
Create table Categorias(
	id int auto_increment primary key,
    nome varchar(30) not null
);
Create table Bibliotecas(
	id int auto_increment primary key,
    nome varchar(50) not null,
    id_cidade int,
    constraint c_fk_b
		foreign key(id_cidade) references Cidades(id)
			on update cascade
            on delete set null
);
Create table Funcionarios(
	id int auto_increment primary key,
    nome varchar(70),
    salario decimal(10,2),
    genero char(2),
    id_cidade int,
    id_biblioteca int,
    constraint c_fk_f
		foreign key(id_cidade) references Cidades(id)
			on update cascade
            on delete set null,
	constraint b_fk_f
		foreign key(id_biblioteca) references Bibliotecas(id)
			on update cascade
            on delete cascade
);
Create table Autores(
	id int auto_increment primary key,
    nome varchar(70) not null,
    cpf char(11) unique not null,
    genero char(2) not null,
    id_cidade int,
    constraint c_fk_a
		foreign key(id_cidade) references Cidades(id)
			on update cascade
            on delete set null
);
Create table Clientes(
	id int auto_increment primary key,
    nome varchar(60) not null,
    idade int not null,
    genero char(2) not null,
    cpf char(11) unique not null,
    id_cidade int,
    constraint c_fk_c
		foreign key(id_cidade) references Cidades(id)
			on update cascade
            on delete set null
);
Create table Livros(
	id int auto_increment primary key,
    titulo varchar(35) not null,
    num_paginas int not null,
    data_publi date not null,
    is_out bool not null,
    id_categoria int,
    id_biblioteca int,
    constraint c_fk_l
		foreign key(id_categoria) references Categorias(id)
			on update cascade
            on delete restrict,
	constraint b_fk_l
		foreign key(id_biblioteca) references Bibliotecas(id)
			on update cascade
            on delete restrict
);
Create table Escreve(
	id_autor int,
    id_livro int,
    constraint a_fk_e
		foreign key(id_autor) references Autores(id)
			on update cascade
            on delete restrict,
	constraint l_fk_e
		foreign key(id_livro) references Livros(id)
			on update cascade
            on delete restrict
);
Create table Emprestimo(
    dataSaida date not null,
    dataRetorno date not null,
	id_cliente int,
    id_livro int,
    constraint c_fk_emp
		foreign key(id_cliente) references Clientes(id)
			on update cascade
            on delete set null,
	constraint l_fk_emp
		foreign key(id_livro) references Livros(id)
			on update cascade
            on delete set null
);

-- Uma view que lista todos os Autores nascidos em cidades que possuem filiais
CREATE VIEW autores_filiais AS 
	Select C.nome as "Cidade", A.nome as "Autores", B.nome as "Filial"
    FROM Cidades C 
    	INNER JOIN Autores A on A.id_cidade = C.id
        INNER JOIN Bibliotecas B on B.id_cidade = C.id;
SELECT * FROM autores_filiais;
SELECT Autores FROM autores_filiais WHERE Cidade LIKE "Torres";

-- Uma view que lista todos os Livros atualmente na biblioteca (NÃO EMPRESTADOS)
CREATE VIEW em_estoque AS 
	SELECT L.titulo as "Livro"
    FROM Livros L
    wHERE L.is_out = 0;
    
select * from em_estoque;  
update Livros set is_out = true where id = 1;
select * from em_estoque;
update Livros set is_out = false where id = 1;
select * from em_estoque;

-- Uma view que lista os top 6 livros mais retirados nos últimos 3 meses
CREATE VIEW maisretirados_livros AS
	SELECT L.titulo as Livro, COUNT(E.id_livro) as Vezes_Retirado
    FROM Emprestimo E
    	INNER JOIN Livros L on E.id_livro = L.id
    WHERE E.dataSaida >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH) AND E.dataSaida <= CURRENT_DATE()
    GROUP BY E.id_livro
    ORDER BY "Vezes Retirado" DESC
    LIMIT 6;
    
select * from maisretirados_livros;
    
-- Uma view que lista as top 6 categorias mais retiradas no último mês
CREATE VIEW maisretirados_categoria AS
	SELECT C.nome as Categoria, COUNT(L.id) as Vezes_Retiradas
    FROM Emprestimo E
    	INNER JOIN Livros L on E.id_livro = L.id
        INNER JOIN Categorias C ON L.id_categoria = C.id
	WHERE E.dataSaida BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH) AND CURRENT_DATE
	GROUP BY C.id
    ORDER BY "Vezes Retiradas" DESC
    LIMIT 6;
    
select * from maisretirados_categoria;
select * from Emprestimo;
    
    
    
    
    
-- Uma SP que "envia" livros para empréstimo
DELIMITER $$
CREATE PROCEDURE add_livro_emprestimo(p_idlivro int, p_idcliente int)
BEGIN
	
    IF (SELECT is_out FROM Livros WHERE id = p_idlivro) = true THEN
    
		SELECT "Livro Locado!" as "Este Livro não está disponível";
	ELSEIF p_idcliente NOT IN (SELECT id FROM Clientes) THEN
    
		SELECT "Cliente não cadastrado!" as "O Cliente não está no sistema";
	ELSEIF p_idlivro NOT IN (SELECT id FROM Livros) THEN
    
		SELECT "Livro Não Encontrado!" as "O Livro não está cadastrado";
    ELSEIF p_idlivro IN (SELECT id from Livros) THEN
    
		INSERT INTO Emprestimo VALUES(current_date(),adddate(dataSaida, INTERVAL 1 week),p_idcliente,p_idlivro);
        UPDATE Livros set is_out = true where Livros.id = p_idlivro;
    END IF;
END $$
DELIMITER ;

update Livros set is_out = true where id = 1;
update Livros set is_out = false where id = 1;
call add_livro_emprestimo(51,1);
select * from Emprestimo;
select * from Livros;


-- Uma SP que "retira" os livros do empréstimo/Devolve o livro do empréstimo a biblioteca
DELIMITER $$
CREATE PROCEDURE receber_livro_emprestimo(p_idlivro int, p_idcliente int)
BEGIN

	IF (SELECT is_out FROM Livros WHERE id = p_idlivro) = false THEN
    
		SELECT "Este Livro não foi retirado para empréstimo" as "Livro não locado!";
	ELSEIF p_idcliente NOT IN (SELECT id FROM Clientes) THEN
    
		SELECT "O Cliente não está no sistema" as "Cliente não cadastrado!";
	ELSEIF p_idlivro NOT IN (SELECT id FROM Livros) THEN
    
		SELECT "O Livro não está cadastrado" as "Livro Não Encontrado!";
    ELSEIF p_idlivro IN (SELECT id from Livros) THEN
    
        UPDATE Livros set is_out = false where Livros.id = p_idlivro;
    END IF;
END $$
DELIMITER ;

call receber_livro_emprestimo(1,1);
select * from Livros;
select * from Emprestimo;


-- Uma SP que retorna os livros de título inserido, categoria inserida ou autor inserido
DELIMITER $$
CREATE PROCEDURE encontrar_livro_filtro(p_titulolivro varchar(35), p_categorialivro int, p_autorlivro int, operador char(1))
-- Operadores: T - Título, C - Categoria, A - Autor
BEGIN

	IF (operador LIKE 'T') THEN
		
        SELECT titulo
        FROM Livros
        WHERE titulo LIKE concat(p_titulolivro,"%");
	ELSEIF (operador LIKE 'C') THEN
    
		IF p_categorialivro NOT IN (SELECT id FROM Categorias) THEN
        
			SELECT "Categoria não identificada" as "Categoria inexistente";
		ELSE
        
			SELECT L.titulo as 'Titulo', C.nome as 'Categoria'
			FROM Categorias C
				inner join Livros L on L.id_categoria = C.id
			WHERE C.id = p_categorialivro;
        END IF;
	ELSEIF (operador LIKE 'A') THEN
    
		IF p_autorlivro NOT IN (SELECT id FROM Autores) THEN
			
            SELECT "Autor não identificado" as "Autor inexistente";
		ELSE
        
			SELECT L.titulo as 'Titulo', A.nome as 'Autor(es)'
            FROM Escreve E
				INNER JOIN Livros L on L.id = E.id_livro
                INNER JOIN Autores A on A.id = E.id_autor
			WHERE E.id_autor = p_autorlivro;
		END IF;
	ELSE 
		
        SELECT "A Operação não é suportada!" as "Operação inexistente";
    END IF;
END $$
DELIMITER ;

CALL encontrar_livro_filtro("O Sa",1,7,"T");


-- Uma SP que cadastra clientes
DELIMITER $$
CREATE PROCEDURE cadastrar_clientes_biblioteca(p_nomecliente varchar(60), p_idadecliente int, p_generocliente char(2), p_cpfcliente char(11), p_idcidadecliente int)
BEGIN

	IF p_cpfcliente IN (SELECT cpf FROM Clientes) THEN
    
		SELECT "Já existe um cliente com esse CPF" as "CPF não único";
	ELSEIF p_cpfcliente IN (SELECT cpf FROM Autores) THEN
    
		SELECT "Já existe um autor com esse CPF" as "CPF não único";
	ELSEIF p_idadecliente < 0 THEN
		
        SELECT "Este cliente não possui idade para ser cadastrado(a)" as "Idade inválida";
	ELSEIF P_idcidadecliente NOT IN (SELECT id FROM Cidades) THEN
    
		SELECT "A cidade inserida não está cadastrada no banco" as "Cidade inexistente";
	ELSE
		
        insert into Clientes values(null,p_nomecliente,p_idadecliente,p_generocliente,p_cpfcliente,p_idcidadecliente);
        SELECT * FROM Clientes;
    END IF;
END $$
DELIMITER ;

CALL cadastrar_clientes_biblioteca("Roberto",5,"M","12469873500",1); -- Cpf cliente já existente
CALL cadastrar_clientes_biblioteca("Roberto",5,"M","12345678911",1); -- Cpf autor já existente
CALL cadastrar_clientes_biblioteca("Roberta",-1,"F","12469852400",1); -- Idade negativa
CALL cadastrar_clientes_biblioteca("Roberta",10,"F","11111111111",15); -- Cidade não existente
CALL cadastrar_clientes_biblioteca("Roberta",21,"F","99451111987",1);


-- Uma SP que permita ao usuário ALTERAR o título, o número de páginas, a data de publicação, a categoria E/OU o autor de um livro* (Ao alterar autor, somente será possível inserir um)
-- Operador: L - Livro completo, T - Titulo, P - Páginas, D - Data Publi, C - Categoria, A - Autor
DELIMITER $$
CREATE PROCEDURE atualizar_valores_livro(operador char(1), p_idlivro int, p_newtitulo varchar(35), p_newpaginas int, p_newdata date, p_newcat int, p_newautor int)
BEGIN
	
    IF p_idlivro IN (SELECT id from Livros) THEN
		
        IF (operador LIKE 'L') THEN
        
			UPDATE Livros set titulo = p_newtitulo, num_paginas = p_newpaginas, data_publi = p_newdata, id_categoria = p_newcat
				WHERE id = p_idlivro;
			UPDATE Escreve set id_autor = p_newautor
				WHERE id_livro = p_idlivro;
		ELSEIF (operador LIKE 'T') THEN
        
			UPDATE Livros set titulo = p_newtitulo
				WHERE id = p_idlivro;
		ELSEIF (operador LIKE 'P') THEN
        
			UPDATE Livros set num_paginas = p_newpaginas
				WHERE id = p_idlivro;
		ELSEIF (operador LIKE 'D') THEN
        
			UPDATE Livros set data_publi = p_newdata
				WHERE id = p_idlivro;
		ELSEIF (operador LIKE 'C') THEN
        
			UPDATE Livros set id_categoria = p_newcat
				WHERE id = p_idlivro;
		ELSEIF (operador LIKE 'A') THEN
        
			UPDATE Escreve set id_autor = p_newautor
				WHERE id_livro = p_idlivro;
		ELSE
        
			SELECT "A operação selectionada não é suportada" as "Operação inválida";
        END IF;
    ELSE
    
		SELECT "O código do livro inserido não consta no banco" as "Livro inexistente";
    END IF;
END $$
DELIMITER ;
select * from Livros;
select * from Escreve;
CALL atualizar_valores_livro("J",1,"Reading 101",50,'071008',3,2);	-- Operador inválido
CALL atualizar_valores_livro("T",15,"Reading 101",50,'071008',3,2); -- Id inexistente
CALL atualizar_valores_livro("T",1,"Reading 101",50,'071008',3,2); -- Mudar Título
CALL atualizar_valores_livro("p",1,"Reading 101",50,'071008',3,2); -- Mudar Páginas
CALL atualizar_valores_livro("D",1,"Reading 101",50,'071008',3,2); -- Mudar Data
CALL atualizar_valores_livro("C",1,"Reading 101",50,'071008',3,2); -- Mudar Categoria
CALL atualizar_valores_livro("A",1,"Reading 101",50,'071008',3,2); -- Mudar Autor
CALL atualizar_valores_livro("L",1,"Aprenda a ler",67,'071108',2,1); -- Mudar tudo (de volta)










-- Inserindo nas tabelas para testar SP`s e views posteriormente

insert into Cidades values(null,"Torres"),(null,"Passo de Torres");
insert into Categorias values(null,"Suspense"),(null,"Educacional"),(null,"Programação"),(null,"Infantojuvenil");
insert into Bibliotecas values(null,"Biblioteca San Martin-Topazio",1),(null,"Biblioteca San Martin-Pasargada",2);
insert into Funcionarios values(null,"Pedro",1420,"M",1,1),(null,"Paola",2200,"F",1,1),(null,"Marcy",950,"F",2,1),(null,"Carlos",1400,"M",2,1),(null,"Beatriz",1500,"F",1,1);
insert into Autores values(null, "Lonteiro Mobato","12345678911",1,"M"),(null, "Tan Lese","10987654321",1,"M"),(null, "Johann Goat","15932648722",2,"M"),(null, "Achado de Massis","12345678901",1,"M");
insert into Clientes values(null,"Neorio",17,"M","12469873500",1),(null,"Nitou",21,"F","94456523100",1),(null,"Julian",8,"M","00537896421",1);
insert into Livros values	(null, "Aprenda a ler", 67, '071108',false,2,1),(null, "O Saci", 102, '081027',false,1,1),(null, "O feiticeiro do Aprendiz", 146, '730418',false,4,1),
							(null, "C# e outras notas", 243, '110429',false,3,1),(null, "Die kuche", 94, '750226',false,1,1);
insert into Escreve values(1,1),(1,2),(2,2),(3,3),(4,4),(2,4),(3,5);
insert into Emprestimo values('221108','221115',1,1);call add_livro_emprestimo(1,1)
