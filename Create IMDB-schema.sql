CREATE SCHEMA [Raw];
GO


DROP TABLE IF EXISTS [Raw].[title.ratings.tsv.gz];
DROP TABLE IF EXISTS [Raw].[title.principals.tsv.gz];
DROP TABLE IF EXISTS [Raw].[title.episode.tsv.gz];
DROP TABLE IF EXISTS [Raw].[title.crew.tsv.gz];
DROP TABLE IF EXISTS [Raw].[title.basics.tsv.gz];
DROP TABLE IF EXISTS [Raw].[title.akas.tsv.gz];
DROP TABLE IF EXISTS [Raw].[name.basics.tsv.gz];
GO



CREATE TABLE [Raw].[title.akas.tsv.gz] (
    titleId    varchar(20), -- a titleId, an alphanumeric unique identifier of the title
    ordering    bigint, -- a number to uniquely identify rows for a given titleId
    title    nvarchar(1000), -- the localized title
    region    nvarchar(50), -- the region for this version of the title
    [language]    nvarchar(50), -- the language of the title
    [types]    varchar(500), -- Enumerated set of attributes for this alternative title. One or more of the following: "alternative", "dvd", "festival", "tv", "video", "working", "original", "imdbDisplay". New values may be added in the future without warning
    attributes    varchar(500), -- Additional terms to describe this alternative title, not enumerated
    isOriginalTitle    bit -- 0: not original title; 1: original title
) WITH (DATA_COMPRESSION=PAGE);

CREATE CLUSTERED INDEX PK ON [Raw].[title.akas.tsv.gz] (titleId) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE [Raw].[title.basics.tsv.gz] (
    titleId    varchar(20), -- alphanumeric unique identifier of the title
    titleType    nvarchar(255), -- the type/format of the title (e.g. movie, short, tvseries, tvepisode, video, etc)
    primaryTitle    nvarchar(1000), -- the more popular title / the title used by the filmmakers on promotional materials at the point of release
    originalTitle    nvarchar(1000), -- original title, in the original language
    isAdult    bit, -- 0: non-adult title; 1: adult title
    startYear    numeric(4, 0), -- represents the release year of a title. In the case of TV Series, it is the series start year
    endYear    numeric(4, 0), -- TV Series end year. ‘\N’ for all other title types
    runtimeMinutes int, -- primary runtime of the title, in minutes
    genres    nvarchar(100), -- includes up to three genres associated with the title
    CONSTRAINT [PK_title.basics.tsv.gz] PRIMARY KEY CLUSTERED (titleId) WITH (DATA_COMPRESSION=PAGE)
);

CREATE TABLE [Raw].[title.crew.tsv.gz] (
    titleId    varchar(20), -- alphanumeric unique identifier of the title
    directors varchar(max), -- director(s) of the given title
    writers varchar(max), -- writer(s) of the given title
) WITH (DATA_COMPRESSION=PAGE);

CREATE CLUSTERED INDEX PK ON [Raw].[title.crew.tsv.gz] (titleId) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE [Raw].[title.episode.tsv.gz] (
    titleId    varchar(20), -- alphanumeric identifier of episode
    parenttitleId    varchar(20), -- alphanumeric identifier of the parent TV Series
    seasonNumber    smallint, -- season number the episode belongs to
    episodeNumber    int, -- episode number of the titleId in the TV series
) WITH (DATA_COMPRESSION=PAGE);

CREATE CLUSTERED INDEX PK ON [Raw].[title.episode.tsv.gz] (titleId, seasonNumber, episodeNumber) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE [Raw].[title.principals.tsv.gz] (
    titleId    varchar(20), -- alphanumeric unique identifier of the title
    ordering    bigint, -- a number to uniquely identify rows for a given titleId
    nameId    varchar(20), -- alphanumeric unique identifier of the name/person
    category    nvarchar(255), -- the category of job that person was in
    job    nvarchar(512), -- the specific job title if applicable, else '\N'
    characters    nvarchar(max), -- the name of the character played if applicable, else '\N'
) WITH (DATA_COMPRESSION=PAGE);

