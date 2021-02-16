<#
.SYNOPSIS
Functions for copying files.

.DESCRIPTION
This script contains two sets of functions:

1) For copying all files under a source directory to a target directory;

2) For copying a single file multiple times, under different names, to a target directory.

In both cases only if the target file does not exist it will be created as a copy of the source 
file.  If the target file already exists it will only be overwritten with a copy of the source 
file if the version number in the source file is newer than the version number in the target file.  

If the target file exists and does not have a version number it will not be overwritten with a 
copy of the source file.  This assumes that all "official" files have version numbers so that if 
a target file does not have a version number it must have been created by the user.  We don't 
want to overwrite the user's custom files.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pslogg module (see https://github.com/AnotherSadGit/Pslogg_PowerShellLogger)
Date:			9 Jul 2019
Version:		1.0.0
#>

# -------------------------------------------------------------------------------------------------
# NO NEED TO CHANGE ANYTHING BELOW THIS POINT, THE REMAINDER OF THE CODE IS GENERIC.
# -------------------------------------------------------------------------------------------------

# Dot source other function scripts.
. (Join-Path $PSScriptRoot 'GitHooksInstaller_HelperFunctions.ps1')
. (Join-Path $PSScriptRoot 'GitHooksInstaller_VersionNumberFunctions.ps1')

#region Copy all files under source directory to target directory *********************************

<#
.SYNOPSIS
Gets a list of files in a source directory that should be copied to the target directory.

.DESCRIPTION
Goes through all the files in the source directory, recursively, and compares them to files in 
the target directory with the same names.  For each matching file name it compares the version 
numbers in the source file with the version number in the target file.  If the version number of 
the source file is greater the file should be copied and it will be included in the output list.

All the source files should have version numbers.  Target files may not if the user has created 
a custom script file (eg for a Git hook).  In that case we don't want to overwrite the user's 
script file.  So assume a target file without a version number is NOT to be overwritten.

.OUTPUTS
System.String

Get-SourceFileToCopy returns the path of each file in the source directory to be copied to the 
target directory.  The paths are relative to the source directory.
#>
function Get-SourceFileToCopy (
    [string]$SourceDirectory,
    [string]$TargetDirectory
    )
{
    Write-LogMessage "Determining which files to copy from $Sourcedirectory to $TargetDirectory..." -IsDebug

    $sourceFileRelativePaths = Get-DirectoryFileRelativePath -DirectoryPath $SourceDirectory
    $sourceFileVersions = Get-DirectoryScriptVersion -DirectoryPath $SourceDirectory `
        -FileNameList $sourceFileRelativePaths

    if (-not $sourceFileVersions -or $sourceFileVersions.Keys.Count -eq 0)
    {
        Write-LogMessage "No source files to copy from $Sourcedirectory to $TargetDirectory." -IsInformation
        return @()
    }

    Write-LogMessage "$($sourceFileVersions.Keys.Count) source files found." -IsDebug

    if (-not (Test-Path -Path $TargetDirectory -PathType Container))
    {
        Write-LogMessage "Target directory $TargetDirectory does not exist: Copy all files." -IsInformation
        return $sourceFileVersions.Keys
    }

    $targetFileVersions = Get-DirectoryScriptVersion -DirectoryPath $TargetDirectory `
        -FileNameList $sourceFileVersions.Keys
 
    $sourceFilesToCopy = @()
    $sourceFileVersions.Keys.ForEach{ 
                                        if ( (Compare-Version $sourceFileVersions[$_] $targetFileVersions[$_]) -eq '>' )
                                        { 
                                            $sourceFilesToCopy += $_ 
                                        } 
                                    }
    
    Write-LogMessage "$($sourceFilesToCopy.Count) files to copy from source directory." -IsInformation

    return $sourceFilesToCopy
}

<#
.SYNOPSIS
Updates files in a target directory by copying newer files from a source directory.

.DESCRIPTION
Set-TargetFileFromSourceDirectory gets a list of files in the source directory along with the 
version numbers embedded in the files (in the contents of the files, not the file version number).  
It then compares this list to the list of files in the target directory.

If a file from the source directory is not present in the target directory, or if the version 
number is greater than that of the file in the target directory, the file will be copied from the 
source directory to the target directory.

If a file is present in the target directory but not in the source directory it will be retained; 
it will not be deleted.

All files in the source directory should have version numbers.  If a file in the target directory 
does not have a version number it is assumed to be a custom script created by a user.  Such user 
scripts should not be overwritten by the generalized scripts this function is designed to 
install.  So if a file in the target directory does not have a version number it will not be 
overwritten by copying the equivalent file from the source directory.

