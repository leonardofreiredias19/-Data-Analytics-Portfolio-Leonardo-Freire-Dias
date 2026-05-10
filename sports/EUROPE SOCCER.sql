/*******************************************************************************
** EUROPE SOCCER PROJECT — COMPLETE DATA PREPARATION SCRIPT
** Version: 2.0 | Includes data quality flags and proxy imputations
**
** This script contains two analytical stages:
**   STAGE 1 → Team Performance KPIs (League, Season, Win Rate, Goals)
**   STAGE 2 → Player Performance KPIs (Attributes with proxy imputations)
**
** Proxy logic for missing player attributes:
**   Proxy 1 — Season missing but player has history → player's own historical avg
**   Proxy 2 — Player has no history at all (369 players) → league + season avg
**   Proxy 3 — avg_sliding_tackle missing, others exist (572 rows) → avg of 3 defensive attrs
**
** Data quality flag (data_quality column):
**   'complete'          → original data, no imputation applied
**   'proxy_history'     → Proxy 1 applied (player historical average)
**   'proxy_league_avg'  → Proxy 2 applied (league + season average)
**   'proxy_defensive'   → Proxy 3 applied to sliding_tackle only
*******************************************************************************/


/*****************************************************************************
** STAGE 1 — TEAM PERFORMANCE
** Produces: one row per team per season with goals and win rate KPIs
******************************************************************************/

-- 1. OBJECTIVE
-- Create a unified analytical table combining Match, Team, League and Country.
-- Calculates goals scored, goals conceded, games played and win rate
-- for each team by season and league.

-- 2. METHODOLOGY
-- JOIN operations connect Match → League → Country → Team.
-- Conditional SUM + CASE differentiates home vs away context for each metric.

-- 3. OUTPUT STRUCTURE
-- League | Country | Team | Season | Games Played | Wins |
-- Goals Scored | Goals Against | Win Rate | Avg Goals Scored | Avg Goals Against

WITH base AS (
    SELECT
        l.name                  AS League,
        c.name                  AS Country,
        t.team_long_name        AS Team,
        m.season,

        -- Goals scored (home or away context)
        SUM(
            CASE
                WHEN m.home_team_api_id = t.team_api_id THEN m.home_team_goal
                ELSE m.away_team_goal
            END
        ) AS goals_scored,

        -- Goals conceded (home or away context)
        SUM(
            CASE
                WHEN m.home_team_api_id = t.team_api_id THEN m.away_team_goal
                ELSE m.home_team_goal
            END
        ) AS goals_against,

        COUNT(*) AS game_played,

        -- Wins: conditional count based on team position
        SUM(
            CASE
                WHEN (m.home_team_api_id = t.team_api_id AND m.home_team_goal > m.away_team_goal)
                  OR (m.away_team_api_id = t.team_api_id AND m.away_team_goal > m.home_team_goal)
                THEN 1 ELSE 0
            END
        ) AS Wins,

        -- Draws: goals equal for both teams
        SUM(
            CASE
                WHEN m.home_team_goal = m.away_team_goal
                THEN 1 ELSE 0
            END
        ) AS Draws

    FROM Match m
    JOIN League l  ON m.league_id       = l.id
    JOIN Country c ON l.country_id      = c.id
    JOIN Team t    ON t.team_api_id IN (m.home_team_api_id, m.away_team_api_id)
    GROUP BY l.name, c.name, t.team_long_name, m.season
)

SELECT
    League,
    Country,
    Team,
    season,
    game_played,
    Wins,
    Draws,
    (game_played - Wins - Draws)                                    AS Losses,
    goals_scored,
    goals_against,
    (Wins * 3) + Draws                                              AS points,
    ROUND(100.0 * ((Wins * 3) + Draws) / (game_played * 3), 2)     AS aproveitamento,
    ROUND(100.0 * Wins / game_played, 2)                            AS win_rate,
    ROUND(1.0 * goals_scored / game_played, 2)                      AS avg_goals_scored,
    ROUND(1.0 * goals_against / game_played, 2)                     AS avg_goals_against
FROM base
ORDER BY League, season, aproveitamento DESC;


