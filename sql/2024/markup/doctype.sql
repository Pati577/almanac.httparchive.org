-- Temporary function to extract doctype
CREATE TEMPORARY FUNCTION EXTRACT_DOCTYPE(summary STRING) RETURNS STRING AS (
  SAFE_CAST(JSON_EXTRACT(summary, '$.doctype') AS STRING)
);

SELECT
  client,
  LOWER(REGEXP_REPLACE(TRIM(EXTRACT_DOCTYPE(summary)), r' +', ' ')) AS doctype, # remove extra spaces and make lower case
  COUNT(*) AS pages,
  SUM(COUNT(*)) OVER (PARTITION BY client) AS total,
  COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY client) AS pct_pages
FROM
  `httparchive.all.pages`
WHERE
  date = '2024-06-01'
GROUP BY
  client,
  doctype
ORDER BY
  pct_pages DESC
LIMIT
  100;