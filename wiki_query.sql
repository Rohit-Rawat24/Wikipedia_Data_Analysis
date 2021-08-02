-- Most Views
CREATE EXTERNAL TABLE IF NOT EXISTS data (
	lang STRING,
	page STRING,
	views INT)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ' '
	LOCATION '/tmp/proj';

LOAD DATA INPATH '/tmp/data/' INTO TABLE pageviews;

CREATE TABLE IF NOT EXISTS en_pageviews (
	page STRING,
	views INT) 
	PARTITIONED BY (lang STRING)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY '\t';

INSERT INTO TABLE en_pageviews PARTITION (lang = 'en')
SELECT page, views FROM pageviews WHERE lang = 'en';

CREATE TABLE IF NOT EXISTS total_en_pageviews
AS SELECT DISTINCT(page), SUM(views) OVER (PARTITION BY page ORDER BY page) 
AS total_views FROM en_pageviews 
WHERE page != 'Main_Page' AND page != 'Special:Search' AND page != '-';

SELECT * FROM total_en_pageviews
WHERE total_views > 10000
ORDER BY total_views DESC;


--
CREATE EXTERNAL TABLE IF NOT EXISTS april_pageviews (
	lang STRING,
	page STRING,
	views INT)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ' '
	LOCATION '/tmp/Proj1';

LOAD DATA INPATH '/tmp/files' INTO TABLE april_pageviews;

CREATE TABLE IF NOT EXISTS a_en_pageviews (
	page STRING,
	views INT)
	PARTITIONED BY (lang STRING)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY '\t';

INSERT INTO TABLE a_en_pageviews PARTITION (lang = 'en')
SELECT page, views FROM april_pageviews WHERE (lang = 'en');

INSERT INTO TABLE a_en_pageviews PARTITION (lang = 'en.m')
SELECT page, views FROM april_pageviews WHERE (lang = 'en.m');

SELECT * FROM a_en_pageviews WHERE page = 'Hotel_California';

CREATE TABLE IF NOT EXISTS total_a_pageviews
AS SELECT DISTINCT(page), SUM(views) OVER (PARTITION BY page ORDER BY page)
AS total_views FROM a_en_pageviews 
WHERE page != 'Main_Page' AND page != 'Special:Search' AND page != '-';

CREATE TABLE IF NOT EXISTS q2_views
AS SELECT * FROM total_a_pageviews 
WHERE total_views > 999
ORDER BY total_views DESC;

CREATE EXTERNAL TABLE IF NOT EXISTS april_clickstream (
	prev STRING,
	curr STRING,
	type STRING,
	occ INT)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY '\t'
	LOCATION '/tmp/Proj1';

LOAD DATA INPATH '/tmp/clickstream-enwiki-2021-04.tsv' INTO TABLE april_clickstream;

CREATE TABLE IF NOT EXISTS internal_links (
	prev STRING,
	curr STRING,
	occ INT)
	PARTITIONED BY (type STRING)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY '\t';

INSERT INTO TABLE internal_links PARTITION (type = 'link')
SELECT prev, curr, occ FROM april_clickstream WHERE type = 'link';

SELECT * FROM internal_links WHERE prev = 'Hotel_California';

CREATE TABLE IF NOT EXISTS total_internal
AS SELECT DISTINCT(prev), SUM(occ) OVER (PARTITION BY prev ORDER BY prev)
AS total_links FROM internal_links
WHERE prev != 'Main_Page';

CREATE TABLE IF NOT EXISTS clickstream_final
AS SELECT prev, total_links FROM total_internal ORDER BY total_links DESC;

CREATE TABLE IF NOT EXISTS final_clickstream
AS SELECT prev, ROUND((total_links / 30), 0) AS daily_clickstream
FROM clickstream_final;

CREATE TABLE IF NOT EXISTS join_clickstream
AS SELECT * FROM final_clickstream WHERE daily_clickstream > 199 ORDER BY daily_clickstream DESC;

SELECT c.prev, c.daily_clickstream, v.total_views, ROUND((c.daily_clickstream / v.total_views), 4)
AS fraction FROM join_clickstream c INNER JOIN q2_views v 
ON (c.prev = v.page);