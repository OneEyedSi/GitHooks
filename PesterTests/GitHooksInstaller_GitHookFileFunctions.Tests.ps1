<#
.SYNOPSIS
Tests of the functions in the GitHooksInstaller_GitHookFileFunctions.ps1 file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                AssertExceptionThrown module (see https://github.com/AnotherSadGit/PesterAssertExceptionThrown)
Version:		1.0.0
Date:			5 Jul 2019
#>

# NOTE: #Requires is not a comment, it's a requires directive.
#Requires -Modules AssertExceptionThrown

# Can't dot source directly using a simple relative path as relative paths are relative to the 
# current working directory, not the directory this test file is in.  The current working 
# directory could be anything.  So Use $PSScriptRoot to get the directory this file is in, and 
# use a path relative to that.
. (Join-Path $PSScriptRoot '..\Installer\GitHooksInstaller_GitHookFileFunctions.ps1' -Resolve)

#region Common helper functions *******************************************************************

function GetArrayDisplayText ([array]$Array)
{
    if ($Array -eq $Null)
    {
        return '[NULL]'
    }

    if ($Array.Count -eq 0)
    {
        return '[EMPTY]'
    }

    return $Array -join ', '
}

function AssertArrayMatch ([array]$ExpectedArray, [array]$ActualArray)
{
    $expectedArrayDisplayText = GetArrayDisplayText $ExpectedArray
    $actualArrayDisplayText = GetArrayDisplayText $ActualArray

    if ($ExpectedArray -eq $Null)
    {        
        if ($ActualArray -eq $Null)
        {
            return
        }

        throw "Expected array to be [NULL].  Actual value: $actualArrayDisplayText"
    }

    if ($ActualArray -eq $Null)
    {
        throw "Expected array to be $expectedArrayDisplayText.  Was actually [NULL]."
    }

    $errorMessage = "Expected array to be $expectedArrayDisplayText.  Was actually $actualArrayDisplayText."

    if ($ExpectedArray.Count -ne $ActualArray.Count)
    {
        throw $errorMessage
    }

    # Arrays must each have the same number of elements.

    if ($ExpectedArray.Count -eq 0)
    {
        return
    }

    for($i = 0; $i -lt $ExpectedArray.Count; $i++)
    {
        if ($ExpectedArray[$i] -ne $ActualArray[$i])
        {
            throw $errorMessage
        }
    }
}

function GetSearchRootDirectory
{
    return 'TestDrive:\GitDirs'
}

function GetGitHookTestDirectories
{
    return @(
                'Repo1\.git\hooks'
                'Repo2\.git\hooks'
            )
}

function GetNoHookTestDirectories
{
    return @(
                'NoHooks1\.git'
                'NoHooks2\.git'
            )
}

function GetNoGitTestDirectories
{
    return @(
                'NoGit1\hooks'
                'NoGit2\hooks'
            )
}

function GetTestDirectoryFullPaths(
    [Switch]$IncludeGitHookDirectories,
    [Switch]$IncludeNoHookDirectories,
    [Switch]$IncludeNoGitDirectories
)
{
    $searchRootDirectory = GetSearchRootDirectory

    $relativeDirectories = @()
    if ($IncludeGitHookDirectories)
    {
        $directories = GetGitHookTestDirectories
        $relativeDirectories += $directories
    }
    if ($IncludeNoHookDirectories)
    {
        $directories = GetNoHookTestDirectories
        $relativeDirectories += $directories
    }
    if ($IncludeNoGitDirectories)
    {
        $directories = GetNoGitTestDirectories
        $relativeDirectories += $directories
    }

    $relativeDirectories.ForEach{ [pscustomobject]@{ ChildPath=$_ } } | 
        Join-Path -Path $searchRootDirectory
}

function GetTestDirectoriesUnderRoot
{
    $testDirectories = GetTestDirectoryFullPaths -IncludeGitHookDirectories `
        -IncludeNoHookDirectories -IncludeNoGitDirectories
    return $testDirectories
}

function ConvertTestPathToFullPath (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true)
    ]
    [string] $Path
    )
{
    process
    {
        return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
    }
}

function CreateTestDirectories
{
    $searchRootDirectory = GetSearchRootDirectory
    $directoriesToCreate = GetTestDirectoriesUnderRoot

    $directoriesToCreate.ForEach{ [pscustomobject]@{ Path=$_ } } |
        New-Item -ItemType Directory
}

#endregion

#region Tests *************************************************************************************

Describe 'Find-GitHookDirectory' {

    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage

    $searchRootDirectory = GetSearchRootDirectory

    Context 'search root directory does not exist' {

        Mock Test-Path { return $False }

        It 'throws exception' {

            { Find-GitHookDirectory -SearchRootDirectory $searchRootDirectory } |
                Assert-ExceptionThrown -WithMessage 'not found'
        }
    }

    Context 'no Git repository directories exist under root directory' {
        
        It 'returns Null' {

            New-Item -Path $searchRootDirectory -ItemType Directory

            $result = Find-GitHookDirectory -SearchRootDirectory $searchRootDirectory

            $result | Should -Be $null
        }
    }

    Context 'Git hook directories exist under root directory' {

        CreateTestDirectories
        
        It 'returns all Git hook directories under root directory' {

            $result = Find-GitHookDirectory -SearchRootDirectory $searchRootDirectory | Sort-Object

            # Find-GitHookDirectory returns the full path to the test directories, expanding  
            # "TestDrive:\" to "C:\Users\{user name}\AppData\Local\Temp\" so we need to do the 
            # same with the expected paths.
            $expected = GetTestDirectoryFullPaths -IncludeGitHookDirectories | ConvertTestPathToFullPath | Sort-Object
            AssertArrayMatch $expected $result
        }
        
        It 'does not return any .git directories that do not have hook sub-directories' {

            $result = Find-GitHookDirectory -SearchRootDirectory $searchRootDirectory | Sort-Object

            $notExpected = GetTestDirectoryFullPaths -IncludeNoHookDirectories | ConvertTestPathToFullPath | Sort-Object
            $notExpected.ForEach{
                if ($result -contains $_)
                {
                    throw "Did not expect function to return .git directory '$_' since it does not have a hook sub-directory"
                }
            }
        }
        
        It 'does not return any hook directories that are not in .git directories' {

            $result = Find-GitHookDirectory -SearchRootDirectory $searchRootDirectory | Sort-Object

            $notExpected = GetTestDirectoryFullPaths -IncludeNoGitDirectories | ConvertTestPathToFullPath | Sort-Object
            $notExpected.ForEach{
                if ($result -contains $_)
                {
                    throw "Did not expect function to return hook directory '$_' since it is not in a .git directory"
                }
            }
        }
    }
}

#endregion

