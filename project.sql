SET search_path TO group12;
SET ROLE group12;

DROP TABLE if exists electric_vehicles;
DROP TABLE if exists district_elections CASCADE;
DROP TABLE if exists district_politics CASCADE;
DROP TABLE if exists details_location CASCADE;
DROP TABLE if exists vehicle_details CASCADE;
DROP TABLE if exists vehicle_location CASCADE;


-- Initial Schemas (CREATE TABLE ...)

CREATE TABLE electric_vehicles (
    "VIN (1-10)" TEXT,
    "County" TEXT,
    "City" TEXT,
    "State" TEXT,
    "Postal Code" INT,
    "Model Year" INT,
    "Make" TEXT,
    "Model" TEXT,
    "Electric Vehicle Type" TEXT,
    "Clean Alternative Fuel Vehicle (CAFV) Eligibility" TEXT,
    "Electric Range" INT,
    "Legislative District" INT,
    "DOL Vehicle ID" BIGINT,
    "Vehicle Location" TEXT,
    "Electric Utility" TEXT,
    "2020 Census Tract" BIGINT
);
\copy electric_vehicles FROM 'data/Electric Vehicle Data.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);

--Data cleaning
UPDATE electric_vehicles
SET "Make" = NULL WHERE TRIM("Make") = '';

UPDATE electric_vehicles
SET "Model Year" = CAST(NULLIF(TRIM("Model Year"::TEXT), '') AS INTEGER)
WHERE "Model Year"::TEXT ~ '^[0-9]+$';

UPDATE electric_vehicles
SET "Electric Range" = CAST(NULLIF(TRIM("Electric Range"::TEXT), '') AS INTEGER)
WHERE "Electric Range"::TEXT ~ '^[0-9]+$';

DELETE FROM electric_vehicles
WHERE "Electric Range" = 0;

--Normalizing into BCNF

CREATE TABLE vehicle_details (
    "VIN (1-10)" TEXT NOT NULL,
    "Model" TEXT NOT NULL,
    "Model Year" INT NOT NULL,
    "Make" TEXT NOT NULL,
    "Electric Vehicle Type" TEXT,
    "Electric Range" INT
);

CREATE TABLE vehicle_location (
    "DOL Vehicle ID" TEXT NOT NULL,
    "County" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "State" TEXT NOT NULL,
    "Postal Code" TEXT NOT NULL,
    "2020 Census Tract" TEXT,
    "Legislative District" INT NOT NULL,
    "Clean Alternative Fuel Vehicle (CAFV) Eligibility" TEXT,
    "Vehicle Location" TEXT,
    "Electric Utility" TEXT
);


CREATE TABLE details_location (
    "VIN (1-10)" TEXT,
    "DOL Vehicle ID" TEXT
);

ALTER TABLE vehicle_location ALTER COLUMN "County" DROP NOT NULL;
ALTER TABLE vehicle_location ALTER COLUMN "City" DROP NOT NULL;
ALTER TABLE vehicle_location ALTER COLUMN "Postal Code" DROP NOT NULL;

INSERT INTO vehicle_details
SELECT DISTINCT "VIN (1-10)", "Model", "Model Year", "Make", "Electric Vehicle Type", "Electric Range"
FROM electric_vehicles
WHERE "VIN (1-10)" IS NOT NULL;

INSERT INTO vehicle_location ("DOL Vehicle ID", "County", "City", "State", "Postal Code", "2020 Census Tract", "Legislative District", "Vehicle Location", "Electric Utility")
SELECT DISTINCT "DOL Vehicle ID", "County", "City", "State", "Postal Code", "2020 Census Tract", "Legislative District", "Vehicle Location", "Electric Utility"
FROM electric_vehicles
WHERE "DOL Vehicle ID" IS NOT NULL AND "Legislative District" IS NOT NULL;


INSERT INTO details_location ("VIN (1-10)", "DOL Vehicle ID")
SELECT DISTINCT "VIN (1-10)", "DOL Vehicle ID"
FROM electric_vehicles
WHERE "VIN (1-10)" IS NOT NULL AND "DOL Vehicle ID" IS NOT NULL AND "Legislative District" IS NOT NULL;

DELETE FROM details_location
WHERE "DOL Vehicle ID" NOT IN (SELECT "DOL Vehicle ID" FROM vehicle_location);


