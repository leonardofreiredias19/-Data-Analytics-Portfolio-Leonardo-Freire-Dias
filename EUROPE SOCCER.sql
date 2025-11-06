/*******************************************************************************
** EUROPE SOCCER PROJECT - SQL DATA PREPARATION STAGE
** This script represents the first stage of a broader analysis on European football.
** Its purpose is to consolidate match data across leagues and seasons,
** preparing the structured dataset that will be used for a BI dashboard on team performance.
*******************************************************************************/

-- 1. OBJECTIVE  
-- The goal of this script is to create a unified analytical table that combines
-- data from matches, teams, leagues, and countries.  
-- By using JOIN statements and conditional aggregations, it calculates key
-- performance indicators (KPIs) such as total goals, goals conceded, matches played,
-- and win rate for each team by season and league.

-- 2. METHODOLOGY  
-- The analysis starts with JOIN operations connecting the following tables:
--   - Match → provides results and team identifiers;
--   - League → defines the competition (Premier League, La Liga, Serie A, etc.);
--   - Country → links leagues to their respective nations;
--   - Team → provides team names and IDs.  
-- Through conditional SUM and CASE statements, the script differentiates between
-- home and away matches to compute offensive and defensive metrics consistently.

-- 3. OUTPUT STRUCTURE  
-- The resulting dataset contains one record per team, per season, per league, including:
--   • League and Country  
--   • Team Name  
--   • Season  
--   • Games Played  
--   • Goals Scored  
--   • Goals Conceded  
--   • Average Goals Scored per Game  
--   • Average Goals Conceded per Game  
--   • Win Rate (% of matches won)  

-- 4. CONTEXT AND NEXT STEPS  
-- This table forms the foundation for the upcoming BI visualization phase,
-- where I will explore trends in team performance, compare leagues,
-- and analyze goal efficiency and win consistency across Europe.  
-- The insights will be visualized through Power BI, with metrics segmented
-- by season and competition level.

-- 5. TECHNICAL INSIGHT  
-- This stage highlights the importance of relational modeling and SQL joins
-- in transforming raw sports data into a clean analytical dataset.
-- It bridges the gap between data engineering and performance analytics,
-- laying the groundwork for deeper storytelling through data visualization.

/*******************************************************************************
** SQL QUERY
** The query below performs all data transformations described above.
*******************************************************************************/

WITH base AS (
  SELECT
    l.name AS League,
    c.name AS Country,
    t.team_long_name AS Team,
    m.season,
    
    -- Total goals scored by the team (home or away)
    SUM(
      CASE 
        WHEN m.home_team_api_id = t.team_api_id THEN m.home_team_goal
        ELSE m.away_team_goal 
      END
    ) AS goals_scored,
    
    -- Total goals conceded by the team (home or away)
    SUM(
      CASE 
        WHEN m.home_team_api_id = t.team_api_id THEN m.away_team_goal
        ELSE m.home_team_goal 
      END
    ) AS goals_against,
    
    -- Total number of games played
    COUNT(*) AS game_played,
    
    -- Count of wins based on match result and team position (home/away)
    SUM(
      CASE
        WHEN (m.home_team_api_id = t.team_api_id AND m.home_team_goal > m.away_team_goal)
          OR (m.away_team_api_id = t.team_api_id AND m.away_team_goal > m.home_team_goal)
        THEN 1 ELSE 0
      END
    ) AS Wins

  FROM Match m
  JOIN League l ON m.league_id = l.id
  JOIN Country c ON l.country_id = c.id
  JOIN Team t ON t.team_api_id IN (m.home_team_api_id, m.away_team_api_id)
  GROUP BY l.name, c.name, t.team_long_name, m.season
)

SELECT
  League,
  Country,
  Team,
  season,
  game_played,
  Wins,
  goals_scored,
  goals_against,
  ROUND(100.0 * Wins / game_played, 2) AS win_rate,
  ROUND(1.0 * goals_scored / game_played, 2) AS avg_goals_scored,
  ROUND(1.0 * goals_against / game_played, 2) AS avg_goals_against
