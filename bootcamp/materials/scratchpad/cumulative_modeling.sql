

-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'player_seasons';

select  *
from player_seasons;
-- group by player_name
-- order by count desc
-- limit 10;

--=======================MODELING=================
CREATE TYPE season_stats AS (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL
                            );
CREATE TYPE scoring_class AS ENUM('star', 'good', 'average', 'bad');
DROP TABLE IF EXISTS players;
CREATE TABLE players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXt,
    draft_number TEXT,
    season_stats season_stats[],
    scoring_class scoring_class,
    years_since_last_season INTEGER,
    current_season INTEGER,
    PRIMARY KEY(player_name, current_season)

);
--
-- ALTER TABLE players
-- RENAME seasons_stat TO season_stats;
-- select MIN(season), MAX(season)
-- from player_seasons;

INSERT INTO players
WITH yesterday AS (
    SELECT *
    FROM players
    where current_season = 2000
),
    today AS (
         SELECT *
    FROM player_seasons
    where season = 2001

    )

SELECT

COALESCE(t.player_name, y.player_name) as player_name,
COALESCE(t.height, y.height) as height,
COALESCE(t.college, y.college) as college,
COALESCE(t.country, y.country) as country,
COALESCE(t.draft_year, y.draft_year) as draft_year,
COALESCE(t.draft_round, y.draft_round) as draft_round,
COALESCE(t.draft_number, y.draft_number) as dtaft_number,
CASE WHEN y.season_stats IS NULL
THEN ARRAY[ROW(
    t.season,
    t.gp,
    t.pts,
    t.reb,
    t.ast
        ):: season_stats]
WHEN t.season IS NOT NULL
    THEN y.season_stats || ARRAY[
    ROW(
    t.season,
    t.gp,
    t.pts,
    t.reb,
    t.ast
        ):: season_stats]
ELSE y.season_stats
END as season_stats,
CASE
    when t.season is not null then
        case when t.pts > 20 then 'star'
            when t.pts > 15 then 'good'
            when t.pts > 10 then 'average'
            else 'bad'
        end::scoring_class
    else y.scoring_class
    end as scoring_class,
case
    when t.season is not null then 0
    else y.years_since_last_season + 1
    end as years_since_last_season,
COALESCE(t.season, y.current_season + 1) AS current_season
from today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;


--====================================
select player_name,
       (season_stats[1]::season_stats).pts as first_season,
     (season_stats[cardinality(season_stats)]::season_stats ).pts as latest_season
from players
where current_season = 2001;
-- and years_since_last_season != 0;
-- and player_name = 'Michael Jordan'
-- limit 10;


select players.player_name,
       unnest(players.season_stats) as season_stats
from players
where current_season = 2001
and player_name = 'Michael Jordan'

with unnested AS (
    select players.player_name,
       unnest(players.season_stats) as season_stats
from players
where current_season = 2001
and player_name = 'Michael Jordan'
)
select player_name,
       (season_stats::season_stats).*
from unnested