-- Keys and constraints

ALTER TABLE vehicle_details ADD CONSTRAINT pk_vehicle_details PRIMARY KEY ("VIN (1-10)");
ALTER TABLE vehicle_location ADD CONSTRAINT pk_vehicle_location PRIMARY KEY ("DOL Vehicle ID");
ALTER TABLE details_location ADD CONSTRAINT pk_details_location PRIMARY KEY ("VIN (1-10)", "DOL Vehicle ID");

ALTER TABLE details_location ADD CONSTRAINT fk_details_location_vin FOREIGN KEY ("VIN (1-10)") REFERENCES vehicle_details("VIN (1-10)") ON DELETE CASCADE;
ALTER TABLE details_location ADD CONSTRAINT fk_details_location_dol FOREIGN KEY ("DOL Vehicle ID") REFERENCES vehicle_location("DOL Vehicle ID") ON DELETE CASCADE;

ALTER TABLE vehicle_details ADD CONSTRAINT chk_model_year CHECK ("Model Year" >= 1900 AND "Model Year" <= EXTRACT(YEAR FROM CURRENT_DATE));
ALTER TABLE vehicle_details ADD CONSTRAINT chk_electric_range CHECK ("Electric Range" >= 0);

--District elections
CREATE TABLE district_elections (
    District TEXT,
    Candidate TEXT,
    Party TEXT,
    Total_Votes INT,
    Won TEXT
);

\copy district_elections FROM 'data/house_candidate.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);

CREATE TABLE district_politics (
    District TEXT,
    Party Text,
    Total_Votes INT
);

INSERT INTO district_politics 
SELECT district, party, total_votes FROM district_elections WHERE won LIKE 'True';