/*******************************************************************************
** FINAL INSIGHTS — STAGE 1
** The dataset delivers a season-by-season snapshot of team performance
** across Europe's top leagues, enabling comparison of offensive strength,
** defensive stability and win consistency.
** Next phase: Power BI dashboard with filters by league, team and season.
*******************************************************************************/


/*****************************************************************************
** STAGE 2 — PLAYER PERFORMANCE (WITH PROXY IMPUTATIONS + DATA QUALITY FLAG)
** Produces: one row per player per season with averaged skill attributes
******************************************************************************/

-- 1. OBJECTIVE
-- Build a season-by-season dataset reflecting each player's average performance
-- with their primary club, including imputed values for missing attributes.

-- 2. METHODOLOGY
-- Step 1 → Unpivot all 22 player columns per match into flat appearance rows
-- Step 2 → Count appearances per player per team per season
-- Step 3 → Identify primary team (most appearances)
-- Step 4 → Aggregate player attributes by year
-- Step 5 → Build player history avg (Proxy 1 source)
-- Step 6 → Build league + season avg (Proxy 2 source)
-- Step 7 → Join everything
-- Step 8 → Apply COALESCE proxies + assign data_quality flag

-- 3. DATA QUALITY FLAG
-- 'complete'         → all attributes present, no imputation
-- 'proxy_history'    → missing season filled with player's own historical avg
-- 'proxy_league_avg' → player has no history, filled with league + season avg
-- 'proxy_defensive'  → sliding_tackle filled with avg of 3 defensive attributes

WITH

-- ── STEP 1: Unpivot player appearances ───────────────────────────────────────
player_appearances AS (
    SELECT m.season, m.home_player_1  AS player_api_id, m.home_team_api_id AS team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_2,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_3,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_4,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_5,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_6,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_7,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_8,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_9,  m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_10, m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.home_player_11, m.home_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_1,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_2,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_3,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_4,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_5,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_6,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_7,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_8,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_9,  m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_10, m.away_team_api_id FROM Match m UNION ALL
    SELECT m.season, m.away_player_11, m.away_team_api_id FROM Match m
),

-- ── STEP 2: Count appearances per player per team per season ─────────────────
player_team_counts AS (
    SELECT
        player_api_id,
        season,
        team_api_id,
        COUNT(*) AS appearances
    FROM player_appearances
    WHERE player_api_id IS NOT NULL
      AND team_api_id   IS NOT NULL
    GROUP BY player_api_id, season, team_api_id
),

-- ── STEP 3: Primary team — most appearances per player per season ─────────────
player_primary_team AS (
    SELECT ptc.player_api_id, ptc.season, ptc.team_api_id
    FROM player_team_counts ptc
    JOIN (
        SELECT player_api_id, season, MAX(appearances) AS max_app
        FROM player_team_counts
        GROUP BY player_api_id, season
    ) mx ON ptc.player_api_id = mx.player_api_id
         AND ptc.season        = mx.season
         AND ptc.appearances   = mx.max_app
),

-- ── STEP 4: Raw player attributes aggregated by year ─────────────────────────
player_attrs_raw AS (
    SELECT
        pa.player_api_id,
        SUBSTR(pa.date, 1, 4)              AS year_attr,
        ROUND(AVG(pa.overall_rating),  2)  AS avg_rating,
        ROUND(AVG(pa.finishing),       2)  AS avg_finishing,
        ROUND(AVG(pa.short_passing),   2)  AS avg_passing,
        ROUND(AVG(pa.shot_power),      2)  AS avg_shot_power,
        ROUND(AVG(pa.positioning),     2)  AS avg_positioning,
        ROUND(AVG(pa.stamina),         2)  AS avg_stamina,
        ROUND(AVG(pa.strength),        2)  AS avg_strength,
        ROUND(AVG(pa.interceptions),   2)  AS avg_interceptions,
        ROUND(AVG(pa.marking),         2)  AS avg_marking,
        ROUND(AVG(pa.standing_tackle), 2)  AS avg_standing_tackle,
        ROUND(AVG(pa.sliding_tackle),  2)  AS avg_sliding_tackle
    FROM Player_Attributes pa
    GROUP BY pa.player_api_id, SUBSTR(pa.date, 1, 4)
),

