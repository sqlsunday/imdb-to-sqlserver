
--- Principals
---------------------------------------

INSERT INTO dbo.Principals WITH (TABLOCKX, HOLDLOCK) (principalId, primaryName, birthYear, deathYear)
SELECT CAST(SUBSTRING(nameId, 3, 100) AS int) AS principalId, primaryName,
       DATEFROMPARTS(birthYear, 1, 1), DATEFROMPARTS(deathYear, 12, 31)
FROM [Raw].[name.basics.tsv.gz];

--- Professions
---------------------------------------

INSERT INTO dbo.Professions WITH (TABLOCKX, HOLDLOCK) (professionId, profession)
SELECT DISTINCT ABS(CHECKSUM(p.[value]))%10000 AS professionId, UPPER(LEFT(p.[value], 1))+SUBSTRING(REPLACE(p.[value], N'_', N' '), 2, 100) AS profession
FROM [Raw].[name.basics.tsv.gz] AS n
CROSS APPLY STRING_SPLIT(n.primaryProfession, N',') AS p
WHERE p.[value]!=''
UNION
SELECT DISTINCT ABS(CHECKSUM(category))%10000 AS professionId,
       UPPER(LEFT(category, 1))+SUBSTRING(REPLACE(category, N'_', N' '), 2, 100)
FROM [Raw].[title.principals.tsv.gz]
WHERE category!=N'';

--- Primary professions
---------------------------------------

INSERT INTO dbo.PrimaryProfessions WITH (TABLOCKX, HOLDLOCK) (principalId, professionId, ordinal)
SELECT CAST(SUBSTRING(n.nameId, 3, 100) AS int) AS principalId, ABS(CHECKSUM(p.[value]))%10000 AS professionId, p.ordinal
FROM [Raw].[name.basics.tsv.gz] AS n
CROSS APPLY STRING_SPLIT(n.primaryProfession, N',', 1) AS p
WHERE p.[value]!='';

--- Genres
---------------------------------------

INSERT INTO dbo.Genres WITH (TABLOCKX, HOLDLOCK) (genreId, genre)
SELECT DISTINCT ABS(CHECKSUM(p.[value]))%32000 AS genreId, UPPER(LEFT(p.[value], 1))+SUBSTRING(REPLACE(p.[value], '_', ' '), 2, 100) AS genre
FROM [Raw].[title.basics.tsv.gz] AS t
CROSS APPLY STRING_SPLIT(t.genres, ',') AS p
WHERE p.[value]!='';

--- Title types
---------------------------------------

INSERT INTO dbo.TitleTypes WITH (TABLOCKX, HOLDLOCK) (titleTypeId, titleType)
SELECT DISTINCT ABS(CHECKSUM(titleType))%100 AS titleTypeId, titleType
FROM [Raw].[title.basics.tsv.gz];

--- Titles
---------------------------------------

INSERT INTO dbo.Titles WITH (TABLOCKX, HOLDLOCK) (titleId, titleTypeId, isAdult, startYear, endYear, runtime)
SELECT CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       ABS(CHECKSUM(titleType))%100 AS titleTypeId,
       isAdult,
       DATEFROMPARTS(startYear, 1, 1), DATEFROMPARTS(endYear, 12, 31),
       DATEADD(minute, runtimeMinutes, CAST('00:00' AS time(0))) AS runtime
FROM [Raw].[title.basics.tsv.gz];


--- Data inconsistency:
---
--- Some titles only exist in the "aka"
--- table.
---------------------------------------

INSERT INTO dbo.TitleTypes (titleTypeId, titleType)
VALUES (0, 'Unknown');

INSERT INTO dbo.Titles WITH (TABLOCKX, HOLDLOCK) (titleId, titleTypeId, isAdult)
SELECT TOP (1) WITH TIES
       CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       0 AS titleTypeId, 0 AS isAdult
FROM [Raw].[title.akas.tsv.gz]
WHERE titleId NOT IN (SELECT titleId FROM [Raw].[title.basics.tsv.gz])
ORDER BY ROW_NUMBER() OVER (PARTITION BY titleId ORDER BY isOriginalTitle DESC, ordering);

--- Title genres
---------------------------------------

INSERT INTO dbo.TitleGenres WITH (TABLOCKX, HOLDLOCK) (titleId, genreId)
SELECT CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       ABS(CHECKSUM(p.[value]))%32000 AS genreId
FROM [Raw].[title.basics.tsv.gz] AS t
CROSS APPLY STRING_SPLIT(t.genres, ',') AS p
WHERE p.[value]!='';

