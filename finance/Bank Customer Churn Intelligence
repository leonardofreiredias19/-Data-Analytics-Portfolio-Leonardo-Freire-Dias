-- ============================================================
-- PROJECT 3 — Bank Customer Churn Intelligence
-- SQL Script — Analytical Base with LTV Proxy, Churn Type and Return Classification
-- ============================================================
-- INSTRUCTIONS:
-- 1. Use Bank_Customer_Churn_Prediction.csv as source
-- 2. Import in DB Browser as table "Bank Customer Churn Prediction"
-- 3. Run each CTE individually to validate before chaining
-- 4. Expected validation at the end:
--    - Total rows: 10,000
--    - Total churn (churn = 1): 2,037
--    - Churn rate: 20.4%
--    - age_band '46-55': churn rate ~50.6%
--    - products_number = 2: churn rate ~8%
--    - ltv_proxy: all values between 0 and 1
--    - is_ideal = 1: 1,157 clients
--    - churn_type = 'Dormente': 3,547 clients
-- ============================================================


-- ── CTE 1: BASE NORM ─────────────────────────────────────────
-- Goal: select all original columns and normalize the four
-- LTV proxy components to a 0-1 scale using window MAX.
--
-- Why normalize:
--   balance ranges from 0 to ~250,000 while tenure ranges
--   from 0 to 10. Without normalization, balance would dominate
--   the LTV score purely due to magnitude, not analytical weight.
--   Dividing each value by its column MAX puts all four variables
--   on the same scale before applying the weighted formula.
--
-- Why NULLIF(..., 0):
--   Protects against division by zero. If any column MAX were 0
--   (theoretically impossible here but good practice), the
--   division would return NULL instead of a runtime error.
--
-- Why ROUND(..., 6):
--   The LTV proxy is a product of four small decimals.
--   Six decimal places preserves enough precision to distinguish
--   between profiles that would appear identical at 2 decimals.
WITH
base_norm AS (
	SELECT
		customer_id,
		credit_score,
		country,
		gender,
		age,
		tenure,
		balance,
		products_number,
		credit_card,
		active_member,
		estimated_salary,
		churn,

		-- Normalization 0-1 for each LTV component
		ROUND(balance          / NULLIF(MAX(balance)          OVER(), 0), 6) AS bal_norm,
		ROUND(products_number  / NULLIF(MAX(products_number)  OVER(), 0), 6) AS prod_norm,
		ROUND(tenure           / NULLIF(MAX(tenure)           OVER(), 0), 6) AS ten_norm,
		ROUND(estimated_salary / NULLIF(MAX(estimated_salary) OVER(), 0), 6) AS sal_norm

	FROM "Bank Customer Churn Prediction"
),


-- ── CTE 2: BASE LTV ──────────────────────────────────────────
-- Goal: calculate the weighted LTV proxy score and create two
-- derived categorical columns: age_band and churn_type.
--
-- How ltv_proxy works:
--   Weighted sum of the four normalized components.
--   Weights reflect analytical priority:
--     balance (40%)         → main proxy for margin via spread
--     products_number (25%) → proxy for recurring revenue
--     tenure (20%)          → realized relationship time
--     estimated_salary (15%)→ proxy for financial capacity
--   Result is always between 0 (lowest profile) and 1 (highest).
--
-- How age_band works:
--   Buckets age into six ranges for the bar chart axis in Act 1
--   and as a global slicer. The 46-55 and 56-65 bands show the
--   highest churn concentration in the EDA.
--
-- How churn_type works:
--   Inferred segmentation — the source has no churn reason column.
--   Logic follows behavioral signals:
--     Dormente     → still active in base but not using (churn=0, inactive)
--     Voluntario   → long relationship, active, multi-product: chose to leave
--     Comportamental → short relationship, inactive, single product: drifted
--     Sobrecarga   → left with 3+ products: product overload hypothesis
--     Saida Geral  → churned but does not fit the above patterns
--     Ativo        → retained and active
base_ltv AS (
	SELECT
		*,

		-- Weighted LTV proxy score (0 to 1)
		ROUND(
			bal_norm  * 0.40 +
			prod_norm * 0.25 +
			ten_norm  * 0.20 +
			sal_norm  * 0.15
		, 4) AS ltv_proxy,

		-- Age band for visual axis and slicer
		CASE
			WHEN age BETWEEN 18 AND 25 THEN '18-25'
			WHEN age BETWEEN 26 AND 35 THEN '26-35'
			WHEN age BETWEEN 36 AND 45 THEN '36-45'
			WHEN age BETWEEN 46 AND 55 THEN '46-55'
			WHEN age BETWEEN 56 AND 65 THEN '56-65'
			ELSE '65+'
		END AS age_band,

		-- Inferred churn category
		CASE
			WHEN churn = 0 AND active_member = 0
				THEN 'Dormente'
			WHEN churn = 1 AND tenure >= 5
				AND active_member = 1
				AND products_number >= 2
				THEN 'Voluntario'
			WHEN churn = 1 AND tenure <= 2
				AND active_member = 0
				AND products_number <= 1
				THEN 'Comportamental'
			WHEN churn = 1 AND products_number >= 3
				THEN 'Sobrecarga'
			WHEN churn = 1
				THEN 'Saida Geral'
			ELSE 'Ativo'
		END AS churn_type

	FROM base_norm
),


