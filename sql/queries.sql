
-- Q1: per-station extreme threshold (95th percentile of summer TMAX, 1991-2020) and extreme days per decade
CREATE OR REPLACE TABLE thr AS
SELECT STATION, quantile_cont(TMAX, 0.95) AS thr FROM clean
WHERE month(DATE) BETWEEN 6 AND 8 AND year(DATE) BETWEEN 1991 AND 2020 GROUP BY 1;

SELECT (yr / 10) * 10 AS decade, AVG(cnt) AS extreme_days_per_year FROM (
  SELECT clean.STATION, year(DATE) AS yr, SUM(TMAX > thr) AS cnt 
  FROM clean JOIN thr USING (STATION) GROUP BY 1, 2
) GROUP BY 1 ORDER BY 1;

-- Q2: fastest-warming stations (slope of extreme days per year)
SELECT STATION, regr_slope(cnt, yr) AS slope FROM (
  SELECT clean.STATION, year(DATE) AS yr, SUM(TMAX > thr) AS cnt 
  FROM clean JOIN thr USING (STATION) GROUP BY 1, 2
) GROUP BY 1 ORDER BY slope DESC LIMIT 10;

-- Q3: features and targets 1-3 days ahead (2020-2024 for modelling)
CREATE OR REPLACE TABLE feat AS
SELECT clean.STATION, DATE, TMAX, TMIN, PRCP, thr, dayofyear(DATE) AS doy,
       LAG(TMAX, 1) OVER w AS tmax_lag1, LAG(TMAX, 2) OVER w AS tmax_lag2, LAG(TMAX, 7) OVER w AS tmax_lag7,
       LAG(TMIN, 1) OVER w AS tmin_lag1, AVG(TMAX) OVER (w ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS tmax_ma7,
       LEAD(TMAX, 1) OVER w AS y_1d, LEAD(TMAX, 2) OVER w AS y_2d, LEAD(TMAX, 3) OVER w AS y_3d
FROM clean JOIN thr USING (STATION) WHERE year(DATE) >= 2020 WINDOW w AS (PARTITION BY clean.STATION ORDER BY DATE);

-- Q4: summary statistics and data check for RQ1
SELECT STATION, COUNT(*) AS total_days, AVG(TMAX) AS mean_tmax FROM clean GROUP BY 1 ORDER BY mean_tmax DESC LIMIT 10;
