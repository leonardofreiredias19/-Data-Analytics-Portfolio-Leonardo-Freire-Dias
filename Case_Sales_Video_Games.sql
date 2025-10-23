/***************** Project Objectives ****************/

/*

This project analyzes the Video Games Sales as at 22 Dec 2016 dataset using SQL.
The goal is to explore sales performance and critical reception through six analytical objectives — ranking top-selling games, identifying publisher, platform, and genre shares, and finding games with the highest critic scores.
It demonstrates how SQL can be used for descriptive data analysis and insights generation.

1st Objective - Rank the fifty best-selling games.
2nd Objective - Identify how much each publisher represents in the sample (in%)
3rd Objective - Identify how much each platform represents in the sample (in%)
4th Objective - Identify how much each genre represents in the sample (in%) 
5th Objective - Identify the top 5 best-selling games with the highest critic scores    
6th Objective - Identify the game with the highest critic score
*/



-- 1st Objective - Rank the fifty best-selling games.

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
    
 -- 5th Objective - Identify the top 5 best-selling games with the highest critic scores     


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
 

/*******************************************************************************
** FINAL ANALYSIS AND INSIGHTS - VIDEO GAMES SALES DATASET
** This commentary summarizes the key findings and market insights from the analysis.
*******************************************************************************/

-- 1. TOP 50 BEST-SELLING GAMES  
-- The dataset was filtered to identify the 50 best-selling video games worldwide.  
-- This ranking provides a solid foundation for understanding the industry's top-performing titles and franchises.

-- 2. PUBLISHER DOMINANCE  
-- The analysis reveals that Nintendo is the undisputed leader among publishers, 
-- accounting for 32 out of the 50 top-selling games — an impressive 64% share.  
-- It is followed by Activision (16%), Take-Two Interactive (12%), Sony Computer Entertainment (4%), 
-- and Microsoft Game Studios (4%).  
-- This result reinforces Nintendo’s long-term dominance and brand power, driven by iconic franchises 
-- such as Mario, Pokémon, and The Legend of Zelda.

-- 3. PLATFORM DISTRIBUTION  
-- When examining platforms, the results show that Nintendo consoles (Wii, DS, 3DS, NES, SNES, N64, GBA) 
-- together represent a large portion of the market, emphasizing the company’s strong ecosystem.  
-- Wii and DS alone account for 36% of the top 50 games, showing their relevance during the 2000s and early 2010s.  
-- PlayStation (PS2, PS3, PS4) holds 22%, while Xbox platforms (X360) represent 14%.  
-- This demonstrates how console generations shaped consumer trends and highlights Nintendo’s exceptional ability 
-- to maintain high-selling titles across multiple generations.

-- 4. GENRE REPRESENTATION  
-- The most represented genres among the top 50 are Shooter (20%), Role-Playing (16%), and Platform (16%), 
-- followed by Action (14%) and Racing (10%).  
-- This indicates a diversified market, where both competitive and narrative-driven experiences perform strongly.  
-- The presence of classic genres like Platform and Role-Playing shows the sustained popularity of traditional 
-- gameplay formats alongside modern action and shooter titles.

-- 5. BEST-SELLING GAMES WITH HIGHEST CRITIC SCORES  
-- “Grand Theft Auto V” dominates this category, appearing multiple times across different platforms (PS3, X360, PS4), 
-- all with a critic score of 97.  
-- This cross-platform success illustrates Take-Two Interactive’s ability to deliver consistent quality and reach 
-- across console generations.  
-- “Super Mario Galaxy” (Wii) also achieved a 97 score, reinforcing Nintendo’s reputation for quality in exclusive titles.  
-- Both cases demonstrate that high sales and critical acclaim can align when innovation meets strong brand identity.

-- 6. HIGHEST CRITIC SCORE OVERALL  
-- The highest critic score in the dataset belongs to “Grand Theft Auto V” (PS3 version) with a score of 97, 
-- confirming its status as one of the most acclaimed games of all time.  
-- This reflects the evolution of the gaming industry, where storytelling, open-world design, and technical excellence 
-- converge to create lasting cultural impact.

-- 7. FINAL INSIGHT  
-- The analysis shows that Nintendo dominates in quantity and heritage, while Take-Two Interactive leads in critical prestige.  
-- This contrast reflects two distinct but successful strategies: one based on iconic franchises and platform exclusivity, 
-- and the other on cinematic innovation and multiplatform expansion.
