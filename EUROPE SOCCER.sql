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
** EUROPE SOCCER PLAYER PERFORMANCE ANALYSIS (2009 - 2016)
** 
** Purpose:
** This SQL Script extracts and aggregates player performance indicators
** from the Europe Soccer Dataset (SQLite), allowing for a detailed view 
** of  individual player contributions to team outcomes across multiple seasons.
*******************************************************************************/


-- =============================================================================
-- STEP 1: BUILD A BASE TABLE OF PLAYER PERFORMANCE FOR SEASON 
-- =============================================================================

WITH player_perf AS(
  SELECT 
  -- League and country context 
  l.name AS League,
  c.name As Country,
  
 -- Team context (each player belongs to a team in a givem match)
  t.team_long_name AS Team,
  
 -- Temporal dimension
  m.season as season,
  
  -- Player identification 
  p.player_name AS Player,
  
  -- ===================================
  -- OFFENSIVE PERFORMANCE METRICS 
  -- ===================================  
  round(CAST(AVG(pa.overall_rating) AS Float), 2) AS AVG_rating,                  -- overall player skills reating
  round(CAST(AVG(pa.finishing) AS Float), 2) AS AVG_finishing,                    -- gols - scoring ability
  round(CAST(AVG(pa.short_passing) AS Float), 2) AS AVG_passing,                  -- build-up play and possession
  round(CAST(AVG(pa.shot_power) AS Float), 2) AS AVG_shot_power,                  -- power of shorts
  round(CAST(AVG(pa.positioning) AS Float), 2) AS AVG_positioning,                -- spatial awareness in attack
  
  -- ====================================
  -- PHYSICAL PERFORMANCE METRICS 
  -- ==================================== 
  
  round(CAST(AVG(pa.stamina) AS Float), 2) AS AVG_stamina,                       -- endurance across matches
  round(CAST(AVG(pa.strength) AS Float), 2) AS AVG_strength,                     -- physical duels and resistance
  
  -- ====================================
  -- DEFENSIVE PERFORMANCE METRICS 
  -- ====================================  
  round(CAST(AVG(pa.interceptions) AS Float), 2) AS AVG_interceptions,           -- ability to read and cut passes
  round(CAST(AVG(pa.marking) AS Float), 2) AS AVG_marking,                       -- defensive discipline
  round(CAST(AVG(pa.standing_tackle) AS Float), 2) AS AVG_standing_tackle,       -- controlled defensive duels
  round(CAST(AVG(pa.sliding_tackle) AS Float), 2) AS AVG_sliding_tackle          -- more aggressive defensive style
  
  
  FROM MATCH m
  JOIN League l ON m.league_id = l.id
  JOIN Country c ON l.country_id = c.id
  JOIN Team t ON t.team_api_id IN (m.home_team_api_id, m.away_team_api_id)
  JOIN Player p ON p.player_api_id IN (
    -- List of home players 
     m.home_player_1, m.home_player_2, m.home_player_3, m.home_player_4, m.home_player_5,
     m.home_player_6, m.home_player_7, m.home_player_8, m.home_player_9, m.home_player_10, m.home_player_11,
     -- List of away players
     m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5,
     m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11
    )
  JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id
  
  -- Group by season, team, and player to create a clear season-by-season view
  GROUP BY l.name, c.name, t.team_long_name, m.season, p.player_name
  )
  
  -- =================================================================
  -- STEP 2: FINAL OUTPUT - PLAYER PERFORMANCE TABLE
  -- =================================================================
  
  SELECT
  	League,
    Country,
    Team,
    season,
    Player,
    AVG_rating,
    AVG_finishing,
 	AVG_passing,                  
    AVG_shot_power,                
  	AVG_positioning,  
    AVG_stamina,                       
  	AVG_strength, 
    AVG_interceptions,           
  	AVG_marking,                       
  	AVG_standing_tackle,       
  	AVG_sliding_tackle
  FROM Player_perf
  ORDER BY League, season, AVG_rating DESC;
  
  
/*******************************************************************************
** FINAL INSIGHTS AND NEXT PHASE
*******************************************************************************/

-- The resulting dataset provides a comprehensive, season-by-season view
-- of player performance across major European leagues between 2009 and 2016.
--
-- It consolidates offensive, physical, and defensive KPIs, allowing analysts
-- to explain team-level outcomes (like goals scored or goals conceded)
-- through individual contributions.
--
-- By connecting this table to the team performance dataset in Power BI,
-- it becomes possible to:
--   ⚽ Identify which players drove offensive success (finishing, shot power)
--   🧤 Understand which teams maintained defensive consistency (marking, tackles)
--   📊 Correlate individual attributes with collective results
--
-- Next Phase:
-- 1️⃣ Export this dataset to CSV format.
-- 2️⃣ Integrate it into Power BI alongside the team-level dataset.
-- 3️⃣ Build visual dashboards connecting player and team metrics to reveal:
--     - The evolution of top-performing players per league/season
--     - How defensive strength impacted goals conceded
--     - How attacking efficiency translated into win rates
-- 4️⃣ Create filters by League, Season, and Team to make the BI dashboard
--     fully interactive and explanatory for all user contexts.