If a file in the target directory is read-only it will not be updated as it is assumed the user 
set the file to read-only for a reason.  No error will be raised but a warning message will be 
logged. 
#>
function Set-TargetFileFromSourceDirectory (
    [string]$SourceDirectory,
    [string]$TargetDirectory    
    )
{
    Write-LogMessage "Updating files in $TargetDirectory from $Sourcedirectory..." -IsDebug

    $sourceFilesToCopy = Get-SourceFileToCopy `
        -SourceDirectory $SourceDirectory -TargetDirectory $TargetDirectory

    if (-not $sourceFilesToCopy -or $sourceFilesToCopy.Count -eq 0)
    {
        Write-LogMessage "No files to update in $TargetDirectory." -IsInformation `
            -Category 'Success'
        return
    }

    $errorOccurred = $False

    # We're copying individual files, not directories, so Copy-Item expects the sub-directory 
    # structure to already exist under the target directory.  If a sub-directory doesn't exist 
    # Copy-Item will error.  So create an empty target file, if it doesn't exist, which will 
    # create the directory structure in the process.  then overwrite the file with Copy-Item.
    foreach ($fileRelativePath in $sourceFilesToCopy) 
    {
        # Cmdlets will raise non-terminating errors if they have problems.  Clear errors 
        # before calling any cmdlets so we can check if there were any problems copying files.
        $Error.Clear()
        $fileErrorOccurred = $False

        $sourceFileFullPath = Join-Path -Path $SourceDirectory -ChildPath $fileRelativePath
        $targetFileFullPath = Join-Path -Path $TargetDirectory -ChildPath $fileRelativePath

        # Source file should always exist but check just to be sure.
        if (-not (Test-Path -Path $sourceFileFullPath -PathType Leaf))
        {
            # If the source file doesn't exist something has gone seriously wrong so exit.
            $errorMessage = "Unable to copy file ${sourceFileFullPath}:  File not found.  Exiting."
            Write-LogMessage $errorMessage -IsError
            throw $errorMessage
        }

        $fileInfo = Set-File $targetFileFullPath

        # The target file should have been created if it didn't exist.  Obviously there was a 
        # problem so skip this file.
        if (-not $fileInfo)
        {
            $fileErrorOccurred = $True
            continue
        }

        if ((Get-ChildItem $targetFileFullPath).IsReadOnly)
        {
            Write-LogMessage "Target file $targetFileFullPath is read-only.  It will not be updated." -IsWarning
            continue
        }

        Write-LogMessage "Copying source file $sourceFileFullPath to target file $targetFileFullPath..." -IsDebug

        
        Copy-Item -Path $sourceFileFullPath -Destination $targetFileFullPath

        if ($Error.Count -gt 0)
        {
            $fileErrorOccurred = $True
        }

        if ($fileErrorOccurred)
        {
            $errorOccurred = $True
            Write-LogMessage "Error updating target file $targetFileFullPath from source file $sourceFileFullPath." `
                -IsError
        }
        else
        {
            Write-LogMessage "Target file $targetFileFullPath updated from source file $sourceFileFullPath." `
                -IsInformation
        }
    }

    if ($errorOccurred)
    {
        Write-LogMessage "Updating files in $TargetDirectory from $SourceDirectory completed with errors." `
            -IsInformation -Category 'Failure'
    }
    else
    {
        Write-LogMessage "Updating files in $TargetDirectory from $SourceDirectory completed successfully." `
            -IsInformation -Category 'Success'
    }
}

#endregion

#region Copy single source file to multiple files in target directory *****************************

<#
.SYNOPSIS
Determines which target files should be overwritten by a copy of a single source file.

.DESCRIPTION
Compares the version number read from a single source file to the version numbers read from a 
list of target files.  If the source file version is newer than the target file version, that 
target file will be flagged to be overwritten.

The files in the target file name list do not have to exist.  Any target files that do not 
exist will be flagged to be copied from the source file.

.OUTPUTS
System.String

Get-TargetFileToUpdate returns the path of each file in the target directory to be copied from 
the source file.  The paths are relative to the target directory.

