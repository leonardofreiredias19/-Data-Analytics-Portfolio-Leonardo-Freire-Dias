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
  goals_scored,
  goals_against,
  ROUND(1.0 * goals_scored / game_played, 2) AS avg_goals_scored,
  ROUND(1.0 * goals_against / game_played, 2) AS avg_goals_against,
  ROUND(100.0 * Wins / game_played, 2) AS win_rate
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