FROM base
ORDER BY League, season, win_rate DESC;


/*******************************************************************************
** FINAL INSIGHTS AND NEXT PHASE
*******************************************************************************/

-- The resulting dataset delivers a season-by-season snapshot of team performance
-- across Europe’s top leagues.  
-- It allows for comparative analysis of offensive strength, defensive stability,
-- and overall efficiency in terms of win rate.  
-- The next phase will involve integrating this structured dataset into Power BI,
-- where I will build visual dashboards to track trends in goals, wins, and consistency
-- across multiple seasons and competitions.


/*******************************************************************************
** EUROPE SOCCER PROJECT - PLAYER PERFORMANCE DATA PREPARATION
** This script represents the second analytical stage of the project.
** It focuses on consolidating player-level data, determining each player’s 
** primary club per season and computing their average performance metrics.
*******************************************************************************/

-- 1. OBJECTIVE
-- The goal of this script is to build a season-by-season dataset that reflects 
-- each player’s average performance with their primary club.  
-- By linking player attributes with match appearances, the dataset reveals 
-- how individual evolution (skills, stamina, marking, etc.) connects to team outcomes.

-- 2. METHODOLOGY
-- The process follows several key stages:
--   1️⃣ Unpivot all match player columns to create a flat structure of appearances 
--       (one row per player, match, and season).  
--   2️⃣ Count how many times each player appeared for each team per season.  
--   3️⃣ Identify the player’s primary team in each season (the one with most appearances).  
--   4️⃣ Join player attributes (ratings, finishing, stamina, etc.) aggregated by year.  
--   5️⃣ Merge everything into a clean analytical table: one row per player per season.

-- 3. OUTPUT STRUCTURE
-- The final dataset contains:
--   • Player Name  
--   • Primary Team Name  
--   • League and Country  
--   • Season  
--   • Average Ratings (offensive, defensive, and physical KPIs)
-- Each row corresponds to one player’s performance during a given season, 
-- providing a timeline of skill evolution across clubs and competitions.

-- 4. CONTEXT AND NEXT STEPS
-- This table will be used to correlate individual performance with team results 
-- (from the “Team Performance” dataset).  
-- In Power BI, this connection will allow analysis such as:
--   ⚽ Which players most influenced their team’s success?  
--   📉 How defensive consistency reduced goals conceded?  
--   📈 How player transfers impacted team evolution?

-- 5. TECHNICAL INSIGHT
-- This stage demonstrates complex data modeling using CTEs (Common Table Expressions),
-- unpivoting techniques, and grouping logic to extract clean player-season relationships.  
-- It bridges match-level granularity with season-level aggregation, 
-- a crucial step for performance analytics in sports data projects.

/*******************************************************************************
** SQL QUERY
** The query below executes all data transformations described above.
*******************************************************************************/

-- 1) Unpivot player appearances (one row per appearance: player_api_id, team, season)
WITH player_appearances AS (

  -- HOME players (each column expanded into rows)
  SELECT m.season AS season, m.home_player_1 AS player_api_id, m.home_team_api_id AS team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_2, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_3, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_4, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_5, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_6, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_7, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_8, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_9, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_10, m.home_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.home_player_11, m.home_team_api_id FROM Match m

  UNION ALL

  -- AWAY players
  SELECT m.season, m.away_player_1, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_2, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_3, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_4, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_5, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_6, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_7, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_8, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_9, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_10, m.away_team_api_id FROM Match m UNION ALL
  SELECT m.season, m.away_player_11, m.away_team_api_id FROM Match m
),

-- 2) Count appearances per player, per team, per season
player_team_counts AS (
  SELECT
    pa.player_api_id,
    pa.team_api_id,
    pa.season,
    COUNT(*) AS appearances
  FROM player_appearances pa
  WHERE pa.player_api_id IS NOT NULL
    AND pa.team_api_id IS NOT NULL
  GROUP BY pa.player_api_id, pa.team_api_id, pa.season
),

