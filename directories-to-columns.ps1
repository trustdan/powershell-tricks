function Escape-Path {
    param (
        [string]$Path
    )
    # Escape special characters that are interpreted as wildcard characters in paths
    return $Path -replace '\[', '`[' -replace '\]', '`]'
}

$outputFile = "C:\Users\output.csv"

while ($true) {
    $baseDir = Read-Host "Enter the path to the base directory"

    if (Test-Path -Path $baseDir) {
        try {
            Write-Host "Processing directory: $baseDir"
            $escapedBaseDir = Escape-Path -Path $baseDir
            $baseDirDepth = ($escapedBaseDir.Split('\').Count - 1)
            $rows = Get-ChildItem -Path $escapedBaseDir -Recurse -ErrorAction SilentlyContinue -Force | Where-Object {
                $testPath = Escape-Path -Path $_.FullName
                $testResult = Test-Path -Path $testPath -PathType Leaf -ErrorAction SilentlyContinue
                return $testResult -or $_ -is [System.IO.DirectoryInfo]
            } | ForEach-Object {
                Write-Host "Processing item: $($_.FullName)"
                $escapedPath = Escape-Path -Path $_.FullName
                $path = $escapedPath.Replace($escapedBaseDir, "").Trim("\")
                $levels = $path.Split("\")
                $depth = $levels.Count + $baseDirDepth
                $row = [ordered]@{}
                for ($i = 0; $i -lt $depth; $i++) {
                    $level = "Level$($i + 1)"
                    if ($i -lt $levels.Count) {
                        $row[$level] = $levels[$i]
                    } else {
                        $row[$level] = ""
                    }
                }
                [PsCustomObject]$row
            }

            if ($rows) {
                $properties = ($rows | Get-Member -MemberType NoteProperty).Name
                $selectProperties = $properties | Sort-Object
                $rows | Select-Object -Property $selectProperties |
                    ConvertTo-Csv -NoTypeInformation |
                    Select-Object -Skip 1 |
                    Out-File -FilePath $outputFile -Encoding UTF8

                Write-Host "CSV file generated successfully: $outputFile"
            } else {
                Write-Host "No accessible files or directories found in the specified base directory."
            }

            break
        }
        catch {
            Write-Host "Error: $_"
        }
    } else {
        Write-Host "The specified base directory does not exist. Please enter a valid path."
    }
}
