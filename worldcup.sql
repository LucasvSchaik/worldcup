-- WK DATABASE - SQL SCHEMA

--  Order: Each table is next in order to which is refers.

--Country
-- =============================

CREATE TABLE Country (
	id INTEGER PRIMARY KEY,
	name VARCHAR(50) NOT NULL UNIQUE, -- THE UNIQUE constraint prevents that for example "Mexico" is inserted two times, it 
	population INTEGER
);

--Stadium
-- =============================
CREATE TABLE Stadium (
	id INTEGER PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	city VARCHAR(50) ,
	country_id INTEGER NOT NULL, -- NO UNIQUE because multiple stadiums can be in the same country.
	capacity INTEGER CHECK  (capacity > 0 ),
	year_built INTEGER,
	owner VARCHAR(50),
	sport_type VARCHAR(50),
	altitude INTEGER,
	has_airco BOOLEAN DEFAULT FALSE,
	FOREIGN KEY (country_id) REFERENCES Country(id)  -- Normally Stadium.city decides the Country. But theoratically cities are not unique so it is chosen to have country_id as a extra attribute in the stadium table and to have it a FK to connect with "Country" 
		ON DELETE NO ACTION -- There should be no cases where a stadium does not contain a county; in that case DELETE will be blocked.
		ON UPDATE CASCADE  -- id is a  surrogate key, so if it ever changes, there is no reason to block it manually  and can be propegated automatically. This is possible because the  PK-CONSTRAINT will check whether the PK i.e. the id is unique. 
);

--Team
-- =============================
CREATE TABLE Team (
	id INTEGER PRIMARY KEY,
	team_code CHAR(3) UNIQUE, -- For example NED, ESP and USA. The team_code is neccesary for the Game table where it is more clear to see who play against who
	--, instead of surrogate values like "id".
	name VARCHAR(50) NOT NULL, 
	coach_name VARCHAR(50),
	fifa_ranking INTEGER,
	CHECK (fifa_ranking > 0)
);

--Player
-- =============================
CREATE TABLE Player (
	id INTEGER PRIMARY KEY,
	name VARCHAR(50),
	team_id INTEGER NOT NULL, -- For example NED, ESP, USA
	position VARCHAR(20)  CHECK (position IN ('Keeper', 'Defender', 'Midfielder', 'Forward')),
	club  VARCHAR(50),
	FOREIGN KEY (team_id) REFERENCES Team(id)
		ON DELETE  NO ACTION
		ON UPDATE CASCADE 
);



--Game
-- =============================
CREATE TABLE Game (
	id INTEGER PRIMARY KEY,
	team1_code CHAR(3) NOT NULL,
	team2_code CHAR(3) NOT NULL,
	stadium_id INTEGER,
	game_date TEXT,
	tournament_phase VARCHAR(30) CHECK (tournament_phase IN ('Group stage', 'Round of 32', 'Round of 16', 'Quarterfinal', 'Semifinal', 'Final')),
	number_of_audience INTEGER,
	temperature NUMERIC(4,1), -- Maximum of 4 digits and 1 decimal. Ideal for every temeprature metric
	humidity NUMERIC(4,1), 
	rain BOOLEAN,
	number_of_corners INTEGER,
	shots_on_target INTEGER,
	possesion_team1 NUMERIC(4,1), -- The possesion of team2 can be calulated by 100-posession_team1
	expected_score NUMERIC(4,1),
	FOREIGN KEY (team1_code) REFERENCES Team(team_code)
		ON DELETE NO ACTION
		ON UPDATE CASCADE, -- If the team_code changes it must be propegated automatically in GAME
		FOREIGN KEY (team2_code) REFERENCES Team(team_code)
		ON DELETE NO ACTION
		ON UPDATE CASCADE,
		FOREIGN KEY("stadium_id") REFERENCES "Stadium"("id") 
		ON DELETE NO ACTION 
		ON UPDATE CASCADE,
		CHECK (team1_code <> team2_code)  -- Team1 and team2 musn't be the same for a team cannot play against itself.
);

--Goal
-- =============================
CREATE TABLE Goal (
	id INTEGER PRIMARY KEY,
	match_id INTEGER NOT NULL,
	player_id INTEGER NOT NULL,
	time INTEGER,
	FOREIGN KEY (match_id) REFERENCES Game(id)
        ON DELETE CASCADE   
        ON UPDATE CASCADE,
    FOREIGN KEY (player_id) REFERENCES Player(id)
        ON DELETE NO ACTION   -- HIstorical data cannot be deleted
        ON UPDATE CASCADE,
		CHECK (time BETWEEN 0 AND 140) -- A game normally can only be 130 minutes . For margin the goal should be limited within 140 minutes.
);