-- ── CTE 3: BASE ESPERADO ─────────────────────────────────────
-- Goal: calculate the expected LTV for each client profile
-- using a window average partitioned by age_band and products_number.
--
-- How ltv_esperado works:
--   AVG(ltv_proxy) OVER (PARTITION BY age_band, products_number)
--   → "for all clients with the same age band AND same number
--      of products, what is the average LTV proxy?"
--   This average becomes the benchmark — the expected return
--   for that profile. Each client is then measured against it.
--
-- Why age_band + products_number as partition:
--   These two variables explain most of the LTV variation in
--   the EDA. A 46-55 client with 2 products has a different
--   expected return than a 26-35 client with 1 product.
--   Combining both creates a meaningful peer group for comparison.
base_esperado AS (
	SELECT
		*,
		ROUND(
			AVG(ltv_proxy) OVER (
				PARTITION BY age_band, products_number
			)
		, 4) AS ltv_esperado
	FROM base_ltv
),


-- ── CTE 4: BASE FINAL ────────────────────────────────────────
-- Goal: calculate the realized/expected LTV ratio, apply the
-- return classification bands, and flag ideal clients.
--
-- How ltv_ratio works:
--   ltv_proxy / ltv_esperado → proportion of expected return realized.
--   A ratio of 1.00 means the client delivered exactly what was
--   expected for their profile. Above 1.00 means they exceeded it.
--   NULLIF protects against division by zero on ltv_esperado.
--
-- How ltv_class works:
--   Translates ltv_ratio into four labeled bands:
--     Superior      (≥ 1.00) → delivered above expected
--     No Minimo     (≥ 0.98) → delivered at minimum threshold
--     Quase o Minimo(≥ 0.95) → slight gap below expected
--     Abaixo do Minimo(< 0.95) → meaningful gap — unrealized potential
--   Used as the conditional formatting key in the Act 2 table.
--
-- How is_ideal works:
--   Flags clients who churned but still delivered the expected
--   return (ltv_ratio >= 0.98). These are the clients the
--   business cannot afford to lose — they have the profile,
--   the balance and the tenure to generate return, yet they left.
base_final AS (
	SELECT
		*,

		-- Proportion LTV realized / expected
		ROUND(
			ltv_proxy / NULLIF(ltv_esperado, 0)
		, 4) AS ltv_ratio,

		-- Return classification band
		CASE
			WHEN ltv_proxy / NULLIF(ltv_esperado, 0) >= 1.00
				THEN 'Superior'
			WHEN ltv_proxy / NULLIF(ltv_esperado, 0) >= 0.98
				THEN 'No Minimo'
			WHEN ltv_proxy / NULLIF(ltv_esperado, 0) >= 0.95
				THEN 'Quase o Minimo'
			ELSE 'Abaixo do Minimo'
		END AS ltv_class,

		-- Ideal client flag
		-- (churned + delivered expected return or above)
		CASE
			WHEN churn = 1
				AND ltv_proxy / NULLIF(ltv_esperado, 0) >= 0.98
			THEN 1 ELSE 0
		END AS is_ideal

	FROM base_esperado
)


-- ── FINAL SELECT ─────────────────────────────────────────────
-- Returns all original columns plus all derived columns.
-- Column order follows analytical logic:
--   identifiers → demographics → financial profile →
--   engagement → outcome → derived dimensions → LTV stack
SELECT
	customer_id,
	credit_score,
	country,
	gender,
	age,
	age_band,
	tenure,
	balance,
	products_number,
	credit_card,
	active_member,
	estimated_salary,
	churn,
	churn_type,
	ltv_proxy,
	ltv_esperado,
	ltv_ratio,
	ltv_class,
	is_ideal
FROM base_final
ORDER BY customer_id;
