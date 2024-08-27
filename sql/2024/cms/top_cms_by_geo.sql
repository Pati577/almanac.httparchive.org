#standardSQL
# CMS popularity per geo
WITH geo_summary AS (
  SELECT
    `chrome-ux-report`.experimental.GET_COUNTRY(country_code) AS geo,
    IF(device = 'desktop', 'desktop', 'mobile') AS client,
    origin,
    COUNT(DISTINCT origin) OVER (PARTITION BY country_code, IF(device = 'desktop', 'desktop', 'mobile')) AS total
  FROM
    `chrome-ux-report.materialized.country_summary`
  WHERE
    yyyymm = 202406
  UNION ALL
  SELECT
    'ALL' AS geo,
    IF(device = 'desktop', 'desktop', 'mobile') AS client,
    origin,
    COUNT(DISTINCT origin) OVER (PARTITION BY IF(device = 'desktop', 'desktop', 'mobile')) AS total
  FROM
    `chrome-ux-report.materialized.device_summary`
  WHERE
    yyyymm = 202406
)

SELECT
  *
FROM (
  SELECT
    client,
    geo,
    cms,
    COUNT(0) AS pages,
    ANY_VALUE(total) AS total,
    COUNT(DISTINCT url) / ANY_VALUE(total) AS pct
  FROM (
    SELECT DISTINCT
      geo,
      client,
      CONCAT(origin, '/') AS url,
      total
    FROM
      geo_summary
  ) JOIN (
    SELECT DISTINCT
      client,
      cats,
      technologies.technology AS cms,
      page as url
    FROM
      `httparchive.all.pages`,
      UNNEST (technologies) AS technologies,
      UNNEST(technologies.categories) AS cats 
    WHERE
      technologies.technology IS NOT NULL AND
      cats = 'CMS' AND
      technologies.technology != '' AND
      date = '2024-06-01'
  ) USING (client, url)
  GROUP BY
    client,
    geo,
    cms)
WHERE
  pages > 1000
ORDER BY
  pages DESC
