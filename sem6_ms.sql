/* Jeœ³i nie istniej to utworzenie bazy danych i pod³¹czenie do niej */
if not exists (select 1 from sys.databases where [name] = 'szkola85')
BEGIN
	CREATE DATABASE szkola85
END

USE szkola85
GO


/* Utworzenie procedury, jeœli nie istnieje 
** Procedura do usuwania tabel */
IF NOT EXISTS 
	( SELECT 1 FROM sysobjects o
		WHERE (o.[name] = 'rmv_table')
		AND		(OBJECTPROPERTY(o.[ID], N'IsProcedure') = 1)
	)
BEGIN
	EXEC sp_sqlExec N'CREATE PROCEDURE dbo.rmv_table AS select 2'
END

GO

ALTER PROCEDURE dbo.rmv_table (@tab_name nvarchar(100) )

AS
	IF EXISTS 
	( SELECT 1 FROM sysobjects o
		WHERE (o.[name] = @tab_name)
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
	)
	BEGIN
		DECLARE @sql nvarchar(1000)
		SET @sql = 'DROP TABLE ' + @tab_name
		EXEC sp_sqlexec @sql
	END
GO

exec rmv_table @tab_name = 'tmp_uczniowie'
GO

/* Tabela tymczasowa dla uczniów */
CREATE TABLE dbo.tmp_uczniowie
(	imie	nvarchar(15)	NOT NULL
,	nazwisko	nvarchar(25) NOT NULL
,	nr_legitymacji	nvarchar(6) NOT NULL
,	data_ur	nvarchar(10)	NOT NULL
)
GO

exec rmv_table @tab_name = 'tmp_oceny'
GO

/* Tabela tymczasowa dla occen */
CREATE TABLE dbo.tmp_oceny
(	ocena	nvarchar(3)		NOT NULL
,	przedmiot	nvarchar(15)	NOT NULL
,	rok_sz	nvarchar(5)		NOT NULL
,	nr_legitymacji	nvarchar(6) NOT NULL
,	imie_n	nvarchar(15)	NOT NULL
,	nazwisko_n	nvarchar(25)	NOT NULL
)
GO

/* tworzymy LOG-i z b³edami
** ELOG_N - nag³owek zbioru b³edów, kto i gdzie zg³osi³
*/
IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'ELOG_N'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.ELOG_N
	(	id_elog_n		int not null identity CONSTRAINT PK_ELOG_N PRIMARY KEY
	,	opis_n			nvarchar(100) NOT NULL
	,	dt				datetime NOT NULL DEFAULT GETDATE()
	,	u_name			nvarchar(40) NOT NULL DEFAULT USER_NAME()
	,	h_name			nvarchar(100) NOT NULL DEFAULT HOST_NAME()
	) 
END
GO

/* detale b³êdu
** musi byæ najpierw wstawiony nag³owek b³edu a potem z ID nag³owka b³edu wstawiane s¹ detale
*/
IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'ELOG_D'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.ELOG_D
	(	id_elog_n		int not null 
			CONSTRAINT FK_ELOG_N__ELOG_P FOREIGN KEY
			REFERENCES ELOG_N(id_elog_n)
	,	opis_d			nvarchar(100) NOT NULL
	) 
END
GO

/* Tworzenie tabel pod g³ówn¹ bazê */
IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'UCZEN'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Uczen
	(	IMIE		NVARCHAR(15)	NOT NULL
	,	NAZWISKO	NVARCHAR(25)	NOT NULL
	,	NR			INT				PRIMARY KEY
	,	UR			DATETIME		NOT NULL
	)
END
GO

IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'NAUCZYCIEL'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Nauczyciel
	(	IMIE		NVARCHAR(15)	NOT NULL
	,	NAZWISKO	NVARCHAR(25)	NOT NULL
	,	ID			INT				IDENTITY PRIMARY KEY
	)
END
GO

IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'PRZEDMIOT'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Przedmiot
	(	NAZWA		NVARCHAR(15)	NOT NULL
	,	ID			INT				IDENTITY PRIMARY KEY
	)
END
GO

IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'ROK_SZKOLNY'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Rok_szkolny
	(	KOD_ROKU_SZKOLNEGO	NVARCHAR(5)	NOT NULL PRIMARY KEY
	,	POCZATEK			DATETIME		NOT NULL
	,	KONIEC				DATETIME		NOT NULL
	)
END
GO

IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'OCENA_SLOWNIK'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Ocena_slownik
	(	WARTOSC			INT		 NOT NULL	PRIMARY KEY
	,	NAZWA		NVARCHAR(15)	NOT NULL
	)
	INSERT INTO Ocena_slownik
	(	WARTOSC
	,	NAZWA
	) VALUES
	(	1,	'Niedostateczny'),
	(	2,	'Dopuszczaj¹cy'),
	(	3,	'Dostateczny'),
	(	4,	'Dobry'),
	(	5,	'Bardzo dobry'),
	(	6,	'Celuj¹cy');
END
GO

IF NOT EXISTS ( SELECT 1  FROM sysobjects  o WHERE o.[name] = 'OCENA'
	AND (OBJECTPROPERTY(o.[ID], 'IsUserTable') = 1)  
)
BEGIN
	CREATE TABLE dbo.Ocena
	(	ID			INT		 IDENTITY PRIMARY KEY
	,	OCENA		INT	NOT NULL
	,	PIERWOTNA_OCENA	INT
	,	NR_UCZEN	INT		NOT NULL	
	,	ID_NAUCZYCIEL	INT	NOT NULL	
	,	ID_PRZEDMIOT	INT	NOT NULL	
	,	ROK_SZKOLNY		nvarchar(5)		NOT NULL
	,	CONSTRAINT FK_OCENA_NAZWA FOREIGN KEY (OCENA) REFERENCES Ocena_slownik (WARTOSC)
	,	CONSTRAINT FK_ROK_SZKOLNY FOREIGN KEY (ROK_SZKOLNY) REFERENCES Rok_szkolny (KOD_ROKU_SZKOLNEGO)
	,	CONSTRAINT FK_OCENA_UCZEN FOREIGN KEY (NR_UCZEN) REFERENCES Uczen (NR)
	,	CONSTRAINT FK_OCENA_NAUCZYCIEL FOREIGN KEY (ID_NAUCZYCIEL) REFERENCES Nauczyciel (ID)
	,	CONSTRAINT FK_OCENA_PRZEDMIOT FOREIGN KEY (ID_PRZEDMIOT) REFERENCES Przedmiot (ID)
	)
END
GO


/* procedura który tworzy pust¹ procedure o zadanej nazwie */
IF NOT EXISTS 
(	SELECT 1 
		FROM sysobjects o 
		WHERE	(o.name = 'create_empty_proc')
		AND		(OBJECTPROPERTY(o.[ID], N'IsProcedure') = 1)
)
BEGIN
	DECLARE @sql nvarchar(500)
	SET @sql = 'CREATE PROCEDURE dbo.create_empty_proc AS '
	EXEC sp_sqlexec @sql
END
GO

ALTER PROCEDURE dbo.create_empty_proc (@proc_name nvarchar(100))
AS
	IF NOT EXISTS 
	(	SELECT 1 
		FROM sysobjects o 
		WHERE	(o.name = @proc_name)
		AND		(OBJECTPROPERTY(o.[ID], N'IsProcedure') = 1)
	)
	BEGIN
		DECLARE @sql nvarchar(500)
		SET @sql = 'CREATE PROCEDURE dbo.' + @proc_name + N' AS '
		EXEC sp_sqlexec @sql
	END
GO

/* procedura który tworzy pust¹ funkcjê o zadanej nazwie */
EXEC dbo.create_empty_proc @proc_name = 'create_empty_fun'
GO

ALTER PROCEDURE dbo.create_empty_fun (@fun_name nvarchar(100))
AS
	IF NOT EXISTS 
	(	SELECT 1 
		FROM sysobjects o 
		WHERE	(o.name = @fun_name)
		AND		(OBJECTPROPERTY(o.[ID], N'IsScalarFunction') = 1)
	)
	BEGIN
		DECLARE @sql nvarchar(500)
		SET @sql = 'CREATE FUNCTION dbo.' + @fun_name + N' () returns money AS begin return 0 end '
		EXEC sp_sqlexec @sql
	END