-- ── STEP 5: Player historical average — Proxy 1 source ───────────────────────
player_history_avg AS (
    SELECT
        player_api_id,
        ROUND(AVG(avg_rating),          2) AS hist_rating,
        ROUND(AVG(avg_finishing),       2) AS hist_finishing,
        ROUND(AVG(avg_passing),         2) AS hist_passing,
        ROUND(AVG(avg_shot_power),      2) AS hist_shot_power,
        ROUND(AVG(avg_positioning),     2) AS hist_positioning,
        ROUND(AVG(avg_stamina),         2) AS hist_stamina,
        ROUND(AVG(avg_strength),        2) AS hist_strength,
        ROUND(AVG(avg_interceptions),   2) AS hist_interceptions,
        ROUND(AVG(avg_marking),         2) AS hist_marking,
        ROUND(AVG(avg_standing_tackle), 2) AS hist_standing_tackle,
        ROUND(AVG(avg_sliding_tackle),  2) AS hist_sliding_tackle
    FROM player_attrs_raw
    GROUP BY player_api_id
),

-- ── STEP 6: League + season average — Proxy 2 source ─────────────────────────
league_season_avg AS (
    SELECT
        l.name                              AS league_name,
        SUBSTR(m2.season, 1, 4)             AS year_attr,
        ROUND(AVG(pa2.overall_rating),  2)  AS league_avg_rating,
        ROUND(AVG(pa2.finishing),       2)  AS league_avg_finishing,
        ROUND(AVG(pa2.short_passing),   2)  AS league_avg_passing,
        ROUND(AVG(pa2.shot_power),      2)  AS league_avg_shot_power,
        ROUND(AVG(pa2.positioning),     2)  AS league_avg_positioning,
        ROUND(AVG(pa2.stamina),         2)  AS league_avg_stamina,
        ROUND(AVG(pa2.strength),        2)  AS league_avg_strength,
        ROUND(AVG(pa2.interceptions),   2)  AS league_avg_interceptions,
        ROUND(AVG(pa2.marking),         2)  AS league_avg_marking,
        ROUND(AVG(pa2.standing_tackle), 2)  AS league_avg_standing_tackle,
        ROUND(AVG(pa2.sliding_tackle),  2)  AS league_avg_sliding_tackle
    FROM Match m2
    JOIN League l ON m2.league_id = l.id
    JOIN player_appearances pa_app
        ON pa_app.season = m2.season
       AND (pa_app.team_api_id = m2.home_team_api_id
            OR pa_app.team_api_id = m2.away_team_api_id)
    JOIN Player_Attributes pa2
        ON pa2.player_api_id = pa_app.player_api_id
       AND SUBSTR(pa2.date, 1, 4) = SUBSTR(m2.season, 1, 4)
    GROUP BY l.name, SUBSTR(m2.season, 1, 4)
),

-- ── STEP 7: Join everything ───────────────────────────────────────────────────
player_team_name AS (
    SELECT
        p.player_api_id,
        p.player_name,
        t.team_long_name    AS team,
        l.name              AS league_name,
        c.name              AS country,
        ppt.season,
        pa.avg_rating,
        pa.avg_finishing,
        pa.avg_passing,
        pa.avg_shot_power,
        pa.avg_positioning,
        pa.avg_stamina,
        pa.avg_strength,
        pa.avg_interceptions,
        pa.avg_marking,
        pa.avg_standing_tackle,
        pa.avg_sliding_tackle,
        pha.hist_rating,
        pha.hist_finishing,
        pha.hist_passing,
        pha.hist_shot_power,
        pha.hist_positioning,
        pha.hist_stamina,
        pha.hist_strength,
        pha.hist_interceptions,
        pha.hist_marking,
        pha.hist_standing_tackle,
        pha.hist_sliding_tackle,
        lsa.league_avg_rating,
        lsa.league_avg_finishing,
        lsa.league_avg_passing,
        lsa.league_avg_shot_power,
        lsa.league_avg_positioning,
        lsa.league_avg_stamina,
        lsa.league_avg_strength,
        lsa.league_avg_interceptions,
        lsa.league_avg_marking,
        lsa.league_avg_standing_tackle,
        lsa.league_avg_sliding_tackle
    FROM player_primary_team ppt
    JOIN Player p       ON p.player_api_id  = ppt.player_api_id
    JOIN Team t         ON t.team_api_id    = ppt.team_api_id
    JOIN Match m        ON m.season         = ppt.season
                       AND (m.home_team_api_id = ppt.team_api_id
                            OR m.away_team_api_id = ppt.team_api_id)
    JOIN League l       ON m.league_id      = l.id
    JOIN Country c      ON l.country_id     = c.id
    LEFT JOIN player_attrs_raw pa
                        ON pa.player_api_id = ppt.player_api_id
                       AND pa.year_attr     = SUBSTR(ppt.season, 1, 4)
    LEFT JOIN player_history_avg pha
                        ON pha.player_api_id = ppt.player_api_id
    LEFT JOIN league_season_avg lsa
                        ON lsa.league_name  = l.name
                       AND lsa.year_attr    = SUBSTR(ppt.season, 1, 4)
    GROUP BY p.player_api_id, ppt.season
)

