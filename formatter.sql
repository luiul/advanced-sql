with -- seller CTEs
seller as (
    select
        *,
        sum(value) over(partition by country) as export
    from
        trades t
        join companies c on t.seller = c.name
),
seller_nodups as (
    select
        distinct country,
        export
    from
        seller
),
seller_full as (
    select
        distinct c.country,
        coalesce(b.export, 0) as export
    from
        seller_nodups b
        right outer join companies c on b.country = c.country
),
-- buyer CTEs (copy seller CTEs and adjust)
buyer as (
    select
        *,
        sum(value) over(partition by country) as i
    from
        trades t
        join companies c on t.buyer = c.name
),
buyer_nodups as (
    select
        distinct country,
        i
    from
        buyer
),
buyer_full as (
    select
        distinct c.country,
        coalesce(b.i, 0) as i
    from
        buyer_nodups b
        right outer join companies c on b.country = c.country
)
select
    b.country,
    export,
    i as "import"
from
    seller_full b
    join buyer_full s on b.country = s.country
order by
    b.country;

--- 

with tally as (
    select
        *,
        case
            when opinion = 'recommended' then 1
            else -1
        end as tally
    from
        opinions
),
cume_tally as (
    select
        *,
        sum(tally) over (partition by place) as cume_tally
    from
        tally
)
select
    distinct place
from
    cume_tally
where
    cume_tally > 0;