GO

/* funkcja która sprawdza poprawnoœæ roku szkolnego*/
EXEC dbo.create_empty_fun 'rok_szkolny_check'
GO

ALTER FUNCTION dbo.rok_szkolny_check(@txt NVARCHAR(5))
RETURNS INT
AS
BEGIN
    DECLARE @isValid INT = 0;

	IF LEN(@txt) != 5
		SET @isValid = 0;
	ELSE IF NOT @txt LIKE '__/__'
		SET @isValid = 0;
	ELSE
    BEGIN
        DECLARE @rok_start INT;
        DECLARE @rok_end INT;

        SELECT 
            @rok_start = 2000 + CONVERT(INT, LEFT(@txt, 2)),
            @rok_end = 2000 + CONVERT(INT, RIGHT(@txt, 2));

        IF (@rok_end - @rok_start) = 1
            SET @isValid = 1;
        ELSE
            SET @isValid = 0;
    END

    RETURN @isValid;
END;
GO

/* funkcja która zamienia wpisan¹ ocenê na pojedyncz¹ wartoœæ */
EXEC dbo.create_empty_fun 'txt2ocena'
GO

ALTER FUNCTION dbo.txt2ocena(@txt nvarchar(3) )
/*
SELECT dbo.txt2ocena(N'3,0'); -- 3
SELECT dbo.txt2ocena(N'3.0'); -- 3
SELECT dbo.txt2ocena(N'3');   -- 3
*/
RETURNS INT
AS
BEGIN
	SET @txt = REPLACE(@txt, N',', N'.');
	DECLARE @result INT;
	SET @result = CAST(CAST(@txt as FLOAT) as INT);
	RETURN @result;
END;
GO

/* funkcja do konwersji daty z txt na datatype albo null */
EXEC dbo.create_empty_fun 'txt2data'
GO

ALTER FUNCTION dbo.txt2data(@txt NVARCHAR(10))
RETURNS DATETIME
AS
BEGIN
    DECLARE @result DATETIME;
    DECLARE @cleanTxt NVARCHAR(10);

    -- Usuñ wszystkie myœlniki i ukoœniki przed sprawdzeniem formatu
    SET @cleanTxt = REPLACE(REPLACE(REPLACE(REPLACE(@txt, '.', ''), '-', ''), ',', ''), '/', '');
    -- SprawdŸ, czy format jest w postaci yyyymmdd
    IF @cleanTxt LIKE N'[1-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]'
    BEGIN
        SET @result = CONVERT(DATETIME, @cleanTxt, 112) -- ISO format yyyymmdd
    END
    -- SprawdŸ, czy format jest w postaci ddmmyyyy po usuniêciu separatorów
    ELSE IF @cleanTxt LIKE N'[0-3][0-9][0-1][0-9][1-2][0-9][0-9][0-9]'
    BEGIN
        -- Konwertuj format ddmmyyyy na datê
        SET @result = CONVERT(DATETIME, 
                              SUBSTRING(@cleanTxt, 5, 4) + '-' + -- Year
                              SUBSTRING(@cleanTxt, 3, 2) + '-' + -- Month
                              SUBSTRING(@cleanTxt, 1, 2),        -- Day
                              120) -- Standard format yyyy-mm-dd
    END
    ELSE
        SET @result = NULL; -- Jeœli format nadal nie pasuje, zwróæ NULL

    RETURN @result;
END;
GO

/* funkcja do sprawdzania poprawnoœci pliku uczniowie
** loguje wszyskie b³êdy jakie znajdzie */
EXEC dbo.create_empty_proc @proc_name = 'tmp_uczniowie_check'
GO