--Assist
-- =============================
CREATE TABLE Assist (
	id INTEGER PRIMARY KEY,
	goal_id INTEGER NOT NULL UNIQUE, -- A goal has at most one assist. To prevent a case where one goal has two assist the UNIQUE constraint is added.
	player_id INTEGER NOT NULL, 
	FOREIGN KEY (goal_id) REFERENCES Goal(id)
		ON DELETE CASCADE -- A assist only exists in the context of a goal.
		ON UPDATE CASCADE,
	FOREIGN KEY (player_id) REFERENCES Player(id)
		ON DELETE NO ACTION -- Historical data cannot be deleted
		ON UPDATE CASCADE
);

--Penalty
-- =============================
CREATE TABLE Penalty (
	id INTEGER PRIMARY KEY,
	match_id INTEGER NOT NULL,
	goal_id INTEGER UNIQUE, --  Like in "Assist" a penalty must have at most 1 goal. For that reason the UNIQUE constraint is at place.
	player_id INTEGER NOT NULL,
	keeper_id INTEGER NOT NULL, -- the keeper that defends the penalty
	result VARCHAR(10) CHECK (result IN ('Scored', 'Missed')),
	 FOREIGN KEY (match_id) REFERENCES Game(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (goal_id) REFERENCES Goal(id)
        ON DELETE NO ACTION     -- if this goal belongs to a scored penalty, deletion is
                            -- blocked so 'goal_id' and 'result' never fall out of sync in the "CHECK"
        ON UPDATE CASCADE,
    FOREIGN KEY (player_id) REFERENCES Player(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (keeper_id) REFERENCES Player(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
		CHECK ( 
			(goal_id IS NULL AND result = 'Missed')
			OR
			(goal_id IS NOT NULL AND result = 'Scored')
		)		
);

--Card
-- =============================
CREATE TABLE Card (
	id INTEGER PRIMARY KEY,
	match_id INTEGER NOT NULL,
	player_id INTEGER NOT NULL,
	time INTEGER,
	type VARCHAR(10) CHECK (type IN ('Yellow', 'Red')),
    FOREIGN KEY (match_id) REFERENCES Game(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (player_id) REFERENCES Player(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

--Substitution
-- =============================
CREATE TABLE Substitution (
	id INTEGER PRIMARY KEY,
	match_id INTEGER NOT NULL,
	player_out_id INTEGER NOT NULL , 
	player_in_id INTEGER NOT NULL ,
	time INTEGER,
	FOREIGN KEY (match_id) REFERENCES Game(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (player_out_id) REFERENCES Player(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (player_in_id) REFERENCES Player(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CHECK (player_out_id <> player_in_id),
	UNIQUE (match_id, player_out_id),
    UNIQUE (match_id, player_in_id)	-- UNIQUE because player can only by subsituted in and out one time per game
);


-- DATABASE POPULATIE
-- populating the database with a selection of some real world cup games from group A with a path to the final.
-- The population was done with help of GenAI as allowed in the assignment discription.
-- ============================================================
 
PRAGMA foreign_keys = ON;
 
-- Country
INSERT INTO Country (id, name, population) VALUES
(1, 'Mexico', 128900000),
(2, 'United States', 335000000),
(3, 'Canada', 39000000);
 
-- Stadium
INSERT INTO Stadium (id, name, city, country_id, capacity, year_built, owner, sport_type, altitude, has_airco) VALUES
(1, 'Estadio Azteca', 'Mexico City', 1, 87000, 1966, 'Grupo Carso', 'Football', 2200, 0),
(2, 'Estadio Akron', 'Guadalajara', 1, 48071, 2010, 'Grupo Omnilife', 'Football', 1566, 0),
(3, 'Estadio BBVA', 'Monterrey', 1, 53500, 2015, 'Rayados de Monterrey', 'Football', 538, 0),
(4, 'SoFi Stadium', 'Los Angeles', 2, 70000, 2020, 'Los Angeles Rams', 'Football', 30, 1),
(5, 'BMO Field', 'Toronto', 3, 45736, 2007, 'MLSE', 'Football', 76, 0),
(6, 'Mercedes-Benz Stadium', 'Atlanta', 2, 71000, 2017, 'AMB Group', 'Football', 320, 1),
(7, 'MetLife Stadium', 'East Rutherford', 2, 82500, 2010, 'NFL', 'Football', 3, 0);
 
-- Team (4 group A teams + selected knock-out teams)
INSERT INTO Team (id, team_code, name, coach_name, fifa_ranking) VALUES
(1, 'MEX', 'Mexico', 'Javier Aguirre', 12),
(2, 'RSA', 'South Africa', 'Hugo Broos', 60),
(3, 'KOR', 'South Korea', 'Hong Myung-bo', 22),
(4, 'CZE', 'Czechia', 'Ivan Hasek', 41),
(5, 'CAN', 'Canada', 'Jesse Marsch', 27),
(6, 'ECU', 'Ecuador', 'Sebastian Beccacece', 26),
(7, 'MAR', 'Morocco', 'Walid Regragui', 13),
(8, 'ARG', 'Argentina', 'Lionel Scaloni', 1),
(9, 'EGY', 'Egypt', 'Hossam Hassan', 33),
(10, 'FRA', 'France', 'Didier Deschamps', 3),
(11, 'SUI', 'Switzerland', 'Murat Yakin', 19),
(12, 'ESP', 'Spain', 'Luis de la Fuente', 2),
(13, 'ENG', 'England', 'Thomas Tuchel', 4);
 
-- Player (selection of core players per team + deliberate high-similarity test records)
INSERT INTO Player (id, name, team_id, position, club) VALUES
-- Mexico
(1, 'Julian Quinones', 1, 'Forward', 'Club America'),
(2, 'Raul Jimenez', 1, 'Forward', 'Fulham'),
(3, 'Roberto Alvarado', 1, 'Midfielder', 'Guadalajara'),
(4, 'Erik Lira', 1, 'Midfielder', 'Cruz Azul'),
(5, 'Cesar Montes', 1, 'Defender', 'Lokomotiv Moscow'),
(6, 'Bryan Gutierrez', 1, 'Midfielder', 'Chivas'),
(7, 'Jesus Gallardo', 1, 'Forward', 'Toluca'),
(8, 'Gilberto Mora', 1, 'Midfielder', 'Tijuana'),
(9, 'Santiago Gimenez', 1, 'Forward', 'AC Milan'),
(10, 'Edson Alvarez', 1, 'Defender', 'West Ham'),
-- South Africa
(11, 'Ronwen Williams', 2, 'Keeper', 'Mamelodi Sundowns'),
(12, 'Sphephelo Sithole', 2, 'Defender', 'Tondela'),
(13, 'Teboho Mokoena', 2, 'Midfielder', 'Mamelodi Sundowns'),
(14, 'Lyle Foster', 2, 'Forward', 'Burnley'),
(15, 'Mbekezeli Mbokazi', 2, 'Defender', 'Chicago Fire'),
(16, 'Aubrey Modiba', 2, 'Defender', 'Mamelodi Sundowns'),
(17, 'Evidence Makgopa', 2, 'Forward', 'Orlando Pirates'),
(18, 'Khuliso Mudau', 2, 'Defender', 'Mamelodi Sundowns'),
-- South Korea
(19, 'Hwang In-beom', 3, 'Midfielder', 'FC Seoul'),
(20, 'Oh Hyeon-gyu', 3, 'Forward', 'Besiktas'),
(21, 'Lee Kang-in', 3, 'Midfielder', 'Mallorca'),
(22, 'Son Heung-min', 3, 'Forward', 'Tottenham'),
(23, 'Hwang Hee-chan', 3, 'Forward', 'Wolverhampton'),
(24, 'Lee Jae-sung', 3, 'Midfielder', 'Mainz 05'),
(25, 'Kim Seung-gyu', 3, 'Keeper', 'FC Tokyo'),
(26, 'Lee Gi-hyuk', 3, 'Defender', 'Gangwon FC'),
(27, 'Kim Jin-gyu', 3, 'Defender', 'Jeonbuk Hyundai Motors'),
-- Czechia
(28, 'Patrik Schick', 4, 'Forward', 'Bayer Leverkusen'),
(29, 'Adam Hlozek', 4, 'Forward', 'TSG Hoffenheim'),
(30, 'Lukas Provod', 4, 'Midfielder', 'Slavia Prague'),
(31, 'Michal Sadilek', 4, 'Midfielder', 'Slavia Prague'),
(32, 'Tomas Chory', 4, 'Forward', 'Slavia Prague'),
(33, 'Mojmir Chytil', 4, 'Forward', 'Slavia Prague'),
(34, 'Ladislav Krejci', 4, 'Midfielder', 'Wolverhampton'),
(35, 'Jindrich Stanek', 4, 'Keeper', 'Slavia Prague'),
(36, 'David Jurasek', 4, 'Defender', 'Slavia Prague'),
-- Canada
(37, 'Jonathan David', 5, 'Forward', 'Juventus'),
(38, 'Alistair Johnston', 5, 'Defender', 'Celtic'),
-- Ecuador
(39, 'Moises Caicedo', 6, 'Midfielder', 'Chelsea'),
-- Morocco
(40, 'Achraf Hakimi', 7, 'Defender', 'PSG'),
(41, 'Youssef En-Nesyri', 7, 'Forward', 'Al-Ittihad'),
-- Argentina
(42, 'Lionel Messi', 8, 'Forward', 'Inter Miami'),
(43, 'Julian Alvarez', 8, 'Forward', 'Atletico Madrid'),
(44, 'Enzo Fernandez', 8, 'Midfielder', 'Chelsea'),
-- Egypt
(45, 'Mohamed Salah', 9, 'Forward', 'Liverpool'),
-- France
(46, 'Kylian Mbappe', 10, 'Forward', 'Real Madrid'),
-- Switzerland
(47, 'Breel Embolo', 11, 'Forward', 'Rennes'),
-- Spain
(48, 'Ferran Torres', 12, 'Forward', 'Barcelona'),
(49, 'Nico Williams', 12, 'Forward', 'Athletic Bilbao'),
(50, 'Pedro Porro', 12, 'Defender', 'Tottenham'),
(51, 'Lamine Yamal', 12, 'Forward', 'Barcelona'),
(52, 'Pedri', 12, 'Midfielder', 'Barcelona'),
(53, 'Unai Simon', 12, 'Keeper', 'Athletic Bilbao'),
-- England
(54, 'Bukayo Saka', 13, 'Forward', 'Arsenal'),
-- Deliberate high-similarity records for the string-similarity query
(55, 'Erick Lira', 1, 'Midfielder', 'Cruz Azul'),
(56, 'Lee Kang In', 3, 'Midfielder', 'Mallorca'),
(57, 'Leonel Messi', 8, 'Forward', 'Inter Miami');

-- Game (6 group games in Groep A + 9 knock-out games, with real results)
INSERT INTO Game (id, team1_code, team2_code, stadium_id, game_date, tournament_phase, number_of_audience, temperature, humidity, rain, number_of_corners, shots_on_target, possesion_team1, expected_score) VALUES
-- Group A
(1, 'MEX', 'RSA', 1, '2026-06-11', 'Group stage', 87000, 24.0, 45.0, 0, 7, 9, 58.0, 1.8),
(2, 'KOR', 'CZE', 2, '2026-06-11', 'Group stage', 41000, 22.0, 50.0, 0, 6, 8, 55.0,1.4),
(3, 'MEX', 'KOR', 2, '2026-06-18', 'Group stage', 46000, 23.0, 48.0, 0, NULL, NULL, NULL, NULL),
(4, 'CZE', 'RSA', 3, '2026-06-18', 'Group stage', 39000, 26.0, 40.0, 0, NULL, NULL, NULL, NULL),
(5, 'MEX', 'CZE', 1, '2026-06-24', 'Group stage', 87000, 25.0, 44.0, 0, NULL, NULL, NULL, NULL),
(6, 'RSA', 'KOR', 3, '2026-06-24', 'Group stage', 40000, 27.0, 38.0, 0, NULL, NULL, NULL, NULL),
-- Knock-out
(7, 'CAN', 'RSA', 4, '2026-06-28', 'Round of 32', 68000, 26.0, 40.0, 0, NULL, NULL, NULL, NULL),
(8, 'MEX', 'ECU', 1, '2026-06-30', 'Round of 32', 87000, 24.0, 46.0, 0, NULL, NULL, NULL, NULL),
(9, 'MAR', 'CAN', 5, '2026-07-04', 'Round of 16', 44000, 21.0, 55.0, 1, NULL, NULL, NULL, NULL),
(10, 'ARG', 'EGY', 6, '2026-07-07', 'Round of 16', 70000, 29.0, 50.0, 0, NULL, NULL, NULL, NULL),
(11, 'FRA', 'MAR', 6, '2026-07-09', 'Quarterfinal', 71000, 28.0, 48.0, 0, NULL, NULL, NULL, NULL),
(12, 'ARG', 'SUI', 4, '2026-07-11', 'Quarterfinal', 69000, 25.0, 42.0, 0, NULL, NULL, NULL, NULL),
(13, 'ESP', 'FRA', 4, '2026-07-14', 'Semifinal', 70000, 26.0, 41.0, 0, NULL, NULL, NULL, NULL),
(14, 'ARG', 'ENG', 6, '2026-07-15', 'Semifinal', 71000, 27.0, 47.0, 0, NULL, NULL, NULL, NULL),
(15, 'ESP', 'ARG', 7, '2026-07-19', 'Final', 82500, 27.0, 55.0, 0, 6, 7, 54.0, 1.1);
 
-- Goal
INSERT INTO Goal (id, match_id, player_id, time) VALUES
-- Group A 
(1, 1, 1, 9),
(2, 1, 2, 67),
(3, 2, 34, 61),
(4, 2, 19, 67),
(5, 2, 20, 83),
(6, 3, 9, 88),
(7, 4, 29, 35),
(8, 4, 14, 70),
(9, 5, 1, 15),
(10, 5, 2, 40),
(11, 5, 9, 77),
(12, 6, 14, 55),
-- Knock-out
(13, 7, 37, 52),   
(14, 8, 1, 30),   
(15, 8, 2, 71),    
(16, 9, 41, 20),  
(17, 9, 40, 44),   
(18, 9, 41, 80),  
(19, 10, 42, 12), 
(20, 10, 43, 38),  
(21, 10, 42, 75), 
(22, 10, 45, 55), 
(23, 10, 45, 90),  
(24, 11, 46, 28), 
(25, 11, 46, 66), 
(26, 12, 42, 18), 
(27, 12, 43, 60),  
(28, 12, 42, 103), 
(29, 12, 47, 80), 
(30, 13, 51, 34),  
(31, 13, 52, 58),  
(32, 14, 42, 22),  
(33, 14, 43, 66), 
(34, 14, 54, 80),  
(35, 15, 48, 106);
 
-- Assist
INSERT INTO Assist (id, goal_id, player_id) VALUES
(1, 2, 3),    -- SOURCE: Alvarado assist on Jimenez
(2, 4, 21),   -- SOURCE: Lee Kang-in assist on Hwang In-beom
(3, 5, 19),   -- SOURCE: Hwang In-beom assist on Oh Hyeon-gyu
(4, 35, 49);  -- SOURCE: Nico Williams assist on the winning goal of Ferran Torres in the final
 
-- Card
INSERT INTO Card (id, match_id, player_id, time, type) VALUES
(1, 1, 13, 17, 'Yellow'),
(2, 1, 6, 23, 'Yellow'),
(3, 1, 12, 50, 'Red'),
(4, 1, 5, 90, 'Red'),
(5, 2, 26, 96, 'Yellow'),
(6, 15, 44, 93, 'Red');  -- SOURCE: Enzo Fernandez, 2e yellow kaart in 90+3', WK-finale
 
-- Substitution
INSERT INTO Substitution (id, match_id, player_out_id, player_in_id, time) VALUES
(1, 1, 7, 8, 65),
(2, 2, 24, 23, 63),
(3, 2, 28, 32, 64),
(4, 2, 30, 31, 64),
(5, 2, 29, 33, 85);
 
-- Penalty (fictive exampe, to query the table
INSERT INTO Penalty (id, match_id, goal_id, player_id, keeper_id, result) VALUES
(1, 3, NULL, 2, 25, 'Missed');

--Task 2: 5 queries

--Join list, Which player has scored a goal, and what was the time of the goal?
SELECT Player.name, Goal.time
FROM Player
JOIN Goal ON Goal.player_id =
Player.id;

--Aggregate function, Which team has the most forward players?
SELECT Team.name,COUNT(Player.id)
AS number_of_forwards
FROM Player
JOIN Team
ON Player.team_id = Team.id
WHERE Player.position = 'Forward'
GROUP BY Team.name
ORDER BY number_of_forwards DESC;

--Nested Query & Set Operation, Which teams were still competing after the group phase?
SELECT DISTINCT name
FROM Team
WHERE team_code IN (
SELECT team1_code
FROM Game
WHERE tournament_phase != "Group
stage"
UNION
SELECT team2_code
FROM Game
WHERE tournament_phase != "Group
stage" );

--Self join, What games were planned on the same day?
SELECT g1.team1_code || ' - ' || g1.
team2_code AS game1,
g2.team1_code || ' - ' || g2.
team2_code AS game2,
g1.game_date
FROM Game AS g1
JOIN Game AS g2
ON g1.game_date = g2.game_date
WHERE g1.id < g2.id;

--Set operation, Which teams played both home and away games?
SELECT team1_code
FROM Game
INTERSECT
SELECT team2_code
FROM Game;