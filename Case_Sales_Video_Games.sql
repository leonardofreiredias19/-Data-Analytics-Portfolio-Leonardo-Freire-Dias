/***************** Project Objectives ****************/

/*

This project analyzes the Video Games Sales as at 22 Dec 2016 dataset using SQL.
The goal is to explore sales performance and critical reception through six analytical objectives — ranking top-selling games, identifying publisher, platform, and genre shares, and finding games with the highest critic scores.
It demonstrates how SQL can be used for descriptive data analysis and insights generation.

1st Objective - Rank the ten best-selling games.
2nd Objective - Identify how much each publisher represents in the sample (in%)
3rd Objective - Identify how much each platform represents in the sample (in%)
4th Objective - Identify how much each genre represents in the sample (in%) 
5th Objective - Identify the top 5 best-selling games with the highest critic scores    
6th Objective - Identify the game with the highest critic score
*/



-- 1st Objective

SELECT * FROM Video_Games_Sales_as_at_22_Dec_2016
ORDER BY global_sales DESC
LIMIT 50;


-- 2nd Objective - Identify how much each publisher represents in the sample (in%) 

With top50 AS (
	SELECT *
	FROM Video_Games_Sales_as_at_22_Dec_2016
	ORDER BY global_sales DESC
	LIMIT 50
 )
 
 SELECT
 	publisher,
    COUNT (*) as Total_games,
    ROUND((COUNT(*) * 100.0/ (SELECT COUNT(*) FROM top50)), 2) as porcentagem
    FROM top50
    GROUP BY publisher
    ORDER BY porcentagem DESC;
    
    
 -- 3rd Objective - Identify how much each platform represents in the sample (in%) 

With top50 AS (
	SELECT *
	FROM Video_Games_Sales_as_at_22_Dec_2016
	ORDER BY global_sales DESC
	LIMIT 50
 )
 
 SELECT
 	platform,
    COUNT (*) as Total_games,
    ROUND((COUNT(*) * 100.0/ (SELECT COUNT(*) FROM top50)), 2) as porcentagem
    FROM top50
    GROUP BY platform
    ORDER BY porcentagem DESC;
 
 
  -- 4th Objective - Identify how much each genre represents in the sample (in%) 

With top50 AS (
	SELECT *
	FROM Video_Games_Sales_as_at_22_Dec_2016
	ORDER BY global_sales DESC
	LIMIT 50
 )
 
 SELECT
 	genre,
    COUNT (*) as Total_games,
    ROUND((COUNT(*) * 100.0/ (SELECT COUNT(*) FROM top50)), 2) as porcentagem
    FROM top50
    GROUP BY genre
    ORDER BY porcentagem DESC;
    
 -- 5th Objective - Identify the game with the highest critic score    


WITH top50 AS (
  SELECT *
  FROM Video_Games_Sales_as_at_22_Dec_2016
  ORDER BY Global_Sales DESC
  LIMIT 50
 )
 
 SELECT *
 FROM top50  
 WHERE Critic_Score = (
   SELECT MAX(Critic_Score)
   FROM top50
   WHERE Critic_Score IS NOT NULL
);
  
  
-- 6th Objective - Identify the game with the highest critic score    
  
WITH top50 AS (
  SELECT *
  FROM Video_Games_Sales_as_at_22_Dec_2016
  ORDER By Global_Sales DESC
  LIMIT 50
 )
 
 SELECT *
 FROM top50 
 WHERE Critic_Score IS NOT NULL
 ORDER BY Critic_Score DESC
 LIMIT 1;
 