ALTER PROCEDURE dbo.tmp_uczniowie_check(@err int = 0 OUTPUT)
AS
BEGIN
    DECLARE @cnt INT, @en NVARCHAR(100), @id_en INT, @enc NVARCHAR(100)

    SET @err = 0
    SET @en = 'B³¹d w procedurze: Uczen_n_process / '

    /* czy s¹ dane? */
    SELECT @cnt = COUNT(*) FROM tmp_uczniowie
    IF @cnt = 0
    BEGIN
        SET @enc = @en + 'Plik z list¹ uczniów PUSTY!'
        INSERT INTO ELOG_N(opis_n) VALUES (@enc)
        SET @id_en = SCOPE_IDENTITY()
        INSERT INTO ELOG_D(id_elog_n, opis_d) VALUES (@id_en, '0 wierszy w tmp_uczniowie')
        RAISERROR(@en, 16, 4)
        SET @err = 1
    END

    /* czy numery legitymacji siê nie powtarzaj¹? */
    IF (SELECT COUNT(*) FROM tmp_uczniowie) != (SELECT COUNT(DISTINCT nr_legitymacji) FROM tmp_uczniowie)
    BEGIN
        SET @enc = @en + 'Numery Legitymacji siê powtarzaj¹'
        INSERT INTO ELOG_N(opis_n) VALUES (@enc)
        SET @id_en = SCOPE_IDENTITY()
        INSERT INTO ELOG_D(id_elog_n, opis_d)
        SELECT DISTINCT
            @id_en, 
            N'Nr legitymacji: ' + n.nr_legitymacji + N' / Ile razy: ' + LTRIM(RTRIM(STR(x.ile_razy, 10, 0)))
        FROM tmp_uczniowie n
        JOIN (
            SELECT t.nr_legitymacji, COUNT(t.nr_legitymacji) AS ile_razy
            FROM tmp_uczniowie t
            GROUP BY t.nr_legitymacji
            HAVING COUNT(t.nr_legitymacji) > 1
        ) x ON (x.nr_legitymacji = n.nr_legitymacji);
        RAISERROR(@en, 16, 4)
        SET @err = 1
    END

	/* Czy numery legitymacji z tmp_uczniowie ju¿ istniej¹ w tabeli Uczen? */
	IF EXISTS (
		SELECT 1
		FROM tmp_uczniowie tu
		INNER JOIN Uczen u ON tu.nr_legitymacji = u.nr
	)
	BEGIN
		SET @enc = @en + 'Numery Legitymacji siê powtarzaj¹ w tabeli Uczen'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
		SELECT DISTINCT
			@id_en, 
			N'Nr legitymacji: ' + tu.nr_legitymacji + N' / Ile razy w Uczen: ' + LTRIM(RTRIM(STR(COUNT(u.nr), 10, 0)))
		FROM tmp_uczniowie tu
		JOIN Uczen u ON tu.nr_legitymacji = u.nr
		GROUP BY tu.nr_legitymacji
		HAVING COUNT(u.nr) > 0

		RAISERROR(@en, 16, 1)
		SET @err = 1
	END

    /* czy datê urodzenia mo¿na poprawnie skonwertowaæ? */
    SELECT @cnt = COUNT(*)
    FROM tmp_uczniowie
    WHERE dbo.txt2data(data_ur) IS NULL;

    IF @cnt > 0
    BEGIN
        SET @enc = @en + 'B³¹d w konwercji daty'
        INSERT INTO ELOG_N(opis_n) VALUES (@enc)
        SET @id_en = SCOPE_IDENTITY()
        INSERT INTO ELOG_D(id_elog_n, opis_d)
        SELECT @id_en, N'Nr legitymacji z b³êdn¹ konwersj¹ daty: ' + n.nr_legitymacji
        FROM tmp_uczniowie n
        WHERE dbo.txt2data(data_ur) IS NULL;
        RAISERROR(@en, 16, 4)
        SET @err = 1
    END

    IF @err != 0
        RETURN -1
    ELSE
        RETURN 0
END
GO

/* funkcja do sprawdzania poprawnoœci pliku oceny
** loguje wszyskie b³êdy jakie znajdzie */
EXEC dbo.create_empty_proc @proc_name = 'tmp_oceny_check'
GO

