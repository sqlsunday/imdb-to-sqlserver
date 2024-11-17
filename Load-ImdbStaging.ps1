
$sqlServerConnstring = "Data Source=.\SQL2022;Initial Catalog=IMDB;Integrated Security=True"




# List of URLs to download
$urls = @(
    "https://datasets.imdbws.com/name.basics.tsv.gz",
    "https://datasets.imdbws.com/title.akas.tsv.gz",
    "https://datasets.imdbws.com/title.basics.tsv.gz",
    "https://datasets.imdbws.com/title.crew.tsv.gz",
    "https://datasets.imdbws.com/title.episode.tsv.gz",
    "https://datasets.imdbws.com/title.principals.tsv.gz",
    "https://datasets.imdbws.com/title.ratings.tsv.gz"
)

# Download each file
foreach ($url in $urls) {
    Invoke-WebRequest -Uri $url -OutFile ([System.IO.Path]::GetFileName($url))
}





# Import System.IO.Compression.FileSystem assembly
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Define the path to the .gz file
$files = Get-Item './*.tsv.gz'

# Connect to your SQL Server
$conn = New-Object System.Data.SqlClient.SqlConnection($sqlServerConnstring)
$conn.Open()


foreach($file in $files) {

    $file.Name

    $rowNumber=0

    # Open the .gz file
    $gzipFileStream = [System.IO.File]::OpenRead($file.FullName)

    # Create a GZipStream object for decompression
    $decompressionStream = New-Object System.IO.Compression.GZipStream($gzipFileStream, [System.IO.Compression.CompressionMode]::Decompress)

    # Create a stream reader to read from the decompression stream
    $streamReader = New-Object System.IO.StreamReader($decompressionStream)

    # Create a command
    $cmd = $conn.CreateCommand()

    # Begin a transaction
    $transaction = $conn.BeginTransaction()
    $cmd.Connection = $conn
    $cmd.Transaction = $transaction

    try {
        $cmd.CommandText = "TRUNCATE TABLE [Raw].["+$file.Name+"];"
        $cmd.ExecuteNonQuery() | Out-Null

        # Read line by line from the .gz file
        while (($line = $streamReader.ReadLine()) -ne $null) {

            # Parse the line and insert it into SQL Server table
            if ($rowNumber -gt 0) {
                if ($line -replace("\\N", "") -replace("`t", "") -ne "") {
                    $cmd.CommandText = "INSERT INTO [Raw].["+$file.Name+"] VALUES ("+(("N'"+($line -replace("'", "''"))+"'") -replace("`t", "', N'") -replace("N'\\N'", "NULL"))+");"
                    $cmd.ExecuteNonQuery() | Out-Null
                }
            }

            $rowNumber=$rowNumber+1

            # For every 10,000 rows, commit the transaction and start a new
            # transaction. This effectively batches the log writes, which
            # improves the overall INSERT performance.
            if (($rowNumber%10000) -eq 0) {
                "Processed: $rowNumber"

                # Commit the transaction
                $transaction.Commit()

                # Begin a transaction
                $transaction = $conn.BeginTransaction()
                $cmd.Connection = $conn
                $cmd.Transaction = $transaction
            }
        }

    }
    catch {
        # Oh no
        $cmd.CommandText
        $_
        $transaction.Rollback()
    }

    "Processed: $rowNumber"

    # Commit the transaction
    $transaction.Commit()
}

# Close the connections and streams
$conn.Close()
$streamReader.Close()
$decompressionStream.Close()
$gzipFileStream.Close()