.NOTES
Get-TargetFileToUpdate is useful for copying the contents of a single, common, script file 
into the Git hooks directory of a Git repository multiple times, once for each Git hook.
#>
function Get-TargetFileToUpdate (
    [string]$SourceFilePath,
    [array]$TargetFileNameList,
    [string]$TargetDirectory
    )
{
    Write-LogMessage "Determining which target files to update in $TargetDirectory..." -IsDebug

    $sourceFileVersionArray = Get-ScriptFileVersion -ScriptPath $SourceFilePath
    $sourceFileVersionText = $sourceFileVersionArray -join '.'

    if ($sourceFileVersionText -eq '99999.0.0.0')
    {
        $errorMessage = "Source file $SourceFilePath has no version number.  " `
            + "Cannot determine if it is more recent than the target files.  Exiting."
        Write-LogMessage $errorMessage -IsError
        throw $errorMessage
    }

    Write-LogMessage "Source file $SourceFilePath has version number $sourceFileVersionText." -IsDebug

    if (-not (Test-Path -Path $TargetDirectory -PathType Container))
    {
        Write-LogMessage "Target directory $TargetDirectory does not exist: Copy all files." -IsInformation
        return $TargetFileNameList
    }

    $targetFileVersions = Get-DirectoryScriptVersion -DirectoryPath $TargetDirectory `
        -FileNameList $TargetFileNameList
    
    $targetFilesToUpdate = @()
    $targetFileVersions.Keys.ForEach{ 
                                        if ( (Compare-Version $sourceFileVersionArray $targetFileVersions[$_]) -eq '>' )
                                        { 
                                            $targetFilesToUpdate += $_ 
                                        } 
                                    }
    
    Write-LogMessage "$($targetFilesToUpdate.Count) files to update in target directory $TargetDirectory." -IsInformation

    return $targetFilesToUpdate
}

<#
.SYNOPSIS
Updates files in a target directory by copying a single source file multiple times, if the source 
file is newer.

.DESCRIPTION
Set-TargetFileFromSourceFile gets a single source file along with the version number embedded in 
the file (in the contents of the file, not the file version number).  It then compares the 
version number to a list of specified target files.

If a target file does not exist, or if the source file's version number is greater than that of 
the target file, the source file will be copied over the target file.

The source file should have a version number.  If a target file does not have a version number it 
is assumed to be a custom script created by a user.  Such user scripts should not be overwritten 
by the generalized scripts this function is designed to install.  So if a target file does not 
have a version number it will not be overwritten by copying the source file over it.

If a target file is read-only it will not be updated as it is assumed the user set the file to 
read-only for a reason.  No error will be raised but a warning message will be logged. 
#>
function Set-TargetFileFromSourceFile (
        [Parameter(Position=0, Mandatory=$true)]
        [string]$SourceFilePath,
        [Parameter(Position=1, Mandatory=$true)]
        [array]$TargetFileNameList,
        [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
        [string]$TargetDirectory
    )
{
    process
    {
        Write-LogMessage "Updating specified target files in $TargetDirectory from source file $SourceFilePath..." -IsDebug

        # Source file should always exist but check just to be sure.
        if (-not (Test-Path -Path $SourceFilePath -PathType Leaf))
        {
            # If the source file doesn't exist something has gone seriously wrong so exit.
            $errorMessage = "Unable to update target files:  Source file ${SourceFilePath} not found.  Exiting."
            Write-LogMessage $errorMessage -IsError
            throw $errorMessage
        }

        # Only want to copy files that are missing in the target directory, or have older version 
        # numbers.
        $filteredTargetFileNameList = Get-TargetFileToUpdate -SourceFilePath $SourceFilePath `
            -TargetFileNameList $TargetFileNameList -TargetDirectory $TargetDirectory

        $errorOccurred = $False
                
        # We're copying individual files, not directories, so Copy-Item expects the sub-directory 
        # structure to already exist under the target directory.  If a sub-directory doesn't exist 
        # Copy-Item will error.  So create an empty target file, if it doesn't exist, which will 
        # create the directory structure in the process.  then overwrite the file with Copy-Item.
        foreach ($fileRelativePath in $filteredTargetFileNameList) 
        {
            # Cmdlets will raise non-terminating errors if they have problems.  Clear errors 
            # before calling any cmdlets so we can check if there were any problems copying files.
            $Error.Clear()
            $fileErrorOccurred = $False

            $targetFileFullPath = Join-Path -Path $TargetDirectory -ChildPath $fileRelativePath
            
            $fileInfo = Set-File $targetFileFullPath

            # The target file should have been created if it didn't exist.  Obviously there was a 
            # problem so skip this file.
            if (-not $fileInfo)
            {
                $fileErrorOccurred = $True
                continue
            }

            if ((Get-ChildItem $targetFileFullPath).IsReadOnly)
            {
                Write-LogMessage "Target file $targetFileFullPath is read-only.  It will not be updated." -IsWarning
                continue
            }

            Write-LogMessage "Copying source file $SourceFilePath to target file $targetFileFullPath..." -IsDebug

            Copy-Item -Path $SourceFilePath -Destination $targetFileFullPath

            if ($Error.Count -gt 0)
            {
                $fileErrorOccurred = $True
            }

            if ($fileErrorOccurred)
            {
                $errorOccurred = $True
                Write-LogMessage "Error updating target file $targetFileFullPath from source file $SourceFilePath." `
                    -IsError
            }
            else
            {
                Write-LogMessage "Target file $targetFileFullPath updated from source file $SourceFilePath." `
                    -IsInformation
            }
        }
        
        if ($errorOccurred)
        {
            Write-LogMessage "Updating files in $TargetDirectory from file $SourceFilePath completed with errors." `
                -IsInformation -Category 'Failure'
        }
        else
        {
            Write-LogMessage "Updating files in $TargetDirectory from file $SourceFilePath completed successfully." `
                -IsInformation -Category 'Success'
        }
    }
}

#endregion