-- ── STEP 8: Final select — apply proxies + assign data_quality flag ───────────
SELECT
    player_api_id,
    player_name,
    team,
    league_name                                                                     AS league,
    country,
    season,

    -- Attributes with proxy fallback (Proxy 1 → Proxy 2)
    ROUND(COALESCE(avg_rating,          hist_rating,          league_avg_rating),          2) AS avg_rating,
    ROUND(COALESCE(avg_finishing,       hist_finishing,       league_avg_finishing),       2) AS avg_finishing,
    ROUND(COALESCE(avg_passing,         hist_passing,         league_avg_passing),         2) AS avg_passing,
    ROUND(COALESCE(avg_shot_power,      hist_shot_power,      league_avg_shot_power),      2) AS avg_shot_power,
    ROUND(COALESCE(avg_positioning,     hist_positioning,     league_avg_positioning),     2) AS avg_positioning,
    ROUND(COALESCE(avg_stamina,         hist_stamina,         league_avg_stamina),         2) AS avg_stamina,
    ROUND(COALESCE(avg_strength,        hist_strength,        league_avg_strength),        2) AS avg_strength,
    ROUND(COALESCE(avg_interceptions,   hist_interceptions,   league_avg_interceptions),   2) AS avg_interceptions,
    ROUND(COALESCE(avg_marking,         hist_marking,         league_avg_marking),         2) AS avg_marking,
    ROUND(COALESCE(avg_standing_tackle, hist_standing_tackle, league_avg_standing_tackle), 2) AS avg_standing_tackle,

    -- Proxy 3 for sliding_tackle: defensive attrs avg as last fallback
    ROUND(COALESCE(
        avg_sliding_tackle,
        hist_sliding_tackle,
        league_avg_sliding_tackle,
        (COALESCE(avg_interceptions,   hist_interceptions,   league_avg_interceptions) +
         COALESCE(avg_marking,         hist_marking,         league_avg_marking) +
         COALESCE(avg_standing_tackle, hist_standing_tackle, league_avg_standing_tackle)) / 3.0
    ), 2) AS avg_sliding_tackle,

    -- ── DATA QUALITY FLAG ────────────────────────────────────────────────────
    -- Identifies which proxy was applied so you can filter or flag in Power BI
    CASE
        WHEN avg_rating IS NOT NULL AND avg_sliding_tackle IS NOT NULL
            THEN 'complete'
        WHEN avg_rating IS NOT NULL AND avg_sliding_tackle IS NULL
            THEN 'proxy_defensive'
        WHEN avg_rating IS NULL AND hist_rating IS NOT NULL
            THEN 'proxy_history'
        ELSE
            'proxy_league_avg'
    END AS data_quality

FROM player_team_name
ORDER BY league_name, season, avg_rating DESC;


/*******************************************************************************
** FINAL INSIGHTS — STAGE 2
** The dataset provides a season-by-season view of player performance
** across Europe's top leagues from 2009 to 2016.
** The data_quality column allows Power BI to signal imputed records,
** giving analysts full transparency over data reliability.
** Next phase: Power BI Player Deep Dive dashboard — radar chart,
** rating evolution and top players ranking per league and season.
*******************************************************************************/
