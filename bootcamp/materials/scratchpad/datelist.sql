INSERT INTO users_cumulated
WITH yesterday AS (
    SELECT
        *
    FROM users_cumulated
    WHERE date = DATE('2023-01-30')
),
    today AS (


        SELECT
            cast(user_id as text) as user_id,
            DATE(CAST(event_time AS TIMESTAMP)) as date_active

        FROM events
        WHere DATE(CAST(event_time AS TIMESTAMP)) = DATE('2023-01-31')
        AND user_id IS NOT NULL
        GROUP BY user_id, DATE(CAST(event_time AS TIMESTAMP))
    )

select
    coalesce(t.user_id, y.user_id) as user_id,
    CASE WHEN y.date_active IS NULL
        THEN ARRAY[t.date_active]
        WHEN t.date_active is null then y.date_active
        ELSE ARRAY[t.date_active] || y.date_active
        END as date_active,
    coalesce(t.date_active, y.date + INTERVAL '1 day') as date
from today t
full outer join yesterday y
on y.user_id = t.user_id;

drop table if exists users_cumulated;
CREATE TABLE users_cumulated(
    user_id text,
    date_active DATE[],
    date DATE,
    PRIMARY KEY (user_id, date)
);

with users as (select *
               from users_cumulated
               where date = DATE('2023-01-31')
               ),
    series as (
        select *
from generate_series(DATE('2023-01-01'), DATE('2023-01-31'), INTERVAL '1 day')
as series_date
    ),

    placeholder_int AS (select CASE
                                   WHEN
                                       date_active @> ARRAY [DATE(series_date)]
                                       THEN CASt(POW(2, 32 - (date - DATE(series_date))) as BIGINT)
                                   ELSE 0
                                   END  as placeholder_int_value,
                               *
                        from users
                                 cross join series
                        where user_id = '743774307695414700')
select
    user_id,
    CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32)),
    BIT_COUNT(CAST(CAST(sum(placeholder_int_value) as BIGINT) as bit(32))) > 0 as dim_is_monthly_active
from placeholder_int
group by user_id;

