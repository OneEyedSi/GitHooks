<#
.SYNOPSIS
Installs shell and PowerShell Git hook scripts on a user's computer.

.DESCRIPTION
Checks for the existence of GITHOOKSDIR environment variable and creates it if it doesn't exist.  

Checks whether the folder pointed to by GITHOOKSDIR exists and creates it if it doesn't exist.

Checks whether the PowerShell scripts exist under the GITHOOKSDIR and adds them if they don't.  If 
any script exists it will not be overridden.

Finds all .git\hooks folders on the user's computer and adds shell scripts for each Git hook to 
every .git\hooks folder.  If a Git hook script already exists it will not be overwritten.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pslogg module (see https://github.com/AnotherSadGit/Pslogg_PowerShellLogger)
Version:		0.9.1
Date:			9 Jul 2019

This script can either be run manually, with the variables set at the top of the script, or from 
the command line, passing in parameter values.

Running from the command line simplifies testing.
#>
Param
(
  [string]$GitHooksDir,
  [string]$LocalGitRepositoriesRootDir,
  [string]$ProxyUrl
)

# Modify these variables if required:

$_gitHooksDir = 'C:\GitHooks'
$_localGitRepositoriesRootDir = 'C:\Working'

# Proxy may be required when installing Pslogg logging module from PowerShell Gallery. 
$_proxyUrl = 'http://127.0.0.1:8080'

# -------------------------------------------------------------------------------------------------
# NO NEED TO CHANGE ANYTHING BELOW THIS POINT, THE REMAINDER OF THE CODE IS GENERIC.
# -------------------------------------------------------------------------------------------------
. (Join-Path $PSScriptRoot 'GitHooksInstaller_GitHookFileFunctions.ps1')

#region Script Arguments and Variables ************************************************************

$_gitHooksDirVariableName = 'GITHOOKSDIR'
$_commonGitHookScriptSourceDirectory = Join-Path $PSScriptRoot '..\GitHookSourceFilesToCopy\CommonGitHooks'
$_gitHookShellScriptSourceFile = Join-Path $PSScriptRoot '..\GitHookSourceFilesToCopy\GitHookShellScript'
$_loggingModule = 'Pslogg'
$_moduleRepository = 'PSGallery'
$_logFileName = 'InstallationResults.log'
$_logLevel = 'VERBOSE'
$_gitHookNames = @(
                    'applypatch-msg'
                    'commit-msg'
                    'post-update'
                    'pre-applypatch'
                    'pre-commit'
                    'prepare-commit-msg'
                    'pre-push'
                    'pre-rebase'
                    'update'
                )

if (-not [string]::IsNullOrWhiteSpace($GitHooksDir))
{
    $_gitHooksDir = $GitHooksDir
}

if (-not [string]::IsNullOrWhiteSpace($LocalGitRepositoriesRootDir))
{
    $_localGitRepositoriesRootDir = $LocalGitRepositoriesRootDir
}

if (-not [string]::IsNullOrWhiteSpace($ProxyUrl))
{
    $_proxyUrl = $ProxyUrl
}

#endregion

#region Script ************************************************************************************

# Install logging module if not already installed.
Install-RequiredModule -ModuleName $_loggingModule -RepositoryName $_moduleRepository `
    -ProxyUrl $_proxyUrl

Set-LogConfiguration -LogFileName $_logFileName -ExcludeDateFromFileName:$False -LogLevel $_logLevel `
    -InformationTextColor Cyan
Set-LogConfiguration -CategoryInfoItem 'Success', @{ Color = 'Green' }
Set-LogConfiguration -CategoryInfoItem 'Failure', @{ Color = 'Red' }

# Set environment variable used by Git hook scripts in repositories to point to central Git hook 
# script directory.  If the environment variable is already set it won't be changed.
Set-EnvironmentVariable -EnvironmentVariableName $_gitHooksDirVariableName -Value $_gitHooksDir

$centralGitHookDirectory = [Environment]::GetEnvironmentVariable($_gitHooksDirVariableName, "Machine")

# Copy the common Git hook PowerShell scripts to the central Git hook script directory.
Write-LogMessage "Copying common Git hook PowerShell scripts to the central Git hook script directory." -IsDebug
Set-TargetFileFromSourceDirectory -SourceDirectory $_commonGitHookScriptSourceDirectory `
    -TargetDirectory $centralGitHookDirectory

# Find all Git repositories under the specified root directory and copy the common script file into 
# each multiple times, once for each Git hook.  The same script file can be used for each Git hook 
# as all it does is call a PowerShell script in the central Git hook script directory.
Set-GitHookFileFromSourceFile -SourceFilePath $_gitHookShellScriptSourceFile `
    -TargetFileNameList $_gitHookNames -TargetRootDirectory $_localGitRepositoriesRootDir

Write-LogMessage "Git hook script installation complete." -IsInformation

#endregion