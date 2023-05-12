# Introdução

Projeto desenvolvido a partir da simulação de uma empresa real, desde a criação de perguntas de negócio até a criação de um dashboard de análise de dados.

Base de dados: Sakila Sample Database
doc: https://dev.mysql.com/doc/sakila/en/sakila-introduction.html

A empresa fictícia se chama Bee Movies, uma vez que os dados representam uma loja de aluguel de DVD. Os requisitos de negócio definidos foram os seguintes:
    - Visão gerencial da situação atual da empresa (mês atual)
    - Análise de quais categorias de filmes são mais locadas e representam maior receita
    - Quais os principais clientes da empresa e onde estão localizados
    - Como está a receita da empresa mês a mês e a comparação com a meta
    - Análise de quais países são os principais clientes

# Modelagem de dados

A estrutura do banco de dados segue conforme imagem abaixo:

![This is an image](https://dev.mysql.com/doc/sakila/en/images/sakila-schema.png)

A fim de simplificar os relacionamentos e montar um star schema no Power BI, foram criadas as seguintes tabelas:

** d_payment **
Dimensão com informações de pagamento das locações.

schema = (
    payment_id varchar(10), 
    payment_date datetime,
    amount numeric(16,2),
    payment_type varchar(30)
)

Para poder ter uma análise mais detalhada, foi criado o campo "payment_type" a partir da geração de números aleatórios e atribuindo uma forma de acordo com o número gerado.
'''
CASE
    WHEN round(RAND() * 3) = 0 THEN "debit card"
    WHEN round(RAND() * 3) = 1 THEN "credit card"
    WHEN round(RAND() * 3) = 2 THEN "cash"
    ELSE "pix"
END payment_type
'''
As demais informações são provenientes da tabela original payment.

** d_category **
Dimensão com a nomenclatura da categoria a partir do id. Todas informações são provenientes da tabela original category.

schema = (
    category_id varchar(10),
    name varchar(30)
)

** d_film **
Dimensão com informações dos filmes. Todas informações são provenientes da tabela original film.

schema = (
    film_id varchar(10),
    title varchar(30),
    description varchar(200),
    rental_duration int,
    rental_rate numeric(16,2),
    rating varchar(10)
)

** d_customer **
Dimensão com informações dos clientes. As informações são provenientes das tabelas originais customer, address, city e country.

schema = (
    customer_id varchar(10),
    first_name varchar(50), 
    last_name varchar(50),
    email varchar(100),
    address varchar(60),
    district varchar(30),
    postal_code varchar(10),
    city varchar(50),
    country varchar(50)
)

** d_store **
Dimensão com informações das lojas. As informações são provenientes das tabelas originais store, address, city e country.

schema = (
    store_id varchar(10),
    address varchar(60),
    district varchar(30),
    city varchar(50),
    country varchar(50)
)

** f_rental **
Tabela fato contendo as ocorrências de locação juntamente com os campos category_id, film_id, store_id e payment_id. As informações são provenientes das tabelas originais rental, inventory, film_category e payment.

schema = (
    rental_id varchar(10),
    rental_date datetime,
    customer_id varchar(10),
    film_id varchar(10),
    store_id varchar(10),
    category_id varchar(10), 
    payment_id varchar(10)
)

# Dashboard

## Star Schema

A partir da modelagem de dados realizada, foi estabelecida uma conexão do Power BI com o banco de dados sakila, a partir do localhost. 

Dentro da ferramenta de BI foi criada uma tabela d_calendar, com datas variáveis a partir das datas presentes na tabela fato, garantindo que todo o período necessário fosse contemplado.
''' d_calendar = CALENDAR(MIN(f_rental[rental_date]), MAX(f_rental[rental_date])) ''' 

Exceto pela d_calendar, todas as tabelas dimensão foram ligadas à tabela fato pelo id correspondente, em uma ligação de 1 para muitos. A calendário foi relacionada através da data, numa ligação 1:1

## Construção Dashboard

### Tela Home

Foi criada uma tela inicial com as principais informações num formato gerencial. Para mostrar apenas a informação mais recente (mês atual), foi criada uma coluna calculada (booleano) na tabela calendário, a partir da fórmula descrita abaixo e utilizando um filtro na página que seleciona somente os dados identificados como mês de referência na fórmula.
''' mes_ref = IF(AND(YEAR(d_calendar[Date]) = YEAR(MAX(d_calendar[Date])), MONTH(d_calendar[Date]) = MONTH(MAX(d_calendar[Date]))), 1, 0) '''

### Tela Categories

Para análise das categorias, foi disponibilizada uma evolução história com base no total de locações e um top 5. Ademais, foi criada uma matriz que apresenta valores totais de locação e receita, a qual pode ser visualizada somente por categorias ou numa forma mais granular, visualizando por filmes dentro de cada categoria.

### Tela Clients

A tela de cliente apresenta Big Numbers relacionados ao total de clientes da empresa e o total de países atendidos por ela. É possível também verificar quais os 5 clientes que mais realizam locações e verificar onde cada um está localizado a partir de um mapa*.

*Para que seja possível a visualização do mapa, é necessário habilitar a função no Power BI: Arquivo > Opções e Configurações > Opções > Global > Segurança.

### Tela Revenue

A tela de receita traz uma particularidade em relação às demais telas. Além do gráfico de evolução histórica, da tabela com informações mais granulares e da análise de qual forma de pagamento é mais utilizada, é apresentado um gráfico de indicador (velocímetro) que faz a comparação da receita atingida com a meta definida. Para isso, foi utilizado o recurso de indicador, que permite que haja um filtro oculto atrelado à ação de um botão. Foi necessário também alterar as interações entre os componentes da tela, para que o filtro oculto funcionasse apenas para o velocímetro enquanto os demais filtros da tela funcionassem para as outras visualizações. Além disso, há também o uso de formatação condiciontal a partir de uma medida que define a cor desse velocímetro, sendo verde para valores acima da meta e vermelho para valores abaixo.

''' 
rev_conditional_format = 
    SWITCH(
        TRUE(),
        SUM(d_payment[amount]) >= [rev_target_amount], "#00E6BB",
        SUM(d_payment[amount]) < [rev_target_amount], "#e6002b"
    )
'''

### Tela Countries

Por fim, a tela de análise dos países apresenta gráficos mais simples, porém com um detalhe diferente das demais: o gráfico que apresenta o total de clientes por país possuí uma dica de ferramenta personalizada, que, ao passar o mouse em cima de cada barra do gráfico, é apresentada uma tabela com o nome e endereço dos clientes.