ALTER PROCEDURE dbo.tmp_oceny_check(@err int = 0 OUTPUT)
AS
	--EXEC dbo.tmp_uczniowie_check @err = @err OUTPUT
	
BEGIN
    DECLARE @cnt INT, @en NVARCHAR(100), @id_en INT, @enc NVARCHAR(100)
	SET @en = 'B³¹d w procedurze: tmp_ocena_chack / '

	/* czy s¹ dane? */
    SELECT @cnt = COUNT(*) FROM tmp_oceny
    IF @cnt = 0
    BEGIN
        SET @enc = @en + 'Plik z list¹ ocen PUSTY!'
        INSERT INTO ELOG_N(opis_n) VALUES (@enc)
        SET @id_en = SCOPE_IDENTITY()
        INSERT INTO ELOG_D(id_elog_n, opis_d) VALUES (@id_en, '0 wierszy w tmp_oceny')
        RAISERROR(@en, 16, 4)
        SET @err = 1
    END

	/* czy przekonwertowana ocena nael¿y 1-6 */
	SELECT @cnt = COUNT(*) FROM tmp_oceny WHERE dbo.txt2ocena(ocena) BETWEEN 1 AND 6

	IF @cnt != (SELECT COUNT(*) FROM tmp_oceny)
	BEGIN
		SET @enc = @en + 'Ocena z poza przedzia³u'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
			SELECT
				@id_en, N'Nr legitymacji z ocen¹ z poza przedzia³u: ' + n.nr_legitymacji + N', przedmiot: ' + n.przedmiot + N', ocena: ' + CONVERT(NVARCHAR(2), dbo.txt2ocena(n.ocena))
			FROM tmp_oceny n
			WHERE dbo.txt2ocena(ocena) NOT BETWEEN 1 AND 6

		RAISERROR(@en, 16, 4)
        SET @err = 1
	END

	/* czy we wszystich jest ten sam rok szkolny? */
	IF (SELECT COUNT(DISTINCT rok_sz) FROM tmp_oceny) > 1
	BEGIN
		SET @enc = @en + 'Wiêcej jak jeden rok szkolny w pliku'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
			SELECT DISTINCT @id_en, N'W pliku wystêpuje rok szkolny: '+t.rok_sz
			FROM tmp_oceny t

		RAISERROR(@en, 16, 4)
		SET @err = 1
	END

	/* czy rok szkolny jest poprawny? */
	SELECT @cnt = COUNT(*) FROM tmp_oceny
	IF @cnt != (SELECT SUM(dbo.rok_szkolny_check(rok_sz)) FROM tmp_oceny)
	BEGIN
		SET @enc = @en + 'B³êdny rok szkolny'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
			SELECT @id_en, N'Nipoprawny rok szkolny: '+t.rok_sz
			FROM tmp_oceny t
			WHERE dbo.rok_szkolny_check(t.rok_sz) = 0

		RAISERROR(@en, 16, 4)
		SET @err = 1
	END

	/* czy nr_legitymacji nale¿y do którego z uczniów? */
	SELECT @cnt = COUNT(*)
	FROM tmp_oceny t
	LEFT JOIN (
		SELECT nr_legitymacji FROM tmp_uczniowie
		UNION
		SELECT nr FROM Uczen
	) AS all_students ON t.nr_legitymacji = all_students.nr_legitymacji
	WHERE all_students.nr_legitymacji IS NULL;

	IF @cnt > 0
	BEGIN
		SET @enc = @en + 'Nie ma ucznia do którego nale¿y ocena'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
			SELECT @id_en, N'Nr legitymacji który nie nale¿y do ¿adnego ucznia: '+t.nr_legitymacji
			FROM tmp_oceny t
			LEFT JOIN (
				SELECT nr_legitymacji FROM tmp_uczniowie
				UNION
				SELECT nr FROM Uczen
			) AS all_students ON t.nr_legitymacji = all_students.nr_legitymacji
			WHERE all_students.nr_legitymacji IS NULL;
		
		RAISERROR(@en, 16, 4)
		SET @err = 1
	END

	/* czy uczeñ ma dwie oceny z tego samego pzedmiotu? */
	SELECT @cnt = COUNT(*)
	FROM (
		SELECT nr_legitymacji, przedmiot
		FROM tmp_oceny
		GROUP BY nr_legitymacji, przedmiot
		HAVING COUNT(*) > 1
	) AS DuplicatedPairs

	IF @cnt > 0
	BEGIN
		SET @enc = @en + 'Uczeñ ma wiêcej ni¿ jedn¹ ocenê z tego samego przedmiotu'
		INSERT INTO ELOG_N(opis_n) VALUES (@enc)
		SET @id_en = SCOPE_IDENTITY()

		INSERT INTO ELOG_D(id_elog_n, opis_d)
			SELECT @id_en, N'Nr legitymacji Ucznia: '+t.nr_legitymacji + N', powtarzaj¹cy siê przedmiot: ' + t.przedmiot
			FROM tmp_oceny t
			GROUP BY t.nr_legitymacji, t.przedmiot
			HAVING COUNT(*) > 1;
		
		RAISERROR(@en, 16, 4)
		SET @err = 1
	END

	IF @err != 0
        RETURN -1
    ELSE
        RETURN 0
