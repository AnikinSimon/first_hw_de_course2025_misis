--Создание таблицы users--
create table users (
    id integer primary key,
    name varchar(100) not null,
    email varchar(150),
    created_at timestamp default current_timestamp
);

--Создание таблицы categories--
create table categories (
    id integer primary key,
    name varchar(100) not null
);

--Создание таблицы products--
create table products (
	id integer  primary key,
	name varchar(100) not null,
	price numeric (10,2) not null check (price>=0),
	category_id integer not null,
	foreign key (category_id) references categories (id)
);

--Создание таблицы orders--
create table orders (
    id int primary key,
    user_id int not NUll,
    foreign key (user_id) references users(id),
    status varchar(150) default 'Ожидает оплаты',
	created_at timestamp default CURRENT_TIMESTAMP
);

--Создание таблицы order_items--
create table order_items (
    id int primary key,
    order_id int not null,
    foreign key (order_id) references orders(id),
    product_id int not null,
    foreign key (product_id) references products(id),
    quantity int default 0 check (quantity >= 0)
);

--Создание таблицы payments--
create table payments (
    id int primary key, 
    order_id int not null,
    foreign key (order_id) references orders(id),
    amount numeric(10,2) default 0 check (amount >= 0),
	payment_date timestamp default current_timestamp
)

--Задание 1--

select 
    categories.name as category_name, 
    AVG(products.price * order_items.quantity) as avg_order_amount
from categories
join products on products.category_id = categories.id
join order_items on order_items.product_id = products.id
join orders on orders.id = order_items.order_id and orders.created_at >= '2023-03-01' and orders.created_at < '2023-04-01'
group by category_name;

--Задание 2--

select 
    users.name as user_name, 
    sum(payments.amount) as total_spent, 
    rank() over (order by sum(payments.amount) desc) as user_rank
from users
join orders on orders.user_id = users.id and orders.status = 'Оплачен'
join payments on payments.order_id = orders.id
group by users.name
order by sum(payments.amount) DESC
limit 3

-- Задание 3--

select to_char(orders.created_at, 'YYYY-MM') as month, 
    COUNT(orders.id) as total_orders, 
    sum(payments.amount) as total_payments
from orders
join payments on orders.id = payments.order_id
group by month
order by month

-- Задание 4--

select 
    products.name as product_name, 
    SUM(order_items.quantity) as total_sold,
    ROUND(
        SUM(order_items.quantity)::NUMERIC /
            (
                select SUM(order_items.quantity)
                from order_items
            ) * 100, 
    2) as sales_percantage 
from products
join order_items on order_items.product_id = products.id
group by product_name
order by total_sold desc
limit 5

--Задание 5--

with avg_total_paid as 
(
    select 
        sum(payments.amount) as total_spent
    from users
    join orders on orders.user_id = users.id and orders.status = 'Оплачен'
    join payments on payments.order_id = orders.id
    group by users.name
    order by sum(payments.amount) DESC
)

select 
    users.name as user_name, 
    sum(payments.amount) as total_spent 
from users
join orders on orders.user_id = users.id and orders.status = 'Оплачен'
join payments on payments.order_id = orders.id
group by users.name
having sum(payments.amount) > (select avg(total_spent) from avg_total_paid)
order by sum(payments.amount) DESC

--Задание 6--

with cte as (
    select 
        categories.name as category_name, 
        products.name as product_name,
        sum(order_items.quantity) as total_sold,
        rank() over (partition by categories.name order by sum(order_items.quantity) desc) as paid_rank
    from categories
    join products on categories.id = products.category_id
    join order_items on order_items.product_id = products.id
    group by categories.name, products.name
)

select category_name, product_name, total_sold
from cte
where paid_rank <= 3;

--Задание 7--

with cte as (
    select 
        to_char(orders.created_at, 'YYYY-MM') as month, 
        categories.name as category_name,
        sum(order_items.quantity*products.price) as total_revenue,
        rank() over (
            partition by to_char(orders.created_at, 'YYYY-MM') 
            order by sum(order_items.quantity*products.price) desc
        ) as rev_rank
    from orders
    join order_items on order_items.order_id = orders.id
    join products on products.id = order_items.product_id
    join categories on categories.id = products.category_id
    where orders.created_at >= '2023-01-01' and orders.created_at < '2023-07-01'
    group by month, category_name
    order by month
)

select month, category_name, total_revenue
from cte 
where rev_rank = 1;

--Задание 8--

select 
    to_char(payments.payment_date, 'YYYY-MM') as month, 
    sum(payments.amount) as monthly_payments,
    sum(sum(payments.amount)) over (
        order by to_char(payments.payment_date, 'YYYY-MM') rows between unbounded preceding and current row
    ) as cumulative_payments
from orders 
join payments on payments.order_id = orders.id
where payments.payment_date is not null
group by month
order by month