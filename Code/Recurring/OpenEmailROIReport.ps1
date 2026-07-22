$excelPath = "$env:USERPROFILE\Repos\Sql-Queries\Code\Recurring\Email ROI report.xlsx"

if (-Not (Test-Path $excelPath)) {
    Write-Error "Excel file not found at path: $excelPath"
    return
}

try {
    # Create Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $true

    # Open the workbook
    $workbook = $excel.Workbooks.Open($excelPath)

    #Refresh external data connections
    $workbook.RefreshAll()
    
    #Sleep for x seconds. This gives the workbook time to refresh
    Start-Sleep -Seconds 120

    # Save the workbook
    $workbook.Save()

    #Sleep for x seconds. This gives the workbook time to save
    Start-Sleep -Seconds 30

    # Close the workbook
    $workbook.Close($false)  # false means don't prompt to save again

    # Quit Excel
    $excel.Quit()
    Write-Host "Workbook saved and closed successfully."
} catch {
    Write-Error "An error occurred: $_"
} finally {
    if ($workbook) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
    }
    if ($excel) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
