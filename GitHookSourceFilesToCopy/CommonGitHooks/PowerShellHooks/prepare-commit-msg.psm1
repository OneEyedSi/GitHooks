<#
.SYNOPSIS
PowerShell module that handles the prepare-commit-msg Git hook event.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                CommonFunctions.psm1 0.8.0
                    (scripts must be in same folder as this script)
Version:		1.0.0
Date:			17 Feb 2021

#>

Import-Module (Join-Path $PSScriptRoot "CommonFunctions.psm1")

$_branchNamesToIgnore = @(
                            'master',
                            'main',
                            'develop',
                            'integration',
                            'temp'
                        )

#region Exported Functions ************************************************************************

<#
.SYNOPSIS
Modifies git commit messages to prepend the branch name to the start of the message.

.DESCRIPTION
The following text will be prepended to the commit message: "{branch name}: ". 

In a merge the branch name prepended to the commit will be the target branch name, the branch 
being merged into. 

The commit message will NOT be modified when:

    1) The commit is on an excluded branch, such as master or develop.  We don't want commits on 
    permanent branches such as master to start with "master: ".  To modify the list of excluded 
    branches edit the list assigned to variable $_branchNamesToIgnore, at the head of this script;

    2) The commit message already has the branch name prepended (for example, if the user has 
    manually included the branch name at the start of the message, of if the user is amending an 
    existing commit);

    3) The HEAD is a detached HEAD.  In other words, the checked out commit is not at the head of a 
    branch.  In that case we can't read the branch name so cannot preprend it to the commit 
    message;

    4) Modifying existing commits via an interactive rebase.

For branch names based on JIRA issues, with known JIRA project names, the branch name will be 
cleaned up before being prepended to the commit message.  For example, if the branch name 
is "toll319_TripManifest" then the text prepended to the commit message will be "TOLL-319: ".

.NOTES


.PARAMETER CommitMessageFilePath 
String.  Path to the temporary file created by Git that contains the commit message. 

.PARAMETER CommitType 
String.  The commit type.  Valid values:
	message:  Commit with -m or -F option;
	template:  Commit with -t option;
	merge:  If commit is a merge commit;
	squash:  If commit is a squash commit.

