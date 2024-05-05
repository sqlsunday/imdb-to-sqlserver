# Create your own SQL Server database from the IMDB dataset

## Important licensing information

IMDB makes this dataset available with a number of licensing terms. The long and short of it is, you can only use
the data for your own, non-commercial use.

Source and licensing: [https://developer.imdb.com/non-commercial-datasets/](https://developer.imdb.com/non-commercial-datasets/)

Data files: [https://datasets.imdbws.com/](https://datasets.imdbws.com/)

## How to download and create the IMDB database

You'll need SQL Server 2022 and up to 20 GB of free disk space to do this.

If you want to run it on a lower version, you'll have to rebuild/replace the `STRING_SPLIT` function calls in the last script.

* Create a new SQL Server database.
  * I've called it IMDB, but you can name it whatever you want.
  * I strongly recommend setting the database to simple recovery model.
* Create the database schema by running `Create IMDB-schema.sql` in the database.
* Download and import the IMDB dataset using the `Load-ImdbStaging.ps1` script. The script will download the files to your current working directory and perform the ingest from there. The download is just a few GB, but inserting the data may take up to a few hours depending on your environment.
* Populate the relational tables using the `Load IMDB relational tables.sql` script.
* If you want, you can now drop the staging tables in the `Raw` schema.

## Approximate compressed table sizes

* dbo.Attributes: 171 rows
* dbo.Episodes: 8M rows, 95 MB
* dbo.Genres: 28 rows
* dbo.Professions: 48 rows
* dbo.PrimaryProfessions: 14M rows, 160 MB
* dbo.Principals: 13M rows, 350 MB
* dbo.Titles: 10M rows, 255 MB
* dbo.TitleCharacters: 5.3M rows, 96 MB
* dbo.TitleGenres: 16M rows, 173 MB
* dbo.TitleNames: 37M rows, 1.1 GB
* dbo.TitleNameAttributes: 500k rows, 9 MB
* dbo.TitlePrincipals: 28M rows, 460 MB
* dbo.TitleTypes: 12 rows
