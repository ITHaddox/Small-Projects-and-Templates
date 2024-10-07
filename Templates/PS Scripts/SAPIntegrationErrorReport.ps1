# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.Office.Interop.Excel

# Set up database connection
$server = "ServerName"
$database = "SOITOSAP"

# Set the date parameters
$startDate = "2020-01-01"  #(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") # Yesterday
$endDate = (Get-Date).ToString("yyyy-MM-dd") # Today
$reportType = 1

# Construct the query with parameters
$query = "EXEC RPT_SAPIntegrationErrorReport_SP @StartSearchDateTime = '$startDate', @EndSearchDateTime = '$endDate', @ReportType = '$reportType'"

# Connect to the database and execute the query
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$server;Database=$database;Integrated Security=True;"
$command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
$connection.Open()
$reader = $command.ExecuteReader()

# Create Excel application and workbook
$excel = New-Object -ComObject Excel.Application
$workbook = $excel.Workbooks.Add()
$worksheet = $workbook.Worksheets.Item(1)

# Write column headers
$col = 1
for ($i = 0; $i -lt $reader.FieldCount; $i++) {
    $worksheet.Cells.Item(1, $col) = $reader.GetName($i)
    $col++
}

# Write data to Excel
$row = 2
while ($reader.Read()) {
    $col = 1
    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        $worksheet.Cells.Item($row, $col) = $reader.GetValue($i)
        $col++
    }
    $row++
}

# Save the Excel file
$excelFilePath = "C:\Users\TylerHadd\Auto Run\DailyErrorReport_PIC_PMPS_$endDate.xlsx"
$workbook.SaveAs($excelFilePath)
$excel.Quit()

# Close database connection
$connection.Close()

## Send email
#$smtpServer = "your.smtp.server"
#$from = "sender@example.com"
#$to = "recipient@example.com"
#$subject = "Daily Report for $startDate to $endDate"
#$body = "Please find attached the daily report for the period $startDate to $endDate."
#
#$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
#$msg = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)
#$attachment = New-Object Net.Mail.Attachment($excelFilePath)
#$msg.Attachments.Add($attachment)
#$smtp.Send($msg)
#
## Clean up
#$attachment.Dispose()
#$msg.Dispose()
#$smtp.Dispose()