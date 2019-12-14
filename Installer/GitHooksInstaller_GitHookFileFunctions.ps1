<#
.SYNOPSIS
Functions for finding and updating Git hook scripts on a user's computer.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pslogg module (see https://github.com/AnotherSadGit/Pslogg_PowerShellLogger)
Version:		0.9.1
Date:			9 Jul 2019
#>

# -------------------------------------------------------------------------------------------------
# NO NEED TO CHANGE ANYTHING BELOW THIS POINT, THE REMAINDER OF THE CODE IS GENERIC.
# -------------------------------------------------------------------------------------------------

# Dot source other function scripts.
. (Join-Path $PSScriptRoot 'GitHooksInstaller_FileCopyFunctions.ps1')

<#
.SYNOPSIS
Returns a list of all the Git hook directories under a specified root directory.
#>
function Find-GitHookDirectory (
    [string]$SearchRootDirectory
    )
{
    Write-LogMessage "Finding Git hook directories under $SearchRootDirectory..." -IsDebug

    if (-not (Test-Path $SearchRootDirectory -PathType Container))
    {
        $errorMessage = "Directory $SearchRootDirectory not found.  Exiting."
        Write-LogMessage $errorMessage -IsError
        throw $errorMessage
    }

    # -Force parameter allows Get-ChildItem to return hidden files and folders.  This is needed 
    # as the .git folders are hidden.  
    # -Filter restricts the returned directories to only those called "hooks".  Apparently it's 
    # not possible to include a path delimiter in the filter so we can't be certain the hooks 
    # directories returned are all under .git directories.  So use Where-Object to ensure this.  
    # We don't want to just use Where-Object for performance reasons - we want to filter out as 
    # many directories as possible before passing the results to the pipeline.
    # -ErrorAction SilentlyContinue is to avoid errors from paths that exceed Windows' maximum 
    # path length.  Select-Object without -ExpandProperty returns an array of PSCustomObjects each 
    # with a single property FullName.  Adding -ExpandProperty instead returns an array of strings.
    $gitHookDirectories = Get-ChildItem -Path $SearchRootDirectory -Recurse -Directory `
        -Force -Filter 'hooks' -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -like '*\.git\hooks' } | 
            Select-Object -ExpandProperty FullName

    if ($gitHookDirectories)
    {
        $NumberOfDirectoriesFound = $gitHookDirectories.Count
    }
    else 
    {
        $NumberOfDirectoriesFound = 0
    }

    Write-LogMessage "$NumberOfDirectoriesFound Git hook directories found under $SearchRootDirectory." -IsInformation

    return $gitHookDirectories
}

<#
.SYNOPSIS
Finds all Git repositories under a specified root directory and updates the Git hook script files 
in each repository.

.DESCRIPTION
For each Git repository Set-GitHookFileFromSourceFile copies a single generic script file into 
the Git hooks directory multiple times, once for every Git hook in the target file name list.  
So the Git hook scripts will all end up identical, for every Git hook in every repository.

The target script file will only be copied if either:

* The target Git hook script file does not exist;

* The target script version number (embedded in the contents of the file; not the same as the 
file version as seen by Windows) is LESS THAN the version number in the source file.

If the target script file does NOT have a version number it will NOT be updated from the source 
file.  We assume that a target script file without a version number is a custom script created by 
a user, as opposed to the generic scripts we're deploying.  We don't want to overwrite custom 
scripts.
#>
function Set-GitHookFileFromSourceFile (
    [string]$SourceFilePath,
    [array]$TargetFileNameList,
    [string]$TargetRootDirectory
)
{
    Write-LogMessage "Updating Git hook script files, for all repositories under $TargetRootDirectory..." -IsDebug

    Find-GitHookDirectory $TargetRootDirectory |
        Set-TargetFileFromSourceFile -SourceFilePath $SourceFilePath -TargetFileNameList $TargetFileNameList

    Write-LogMessage "Git hook script files updated for all repositories under $TargetRootDirectory." -IsInformation
}
