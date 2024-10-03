<#
.SYNOPSIS
PowerShell module that handles the prepare-commit-msg Git hook event.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                CommonFunctions.psm1 1.0.0
                    (scripts must be in same folder as this script)
Version:		1.3.2
Date:			3 Oct 2024

#>

Import-Module (Join-Path $PSScriptRoot "CommonFunctions.psm1")

$_branchNamesToIgnore = @(
    'master',
    'main',
    'develop',
    'integration',
    'temp'
)

$_branchPrefixesToIgnore = @(
    'feature',
    'feat',
    'features',
    'bug',
    'bugs',
    'bugfix',
    'bugfixes',
    'release',
    'releases',
    'adhoc',
    'hotfix',
    'hotfixes',
    'patch',
    'patches',
    'devops',
    'cherrypick'
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
    manually included the branch name at the start of the message, or if the user is amending an 
    existing commit);

    3) The HEAD is a detached HEAD.  In other words, the checked out commit is not at the head of a 
    branch.  In that case we can't read the branch name so cannot prepend it to the commit 
    message;

    4) Modifying existing commits via an interactive rebase.

For branch names starting with Jira ticket numbers, of the form "xxx-nnn" or "xxxnnn", where "xxx" 
represents one or more letters and "nnn" represents one or more digits, only the Jira ticket 
number will be prepended to the commit message.  Any remaining text in the branch name after the 
digits will be ignored.  For example, if the branch name is "toll319_TripManifest" then the text 
prepended to the commit message will be "TOLL-319: ".

Similarly, known branch prefixes will be ignored.  For example, if the branch name is 
"feature/toll319_TripManifest" then the text prepended to the commit message will be "TOLL-319: ".  
To modify the list of prefixes to ignore, edit the list assigned to variable 
$_branchPrefixesToIgnore, at the head of this script. 

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
function Start-GitHook 
(
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

    # If the currently checked out commit is not the HEAD of a branch then branch name will be $Null.
    $branchName = Get-BranchName

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
Gets the name of the Git branch that is currently checked out.

.DESCRIPTION
If the currently checked out commit is the HEAD of a branch then the branch name will be returned. 
If the currently checked out commit is not the HEAD of a branch then $Null will be returned.
#>
function Get-BranchName ()
{
    # The --quiet option prevents it from outputting an error message.
    $branchName = (git symbolic-ref --quiet --short HEAD)
    return $branchName
}

<#
.SYNOPSIS
Removes any known prefix from the Git branch name.

.DESCRIPTION
Removes any known prefix, such as "feature" or "bug", from the Git branch name.
#>
function Remove-KnownPrefixFromBranchName (
    [string]$BranchName
)
{
    foreach ($prefixToIgnore in $script:_branchPrefixesToIgnore)
    {
        # Regex Pattern:
        #   ^$prefixToIgnore    Branch name starts with prefix to ignore
        #   [/\.\-_]            A separator character.  One of: 
        #                           / (forward slash)
        #                           . (period)
        #                           - (hyphen)
        #                           _ (underscore) 
        #   (.+)                Capture group: One or more of any characters
        # So the prefix will only be stripped off if it's followed by a separator then 
        # at least one further character.  Prefix by itself or prefix + separator without 
        # any further text will not be stripped from the branch name.
        $regexPattern = "^$prefixToIgnore[/\.\-_](.+)"
        if ($BranchName -imatch $regexPattern)
        {
            # $matches[0] is the whole text that matches the regex pattern.  $matches[1] is the 
            # text in the first capture group.
            return $matches[1]
        }
    }

    return $BranchName
}

<#
.SYNOPSIS
Gets the prefix, based on the Git branch, that will be prepended to the Git commit message.

.DESCRIPTION
Cleans up branch names that are based on Jira issues or numeric ticket numbers.  Any known 
branch prefixes, such as "feature" or "bug", will be stripped out.  Examples:

    1) Branch "feature/toll319_TripManifest"                    -> prefix "TOLL-319" 
    2) Branch "Smiths-742"                                      -> prefix "SMITHS-742" 
    3) Branch "smiths742-smiths789"                             -> prefix "SMITHS-742-SMITHS-789" 
    4) Branch "bugfix/123456-bulkinsert-incorrect-deductions"   -> prefix "123456" 
    5) Branch "bug/123456-134567-bulk-import-error"             -> prefix "123456-134567" 
    6) Branch "feature/add-dashboard"                           -> prefix "add-dashboard" 

For Jira-style ticket numbers the cleaned up branch names will take the form: 
    {CAPITALIZED TEXT}-{issue number}
Any leading spaces and any trailing non-digit characters (eg text, hyphens, underscores, spaces) 
will be stripped out.