.PARAMETER CommitHash 
String.  SHA1 hash of commit.  Only supplied if -c, -C, or -amend option set.
#>
function Start-GitHook (
    [string]$CommitMessageFilePath, 
    [string]$CommitType, 
    [string]$CommitHash
)
{
    $gitHookName = $MyInvocation.MyCommand.ModuleName
    Set-MessageHeader $gitHookName
    
    Write-OutputMessage 'Editing the commit message...'

    $commitMessageNotModifiedNote = 'Commit message will not be modified.'

    if ([string]::IsNullOrWhiteSpace($CommitMessageFilePath))
    {
        Exit-WithMessage "The path to the commit message temp file was not passed to the Start-GitHook function.  $commitMessageNotModifiedNote"
    }

    $CommitMessageFilePath = $CommitMessageFilePath.Trim()

    Write-OutputMessage "Commit message file path: $CommitMessageFilePath"

    if ([string]::IsNullOrWhiteSpace($CommitType))
    {
        Exit-WithMessage "Commit type was not passed to the Start-GitHook function.  $commitMessageNotModifiedNote"
    }

    $CommitType = $CommitType.Trim()

    Write-OutputMessage "Commit type: $CommitType"

    # If the currently checked out commit is not the HEAD of a branch then this will return $Null.
    # The --quiet option prevents it from outputting an error message.
    $branchName = (git symbolic-ref --quiet --short HEAD)

    if ([string]::IsNullOrWhiteSpace($branchName))
    {
        Exit-WithMessage "Could not read git branch name.  $commitMessageNotModifiedNote"
    }

    $branchName = $branchName.Trim()

    Write-OutputMessage "Git branch name: $branchName"

    $commitMessagePrefix = Get-CommitMessagePrefix $branchName

    Write-OutputMessage "Commit message prefix: $commitMessagePrefix"

    # Don't want to add branch name to commit message if it's one of the permanent branches, 
    # like master or develop.
    if ($branchName -in $script:_branchNamesToIgnore)
    {
        Exit-WithMessage "Committing to reserved branch $branchName.  $commitMessageNotModifiedNote"
    }

    if (-not (Test-Path $CommitMessageFilePath))
    {
	    Exit-WithMessage "Could not find commit message temp file '$CommitMessageFilePath'.  Cannot modify commit message."
    }

    $existingCommitMessageFileContents = Get-Content $CommitMessageFilePath

    Write-OutputMessage 'Original commit message:'
    $fileContentsToDisplay = Set-IndentOnFileContent $existingCommitMessageFileContents
    Write-OutputMessage $fileContentsToDisplay -WriteFirstLineOnly

    # Single line commit message.
    if ($existingCommitMessageFileContents -is [string])
    {
        $existingCommitMessage = $existingCommitMessageFileContents.Trim()
    
        Exit-IfEditingExistingCommit $existingCommitMessage $commitMessagePrefix

        $commitMessageFileContents = "${commitMessagePrefix}: $existingCommitMessage"
    }
    # Multi-line commit message.
    elseif ($existingCommitMessageFileContents -is [array] `
    -and $existingCommitMessageFileContents.Count -gt 0)
    {
        $existingCommitMessageFirstLine = $existingCommitMessageFileContents[0].Trim()

        Exit-IfEditingExistingCommit $existingCommitMessageFirstLine $commitMessagePrefix

        $newFirstLine = "${commitMessagePrefix}: $existingCommitMessageFirstLine"
        $commitMessageFileContents = $existingCommitMessageFileContents
        $commitMessageFileContents[0] = $newFirstLine
    }

    Write-OutputMessage 'Modified commit message to write back to file:'
    $fileContentsToDisplay = Set-IndentOnFileContent $commitMessageFileContents
    Write-OutputMessage $fileContentsToDisplay -WriteFirstLineOnly

    Set-Content -Path $CommitMessageFilePath -Value $commitMessageFileContents

    Write-OutputMessage "Commit message updated."
    Write-OutputMessage "PowerShell Git hook function complete."

    Exit-WithSuccess
}

#endregion

#region Private Helper Functions ******************************************************************

<#
.SYNOPSIS
Writes a message to standard output then exits.

.DESCRIPTION
Even if there is a problem with this script we don't want to abort the Git action that triggered 
it; this script isn't that important.  So exit with status code 0 = success (any non-zero status 
code would result in Git aborting the action that triggered this script).
#>
function Exit-WithMessage (
    [string]$Message
    )
{
    if (-not $Message)
    {
        $Message = 'Commit message will not be modified.'
    }

    Write-OutputMessage $Message

    Exit-WithSuccess
}

<#
.SYNOPSIS
Exits this script with success.

.DESCRIPTION
Even if there is a problem with this script we don't want to abort the Git action that triggered 
it; this script isn't that important.  So exit with status code 0 = success (any non-zero status 
code would result in Git aborting the action that triggered this script).
#>
function Exit-WithSuccess ()
{
    exit 0
}

<#
.SYNOPSIS
Gets the prefix, based on the Git branch, that will be prepended to the Git commit message.

.DESCRIPTION
Cleans up branch names that are based on JIRA issues.  Examples:

    1) Branch "toll319_TripManifest" -> prefix "TOLL-319" 
    2) Branch "Smiths-742"           -> prefix "SMITHS-742" 

The cleaned up branch names will take the form: 
    {CAPITALIZED TEXT}-{issue number}
Any leading spaces and any trailing non-digit characters (eg text, hyphens, underscores, spaces) 
will be stripped out.

Note that the hyphen is optional in the branch name - it will be inserted into the prefix if it 
doesn't exist in the branch name.

Any branch names that don't match the JIRA issue pattern will be returned unchanged.
#>
function Get-CommitMessagePrefix (
    [string]$BranchName
    )
{
    if (-not $BranchName)
    {
        return ''
    }

    # Regex Pattern:
    #    ^\s*          Starts with zero or more whitespaces 
    #    ([A-Za-z]+)   First capture group: Matches one or more upper or lower case letters 
    #    -?            An optional "-" (hyphen)
    #    (\d+)         Second capture group: Matches one or more digits, (JIRA issue number)
    $regexPattern = "^\s*([A-Za-z]+)-?(\d+)"

    $commitMessagePrefix = $BranchName

    if ($BranchName -match $regexPattern)
    {    
        $commitMessagePrefix = "$($matches[1].ToUpper())-$($matches[2])"
    }

    return $commitMessagePrefix.Trim()
}

function Exit-IfEditingExistingCommit (
    [string]$ExistingCommitMessageFirstLine,
    [string]$BranchName
    )
{
    $ExistingCommitMessageFirstLine = $ExistingCommitMessageFirstLine.Trim()

    if ($ExistingCommitMessageFirstLine.StartsWith('fixup!'))
    {
        Write-OutputMessage 'Fixup commit message will not be modified.'

        exit 0
    }
    
    if ($ExistingCommitMessageFirstLine.StartsWith('squash!'))
    {
        Write-OutputMessage 'Squash commit message will not be modified.'

        exit 0
    }
    
    if ($ExistingCommitMessageFirstLine.StartsWith($BranchName))
    {
        Write-OutputMessage 'Commit message already has a prefix; commit message will not be modified.'

        exit 0
    }
}  

function Set-IndentOnFileContent (
        $FileContents
    )
{
    # Won't throw error if $FileContents are an array.
    if ([string]::IsNullOrWhiteSpace($FileContents))
    {
        return ''
    }

    if ($FileContents -is [string])
    {
        return "  $FileContents"
    }

    if ($FileContents -is [array] -and $FileContents.Count -gt 0)
    {
        return $FileContents.ForEach({"  $_"})
    }

    return $FileContents
}

#endregion

#region Module Members to Export ******************************************************************

Export-ModuleMember -Function Start-GitHook

#endregion