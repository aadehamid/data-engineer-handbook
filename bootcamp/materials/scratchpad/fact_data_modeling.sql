--=======DETERMINE THE GRAIN===========
WITH dedeuped AS (
    select
           g.game_date_est,
        gd.*,
             ROW_NUMBER() over (PARTITION BY gd.game_id, gd.team_id,
            gd.player_id order by g.game_date_est) as row_num
     from game_details gd
     JOIN games g
     ON g.game_id = gd.game_id
)

select * from dedeuped
where row_num = 1
order by row_num desc;

select
    game_id, team_id, player_id,
    COUNT(1)
    from game_details
group by game_id, team_id, player_id
having count(1) > 1;

--==============SELECTING DIMENSIONS=======================
--=======DETERMINE THE GRAIN===========
DROP TABLE IF EXISTS fct_game_details;
CREATE TABLE fct_game_details (
    dim_game_date DATE,
    dim_season INTEGER,
    dim_team_id INTEGER,
    dim_player_id INTEGER,
    dim_player_name TEXT,
    dim_start_position TEXT,
    dim_is_playing_at_home boolean,
    dim_did_not_play boolean,
    dim_did_not_dress boolean,
    dim_not_with_team boolean,
    m_minutes REAL,
    m_fgm INTEGER,
    m_fga INTEGER,
    m_fg3m INTEGER,
    m_fg3a INTEGER,
    m_ftm INTEGER,
    m_fta INTEGER,
    m_oreb INTEGER,
    m_dreb INTEGER,
    m_reb INTEGER,
    m_ast INTEGER, m_stl INTEGER, m_blk INTEGER, m_turnovers INTEGER,
    m_pf INTEGER,
    m_pts REAL,
    m_plus_minus INTEGER,
    PRIMARY KEY(dim_game_date, dim_player_id, dim_team_id)

);
INSERT INTO fct_game_details (
    dim_game_date,
    dim_season,
    dim_team_id,
    dim_player_id,
    dim_player_name,
    dim_start_position,
    dim_is_playing_at_home,
    dim_did_not_play,
    dim_did_not_dress,
    dim_not_with_team,
    m_minutes,
    m_fgm,
    m_fga,
    m_fg3m,
    m_fg3a,
    m_ftm,
    m_fta,
    m_oreb,
    m_dreb,
    m_reb,
    m_ast,
    m_stl,
    m_blk,
    m_turnovers,
    m_pf,
    m_pts,
    m_plus_minus
)
WITH deduped AS (
    SELECT
           g.game_date_est,
           g.season,
           g.home_team_id,
           gd.*,
           ROW_NUMBER() OVER (PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS row_num
     FROM game_details gd
     JOIN games g ON g.game_id = gd.game_id
)
SELECT
    game_date_est AS dim_game_date,
    season AS dim_season,
    team_id AS dim_team_id,
    player_id AS dim_player_id,
    player_name AS dim_player_name,
    start_position AS dim_start_position,
    (team_id = home_team_id) AS dim_is_playing_at_home,
    (POSITION('DNP' IN COALESCE(comment, '')) > 0) AS dim_did_not_play,
    (POSITION('DND' IN COALESCE(comment, '')) > 0) AS dim_did_not_dress,
    (POSITION('NWT' IN COALESCE(comment, '')) > 0) AS dim_not_with_team,
    CAST(split_part(min, ':', 1) AS NUMERIC) +
    CAST(split_part(min, ':', 2) AS NUMERIC) / 60 AS m_minutes,
    fgm AS m_fgm,
    fga AS m_fga,
    fg3m AS m_fg3m,
    fg3a AS m_fg3a,
    ftm AS m_ftm,
    fta AS m_fta,
    oreb AS m_oreb,
    dreb AS m_dreb,
    reb AS m_reb,
    ast AS m_ast,
    stl AS m_stl,
    blk AS m_blk,
    "TO" AS m_turnovers,
    pf AS m_pf,
    pts AS m_pts,
    plus_minus AS m_plus_minus
FROM deduped
WHERE row_num = 1;

select * from fct_game_details;
select fct_game_details.dim_player_name,
       COUNT(1) as num_games,
       COUNT(CASE WHEN fct_game_details.dim_not_with_team THEN 1 END)
from fct_game_details
group by 1
order by 2 DESC