END;
GO

/* procedura przenosz¹ca dane z tabel tmp do tabel s³ownikowych */
EXEC dbo.create_empty_proc @proc_name = 'move_to_dict_table'
GO

ALTER PROCEDURE dbo.move_to_dict_table(@err int = 0 OUTPUT)
AS
BEGIN
	/* dodanie nowych uczniów */
	INSERT INTO Uczen (IMIE, NAZWISKO, NR, UR)
	SELECT DISTINCT t.imie, t.nazwisko, t.nr_legitymacji, dbo.txt2data(t.data_ur)
		FROM tmp_uczniowie t
		WHERE NOT EXISTS
		( SELECT *
			FROM Uczen u
			WHERE	(t.imie = u.IMIE)
			AND		(t.nazwisko = u.NAZWISKO)
			AND		(t.nr_legitymacji = u.NR)
			AND		(dbo.txt2data(t.data_ur) = u.UR)
		);

	/* dodanie nowych nauczycieli */
	INSERT INTO Nauczyciel(IMIE, NAZWISKO)
	SELECT DISTINCT t.imie_n, t.nazwisko_n
		FROM tmp_oceny t
		WHERE NOT EXISTS
		( SELECT *
			FROM Nauczyciel n
			WHERE	(t.imie_n = n.IMIE)
			AND		(t.nazwisko_n = n.NAZWISKO)
		);

	/* dodanie nowych przedmiotów */
	INSERT INTO Przedmiot (NAZWA)
	SELECT DISTINCT t.przedmiot
		FROM tmp_oceny t
		WHERE NOT EXISTS
		( SELECT *
			FROM Przedmiot p
			WHERE t.przedmiot = p.NAZWA
		)

	/* dodanie roku szkolnego */
	INSERT INTO dbo.Rok_szkolny (KOD_ROKU_SZKOLNEGO, POCZATEK, KONIEC)
	SELECT 
		DISTINCT rok_sz AS KOD_ROKU_SZKOLNEGO,
		-- Przekszta³cenie kodu roku szkolnego na datê pocz¹tkow¹ (1 wrzeœnia)
		CONVERT(DATETIME, '01-SEP-' + SUBSTRING(rok_sz, 1, 2)) AS POCZATEK,
		-- Przekszta³cenie kodu roku szkolnego na datê koñcow¹ (30 czerwca nastêpnego roku)
		CONVERT(DATETIME, '30-JUN-' + SUBSTRING(rok_sz, 4, 5)) AS KONIEC
	FROM tmp_oceny
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.Rok_szkolny r
		WHERE r.KOD_ROKU_SZKOLNEGO = tmp_oceny.rok_sz
	);
END
GO

/* Procedura do przenoszenia z tabeli tmp do tabeli oceny i zaci¹gniêcie relacji ze s³owników */
EXEC dbo.create_empty_proc @proc_name = 'move_to_grade_table'
GO