CREATE CLUSTERED INDEX PK ON [Raw].[title.principals.tsv.gz] (titleId, ordering) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE [Raw].[title.ratings.tsv.gz] (
    titleId    varchar(20), -- alphanumeric unique identifier of the title
    averageRating numeric(10, 6), -- weighted average of all the individual user ratings
    numVotes bigint, -- number of votes the title has received
) WITH (DATA_COMPRESSION=PAGE);

CREATE CLUSTERED INDEX PK ON [Raw].[title.ratings.tsv.gz] (titleId) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE [Raw].[name.basics.tsv.gz] (
    nameId    varchar(20), -- alphanumeric unique identifier of the name/person
    primaryName    nvarchar(255), -- name by which the person is most often credited
    birthYear    numeric(4, 0), -- in YYYY format
    deathYear    numeric(4, 0), -- in YYYY format if applicable, else '\N'
    primaryProfession    nvarchar(100), -- the top-3 professions of the person
    knownForTitles    varchar(100), -- titles the person is known for,
    CONSTRAINT [PK_name.basics.tsv.gz] PRIMARY KEY CLUSTERED (nameId) WITH (DATA_COMPRESSION=PAGE)
);
GO













DROP TABLE IF EXISTS [dbo].[Episodes]
DROP TABLE IF EXISTS [dbo].[TitleCharacters]
DROP TABLE IF EXISTS [dbo].[TitlePrincipals]
DROP TABLE IF EXISTS [dbo].[TitleNameAttributes]
DROP TABLE IF EXISTS [dbo].[Attributes]
DROP TABLE IF EXISTS [dbo].[TitleNames]
DROP TABLE IF EXISTS [dbo].[TitleGenres]
DROP TABLE IF EXISTS [dbo].[Titles]
DROP TABLE IF EXISTS [dbo].[TitleTypes]
DROP TABLE IF EXISTS [dbo].[Genres]
DROP TABLE IF EXISTS [dbo].[PrimaryProfessions]
DROP TABLE IF EXISTS [dbo].[Professions]
DROP TABLE IF EXISTS [dbo].[Principals]
GO



CREATE TABLE dbo.Principals (
    principalId     int NOT NULL,
    primaryName     nvarchar(120) NOT NULL,
    birthYear       date NULL,
    deathYear       date NULL,
    CONSTRAINT PK_Principals PRIMARY KEY CLUSTERED (principalId) WITH (DATA_COMPRESSION=PAGE)
);

CREATE TABLE dbo.Professions (
    professionId    smallint NOT NULL,
    profession      varchar(50) NOT NULL,
    CONSTRAINT PK_Professions PRIMARY KEY CLUSTERED (professionId)
);

CREATE TABLE dbo.PrimaryProfessions (
    principalId          int NOT NULL,
    professionId    smallint NOT NULL,
    ordinal         tinyint NOT NULL,
    CONSTRAINT PK_PrimaryProfession PRIMARY KEY CLUSTERED (principalId, professionId) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_PrimaryProfession_Principal FOREIGN KEY (principalId) REFERENCES dbo.Principals (principalId),
    CONSTRAINT FK_PrimaryProfession_Profession FOREIGN KEY (professionId) REFERENCES dbo.Professions (professionId)
);

CREATE TABLE dbo.Genres (
    genreId         smallint NOT NULL,
    genre           varchar(50) NOT NULL,
    CONSTRAINT PK_Genres PRIMARY KEY CLUSTERED (genreId)
);

CREATE TABLE dbo.TitleTypes (
    titleTypeId     tinyint NOT NULL,
    titleType       varchar(100) NOT NULL,
    CONSTRAINT PK_TitleTypes PRIMARY KEY CLUSTERED (titleTypeId)
);

CREATE TABLE dbo.Titles (
    titleId         int NOT NULL,
    titleTypeId     tinyint NOT NULL,
    isAdult         bit NOT NULL,
    startYear       date NULL,
    endYear         date NULL,
    runtime         time(0) NULL,
    voteCount       int NULL,
    averageRating   numeric(4, 2) NULL,
    CONSTRAINT PK_Titles PRIMARY KEY CLUSTERED (titleId) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_Titles_TitleType FOREIGN KEY (titleTypeId) REFERENCES dbo.TitleTypes (titleTypeId)
);