-- 3) For each player-season choose the team with most appearances (primary club)
player_primary_team AS (
  SELECT
    ptc.player_api_id,
    ptc.season,
    ptc.team_api_id,
    ptc.appearances
  FROM player_team_counts ptc
  JOIN (
    SELECT player_api_id, season, MAX(appearances) AS max_apps
    FROM player_team_counts
    GROUP BY player_api_id, season
  ) m
    ON ptc.player_api_id = m.player_api_id
    AND ptc.season = m.season
    AND ptc.appearances = m.max_apps
),

-- 4) Attach player and team context (names, league, and country)
player_primary_team_named AS (
  SELECT
    ppt.player_api_id,
    p.player_name,
    t.team_long_name AS team_name,
    l.name AS league_name,
    c.name AS country_name,
    ppt.season
  FROM player_primary_team ppt
  LEFT JOIN Player p ON p.player_api_id = ppt.player_api_id
  LEFT JOIN Team t ON t.team_api_id = ppt.team_api_id
  LEFT JOIN Match m ON m.season = ppt.season AND (m.home_team_api_id = ppt.team_api_id OR m.away_team_api_id = ppt.team_api_id)
  LEFT JOIN League l ON m.league_id = l.id
  LEFT JOIN Country c ON l.country_id = c.id
  GROUP BY ppt.player_api_id, p.player_name, t.team_long_name, l.name, c.name, ppt.season
),

-- 5) Aggregate player attributes by year
player_attr_by_year AS (
  SELECT
    pa.player_api_id,
    strftime('%Y', pa.date) AS year_attr,
    ROUND(AVG(pa.overall_rating), 2)      AS avg_rating,
    ROUND(AVG(pa.finishing), 2)           AS avg_finishing,
    ROUND(AVG(pa.short_passing), 2)       AS avg_passing,
    ROUND(AVG(pa.shot_power), 2)          AS avg_shot_power,
    ROUND(AVG(pa.positioning), 2)         AS avg_positioning,
    ROUND(AVG(pa.stamina), 2)             AS avg_stamina,
    ROUND(AVG(pa.strength), 2)            AS avg_strength,
    ROUND(AVG(pa.interceptions), 2)       AS avg_interceptions,
    ROUND(AVG(pa.marking), 2)             AS avg_marking,
    ROUND(AVG(pa.standing_tackle), 2)     AS avg_standing_tackle,
    ROUND(AVG(pa.sliding_tackle), 2)      AS avg_sliding_tackle
  FROM Player_Attributes pa
  GROUP BY pa.player_api_id, strftime('%Y', pa.date)
)

-- 6) Final join: primary team per season + attributes for corresponding year
SELECT
  pptn.player_api_id AS player_api_id,
  pptn.player_name  AS player_name,
  pptn.team_name    AS team,
  pptn.league_name  AS league,
  pptn.country_name AS country,
  pptn.season       AS season,
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
  pa.avg_sliding_tackle
FROM player_primary_team_named pptn
LEFT JOIN player_attr_by_year pa
  ON pa.player_api_id = pptn.player_api_id
  AND pa.year_attr = SUBSTR(pptn.season, 1, 4)
ORDER BY pptn.league_name, pptn.season, pa.avg_rating DESC;


/*******************************************************************************
** FINAL INSIGHTS AND NEXT PHASE
*******************************************************************************/

-- The resulting dataset provides a season-by-season view of player performance 
-- in Europe’s top leagues from 2009 to 2016.  
-- It allows analysts to understand how individual metrics evolved and 
-- to connect them with team performance results.  
-- In the next stage, this dataset will be imported into Power BI to visualize:
--   • Top-performing players per league and season  
--   • Evolution of player skill ratings and physical attributes  
--   • Correlations between player averages and team success metrics  
-- This step bridges micro (player) and macro (team) perspectives, completing
-- the analytical foundation of the European Soccer project.
