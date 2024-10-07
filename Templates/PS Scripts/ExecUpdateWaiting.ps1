# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Log Path
$logPath = "C:\Users\TylerHadd\Auto Run\UpdateWaiting_$(Get-Date -Format 'yyyyMMdd').log"
Start-Transcript -Path $logPath -Append

# Set up database connection
$server = "ServerName"
$database = "SOIToSAP"

# Construct the query with parameters
$query = "EXEC SOIToSAP..[PRC_UpdateWaitingSAPIntegration_SP]"

# Connect to the database and execute the query
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$server;Database=$database;Integrated Security=True;"
$command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
$connection.Open()

# Close database connection
$connection.Close()

Stop-Transcript