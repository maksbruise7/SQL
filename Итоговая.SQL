
-- 1. Выведите название самолетов, которые имеют менее 50 посадочных мест?

select  a.aircraft_code, a.model, count(s.seat_no) 
from aircrafts a 
left join seats s on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code, a.model 
having count(s.seat_no) < 50


-- 2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

with monthly_totals as (
    select  DATE_TRUNC('month', b.book_date) AS month_start,
           SUM(b.total_amount) AS total_amount
    from bookings b
    group by 1
)
select t.month_start, t.total_amount, 
       ROUND(((t.total_amount - LAG(t.total_amount, 1, 0.) over (order by t.month_start)) / 
       LAG(t.total_amount, 1) over (order by t.month_start)) * 100, 2)
from monthly_totals t
order by t.month_start


	
	
-- 3. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.

select a.model
from aircrafts a
left join (
    select s.aircraft_code, array_agg(fare_conditions) AS conditions
    from seats s
    group by s.aircraft_code
) t ON a.aircraft_code = t.aircraft_code
where 'Business' NOT IN (select UNNEST(t.conditions))



-- 4. Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, учитывая только те самолеты, 
--которые летали пустыми и только те дни, где из одного аэропорта таких самолетов вылетало более одного.
 --В результате должны быть код аэропорта, дата, количество пустых мест в самолете и накопительный итог.


select  t.departure_airport, t.actual_departure, t.count, t.sum
from (
    select t.actual_departure, t.departure_airport, t.aircraft_code, s.count,
           count(t.aircraft_code) over (partition by t.actual_departure, t.departure_airport) count_of_boards,
           sum(s.count) OVER (partition by t.actual_departure, t.departure_airport ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sum
    from (
        select date_trunc('day', f.actual_departure) AS actual_departure,
               f.departure_airport,
               f.aircraft_code
        from flights f
        left join boarding_passes bp ON bp.flight_id = f.flight_id
        where bp.boarding_no IS NULL AND (f.status = 'Departed' OR f.status = 'Arrived')
        group by 1, 2, 3
    ) t
    left join (
        select aircraft_code, count(seat_no)
        from seats s 
        group by aircraft_code
    ) s ON s.aircraft_code = t.aircraft_code  
    order by 1, 2
) t 
where count_of_boards > 1


-- 5. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
 --Выведите в результат названия аэропортов и процентное отношение.
 --Решение должно быть через оконную функцию.

	select  t.departure_airport, t.arrival_airport, 
       round((t.count::numeric / t.sum) * 100, 4) AS "share of flights"
from (
    select f.departure_airport, f.arrival_airport, count(*) AS count,
           sum(count(*)) OVER () AS sum
    from flights f
   left join airports a ON a.airport_code = f.departure_airport 
    group by f.departure_airport, f.arrival_airport
    order by f.departure_airport
) t


	
-- 6. Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7


select  phone_substr, COUNT(passenger_id)
from (
    select SUBSTRING(contact_data ->> 'phone' from 3 FOR 3) AS phone_substr, passenger_id
    from tickets
) AS subquery
group by phone_substr
order by phone_substr


-- 7. Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом полученном классе


select  class_amount, COUNT(class_amount)
from (
    select 
        case
            when total_amount < 50000000 then 'low'
            when  total_amount between 50000000 AND 150000000 then 'middle'
            else 'high'
        end AS class_amount
    from  (
        select f.departure_airport, f.arrival_airport, SUM(tf.amount) AS total_amount
        from flights f
        left join ticket_flights tf ON tf.flight_id = f.flight_id
        group by f.departure_airport, f.arrival_airport
    ) AS t
    where total_amount is not null
) AS tf
group by class_amount


-- 8. Вычислите медиану стоимости перелетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости перелетов, округленной до сотых
    
select distinct percentile_cont(0.5) within group (order by tf.amount) as "Медиана стоимости билета", 
				percentile_cont(0.5) within group (order by b.total_amount) as "Медиана стоимости бронирования", 
				round(((percentile_cont(0.5) within group (order by b.total_amount))/(percentile_cont(0.5) within group (order by tf.amount)))::numeric, 2)
from tickets t 
left join ticket_flights tf on tf.ticket_no = t.ticket_no 
left join bookings b on b.book_ref = t.book_ref 



-- 9. Найдите значение минимальной стоимости полета 1 км для пассажиров. 
--То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат.

create extension cube
create extension earthdistance

select  
    t.departure_airport, 
    t.arrival_airport, 
    round((t.min / t.distance), 2) AS "Стоимость 1 км. по маршруту" 
from (
    select t.departure_airport, t.arrival_airport, a.longitude AS dep_lot, a.latitude AS dep_lat, 
    t.min,
        (earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(b.latitude, b.longitude))::int) / 1000 AS distance
    from (
        select f.departure_airport, f.arrival_airport, 
            MIN(tf.amount) AS min
        from flights f 
        left join ticket_flights tf ON tf.flight_id = f.flight_id
        group by 1, 2
    ) t
    left join airports a ON a.airport_code = t.departure_airport
    left join airports b ON b.airport_code = t.arrival_airport
) t
