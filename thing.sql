ALTER TABLE district_elections ADD state_code VARCHAR(2);
ALTER TABLE district_elections ADD democratic BOOLEAN;
ALTER TABLE district_elections ADD republican BOOLEAN;

UPDATE district_elections SET state_code = 'AL' WHERE district LIKE '%Alabama%';

UPDATE district_elections 
SET state_code = 'AK'
	WHERE district LIKE '%Alaska%';

UPDATE district_elections 
SET state_code = 'AZ'
	WHERE district LIKE '%Arizona%';

UPDATE district_elections 
SET state_code = 'AR'
	WHERE district LIKE '%Arkansas%';

UPDATE district_elections 
SET state_code = 'CA'
	WHERE district LIKE '%California%';

UPDATE district_elections 
SET state_code = 'CO'
	WHERE district LIKE '%Colorado%';

UPDATE district_elections 
SET state_code = 'CT'
	WHERE district LIKE '%Connecticut%';

UPDATE district_elections 
SET state_code = 'DE'
	WHERE district LIKE '%Delaware%';

UPDATE district_elections 
SET state_code = 'FL'
	WHERE district LIKE '%Florida%';

UPDATE district_elections 
SET state_code = 'GA'
	WHERE district LIKE '%Georgia%';

UPDATE district_elections 
SET state_code = 'HI'
	WHERE district LIKE '%Hawaii%';

UPDATE district_elections 
SET state_code = 'ID'
	WHERE district LIKE '%Idaho%';

UPDATE district_elections 
SET state_code = 'IL'
	WHERE district LIKE '%Illinois%';

UPDATE district_elections 
SET state_code = 'IN'
	WHERE district LIKE '%Indiana%';

UPDATE district_elections 
SET state_code = 'IA'
	WHERE district LIKE '%Iowa%';

UPDATE district_elections 
SET state_code = 'KS'
	WHERE district LIKE '%Kansas%';

UPDATE district_elections 
SET state_code = 'KY'
	WHERE district LIKE '%Kentucky%';

UPDATE district_elections 
SET state_code = 'LA'
	WHERE district LIKE '%Louisiana%';

UPDATE district_elections 
SET state_code = 'ME'
	WHERE district LIKE '%Maine%';

UPDATE district_elections 
SET state_code = 'MD'
	WHERE district LIKE '%Maryland%';

UPDATE district_elections 
SET state_code = 'MA'
	WHERE district LIKE '%Massachusetts%';

UPDATE district_elections 
SET state_code = 'MI'
	WHERE district LIKE '%Michigan%';

UPDATE district_elections 
SET state_code = 'MN'
	WHERE district LIKE '%Minnesota%';

UPDATE district_elections 
SET state_code = 'MS'
	WHERE district LIKE '%Mississippi%';

UPDATE district_elections 
SET state_code = 'MO'
	WHERE district LIKE '%Missouri%';

UPDATE district_elections 
SET state_code = 'MT'
	WHERE district LIKE '%Montana%';

UPDATE district_elections 
SET state_code = 'NE'
	WHERE district LIKE '%Nebraska%';

UPDATE district_elections 
SET state_code = 'NV'
	WHERE district LIKE '%Nevada%';

UPDATE district_elections 
SET state_code = 'NH'
	WHERE district LIKE '%New Hampshire%';

UPDATE district_elections 
SET state_code = 'NJ'
	WHERE district LIKE '%New Jersey%';

UPDATE district_elections 
SET state_code = 'NM'
	WHERE district LIKE '%New Mexico%';

UPDATE district_elections 
SET state_code = 'NY'
	WHERE district LIKE '%New York%';

UPDATE district_elections 
SET state_code = 'NC'
	WHERE district LIKE '%North Carolina%';

UPDATE district_elections 
SET state_code = 'ND'
	WHERE district LIKE '%North Dakota%';

UPDATE district_elections 
SET state_code = 'OH'
	WHERE district LIKE '%Ohio%';

UPDATE district_elections 
SET state_code = 'OK'
	WHERE district LIKE '%Oklahoma%';

UPDATE district_elections 
SET state_code = 'OR'
	WHERE district LIKE '%Oregon%';

UPDATE district_elections 
SET state_code = 'PA'
	WHERE district LIKE '%Pennsylvania%';

UPDATE district_elections 
SET state_code = 'RI'
	WHERE district LIKE '%Rhode Island%';

UPDATE district_elections 
SET state_code = 'SC'
	WHERE district LIKE '%South Carolina%';

UPDATE district_elections 
SET state_code = 'SD'
	WHERE district LIKE '%South Dakota%';

UPDATE district_elections 
SET state_code = 'TN'
	WHERE district LIKE '%Tennessee%';

UPDATE district_elections 
SET state_code = 'TX'
	WHERE district LIKE '%Texas%';

UPDATE district_elections 
SET state_code = 'UT'
	WHERE district LIKE '%Utah%';

UPDATE district_elections 
SET state_code = 'VT'
	WHERE district LIKE '%Vermont%';

UPDATE district_elections 
SET state_code = 'VA'
	WHERE district LIKE '%Virginia%';

UPDATE district_elections 
SET state_code = 'WA'
	WHERE district LIKE '%Washington%';

UPDATE district_elections 
SET state_code = 'WV'
	WHERE district LIKE '%West Virginia%';

UPDATE district_elections 
SET state_code = 'WI'
	WHERE district LIKE '%Wisconsin%';

UPDATE district_elections 
SET state_code = 'WY'
	WHERE district LIKE '%Wyoming%';

UPDATE district_elections
SET democratic = True
	WHERE party = 'DEM' 
		AND won = 'True';

UPDATE district_elections
SET democratic = False
	WHERE party != 'DEM' 
		OR won != 'True';

UPDATE district_elections
SET republican = True
	WHERE party = 'REP' 
		AND won = 'True';

UPDATE district_elections
SET republican = False
	WHERE party != 'REP' 
		OR won != 'True';

CREATE TABLE district_winners (
	legislative_district TEXT,
	state VARCHAR(2),
	republican BOOLEAN,
	democratic BOOLEAN
);

INSERT INTO district_winners
SELECT d.district, d.state_code, d.republican, d.democratic 
FROM district_elections AS d
WHERE d.won = 'True';
