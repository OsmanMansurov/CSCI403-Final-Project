/*
CSCI403-Final-Project
Aidan Morganfield, Chris Olsten, Osman Mansurov, Omar Mansurov
Professor Fierro
CSCI403 Database Management
04/28/2025
*/

SET search_path TO group12;
SET ROLE group12;

DROP TABLE if exists electric_vehicles;
DROP TABLE if exists district_elections CASCADE;
DROP TABLE if exists district_politics CASCADE;
DROP TABLE if exists details_location CASCADE;
DROP TABLE if exists vehicle_details CASCADE;
DROP TABLE if exists vehicle_location CASCADE;


/*
------------------------------------------------------------------------------------------
Electric Vehicle Data
------------------------------------------------------------------------------------------
*/

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

--Data Cleaning (Deliverable 1 -- Part 1/2)
--This work was done by Chris Olsten for Take Home Assignment 2
--It was included as part of the data cleaning deliverable as the cleaning was important for joining with the additional data we collected
--The new data set also required a significant amount of additional cleaning
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

--Schema Design: Normalizing into BCNF and Adding Keys and constraints
--This work was done by Chris Olsten for Take Home Assignment 2 and was not used as a deliverable for our final project report
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

ALTER TABLE vehicle_details ADD CONSTRAINT pk_vehicle_details PRIMARY KEY ("VIN (1-10)");
ALTER TABLE vehicle_location ADD CONSTRAINT pk_vehicle_location PRIMARY KEY ("DOL Vehicle ID");
ALTER TABLE details_location ADD CONSTRAINT pk_details_location PRIMARY KEY ("VIN (1-10)", "DOL Vehicle ID");

ALTER TABLE details_location ADD CONSTRAINT fk_details_location_vin FOREIGN KEY ("VIN (1-10)") REFERENCES vehicle_details("VIN (1-10)") ON DELETE CASCADE;
ALTER TABLE details_location ADD CONSTRAINT fk_details_location_dol FOREIGN KEY ("DOL Vehicle ID") REFERENCES vehicle_location("DOL Vehicle ID") ON DELETE CASCADE;

ALTER TABLE vehicle_details ADD CONSTRAINT chk_model_year CHECK ("Model Year" >= 1900 AND "Model Year" <= EXTRACT(YEAR FROM CURRENT_DATE));
ALTER TABLE vehicle_details ADD CONSTRAINT chk_electric_range CHECK ("Electric Range" >= 0);


/*
------------------------------------------------------------------------------------------
20201103_legislative (Washington Legislative District Election Results)
------------------------------------------------------------------------------------------
*/
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

--Data Cleaning (Deliverable 1 -- Part 2/2)
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



/*
------------------------------------------------------------------------------------------
Interesting Queries (Deliverable 3)
------------------------------------------------------------------------------------------
*/
--Query 1
SELECT DISTINCT "Make", "Model", AVG("Electric Range") as "Avg_Range"
FROM vehicle_details
GROUP BY "Make", "Model"
ORDER BY "Make", "Model";

--Query 2
SELECT party, COUNT(*) from legislative_data
GROUP by party;

--Query 3
SELECT party, COUNT(*)
FROM legislative_data JOIN vehicle_location ON legislative_data.district = vehicle_location."Legislative District"
GROUP BY party;  

--Query 4
WITH vehicles_registered AS(
    SELECT "Make", "Legislative District"
    FROM ((vehicle_details JOIN details_location ON vehicle_details."VIN (1-10)"=details_location."VIN (1-10)") 
    JOIN vehicle_location ON details_location."DOL Vehicle ID"=vehicle_location."DOL Vehicle ID")
)
SELECT "Make", COUNT(*), party
FROM legislative_data JOIN vehicles_registered ON legislative_data.district = vehicles_registered."Legislative District"
GROUP BY "Make",party ORDER BY "Make", count DESC;