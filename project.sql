SET search_path TO group12;

DROP TABLE if exists electric_vehicles;
DROP TABLE if exists details_location CASCADE;
DROP TABLE if exists vehicle_details CASCADE;
DROP TABLE if exists vehicle_location CASCADE;


-- (Q2) Initial Schema (CREATE TABLE ...)

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
\copy electric_vehicles FROM 'data/Electric\ Vehicle\ Data.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);

CREATE TABLE district_elections (
    District TEXT,
    Candidate TEXT,
    Party TEXT,
    Total Votes INT,
    Won TEXT
);

\copy district_elections FROM 'data/house_candidate.csv' WITH (DELIMITER ',', FORMAT CSV, HEADER);

CREATE TABLE district_politics (
    District TEXT,
    Party Text
);

-- (Q2) Load data into the table and clean data (\copy ...)


INSERT INTO district_politics VALUES (SELECT District, Party FROM district_elections WHERE Won = "TRUE");

-- (Q4) Normalized schemas (CREATE TABLE ...)

CREATE TABLE vehicle_details (
    "VIN (1-10)" TEXT NOT NULL,
    "Model" TEXT NOT NULL,
    "Model Year" INT NOT NULL,
    "Make" TEXT NOT NULL,
    "Electric Vehicle Type" TEXT,
    "Electric Range" INT,
);

CREATE TABLE vehicle_location (
    "DOL Vehicle ID" TEXT NOT NULL,
    "County" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "State" TEXT NOT NULL,
    "Postal Code" TEXT NOT NULL,
    "2020 Census Tract" TEXT,
    "Legislative District" INT,
    "Clean Alternative Fuel Vehicle (CAFV) Eligibility" TEXT,
    "Vehicle Location" TEXT,
    "Electric Utility" TEXT
);


CREATE TABLE details_location (
    "VIN (1-10)" TEXT,
    "DOL Vehicle ID" TEXT
);


-- (Q5) Loading data from the initial table into the normalized tables  (INSERT INTO ... SELECT ...)

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

ALTER TABLE vehicle_location ALTER COLUMN "County" DROP NOT NULL;
ALTER TABLE vehicle_location ALTER COLUMN "City" DROP NOT NULL;
ALTER TABLE vehicle_location ALTER COLUMN "Postal Code" DROP NOT NULL;

INSERT INTO vehicle_details ("VIN (1-10)", "Model", "Model Year", "Make", "Electric Vehicle Type", "Electric Range")
SELECT DISTINCT "VIN (1-10)", "Model", "Model Year", "Make", "Electric Vehicle Type", "Electric Range"
FROM electric_vehicles
WHERE "VIN (1-10)" IS NOT NULL;

INSERT INTO vehicle_location ("DOL Vehicle ID", "County", "City", "State", "Postal Code", "2020 Census Tract", "Legislative District", "Vehicle Location", "Electric Utility")
SELECT DISTINCT "DOL Vehicle ID", "County", "City", "State", "Postal Code", "2020 Census Tract", "Legislative District", "Vehicle Location", "Electric Utility"
FROM electric_vehicles
WHERE "DOL Vehicle ID" IS NOT NULL;

DELETE FROM details_location
WHERE "DOL Vehicle ID" NOT IN (SELECT "DOL Vehicle ID" FROM vehicle_location);


INSERT INTO details_location ("VIN (1-10)", "DOL Vehicle ID")
SELECT DISTINCT "VIN (1-10)", "DOL Vehicle ID"
FROM electric_vehicles
WHERE "VIN (1-10)" IS NOT NULL AND "DOL Vehicle ID" IS NOT NULL;



-- (Q6) Keys and constraints (ALTER TABLE ... ADD CONSTRAINT ...)

ALTER TABLE vehicle_details ADD CONSTRAINT pk_vehicle_details PRIMARY KEY ("VIN (1-10)");
ALTER TABLE vehicle_location ADD CONSTRAINT pk_vehicle_location PRIMARY KEY ("DOL Vehicle ID");
ALTER TABLE details_location ADD CONSTRAINT pk_details_location PRIMARY KEY ("VIN (1-10)", "DOL Vehicle ID");

ALTER TABLE details_location ADD CONSTRAINT fk_details_location_vin FOREIGN KEY ("VIN (1-10)") REFERENCES vehicle_details("VIN (1-10)") ON DELETE CASCADE;
ALTER TABLE details_location ADD CONSTRAINT fk_details_location_dol FOREIGN KEY ("DOL Vehicle ID") REFERENCES vehicle_location("DOL Vehicle ID") ON DELETE CASCADE;

ALTER TABLE vehicle_details ADD CONSTRAINT chk_model_year CHECK ("Model Year" >= 1900 AND "Model Year" <= EXTRACT(YEAR FROM CURRENT_DATE));
ALTER TABLE vehicle_details ADD CONSTRAINT chk_electric_range CHECK ("Electric Range" >= 0);


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