CREATE TABLE dbo.TitleGenres (
    titleId         int NOT NULL,
    genreId         smallint NOT NULL,
    CONSTRAINT PK_TitleGenres PRIMARY KEY CLUSTERED (titleId, genreId) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_TitleGenres_Title FOREIGN KEY (titleId) REFERENCES dbo.Titles (titleId),
    CONSTRAINT FK_TitleGenres_Genre FOREIGN KEY (genreId) REFERENCES dbo.Genres (genreId)
);

CREATE TABLE dbo.TitleNames (
    titleId         int NOT NULL,
    ordinal         tinyint NOT NULL,
    region          varchar(5) NULL,
    [language]      varchar(5) NULL,
    isOriginal      bit NOT NULL,
    title           nvarchar(1000) NOT NULL,
    CONSTRAINT PK_TitleNames PRIMARY KEY CLUSTERED (titleId, ordinal) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_TitleNames_Title FOREIGN KEY (titleId) REFERENCES dbo.Titles (titleId)
);

CREATE UNIQUE INDEX IX_TitleNames_Original ON dbo.TitleNames (titleId)
    INCLUDE (title) WHERE (isOriginal=1) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE dbo.Attributes (
    attributeId     int NOT NULL,
    class           varchar(20) NOT NULL,
    attribute       varchar(100) NOT NULL,
    CONSTRAINT PK_Attributes PRIMARY KEY CLUSTERED (attributeId),
    CONSTRAINT UQ_Attributes UNIQUE (class, attribute)
);

CREATE TABLE dbo.TitleNameAttributes (
    titleId         int NOT NULL,
    ordinal         tinyint NOT NULL,
    attributeId     int NOT NULL,
    CONSTRAINT PK_TitleNameAttributes PRIMARY KEY CLUSTERED (titleId, ordinal, attributeId) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_TitleNameAttributes_TitleName FOREIGN KEY (titleId, ordinal) REFERENCES dbo.TitleNames (titleId, ordinal),
    CONSTRAINT FK_TitleNameAttributes_Attribute FOREIGN KEY (attributeId) REFERENCES dbo.Attributes (attributeId)
);

CREATE TABLE dbo.TitlePrincipals (
    titleId         int NOT NULL,
    ordinal         smallint NOT NULL,
    principalId     int NOT NULL,
    professionId    smallint NOT NULL,
    knownForOrdinal tinyint NULL,
    CONSTRAINT PK_TitlePrincipals PRIMARY KEY CLUSTERED (titleId, ordinal) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_TitlePrincipals_Title FOREIGN KEY (titleId) REFERENCES dbo.Titles (titleId),
    CONSTRAINT FK_TitlePrincipals_Principal FOREIGN KEY (principalId) REFERENCES dbo.Principals (principalId),
    CONSTRAINT FK_TitlePrincipals_Profession FOREIGN KEY (professionId) REFERENCES dbo.Professions (professionId)
);


CREATE TABLE dbo.TitleCharacters (
    titleId         int NOT NULL,
    principalId     int NOT NULL,
    [character]     nvarchar(500) NOT NULL,
    CONSTRAINT FK_TitleCharacters_Title FOREIGN KEY (titleId) REFERENCES dbo.Titles (titleId),
    CONSTRAINT FK_TitleCharacters_Principal FOREIGN KEY (principalId) REFERENCES dbo.Principals (principalId)
);

CREATE CLUSTERED INDEX IX_TitleCharacters ON dbo.TitleCharacters (titleId, principalId) WITH (DATA_COMPRESSION=PAGE);

CREATE TABLE dbo.Episodes (
    parentId        int NOT NULL,
    episodeId       int NOT NULL,
    season          smallint NULL,
    episode         int NULL,
    CONSTRAINT PK_Episodes PRIMARY KEY CLUSTERED (episodeId) WITH (DATA_COMPRESSION=PAGE),
    CONSTRAINT FK_TitleCharacters_Parent FOREIGN KEY (parentId) REFERENCES dbo.Titles (titleId),
    CONSTRAINT FK_TitleCharacters_Episode FOREIGN KEY (episodeId) REFERENCES dbo.Titles (titleId)
);


