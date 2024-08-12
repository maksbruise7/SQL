--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

explain analyze --1.275
select film_id, title, special_features
from film 
where special_features::text like '%Behind the Scenes%'

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

explain analyze --0.527
select film_id, title, special_features
from film 
where special_features && array['Behind the Scenes']


explain analyze --1.363
select title, array_agg(unnest)
from (
	select title, unnest(special_features), film_id
	from film) t
where unnest = 'Behind the Scenes'
group by film_id, title



--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.


explain analyze --14.708
with cte as (
	select film_id, title, special_features
from film 
where special_features::text like '%Behind the Scenes%'
)
select c.customer_id, count(cte.film_id) as film_count
from customer c
left join rental r on c.customer_id = r.customer_id
left join inventory i on r.inventory_id = i.inventory_id
left join cte on cte.film_id = i.film_id 
group by c.customer_id
order by c.customer_id 



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

explain analyze --13.611
with bts_films AS (
    select film_id, title, special_features
    from film
    where special_features::text LIKE '%Behind the Scenes%'
)
select r.customer_id, COUNT(r.inventory_id) AS film_count
from rental r
join inventory i ON r.inventory_id = i.inventory_id
join bts_films f ON i.film_id = f.film_id
group by r.customer_id
order by r.customer_id



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

explain analyze --15.194
create materialized view customer_bts_films as
with bts_films AS (
    select film_id, title, special_features
    from film
    where special_features::text LIKE '%Behind the Scenes%'
)
select r.customer_id, COUNT(r.inventory_id) as film_count
from rental r
join inventory i ON r.inventory_id = i.inventory_id
join bts_films f ON i.film_id = f.film_id
group by r.customer_id
order by r.customer_id

refresh materialized view customer_bts_films


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.


--1. На основе написанных запросов, логический оператор && затрачивает меньше ресурсов системы, чем другие операторы и функции SQL
--2. По результатам написанных запросов, метод подзапроса затрачивает незначительно меньше ресурсов сиситемы, чем CTE.