ALTER PROCEDURE dbo.move_to_grade_table(@err int = 0 OUTPUT)
AS
BEGIN
	MERGE INTO ocena AS o
	USING (
		SELECT
			t.ocena,
			p.ID AS id_przedmiotu,
			u.nr AS nr_uczen,
			n.id AS id_nauczyciel,
			r.kod_roku_szkolnego AS rok_szkolny
		FROM
			tmp_oceny t
		JOIN uczen u ON t.nr_legitymacji = u.nr
		JOIN nauczyciel n ON t.imie_n = n.imie AND t.nazwisko_n = n.nazwisko
		JOIN rok_szkolny r ON t.rok_sz = r.kod_roku_szkolnego
		JOIN przedmiot p ON t.przedmiot = p.nazwa
	) AS source
	ON
		o.nr_uczen = source.nr_uczen AND
		o.id_przedmiot = source.id_przedmiotu AND
		o.rok_szkolny = source.rok_szkolny
	WHEN MATCHED THEN
		UPDATE SET
			o.pierwotna_ocena = CASE
				WHEN o.pierwotna_ocena IS NULL THEN o.ocena
				ELSE o.pierwotna_ocena
			END,
			o.ocena = source.ocena
	WHEN NOT MATCHED THEN
		INSERT (ocena, nr_uczen, id_nauczyciel, id_przedmiot, rok_szkolny)
		VALUES (source.ocena, source.nr_uczen, source.id_nauczyciel, source.id_przedmiotu, source.rok_szkolny);
END;
GO

/* Funkcje pomocnicze do tworzenia danych na kszta³t json */
EXEC dbo.create_empty_fun @fun_name = 'JsonValue'
GO

ALTER FUNCTION dbo.JsonValue ( 
    @key NVARCHAR(MAX), 
    @value NVARCHAR(MAX)
	)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @json NVARCHAR(MAX)
    SET @json = '"' + REPLACE(@key, '"', '\"') + '": "' + REPLACE(@value, '"', '\"') + '"'
    RETURN @json
END
GO

EXEC dbo.create_empty_fun @fun_name = 'JsonObject'
GO

ALTER FUNCTION dbo.JsonObject (
	@jsonPairs NVARCHAR(MAX)
	)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN '{' + @jsonPairs + '}'
END
GO

/* Procedura zwracaj¹ca plik JSON z oceami dla uczniów za konkretny rok skzolny */
EXEC dbo.create_empty_proc @proc_name = 'get_json_for_year';
GO