Note that for Jira-style ticket numbers the hyphen is optional in the branch name - it will be 
inserted into the prefix that is returned if it doesn't exist in the branch name.

Branch names that include either Jira issue numbers or numeric ticket numbers can include a parent 
issue and a child issue number.  Both parent and child numbers will be included in the prefix.  
The parent and child issue numbers can be separated by either a hyphen ("-") or an 
underscore ("_").

Any branch names that don't match either the Jira-style ticket pattern or a numeric ticket number 
will have known branch prefixes, such as "feature" or "bug", stripped out and the remainder of 
the branch name will be returned unchanged.
#>
function Get-CommitMessagePrefix (
    [string]$BranchName
)
{
    if (-not $BranchName)
    {
        return ''
    }

    $strippedBranchName = Remove-KnownPrefixFromBranchName -BranchName $BranchName

    $commitMessagePrefix = $strippedBranchName

    # Jira-style Regex Pattern:

    # Examples:
    #   Branch Name                                 Resulting Prefix
    #   -----------                                 ----------------
    #   smiths-123-add-bulk-import                  SMITHS-123
    #   smiths123-add-bulk-import                   SMITHS-123
    #   smiths-123_smiths-987-bulk-import-error     SMITHS-123-SMITHS-987
    #                                                   (assumption is that SMITHS-123 is the 
    #                                                   parent issue and SMITHS-987 is the child)

    # Regex Pattern:
    #   ^([A-Za-z]+)    First capture group at the start of the branch name: Matches one or more 
    #                       upper or lower case letters 
    #   -?              An optional "-" (hyphen)
    #   (\d+)           Second capture group: Matches one or more digits, (Jira issue number)
    #   [-_]?           An optional "-" (hyphen) or "_" (underscore)
    #   (?:...)?        An optional non-capture group, containing the third and forth capture 
    #                       groups, identical to the first and second capture groups
    #   
    $regexPattern = "^([A-Za-z]+)-?(\d+)[-_]?(?:([A-Za-z]+)-?(\d+))?"

    if ($strippedBranchName -imatch $regexPattern)
    {    
        $commitMessagePrefix = "$($matches[1].ToUpper())-$($matches[2])"

        # Count must be 5, not 4: $matches[0], representing all the text that matches, plus the 
        # 4 capture groups.
        if ($matches.Count -ge 5)
        {
            $commitMessagePrefix += "-$($matches[3].ToUpper())-$($matches[4])"
        }

        return $commitMessagePrefix.Trim()
    }

    # Azure Boards workitem number / GitHub issue number with optional child issue: 

    # Examples:
    #   Branch Name                                 Resulting Prefix
    #   -----------                                 ----------------
    #   123456-add-bulk-import                      123456
    #   123456-134567-bulk-import-error             123456-134567 
    #                                                   (assumption is that 123456 is the parent 
    #                                                   issue and 134567 is the child)

    # Regex Pattern:
    #   ^(\d+)              First capture group at the start of the branch name: Matches one or 
    #                       more digits
    #   (?:[-_](\d+))?      Optional non-capture group: Matches a dash or underscore followed by 
    #                       a capture group matching one or more digits
    $regexPattern = "^(\d+)(?:[-_](\d+))?"

    if ($strippedBranchName -imatch $regexPattern)
    {    
        $commitMessagePrefix = $matches[1]

        # Count must be 3, not 2: $matches[0], representing all the text that matches, plus the 
        # 2 capture groups.
        if ($matches.Count -ge 3)
        {
            $commitMessagePrefix += '-' + $matches[2]
        }
    }
    
    return $commitMessagePrefix.Trim()
}

function Exit-IfEditingExistingCommit (
    [string]$ExistingCommitMessageFirstLine,
    [string]$CommitMessagePrefix
)
{
    $ExistingCommitMessageFirstLine = $ExistingCommitMessageFirstLine.Trim()

    if ($ExistingCommitMessageFirstLine.StartsWith('fixup!'))
    {
        Write-OutputMessage 'Fixup commit message will not be modified.'

        Exit-WithSuccess
    }
    
    if ($ExistingCommitMessageFirstLine.StartsWith('squash!'))
    {
        Write-OutputMessage 'Squash commit message will not be modified.'

        Exit-WithSuccess
    }
    
    if ($ExistingCommitMessageFirstLine.StartsWith($CommitMessagePrefix))
    {
        Write-OutputMessage 'Commit message already has a prefix; commit message will not be modified.'

        Exit-WithSuccess
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
        return $FileContents.ForEach({ "  $_" })
    }

    return $FileContents
}
    
#endregion

#region Module Members to Export ******************************************************************

Export-ModuleMember -Function Start-GitHook

#endregion