--Term-116 data (I'm not sure if this data is useful)
DROP TABLE IF EXISTS term_data;
CREATE TABLE term_data (
    "id" TEXT,
    "name" TEXT,
    "sort_name" TEXT,
    "email" TEXT,
    "twitter" TEXT,
    "facebook" TEXT,
    "group" TEXT,
    "group_id" TEXT,
    "area_id" TEXT,
    "area" TEXT,
    "chamber" TEXT,
    "term" TEXT,
    "start_date" TEXT,
    "end_date" TEXT,
    "image" TEXT,
    "gender" TEXT,
    "wikidata" TEXT,
    "wikidata_group" TEXT,
    "wikidata_area" TEXT
);
\copy term_data FROM 'data/term-116.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);

DROP TABLE IF EXISTS district_data;
CREATE TABLE district_data(
    "group_id" TEXT,
    "State" TEXT,
    "Legislative District" INTEGER
);
INSERT INTO district_data (group_id, "State", "Legislative District")
SELECT
    group_id,
    SUBSTR(area_id, 1, 2),
    CAST(SUBSTR(area_id, 4) AS INTEGER)
FROM term_data;


--Legislative district information Washington
DROP TABLE IF EXISTS uncleaned_legislative_data;
CREATE TABLE uncleaned_legislative_data(
    "Race" TEXT,
    "Candidate" TEXT,
    "Party" TEXT,
    "Votes" INTEGER,
    "PercentageOfTotalVotes" NUMERIC,
    "JurisdictionName" TEXT
);
\copy uncleaned_legislative_data FROM 'data/20201103_legislative.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);


UPDATE uncleaned_legislative_data
SET "Party" = 'Republican'
WHERE "Party" LIKE '%Republican%' OR "Party" LIKE '%GOP%';

UPDATE uncleaned_legislative_data
SET "Party" = 'Democrat'
WHERE "Party" LIKE '%Democrat%';

DROP TABLE IF EXISTS legislative_data;
CREATE TABLE legislative_data(
    district INTEGER NOT NULL,
    party TEXT NOT NULL,
    total_votes INTEGER NOT NULL
);
INSERT INTO legislative_data (district, party, total_votes)
WITH RankedResults AS (
    SELECT
        CAST(SUBSTR("Race", 22, 2) AS INTEGER) AS district,
        "Party",
        "Votes" / ("PercentageOfTotalVotes" / 100) AS total_votes,
        ROW_NUMBER() OVER (PARTITION BY CAST(SUBSTR("Race", 22, 2) AS INTEGER) ORDER BY "Votes" DESC) AS Rank
    FROM uncleaned_legislative_data
    WHERE "Race" LIKE '%State Representative Pos. 1%' OR "Race" LIKE '%Representative, Position 1%'
)
SELECT
    district,
    "Party",
    total_votes
FROM RankedResults
WHERE Rank = 1 ORDER BY district;



--Interesting queries(Aidan)
SELECT DISTINCT "Make", "Model", AVG("Electric Range") as "Avg_Range"
FROM vehicle_details
GROUP BY "Make", "Model"
ORDER BY "Make", "Model";

--Query2
SELECT COUNT(*) AS vehicles_registered, "Make", "Model"
FROM vehicle_details
GROUP BY "Make", "Model"
ORDER BY vehicles_registered DESC;

--Query 3
SELECT COUNT(*) AS vehicles_registered, "Make"
FROM vehicle_details
GROUP BY "Make"
ORDER BY vehicles_registered DESC;

--Query 4
SELECT party, COUNT(*)
FROM legislative_data JOIN vehicle_location ON legislative_data.district = vehicle_location."Legislative District"
GROUP BY party;  

--Query 5
WITH vehicles_registered AS(
    SELECT "Make", "Legislative District"
    FROM ((vehicle_details JOIN details_location ON vehicle_details."VIN (1-10)"=details_location."VIN (1-10)") 
    JOIN vehicle_location ON details_location."DOL Vehicle ID"=vehicle_location."DOL Vehicle ID")
)
SELECT "Make", COUNT(*), party
FROM legislative_data JOIN vehicles_registered ON legislative_data.district = vehicles_registered."Legislative District"
GROUP BY "Make",party ORDER BY "Make", count DESC;


--Everything below this point was part of Chris's original assignment.
--We can use some of it so I don't want to delete it, but I am commenting it out for organizational purposes
/*
-- (Q7) Interesting Queries (SELECT ...)

-- Query 1: Find the top 5 most common electric vehicle models
SELECT "Model", COUNT(*) AS "Total Count"
FROM vehicle_details
GROUP BY "Model"
ORDER BY "Total Count" DESC
LIMIT 5;

-- Query 2: Find the average electric range per state for vehicles with a valid electric range
SELECT "State", AVG("Electric Range") AS "Average Range"
FROM vehicle_location
JOIN details_location ON vehicle_location."DOL Vehicle ID" = details_location."DOL Vehicle ID"
JOIN vehicle_details ON details_location."VIN (1-10)" = vehicle_details."VIN (1-10)"
WHERE "Electric Range" IS NOT NULL
GROUP BY "State"
ORDER BY "Average Range" DESC;


-- Query 3: Find the most popular electric vehicle make in each state
WITH RankedMakes AS (
    SELECT 
        vehicle_location."State",
        vehicle_details."Make",
        COUNT(*) AS "Total Count",
        RANK() OVER (PARTITION BY vehicle_location."State" ORDER BY COUNT(*) DESC) AS rank
    FROM vehicle_location
    JOIN details_location ON vehicle_location."DOL Vehicle ID" = details_location."DOL Vehicle ID"
    JOIN vehicle_details ON details_location."VIN (1-10)" = vehicle_details."VIN (1-10)"
    GROUP BY vehicle_location."State", vehicle_details."Make"
)
SELECT "State", "Make", "Total Count"
FROM RankedMakes
WHERE rank = 1;

-- (Q8) Indexes and performance tuning (CREATE INDEX ...)

CREATE INDEX idx_model ON vehicle_details("Model");

EXPLAIN ANALYZE
SELECT "Model", COUNT(*) AS "Total Count"
FROM vehicle_details
GROUP BY "Model"
ORDER BY "Total Count" DESC
LIMIT 5;

CREATE INDEX idx_location_state ON vehicle_location("DOL Vehicle ID", "State");
CREATE INDEX idx_vehicle_range ON vehicle_details("VIN (1-10)", "Electric Range");

EXPLAIN ANALYZE
SELECT "State", AVG("Electric Range") AS "Average Range"
FROM details_location
JOIN vehicle_location ON vehicle_location."DOL Vehicle ID" = details_location."DOL Vehicle ID"
JOIN vehicle_details ON details_location."VIN (1-10)" = vehicle_details."VIN (1-10)"
WHERE "Electric Range" IS NOT NULL
GROUP BY "State";
*/