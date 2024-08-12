--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.


select concat(c.last_name, ' ', c.first_name), a.address, ci.city, ct.country
from customer c
join address a on a.address_id = c.address_id
join city ci on ci.city_id = a.city_id
join country ct on ct.country_id = ci.country_id 


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select st.store_id, count(c.customer_id) as "Количество покупателей"
from store st  
join customer c on c.store_id = st.store_id
group by st.store_id


--Доработайте запрос и выведите только те магазины, у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам с использованием функции агрегации.

select st.store_id, count(c.customer_id) as "Количество покупателей"
from store st 
join customer c on c.store_id = st.store_id
group by st.store_id
having count(c.customer_id) > 300



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя", count(r.rental_id) as "Количество фильмов"
from customer c 
join rental r on r.customer_id = c.customer_id
group by c.customer_id
order by count(rental_id) desc
limit 5


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя", count(r.rental_id) as "Количество фильмов", round(sum(p.amount) as "Общая сумма платежей", 
min(p.amount) as "Минимальное значение платежа", max(p.amount) as "Максимальное значение платежа"
from customer c 
join rental r on r.customer_id = c.customer_id
join payment p on r.customer_id =p.customer_id and p.rental_id = r.rental_id 
group by c.customer_id


--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.

select c.city, ci.city
from city c
cross join city ci
where c.city != ci.city


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.

select r.customer_id as "ID покупателя", round((avg(return_date::date - rental_date::date)), 2) as "Среднее количество дней на возврат"
from rental r
group by r.customer_id
order by r.customer_id 









