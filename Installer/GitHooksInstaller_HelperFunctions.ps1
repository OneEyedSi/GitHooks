<#
.SYNOPSIS
Helper functions for installing Git hook scripts on a user's computer.

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
# NOTE: #Requires is not a comment, it's a requires directive.
#Requires -RunAsAdministrator # To install module from PowerShell Gallery.

<#
.SYNOPSIS
Checks whether the specified module is already installed and installs it if it isn't.

.DESCRIPTION
If the specified module is not already installed the function will attempt to install it 
assuming it has direct access to the repository.  If that fails it will attempt to install the 
module via a proxy server.

.NOTES
This function to install a module must be run under administrator privileges.

Cannot include logging in this function because it will be used to install the logging module 
if it's not already installed.
#>
function Install-RequiredModule (
    [string]$ModuleName,
    [string]$RepositoryName,
    [string]$ProxyUrl
    )
{
    # "Get-InstalledModule -Name <module name>" will throw a non-terminating error if the module 
    # is not installed.  Don't want to display the error so silently continue.
    if (Get-InstalledModule -Name $ModuleName `
        -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
    {
        return
    }
    
    # Repository probably has too many modules to enumerate them all to find the name.  So call 
    # "Find-Module -Repository $RepositoryName -Name $ModuleName" which will raise a 
    # non-terminating error if the module isn't found.

    # Silently continue on error because the error message isn't user friendly.  We'll display 
    # our own error message if needed.
    if ((Find-Module -Repository $RepositoryName -Name $ModuleName `
        -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).Count -eq 0)
    {
        throw "Module '$ModuleName' not found in repository '$RepositoryName'.  Exiting."
    }
    
    # If Install-Module fails because it's behind a proxy we want to fail silently, without 
    # displaying anything in console to scare the user.  Errors from Install-Module are 
    # non-terminating.  They won't be caught using try - catch unless ErrorAction is set to Stop. 
    
    try
    {
        Install-Module -Name $ModuleName -Repository $RepositoryName `
            -ErrorAction Stop -WarningAction SilentlyContinue

        $errorOnDirectInstall = $False
    }
    catch 
    {
        $errorOnDirectInstall = $True
    }

    if ($errorOnDirectInstall)
    {
        # Try again, this time with proxy details.

        $proxyCredential = Get-Credential -Message 'Please enter credentials for proxy server'

        # No need to Silently Continue this time.  We want to see the error details.  Convert 
        # non-terminating errors to terminating via ErrorAction Stop.   
        Install-Module -Name $ModuleName -Repository $RepositoryName `
            -Proxy $ProxyUrl -ProxyCredential $proxyCredential -ErrorAction Stop
    }

    if (-not (Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue))
    {
        throw "Unknown error installing module '$ModuleName' from repository '$RepositoryName'.  Exiting."
    }

    Write-Output "Module '$ModuleName' successfully installed from repository '$RepositoryName'."
}

<#
.SYNOPSIS
Checks whether the specified environment variable exists and, if not, sets it to the specified value.

.DESCRIPTION
If the environment variable already exists its value will not be changed.
#>
function Set-EnvironmentVariable (
    [string]$EnvironmentVariableName,
    [string]$Value
)
{
    Write-LogMessage "Checking $EnvironmentVariableName environment variable exists..." -IsDebug
    
    if (-not [Environment]::GetEnvironmentVariable($EnvironmentVariableName, "Machine"))
    {
        Write-LogMessage "Setting $EnvironmentVariableName environment variable to '$Value'..." -IsDebug

        # Want to save it permanently, not just for this session, so specify "machine" as target
        # to save it as a system variable.  If no target specified it will only be set for this 
        # session.
        [Environment]::SetEnvironmentVariable($EnvironmentVariableName, $Value, "Machine")
    }

    $Value = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, "Machine")
    Write-LogMessage "$EnvironmentVariableName environment variable set to '$Value'." -IsInformation `
        -Category 'Success'
}

<#
.SYNOPSIS
Checks if the specified file exists and creates it if it doesn't.

.OUTPUTS
FileInfo object representing the specified file if it exists or is created.  If the file is not 
created successfully then returns $Null.
#>
function Set-File (
    [string]$FilePath
    )
{
    Write-LogMessage "Checking if file $FilePath exists..." -IsDebug

    if (Test-Path -Path $FilePath -PathType Leaf)
    {
        Write-LogMessage "File $FilePath found." -IsInformation
        # -Force so that Get-Item can read hidden files.
        $fileInfo = Get-Item -Path $FilePath -Force
        return $fileInfo
    }

    Write-LogMessage "File $FilePath not found.  Creating file..." -IsDebug

    # -Force needed to create directory structure file will be added to, if it doesn't already 
    # exist.
    $fileInfo = New-Item -Path $FilePath -ItemType File -Force

    if (-not $fileInfo)
    {
        Write-LogMessage "Could not create file $FilePath." -IsError
        return $Null
    }

    Write-LogMessage "File $FilePath created successfully." -IsDebug

    return $fileInfo
}