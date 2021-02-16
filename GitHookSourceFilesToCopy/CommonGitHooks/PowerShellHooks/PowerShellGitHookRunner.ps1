<#
.SYNOPSIS
Runs the appropriate PowerShell script for the specified Git hook.

.DESCRIPTION
This generic PowerShell Git Hook Runner script simplifies maintenance of the Git hook scripts.  
It allows there to be a single central directory with a single copy of each Git hook script, 
instead of a different copy of each Git hook script in each repository.
  
All Git hooks in all repositories can then be identical generic scripts that call this one 
script.  This script will call the appropriate PowerShell Git hook script in this central 
location.  This script determines which PowerShell Git hook script to run based on the 
filename of the calling script in the Git repository.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                CommonFunctions.psm1 0.8.0
                    (scripts must be in same folder as this script)
Date:			5 Jun 2019
Version:		1.0.0

This script uses the $Args built-in variable to receive the arguments passed from the calling 
Git hook scripts in the Git repositories.  Different Git hooks have different arguments and some 
have optional arguments so we can't specify particular named parameters in this generic script 
to handle the arguments passed in.

In every case the first argument passed by position, $Args[0], will be the name of the calling 
Git hook script, eg "prepare-commit-msg".  The remaining arguments are those that Git passes 
into the calling Git hook script, just passed straight through to this script in the same order 
they were passed from Git to the calling script.

A non-zero exit value will abort the action in Git that triggered the Git hook.

The output statements in this script and the scripts it calls will be displayed in either the Git 
bash console or the Git Extensions Process dialog, depending on which Git client the user is 
using.

ASSUMPTIONS:
1) That the PowerShell scripts called or imported by this script are in the same directory as 
    this script.
2) That the PowerShell Git hook module scripts have the following naming convention:
        {Git hook name}.psm1
    eg the PowerShell module that handles the prepare-commit-msg Git hook is 
        prepare-commit-msg.psm1
3) That each PowerShell Git hook module has a Start-GitHook function.

#>

Write-Output "Executing PowerShell Git Hook Runner..."

if (-not $Args -or $Args.Count -eq 0)
{
    Write-Output 'The name of the Git hook was not specified so cannot continue.  Aborting.'

    exit 1
}

# The first element of the Args is the name of the Git hook.  The remaining Args are the 
# arguments Git passed into the calling Git hook script.
$gitHook = $Args[0].Trim()

if ([string]::IsNullOrWhiteSpace($gitHook))
{
    Write-Output 'The name of the Git hook was not specified so cannot continue.  Aborting.'

    exit 2
}

$modulePath = Join-Path $PSScriptRoot "${gitHook}.psm1"

if (-not (Test-Path $modulePath))
{
    Write-Output "No PowerShell module for Git hook $gitHook.  Finishing."

    # Having no Git hook handler is not an error so exit with success.
    exit 0
}

Write-Output "Importing PowerShell $gitHook module..."

Import-Module $modulePath

Write-Output "Executing imported function for Git hook $gitHook..."

if ($Args.Count -le 1)
{
    $gitHookArgs = $Null
}
else
{
    $gitHookArgs = $Args[1..($Args.Count-1)]
}

# Note the leading "@" instead of "$" in "@gitHookArgs".  This is splatting - passing an array 
# into a function where each element of the array is passed to a separate function parameter.  If 
# we had used "$" then the array would be flattened and passed as a single string argument to the 
# first parameter of the function.
# Note that splatting handles mismatches between the number of array elements and the number of 
# function parameters without error.  This works in both directions - too few array elements or 
# too many.  In either case there will be no error unless the function requires the missing 
# parameters.
Start-GitHook @gitHookArgs

# This may not be hit if the imported Start-GitHook function includes an exit statement.
Write-Output "PowerShell module for Git hook $gitHook has completed."

exit 0