INSERT INTO dbo.TitleNames WITH (TABLOCKX, HOLDLOCK) (titleId, ordinal, region, [language], isOriginal, title)
SELECT CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       ordering AS ordinal, region, [language],
       (CASE WHEN ordering=MIN((CASE WHEN ISNULL(isOriginalTitle, 1)=1 THEN ordering END)) OVER (PARTITION BY titleId) THEN 1 ELSE 0 END) AS isOriginal,
       title
FROM [Raw].[title.akas.tsv.gz];

--- Attributes: title attribute
---------------------------------------

INSERT INTO dbo.Attributes WITH (TABLOCKX, HOLDLOCK) (attributeId, class, attribute)
SELECT DISTINCT DENSE_RANK() OVER (ORDER BY (SELECT a.[value])) AS attributeId,
       'Title attribute' AS class, a.[value] AS attribute
FROM [Raw].[title.akas.tsv.gz] AS aka
CROSS APPLY STRING_SPLIT(aka.attributes, CHAR(2)) AS a
WHERE a.[value]!='';

INSERT INTO dbo.TitleNameAttributes WITH (TABLOCKX, HOLDLOCK) (titleId, ordinal, attributeId)
SELECT DISTINCT CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       aka.ordering AS ordinal,
       attr.attributeId
FROM [Raw].[title.akas.tsv.gz] AS aka
CROSS APPLY STRING_SPLIT(aka.attributes, CHAR(2)) AS a
INNER JOIN dbo.Attributes AS attr ON attr.class='Title attribute' AND attr.attribute=a.[value];

--- Attributes: Title types
---------------------------------------

INSERT INTO dbo.Attributes WITH (TABLOCKX, HOLDLOCK) (attributeId, class, attribute)
SELECT DISTINCT (SELECT MAX(attributeId) FROM dbo.Attributes)+
       DENSE_RANK() OVER (ORDER BY (SELECT a.[value])) AS attributeId,
       'Title types' AS class, a.[value] AS attribute
FROM [Raw].[title.akas.tsv.gz] AS aka
CROSS APPLY STRING_SPLIT(aka.[types], CHAR(2)) AS a
WHERE a.[value] NOT IN ('imdbDisplay', 'original');

INSERT INTO dbo.TitleNameAttributes WITH (TABLOCKX, HOLDLOCK) (titleId, ordinal, attributeId)
SELECT DISTINCT CAST(SUBSTRING(titleId, 3, 10) AS int) AS titleId,
       aka.ordering AS ordinal,
       attr.attributeId
FROM [Raw].[title.akas.tsv.gz] AS aka
CROSS APPLY STRING_SPLIT(aka.[types], CHAR(2)) AS a
INNER JOIN dbo.Attributes AS attr ON attr.class='Title types' AND attr.attribute=a.[value];


--- Data inconsistency:
---
--- Some titles and principals only
--- exist in the "title.principals"
--- dataset.
---------------------------------------

INSERT INTO dbo.Titles WITH (TABLOCKX, HOLDLOCK) (titleId, titleTypeId, isAdult)
SELECT DISTINCT CAST(SUBSTRING(titleId, 3, 10) AS int), 0 AS titleTypeId, 0 AS isAdult
FROM [Raw].[title.principals.tsv.gz]
WHERE CAST(SUBSTRING(titleId, 3, 10) AS int) NOT IN (SELECT titleId FROM dbo.Titles);

INSERT INTO dbo.Principals WITH (TABLOCKX, HOLDLOCK) (principalId, primaryName)
SELECT DISTINCT CAST(SUBSTRING(nameId, 3, 10) AS int) AS principalId, N'Unknown' AS primaryName
FROM [Raw].[title.principals.tsv.gz]
WHERE CAST(SUBSTRING(nameId, 3, 10) AS int) NOT IN (SELECT principalId FROM dbo.Principals);

--- Title principals
---------------------------------------

INSERT INTO dbo.TitlePrincipals WITH (TABLOCKX, HOLDLOCK) (titleId, ordinal, principalId, professionId)
SELECT CAST(SUBSTRING(tp.titleId, 3, 10) AS int) AS titleId,
       tp.ordering AS ordinal,
       CAST(SUBSTRING(tp.nameId, 3, 10) AS int) AS principalId,
       ABS(CHECKSUM(tp.category))%10000 AS professionId
FROM [Raw].[title.principals.tsv.gz] AS tp;

--- Principals "known for" titles
---------------------------------------

