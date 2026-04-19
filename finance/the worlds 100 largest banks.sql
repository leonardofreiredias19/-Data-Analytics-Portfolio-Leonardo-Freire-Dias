/***************** Project Objectives ****************/

/*
This project analyzes the World’s 100 Largest Banks – April 2023 dataset using SQL.
The goal is to explore the global ranking of banks by total assets (USD billions) and examine their market share by country — including the average assets per bank and the total market share by nation.
It demonstrates how SQL can be used for descriptive data analysis and to generate meaningful financial insights.

1st Objective - Rank the most rich bank of the world.
2nd Objective - Count the number and Percentage of Banks by Country.
3rd Objective - Total Assets (USD Billion) and Global Market Share by Country.
4th Objective - Average Assets Per Bank and Total Market Share by Country. 
*/



-- 1st Objective - Rank the most rich banks of the world.  

SELECT
	*
FROM Largest_Banks;


-- 2nd Objective - Count the number and Percentage of Banks by Country. 

WITH Total_Institutions AS(
  SELECT
  	CAST(COUNT(bank_name) AS REAL) AS Total_Count
  FROM
  	Largest_Banks
  )
  
  SELECT
  	lb.country,
    COUNT(lb.bank_name) As Number_Of_banks,
    -- calculates the percentage of total banks represented by the country
    ROUND((COUNT(lb.bank_name)*100.0/ti.Total_Count), 2) AS Percentage_Of_Total
  
  FROM
	Largest_Banks As lb
  CROSS JOIN
    Total_Institutions AS ti
  GROUP BY
    lb.Country, ti.Total_Count
  ORDER BY
    Percentage_Of_Total DESC;


--3rd Objective - Total Assets (USD Billion) and Global Market Share by Country.

WITH Global_Total_Assets AS (
  SELECT
  	SUM(total_assets_2022_usd_billion) As Global_Assets
  FROM
  	Largest_Banks
)

SELECT
	lb.Country,
    SUM(lb.total_assets_2022_usd_billion) AS Total_Assets_USD_Billion,
    -- Calculates the Market Share: (Country Total Assets / Global Total Assets)* 100
    ROUND((SUM(lb.Total_assets_2022_USD_billion)*100.0 /gta.Global_Assets), 2) AS Market_Share_Percent
 FROM
 	Largest_Banks AS lb
 CROSS JOIN
 	Global_Total_Assets As gta
 GROUP BY
 	lb.Country, gta.Global_Assets
 ORDER BY
 	Total_Assets_USD_Billion DESC;
 
    
 -- 4th Objective - Average Assets Per Bank and Total Market Share by Country. 
 
 WITH Global_Total_Assets AS (
   SELECT
   	  SUM(total_assets_2022_usd_billion) AS Global_Assets
   FROM
   		Largest_Banks
  )
  
  SELECT
  	  lb.Country,
      COUNT(lb.bank_name) AS Number_Of_Banks,
      ROUND(AVG(lb.total_assets_2022_usd_billion),2) AS Average_Assets_Per_Bank,
      -- Reutilize the Market Share for Context
      ROUND((SUM(lb.total_assets_2022_usd_billion) * 100.0 / gta.Global_Assets), 2) As Market_Share_Percent
  FROM
  	  Largest_Banks As lb
  CROSS  JOIN
  	  Global_Total_Assets As gta
  GROUP BY
  	  lb.Country, gta.Global_Assets
  HAVING
      COUNT(lb.Bank_name) > 1 -- Foccus on contries with more tham one bank for relevant average
  ORDER BY
  	  Average_Assets_Per_Bank DESC;
      
      
 /*******************************************************************************
** FINAL ANALYSIS AND INSIGHTS - LARGEST BANKS DATASET
** This commentary summarizes the key findings regarding global financial dominance.
*******************************************************************************/

-- 1. GLOBAL LEADERSHIP AND CHINA'S DOMINANCE
-- The analysis confirms that the largest bank in the world by total assets in 2022 is the
-- Industrial and Commercial Bank of China Limited (ICBC), with $5,742.86 billion in assets.
-- China holds the highest representation in the ranking, with 20 banks, accounting for 20%
-- of the total number of institutions in the global list.

-- 2. MARKET SHARE AND CONCENTRATION
-- China's 20 banks command a significant portion of the total market: their aggregate assets
-- amount to $34,823.85 billion, which corresponds to 31.11% of the total Market Share Percent in this dataset.
-- This metric highlights the immense financial power concentrated in the Chinese banking sector.

-- 3. ASSET SIZE VS. AVERAGE SIZE
-- However, when analyzing the Average Assets per Bank (Query 3), China loses the top position
-- to France, which leads the ranking in this specific category. This suggests that while China has
-- a high volume of assets distributed across 20 mega-banks, France's smaller presence may consist of
-- institutions with an even higher average individual asset base.

-- 4. CONTEXTUAL GROWTH
-- This concentration of size in China is contextualized by the sector's massive growth.
-- The Chinese banking sector experienced a growth rate of nearly 10% year-over-year in 2022,
-- surpassing pre-COVID growth rates (2018 and 2019). 
-- https://www.ey.com/content/dam/ey-unified-site/ey-com/en-cn/newsroom/2023/5/documents/ey-listed-banks-in-china-2022-review-and-outlook-en.pdf