ALTER PROCEDURE dbo.get_json_for_year(@rs NVARCHAR(5))
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @json NVARCHAR(MAX) = '';
    DECLARE @studentJson NVARCHAR(MAX) = '';
    DECLARE @gradeJson NVARCHAR(MAX) = '';
    DECLARE @first BIT = 1;
    DECLARE @firstGrade BIT;
    DECLARE @name NVARCHAR(MAX);
    DECLARE @surname NVARCHAR(MAX);
    DECLARE @birthdate VARCHAR(10);
    DECLARE @id NVARCHAR(MAX);

    -- Start the JSON output
    SELECT @json = dbo.JsonObject(
        dbo.JsonValue('rok_szkolny', kod_roku_szkolnego) + ',' +
        dbo.JsonValue('data_rozpoczecia', CONVERT(VARCHAR, poczatek, 105)) + ',' +
        dbo.JsonValue('data_zakonczenia', CONVERT(VARCHAR, koniec, 105))
    )
    FROM rok_szkolny
    WHERE kod_roku_szkolnego = @rs;

    -- Remove the closing brace to add students
    SET @json = LEFT(@json, LEN(@json) - 1) + ',"uczniowie": [';

    -- Loop through students that have grades
    DECLARE student_cursor CURSOR FOR
        SELECT DISTINCT u.imie, u.nazwisko, CONVERT(VARCHAR, u.ur, 105), u.nr
        FROM Uczen u
        JOIN ocena o ON u.nr = o.nr_uczen
        WHERE EXISTS (
            SELECT 1
            FROM ocena
            WHERE nr_uczen = u.nr
            AND Rok_szkolny = @rs
        );

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @name, @surname, @birthdate, @id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @firstGrade = 1;
        SET @gradeJson = '';

        -- Fetch grades for current student
        SELECT @gradeJson += CASE WHEN @firstGrade = 1 THEN '' ELSE ',' END +
            dbo.JsonObject(
                dbo.JsonValue('ocena', CONVERT(VARCHAR, ocena)) + ',' +
                dbo.JsonValue('ocena_slownie', ocena_slownie) + ',' +
                dbo.JsonValue('pierwotna_ocena', ISNULL(CONVERT(VARCHAR, pierwotna_ocena), 'null')) + ',' +
                dbo.JsonValue('przedmiot', przedmiot) + ',' +
                dbo.JsonValue('nauczyciel', nauczyciel)
            ),
            @firstGrade = 0
        FROM (
            SELECT o.ocena, os.nazwa as ocena_slownie, o.pierwotna_ocena, p.nazwa as przedmiot, n.imie + ' ' + n.nazwisko as nauczyciel
            FROM ocena o
            JOIN nauczyciel n ON o.id_nauczyciel = n.id
            JOIN przedmiot p ON o.id_przedmiot = p.id
            JOIN ocena_slownik os ON o.ocena = os.wartosc
            WHERE o.nr_uczen = @id
            AND o.ROK_SZKOLNY = @rs
        ) as grades;

        -- Append student JSON
        IF @gradeJson != ''
        BEGIN
            SET @studentJson += CASE WHEN @first = 1 THEN '' ELSE ',' END +
                dbo.JsonObject(
                    dbo.JsonValue('uczen', @name + ' ' + @surname) + ',' +
                    dbo.JsonValue('data_urodzenia', @birthdate) + ',' +
                    dbo.JsonValue('nr_legitymacji', @id) + ',' +
                    '"oceny": [' + @gradeJson + ']'
                );
            SET @first = 0;
        END

        FETCH NEXT FROM student_cursor INTO @name, @surname, @birthdate, @id;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    -- Close the students array and the whole JSON object
    SET @json += @studentJson + ']}';

    -- Return the JSON result
    SELECT @json AS JsonOutput;
END;
GO

/***********************************************************************************************************
********************************************* DANE TESTOWE *************************************************
***********************************************************************************************************/

INSERT INTO dbo.tmp_uczniowie (imie, nazwisko, nr_legitymacji, data_ur)
VALUES
	('Tomasz', 'Kowalski', '313565', '28.01.2009'),
	('Jan', 'Nowak', '302648', '20-05-2009'),
	('Piotr', 'Lewandowski', '310013', '20090411');

INSERT INTO tmp_oceny(ocena, przedmiot, rok_sz, nr_legitymacji, imie_n, nazwisko_n)
VALUES
('4',	'Przyroda',	'22/23',	'313565',	'Anna',	'Graba'),
('6',	'WF',	'22/23',	'313565',	'Piotr',	'Januchta'),
('5',	'Matematyka',	'22/23',	'313565',	'Tadeusz',	'Miko³ajuk'),
('4',	'WF',	'22/23',	'302648',	'Piotr',	'Januchta'),
('4',	'Przyroda',	'22/23',	'302648',	'Anna',	'Graba'),
('3',	'Matematyka',	'22/23',	'302648',	'Tadeusz',	'Miko³ajuk'),
('4',	'WF',	'22/23',	'310013',	'Piotr',	'Januchta'),
('6',	'Przyroda',	'22/23',	'310013',	'Aleksandra',	'Wróblewska'),
('2',	'Historia',	'22/23',	'310013',	'Piotr',	'Borowik');

select * from tmp_uczniowie
select * from tmp_oceny

-- sprawdzenie dzi¹³ania
EXEC dbo.tmp_uczniowie_check
EXEC dbo.tmp_oceny_check
EXEC dbo.move_to_dict_table
EXEC dbo.move_to_grade_table

select * from uczen
select * from Nauczyciel
select * from Przedmiot
select * from Rok_szkolny
select * from Ocena

select * from ELOG_N
select * from ELOG_D

-- Procedura zwracaj¹ca JSON
EXEC dbo.get_json_for_year @rs = '22/23'
