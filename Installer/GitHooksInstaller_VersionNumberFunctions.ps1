<#
.SYNOPSIS
Functions related to script version numbers, called when installing Git hook scripts on a user's 
computer.

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

<#
.SYNOPSIS
Gets user-friendly display text representing a script version number, from a version-number array.

.DESCRIPTION
The version-number array should have four elements.  These will be concatenated together in the 
form "x.x.x.x".  User-friendly text will be displayed if the array is $Null or has no elements.
#>
function Get-VersionArrayDisplayText (
    [array]$VersionArray
    )
{
    if ($VersionArray -eq $Null)
    {
        return '[NULL]'
    }
    if ($VersionArray.Count -eq 0)
    {   
        return '[EMPTY]'
    }

    return $VersionArray -join '.'
}

<#
.SYNOPSIS
Gets the regular expression pattern used to extract a version number from a text file.

.NOTES
The regular expression pattern will extract the first version number in the contents of the file 
in the form:

[#...] Version : x.x.x.x

where [#...] are one or more optional comment symbols, and the x's represent numbers.

#>
function Get-VersionNumberRegexPattern ()
{
    # Regex Pattern to retrieve version number from a line of text:
    <#
        ^                  The text matching the pattern must be at the start of the line
        \s*                Optional whitespaces (zero or more)
        #*                 Optional "#" characters (zero or more)
        \s*                Optional whitespaces (zero or more)
        Version            Required word "Version" (NB: We're doing a case-insensitive comparison)
        \s*                Optional whitespaces (zero or more)
        :                  Required character ":"
        \s*                Optional whitespaces (zero or more)
        (                  Start of capture group to capture the version number
          [^\.\s]{1,12}    Required 1-12 characters (any characters except period (fullstop) and 
                           whitespace)     
          (?:\.[^\.\s]{1,12}){0,3}    Optional non-capturing group: period (fullstop) followed by 
                                      1-12 characters (any characters except period (fullstop) and 
                                      whitespace).  The group may appear 0-3 times
        )                  End of capture group to capture the version number
    #>

    # So we're looking for lines that start something like:
    <#

      #   Version  :   1.10.2.345678
    ^ ^ ^         ^  ^   ^
    | | |         |  |   |
    | |  \        | /    Number can have 1-4 parts
    | | Optional spaces
    | One or more "#"
    Optional spaces

    or       
       Version  :   1.10.2.345678
    (as above but without any "#" at the start of the line, for version numbers embedded in block 
    comments)

    A minimal version might be (without any spaces, and with only one part to the version number):

    Version:1

    Will also pick up non-numeric version numbers like:

    Version  :   a.b.c.d
    Version  :   1a
    Version  :   1.a
    Version  :   1a.b.c.d
    Version  :   1.a#.c.d
    (we'll exclude them later on because it's too hard to exclude them reliably in the regex)

    #> 
    $regexPattern = '^\s*#*\s*Version\s*:\s*([^\.\s]{1,12}(?:\.[^\.\s]{1,12}){0,3})'

    return $regexPattern
}

<#
.SYNOPSIS
Gets the version number from the contents of a script file as a string.

.DESCRIPTION
Uses a regular expression to find the first version number in the contents of the file in the 
form:

[#...] Version: x.x.x.x

where [#...] are one or more optional comment symbols and leading whitespace, and the "x.x.x.x" 
represents the version number string that will be returned.

The characters in the version number do not have to be numeric, eg "1.2a.3.#".  However, no 
whitespace is allowed within the version number.  For example if the version number line in a 
file is "Version : 1.2. 3.4" then the version number that is returned will be "1.2".

.OUTPUTS
String.

The version number text embedded in the contents of the specified script file.

If the file is not found "0.0.0.0" will be returned.

If the version number text has more than four parts, eg "1.2.3.4.5" then only the first four 
parts will be returned, eg "1.2.3.4".
#>
function Get-ScriptFileVersionString (
    [string]$ScriptPath
    )
{    
    $regexPattern = Get-VersionNumberRegexPattern

    # Files that have not been found should have a really low version number so the file will 
    # be copied from the source.
    $defaultVersionText = '0.0.0.0'
    # Assume files without versions are custom scripts saved by the user, as all our script files 
    # should have a version number.  We don't want to overwrite scripts created by users so give 
    # them a really high version number.
    $fileWithoutVersionText = '99999.0.0.0'
    
    Write-LogMessage "Getting version number for file '${ScriptPath}'..." -IsDebug

    if (-not (Test-Path $ScriptPath -PathType Leaf))
    {
        $logMessage = "File '${ScriptPath}' was not found.  Returning version $defaultVersionText."
        Write-LogMessage $logMessage -IsInformation
        return $defaultVersionText
    }

    Write-LogMessage "File '${ScriptPath}' found.  Searching file for version number..." -IsDebug

    $matchInfo = Select-String -Path $ScriptPath -Pattern $regexPattern

    if (-not $matchInfo)
    {
        $logMessage = "No version number found in file '${ScriptPath}'.  " `
            + "Returning version $fileWithoutVersionText." 
        Write-LogMessage $logMessage -IsDebug
        return $fileWithoutVersionText
    }

    # We're only interested in the first match.
    $match = $matchInfo.Matches[0]

    # Group 0 is the whole match, group 1 is the text from the capture group.
    if ($match.Groups.Count -eq 1)
    {
        # This shouldn't be possible: Match but no capture group.
        $logMessage = "No capture group found for regex match in file '${ScriptPath}'.  " `
            + "Returning version $fileWithoutVersionText." 
        Write-LogMessage $logMessage -IsDebug
        return $fileWithoutVersionText
    }

    $versionNumberText = $match.Groups[1].Value

    Write-LogMessage "Version number found in file '${ScriptPath}':  $versionNumberText" -IsDebug

    Write-Output $versionNumberText
}

<#
.SYNOPSIS
Converts a version number string to an array of version number parts.

.DESCRIPTION
Converts a version number string, of the form "1.2.3.4" to an array of the form @(1,2,3,4).

If the version number string has less than four parts it will be padded with zeros to a 
four-part array.  For example "1.2" => @(1,2,0,0).

If the version number string has more than four parts only the first four parts will be returned 
in the array.  For example "1.2.3.4.5" => @(1,2,3,4).

If no version number string is supplied, or if the supplied version number string contains 
non-numeric characters (eg "1.2a.3.#") a default version number array will be returned: 
@(99999,0,0,0).  

.NOTES
The large leading number in the default version number array ensures that a destination file 
will not be overwritten if a user has created the file.  The assumption being that a file 
without a version number, or with an invalid one, has been created by a user since all the 
"official" files will have valid numeric version numbers.
#>
function Convert-VersionNumberStringToArray (
    [string]$VersionNumberText
    )
{
    $defaultVersionArray = @(99999, 0, 0, 0)
    $defaultVersionText = $defaultVersionArray -join ','

    Write-LogMessage "Converting version number string to array..." -IsDebug

    if ([string]::IsNullOrWhiteSpace($VersionNumberText))
    {
        $logMessage = "No version number supplied.  " `
            + "Returning default version number:  $defaultVersionText"
        Write-LogMessage $logMessage -IsDebug
        return $defaultVersionArray
    }

    $tempArray = @()
    try 
    {
        $tempArray = $VersionNumberText.Split('.').ForEach([int])
    }
    catch 
    {
        $logMessage = "Invalid, non-numeric, version number '$versionNumberText'.  " `
            + "Returning version $defaultVersionText."
        Write-LogMessage $logMessage -IsDebug
        return $defaultVersionArray
    }  
    
    

    # Ensure array returned has four parts.  If not pad with trailing zeros.
    $versionArray = @(0, 0, 0, 0)

    $numberOfElements = $tempArray.Count
    if ($numberOfElements -gt $versionArray.Count)
    {
        $numberOfElements = $versionArray.Count
    }

    for($i=0; $i -lt $numberOfElements; $i++)
    {
        $versionArray[$i] = $tempArray[$i]
    }

    $returnedVersionText = $versionArray -join ','
    Write-LogMessage "Version number returned:  $returnedVersionText" -IsDebug

    Write-Output $versionArray
}

<#
.SYNOPSIS
Gets the version number from the contents of a script file, as an integer array.

.DESCRIPTION
Uses a regular expression to find the first version number in the contents of the file in the 
form:

[#...] Version: x.x.x.x

where [#...] are one or more optional comment symbols and leading whitespace, and the "x.x.x.x" 
represents the version number that will be returned.

A version number in the contents of a file: 

    Version :  1.20.2.3563

will be converted to array: 

    @(1,20,2,3563)

.OUTPUTS
Array of four integers representing the version number found in the file.

If the file is not found array @(0,0,0,0) will be returned, to ensure the file is created.

If the file does NOT contain a version number, or if the version number is invalid (eg one or 
more parts is not numeric) then array @(99999,0,0,0) will be returned.  This ensures that a 
destination file will not be overwritten if a user has created the file.  The assumption being 
that a file without a version number, or with an invalid one, has been created by a user since 
all the "official" files will have valid numeric version numbers.

If the version number in the file has less than four parts then it will be right-padded with 
zeros to ensure the array has four parts, eg "1.2" => @(1,2,0,0)

If the version number in the file has more than four parts then only the first four parts will 
be returned in the array eg "1.2.3.4.5" => @(1,2,3,4).
#>
function Get-ScriptFileVersion (
    [string]$ScriptPath
    )
{
    $versionNumberString = Get-ScriptFileVersionString $ScriptPath
    $versionNumberArray = Convert-VersionNumberStringToArray $versionNumberString

    return $versionNumberArray
}

<#
.SYNOPSIS
Gets an array of the paths to all files under a specified directory, relative to that directory.

.DESCRIPTION
Recursively retrieves all files under a specified directory (all the files in the directory, and 
in the tree of sub-directories rooted on that directory).  Returns an array of paths to those 
files, relative to the specified directory.
#>
function Get-DirectoryFileRelativePath (
    [string]$DirectoryPath
    )
{
    if (-not (Test-Path $DirectoryPath -PathType Container))
    {
        $errorMessage = "Directory '${DirectoryPath}' does not exist.  Exiting."
        Write-LogMessage $errorMessage -IsError
        throw $errorMessage
    }

    Write-LogMessage "Recursively retrieving list of files under directory '${DirectoryPath}'..." -IsDebug
        
    # $PWD is the current working directory (FileInfo object).
    $originalWorkingDirectory = $PWD

    # Want relative paths below the source directory.  Resolve-Path -Relative is relative to 
    # location set in Set-Location.
    Set-Location -Path $DirectoryPath
    $fileNameList = Get-ChildItem -Path $DirectoryPath -File -Recurse | 
        Select-Object PsPath |
        Resolve-Path -Relative

    Write-LogMessage "$($fileNameList.Count) files found under directory '${DirectoryPath}'." -IsDebug

    Set-Location -Path $originalWorkingDirectory

    return $fileNameList
}

<#
.SYNOPSIS 
Gets an array of script file version numbers for the files in a specified directory.

.DESCRIPTION
Gets the version numbers embeded in the contents of each file, not their file version 
from the file system.

If no list of files is supplied the function will get version numbers of every file in the 
specified directory and, recursively, in its sub-directories.

If no list of files is supplied and the directory path does not exist the function will exit 
with an error code.

The directory path may not exist if a list of files is supplied.  This may occur when 
testing a destination directory for a file copy.  In that case we want to copy all files from 
the source directory so the version number for each file will be set to @(0,0,0,0).

.OUTPUTS
System.Collections.Hashtable

A hashtable where the keys are the paths of the files, relative to the specified directory, 
and the values are four-part arrays with the version numbers read from the files.
#>
function Get-DirectoryScriptVersion (
    [string]$DirectoryPath,    
    [array]$FileNameList
    )
{
    Write-LogMessage "Getting script versions for directory '${DirectoryPath}'..." -IsDebug

    if ([string]::IsNullOrWhiteSpace($DirectoryPath))
    {
        $errorMessage = 'Directory not specified.  Exiting.'
        Write-LogMessage $errorMessage -IsError
        throw $errorMessage
    }

    if (-not $FileNameList -or $FileNameList.Count -eq 0)
    {
        $errorMessage = 'No file names specified.  Exiting.'
        Write-LogMessage $errorMessage -IsError
        throw $errorMessage
    }
    
    Write-LogMessage "Generating full file names..." -IsDebug

    # Keys are the short filenames, values are the long filenames.
    $fileNames = @{}
    # can't use -Resolve switch with Join-Path because that will raise error if path component 
    # (eg sub-directory) does not exist.  Not a problem since we won't include any wildcards 
    # in directory or file paths.
    $FileNameList.ForEach{ $fileNames[$_] = (Join-Path -Path $DirectoryPath -ChildPath $_) }

    Write-LogMessage "$($fileNames.Keys.Count) generated." -IsDebug
    
    # Keys are the short filenames, values are the file version numbers, as arrays.
    $scriptVersions = @{}
    $fileNames.Keys.ForEach{ $scriptVersions[$_] = (Get-ScriptFileVersion $fileNames[$_]) }

    $logMessage = "Returning $($scriptVersions.Values.Count) version numbers " `
        + "for files under directory '${DirectoryPath}'."
    Write-LogMessage $logMessage -IsInformation

    Write-Output $scriptVersions
}

<#
.SYNOPSIS
Compares two version number arrays and indicates whether they are identical and, if not, which 
is the lesser of the two.

.DESCRIPTION
Compares elements in identical positions in the two arrays.  If the two elements are identical it 
will continue to the next element position.  

If the element in the left-hand array is less than the element in the right-hand array the 
comparison is stopped and '<' is returned.

If the element in the left-hand array is greater than the element in the right-hand array the 
comparison is stopped and '>' is returned.

If one array has less elements than the other the shorter array is effectively padded with 
trailing zeros to make it the same length as the longer array.  the arrays are then compared in 
the normal way.

If the comparison reaches the end of the two arrays without finding a difference in any elements 
the arrays must be identical.  In that case '=' is returned.

.OUTPUTS
System.String

A single character which can take one of the following values:

'=' :   The two arrays are identical;
'<' :   The left-hand array is less than the right-hand one;
'>' :   The left-hand array is greater than the right-hand one.

#>
function Compare-Version (
    [array]$LeftVersionArray,
    [array]$RightVersionArray
    )
{
    $leftDisplayText = Get-VersionArrayDisplayText $LeftVersionArray
    $rightDisplayText = Get-VersionArrayDisplayText $RightVersionArray
    Write-LogMessage "Comparing version arrays $leftDisplayText and $rightDisplayText..." -IsDebug

    $leftIsEmpty = $False
    if ($LeftVersionArray -eq $Null -or $LeftVersionArray.Count -eq 0)
    {
        $leftIsEmpty = $True    
    }

    if ($RightVersionArray -eq $Null -or $RightVersionArray.Count -eq 0)
    {
        if ($leftIsEmpty)
        {
            Write-LogMessage 'Both version arrays are Null or empty.' -IsDebug
            return '='
        }   
        
        Write-LogMessage 'Right version array is Null or empty.' -IsDebug
        return '>'
    }

    if ($leftIsEmpty)
    {
        Write-LogMessage 'Left version array is Null or empty.' -IsDebug
        return '<'
    }
    
    $numberOfElements = ($LeftVersionArray.Count,$RightVersionArray.Count | 
                            Measure-Object -Minimum).Minimum 
    
    for($i=0; $i -lt $numberOfElements; $i++)
    {
        Write-LogMessage "Comparing element $i..." -IsDebug

        if ($LeftVersionArray[$i] -lt $RightVersionArray[$i])
        {
            Write-LogMessage 'Left version element is less than equivalent right version element.' -IsDebug
            return '<'
        }
        if ($LeftVersionArray[$i] -gt $RightVersionArray[$i])
        {
            Write-LogMessage 'Left version element is greater than equivalent right version element.' -IsDebug
            return '>'
        }
    }

    if ($LeftVersionArray.Count -gt $numberOfElements)
    {
        Write-LogMessage 'Left version array has more elements than right so is greater.' -IsDebug
        return '>'
    }

    if ($RightVersionArray.Count -gt $numberOfElements)
    {
        Write-LogMessage 'Left version array has fewer elements than right so is lesser.' -IsDebug
        return '<'
    }

    Write-LogMessage 'Left and right version arrays are identical.' -IsDebug
    return '='
}