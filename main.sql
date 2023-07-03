--creating database
CREATE TABLE films (
    id_film SERIAL PRIMARY KEY,
    duration INTEGER NOT NULL,
    title VARCHAR(40) NOT NULL,
    release_year INTEGER NOT NULL CHECK (release_year > 1700 AND release_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    budget INTEGER NOT NULL,
);

CREATE TABLE countries_film (
id_film integer NOT NULL,
country_name VARCHAR(40) NOT NULL, 
FOREIGN KEY (id_film) REFERENCES films (id_film)
);
  
CREATE TABLE creators (
	id_creator SERIAL PRIMARY KEY,
	first_name VARCHAR(40) NOT NULL,
	last_name VARCHAR(40) NOT NULL,
	date_of_birth DATE NOT NULL
);

CREATE TABLE filming (
	id_film INTEGER REFERENCES films (id_film),
	id_creator INTEGER REFERENCES creators (id_creator),
	PRIMARY KEY (id_film, id_creator)
);

CREATE TABLE film_festivals (
	id SERIAL PRIMARY KEY,
	name_fest VARCHAR(100) NOT NULL UNIQUE
);
  
CREATE TABLE type_award (
	id SERIAL PRIMARY KEY,
	name_award VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE awards (
	id_award SERIAL PRIMARY KEY,
	id_film INTEGER,
	id_creator INTEGER,
	title VARCHAR(40) NOT NULL,
	where_from VARCHAR(100) NOT NULL,
	year_of_receipt INTEGER NOT NULL,
		FOREIGN KEY (id_film) REFERENCES films (id_film),
		FOREIGN KEY (id_film, id_creator) REFERENCES filming (id_film, id_creator),
		FOREIGN KEY (id_creator) REFERENCES creators (id_creator),
		FOREIGN KEY (title) REFERENCES type_award (name_award),
		FOREIGN KEY (where_from) REFERENCES film_festivals (name_fest)
);

CREATE TABLE users (
	id_user SERIAL PRIMARY KEY,
	nickname VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE critics (
	id_critic SERIAL PRIMARY KEY,
	first_name VARCHAR(40) NOT NULL,
	last_name VARCHAR(40) NOT NULL,
	date_of_birth DATE NOT NULL
);


CREATE TABLE reviews (
	id_review SERIAL PRIMARY KEY,
	id_film INTEGER REFERENCES films (id_film),
	review_text VARCHAR(500) NOT NULL,
	rating DOUBLE PRECISION NOT NULL,
	id_user INTEGER,
	id_critic INTEGER,
		FOREIGN KEY (id_user) REFERENCES users (id_user),
		FOREIGN KEY (id_critic) REFERENCES critics (id_critic)
);

CREATE TABLE accept_positions (
	id SERIAL PRIMARY KEY,
	name_profession VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE creators_positions (
	id_film INTEGER,
	id_creator INTEGER,
	nature_of_part VARCHAR(40) NOT NULL,
	actor_role VARCHAR(40),
		PRIMARY KEY (id_film, id_creator, nature_of_part),
		FOREIGN KEY (id_film) REFERENCES films (id_film),
		FOREIGN KEY (id_film, id_creator) REFERENCES filming (id_film, id_creator),
		FOREIGN KEY (id_creator) REFERENCES creators (id_creator),
		FOREIGN KEY (nature_of_part) REFERENCES accept_positions (name_profession)
);

--Creating views
CREATE VIEW oscar_awarded_films AS
	SELECT films.title, films.release_year, awards.title AS oscar_category
		FROM films
			JOIN awards ON films.id_film = awards.id_film
			WHERE awards.title = ‘Оскар’;

CREATE VIEW oscar_best_actor AS
	SELECT creators.first_name, creators.last_name, awards.year_of_receipt
		FROM creators
			JOIN awards ON creators.id_creator = awards.id_creator
			WHERE awards.title = 'Оскар' AND awards.where_from = 'Новый урожай';

CREATE VIEW films_by_Roland_Emmerich AS
	SELECT films.title, films.duration, films.release_year
		FROM films
			JOIN creators_positions ON films.id_film = creators_positions.id_film
			JOIN creators ON creators_positions.id_creator = creators.id_creator
				WHERE creators.first_name = 'Roland' AND creators.last_name = 'Emmerich' AND creators_positions.nature_of_part = 'Режиссер';

CREATE VIEW high_rated_films AS
	SELECT films.title, films.duration, films.release_year, AVG(reviews.rating) AS overall_rating
		FROM films
			JOIN reviews ON films.id_film = reviews.id_film
			GROUP BY films.id_film
			HAVING AVG(reviews.rating) > 7;

CREATE VIEW high_critic_rating_films AS
	SELECT films.title, films.duration, films.release_year, AVG(reviews.rating) AS critic_rating
		FROM films
			JOIN reviews ON films.id_film = reviews.id_film
			JOIN critics ON reviews.id_critic = critics.id_critic
				GROUP BY films.title, films.duration, films.release_year
				HAVING AVG(reviews.rating) > 8;

CREATE VIEW actors_born_after_1970 AS
	SELECT creators.first_name, creators.last_name, creators.date_of_birth
		FROM creators
			JOIN creators_positions ON creators.id_creator = creators_positions.id_creator
			WHERE creators.date_of_birth > '1970-01-01' AND creators_positions.nature_of_part = 'Актер';

--Creating some roles
CREATE ROLE administrator;
CREATE ROLE employee;
CREATE ROLE client; 

GRANT SELECT ON users TO administrator;
GRANT SELECT ON users TO employee;
GRANT INSERT, UPDATE ON users TO client;
GRANT SELECT ON critics TO administrator;
GRANT SELECT, UPDATE, INSERT ON critics TO employee;
GRANT SELECT ON critics TO client;
GRANT SELECT ON reviews TO administrator;
GRANT SELECT, UPDATE, INSERT, DELETE ON reviews TO employee;
GRANT SELECT, UPDATE, INSERT, DELETE ON reviews TO client;
GRANT SELECT, UPDATE, INSERT, DELETE ON accept_positions TO administrator;
GRANT SELECT, UPDATE, INSERT ON accept_positions TO employee;
GRANT SELECT ON accept_positions TO client;
GRANT SELECT ON creator_positions TO administrator;
GRANT SELECT, UPDATE, INSERT ON creator_positions TO employee;
GRANT SELECT ON creator_positions TO client;
GRANT SELECT ON filming TO administrator;
GRANT SELECT, UPDATE, INSERT, DELETE ON filming TO employee;
GRANT SELECT ON filming TO client;
GRANT SELECT ON creators TO administrator;
GRANT SELECT, UPDATE, INSERT, DELETE ON creators TO employee;
GRANT SELECT ON creators TO client;
GRANT SELECT, UPDATE, INSERT, DELETE ON countries_film TO administrator;
GRANT SELECT, UPDATE, INSERT ON countries_film TO employee;
GRANT SELECT ON countries_film TO client;
GRANT SELECT, UPDATE, INSERT, DELETE ON type_award TO administrator;
GRANT SELECT, UPDATE, INSERT ON type_award TO employee;
GRANT SELECT ON type_award TO client;
GRANT SELECT, UPDATE, INSERT, DELETE ON film_festivals TO administrator;
GRANT SELECT, UPDATE, INSERT ON film_festivals TO employee;
GRANT SELECT ON film_festivals TO client;
GRANT SELECT ON films TO administrator;
GRANT SELECT, UPDATE, INSERT, DELETE ON films TO employee;
GRANT SELECT ON films TO client;
GRANT SELECT ON awards TO administrator;
GRANT SELECT, UPDATE, INSERT, DELETE ON awards TO employee;
GRANT SELECT ON awards TO client;
GRANT INSERT, UPDATE, DELETE ON award TO administrator
GRANT INSERT, UPDATE, DELETE ON film TO employee;
GRANT INSERT, UPDATE, DELETE ON "user" TO user;
GRANT INSERT, UPDATE, DELETE ON review TO user;

CREATE USER admin_user WITH PASSWORD 'admin_password';
ALTER USER admin_user WITH ROLE administrator;
 
CREATE USER employee_user WITH PASSWORD 'employee_password';
ALTER USER employee_user WITH ROLE employee;
 
CREATE USER regular_user WITH PASSWORD 'user_password';
ALTER USER regular_user WITH ROLE client;

--Creating index
CREATE INDEX idx_film_title ON films (title);

CREATE INDEX idx_creator_name ON creators (first_name, last_name);

CREATE INDEX idx_creating_film_creator ON filming (id_film, id_creator);

CREATE INDEX idx_review_film ON reviews (id_film);

--Creating triggers
ALTER TABLE films
	ADD CONSTRAINT check_budget
		CHECK (budget >= 0);

CREATE OR REPLACE FUNCTION check_award_year() 
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.year_of_receipt < (SELECT release_year FROM films WHERE id_film = NEW.id_film)) THEN
        RAISE EXCEPTION 'Год выдачи награды должен быть больше или такой же, как год выхода фильма';
    END IF;

    RETURN NEW;
END;

CREATE TRIGGER check_award_year_trigger
BEFORE INSERT OR UPDATE ON awards
FOR EACH ROW
EXECUTE FUNCTION check_award_year();

CREATE OR REPLACE FUNCTION check_critic_age() RETURNS TRIGGER AS $$
DECLARE
    critic_age INTEGER;
BEGIN
    SELECT EXTRACT(YEAR FROM age(NEW.date_of_birth)) INTO critic_age;

    IF (critic_age < 18) THEN
        RAISE EXCEPTION 'Возраст критика должен быть не менее 18 лет';
    END IF;

    RETURN NEW;
END;