UPDATE tp
SET tp.knownForOrdinal=k.ordinal
FROM [Raw].[name.basics.tsv.gz] AS n
CROSS APPLY STRING_SPLIT(n.knownForTitles, ',', 1) AS k
INNER JOIN dbo.TitlePrincipals AS tp WITH (TABLOCKX, HOLDLOCK) ON
    CAST(SUBSTRING(n.nameId, 3, 10) AS int)=tp.PrincipalId AND
    CAST(SUBSTRING(k.[value], 3, 10) AS int)=tp.TitleId
WHERE k.[value]!='';

--- Title characters
---------------------------------------

INSERT INTO dbo.TitleCharacters WITH (TABLOCKX, HOLDLOCK) (titleId, principalId, [character])
SELECT CAST(SUBSTRING(tp.titleId, 3, 10) AS int) AS titleId,
       CAST(SUBSTRING(tp.nameId, 3, 10) AS int) AS principalId,
       ch.[value] AS [character]
FROM [Raw].[title.principals.tsv.gz] AS tp
CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(SUBSTRING(tp.[characters], 3, LEN(tp.[characters])-4), N'","', NCHAR(9)), N'\"', N'"'), NCHAR(9)) AS ch;

--- Directors and writers
--- (there's a slight overlap with the
--- title principals here)
---------------------------------------

SELECT t.titleId,
       x.principalId,
       x.professionId
INTO #writers_directors
FROM [Raw].[title.crew.tsv.gz] AS tc
CROSS APPLY (
    VALUES (CAST(SUBSTRING(tc.titleId, 3, 10) AS int))
    ) AS t(titleId)
CROSS APPLY (
        SELECT CAST(SUBSTRING(p.[value], 3, 10) AS int) AS principalId, ABS(CHECKSUM('director'))%10000 AS professionId
        FROM STRING_SPLIT(tc.directors, ',') AS p
        WHERE tc.directors!=''
    UNION
        SELECT CAST(SUBSTRING(w.[value], 3, 10) AS int) AS principalId, ABS(CHECKSUM('writer'))%10000 AS professionId
        FROM STRING_SPLIT(tc.writers, ',') AS w
        WHERE tc.writers!=''
    ) AS x
LEFT JOIN dbo.TitlePrincipals AS tp ON
    tp.titleId=CAST(SUBSTRING(tc.titleId, 3, 10) AS int) AND
    tp.principalId=x.principalId
WHERE tp.titleId IS NULL;


--- Data inconsistency:
---

--- Some of these titles and principals
--- are not in their proper respective
--- datasets.
---------------------------------------

INSERT INTO dbo.Titles WITH (TABLOCKX, HOLDLOCK) (titleId, titleTypeId, isAdult)
SELECT DISTINCT titleId, 0 AS titleTypeId, 0 AS isAdult
FROM #writers_directors
WHERE titleId NOT IN (SELECT titleId FROM dbo.Titles);

INSERT INTO dbo.Principals WITH (TABLOCKX, HOLDLOCK) (principalId, primaryName)
SELECT DISTINCT principalId, N'Unknown' AS primaryName
FROM #writers_directors
WHERE principalId NOT IN (SELECT principalId FROM dbo.Principals);

--- ... and the actual title principals
---------------------------------------

INSERT INTO dbo.TitlePrincipals WITH (TABLOCKX, HOLDLOCK) (titleId, ordinal, principalId, professionId)
SELECT x.titleId,
       ISNULL(o.ordinal, 0)+ROW_NUMBER() OVER (PARTITION BY x.titleId ORDER BY x.professionId, x.principalId) AS ordinal,
       x.principalId,
       x.professionId
FROM #writers_directors AS x
LEFT JOIN (
    SELECT titleId, MAX(ordinal) AS ordinal
    FROM dbo.TitlePrincipals
    GROUP BY titleId
    ) AS o ON x.titleId=o.titleId;

DROP TABLE #writers_directors;


--- Epidodes
---------------------------------------


INSERT INTO dbo.Episodes WITH (TABLOCKX, HOLDLOCK) (parentId, episodeId, season, episode)
SELECT CAST(SUBSTRING(parentTitleId, 3, 10) AS int) AS parentId,
       CAST(SUBSTRING(titleId, 3, 10) AS int) AS episodeId,
       seasonNumber AS season,
       episodeNumber AS episode
FROM [Raw].[title.episode.tsv.gz];

--- Votes and average ratings on
--- titles.
---------------------------------------

UPDATE t
SET t.voteCount=r.numVotes, t.averageRating=r.averageRating
FROM dbo.Titles AS t WITH (TABLOCKX, HOLDLOCK)
INNER JOIN [Raw].[title.ratings.tsv.gz] AS r ON t.titleId=CAST(SUBSTRING(r.titleId, 3, 10) AS int);

