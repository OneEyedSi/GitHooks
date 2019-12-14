<#
.SYNOPSIS
Tests of the functions in the GitHooksInstaller_VersionNumberFunctions.ps1 file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                AssertExceptionThrown module (see https://github.com/AnotherSadGit/PesterAssertExceptionThrown)
Version:		0.5.0
Date:			1 Jul 2019
#>

# NOTE: #Requires is not a comment, it's a requires directive.
#Requires -Modules AssertExceptionThrown

# Can't dot source directly using a simple relative path as relative paths are relative to the 
# current working directory, not the directory this test file is in.  The current working 
# directory could be anything.  So Use $PSScriptRoot to get the directory this file is in, and 
# use a path relative to that.
. (Join-Path $PSScriptRoot '..\Installer\GitHooksInstaller_VersionNumberFunctions.ps1' -Resolve)

Describe 'Get-VersionArrayDisplayText' {

    It 'returns "[NULL]" when version array is $Null' {        
        Get-VersionArrayDisplayText $Null | Should -Be '[NULL]'
    }

    It 'returns "[EMPTY]" when version array has no elements' {        
        Get-VersionArrayDisplayText @() | Should -Be '[EMPTY]'
    }

    It 'returns version numbers joined with periods when version array has elements' { 
        $array = @(0, 1, 2, 3)       
        Get-VersionArrayDisplayText $array | Should -Be '0.1.2.3'
    }
}

function GetRegex ([string]$RegexPattern)
{
    $regex = New-Object System.Text.RegularExpressions.Regex($RegexPattern, 
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    return $regex
}

function TestRegexMatch ([string]$TextToSearch, [string]$ExpectedVersionNumber, [System.Text.RegularExpressions.Regex]$Regex)
{
    $match = $Regex.Match($TextToSearch)

    $match.Success | Should -Be $True
    # match has two groups, not one, because the first group is the match 
    # and the second group is the capture group.
    $match.Groups.Count | Should -Be 2
    $match.Groups[1].Value | Should -be $ExpectedVersionNumber
}

function TestRegexNonMatch ([string]$TextToSearch, [System.Text.RegularExpressions.Regex]$Regex)
{
    $match = $Regex.Match($TextToSearch)
    $match.Success | Should -Be $False
}

Describe 'VersionNumberRegexPattern' {
    $regexPattern = Get-VersionNumberRegexPattern
    $regex = GetRegex -RegexPattern $regexPattern
    
    It 'does not match empty string' {
        TestRegexNonMatch -TextToSearch '' -Regex $regex
    }
    
    It 'does not match blank string' {
        TestRegexNonMatch -TextToSearch '  ' -Regex $regex
    }
    
    It 'does not match version number without colon' {
        TestRegexNonMatch -TextToSearch 'version 1' -Regex $regex
    }
    
    It 'reads single digit version number with no leading spaces or comments' {
        TestRegexMatch -TextToSearch 'version:1' -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads single digit version number with leading spaces' {
        TestRegexMatch -TextToSearch '  version:1' -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads single digit version number with leading tabs' {
        TestRegexMatch -TextToSearch "`t`tversion:1" -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads single digit version number with leading comment characters' {
        TestRegexMatch -TextToSearch '##  version:1' -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads single digit version number with spaces around colon' {
        TestRegexMatch -TextToSearch 'version  :  1' -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads single digit version number with tabs around colon' {
        TestRegexMatch -TextToSearch "version`t:`t1" -ExpectedVersionNumber '1' -Regex $regex
    }
    
    It 'reads 2-part version number' {
        TestRegexMatch -TextToSearch '  version  :  1.2' -ExpectedVersionNumber '1.2' -Regex $regex
    }
    
    It 'reads 4-part version number' {
        TestRegexMatch -TextToSearch '  version  :  1.2.3.4' -ExpectedVersionNumber '1.2.3.4' -Regex $regex
    }
    
    It 'reads only first 4-parts of a 5-part version number' {
        TestRegexMatch -TextToSearch '  version  :  1.2.3.4.5' -ExpectedVersionNumber '1.2.3.4' -Regex $regex
    }
    
    It 'reads single non-numeric version number' {
        TestRegexMatch -TextToSearch '  version  :  a#' -ExpectedVersionNumber 'a#' -Regex $regex
    }
    
    It 'reads single version number with a mixture of numeric and non-numeric characters' {
        TestRegexMatch -TextToSearch '  version  :  1a' -ExpectedVersionNumber '1a' -Regex $regex
    }
    
    It 'reads multi-part non-numeric version number' {
        TestRegexMatch -TextToSearch '  version  :  a.b.c.d' -ExpectedVersionNumber 'a.b.c.d' -Regex $regex
    }
    
    It 'reads multi-part version number with some numeric and some non-numeric parts' {
        TestRegexMatch -TextToSearch '  version  :  1.b.3.d' -ExpectedVersionNumber '1.b.3.d' -Regex $regex
    }
    
    It 'reads multi-part version number with individual part that mixes numeric and some non-numeric characters' {
        TestRegexMatch -TextToSearch '  version  :  1.2#.3c' -ExpectedVersionNumber '1.2#.3c' -Regex $regex
    }
    
    It 'reads version number with multiple digits in each part' {
        TestRegexMatch -TextToSearch '  version  :  100000.200000.300000.400000' -ExpectedVersionNumber '100000.200000.300000.400000' -Regex $regex
    }
    
    It 'retains leading zeros in version number' {
        TestRegexMatch -TextToSearch '  version  :  01.02.03.04' -ExpectedVersionNumber '01.02.03.04' -Regex $regex
    }
}

Describe 'Get-ScriptFileVersionString' {

    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage 
        
    $testFilePath = 'C:\TestFile.txt'
    $allZeroVersionString = '0.0.0.0'
    $highValuedVersionString = '99999.0.0.0'

    Context 'file not found' {
        Mock Test-Path { return $False }

        It 'returns all-zero version string' {
            Get-ScriptFileVersionString $testFilePath | Should -Be $allZeroVersionString
        }
    }    

    Context 'file found but no version number' {
        Mock Test-Path { return $True }
        Mock Select-String { return @() }

        It 'returns high-valued version string' {
            Get-ScriptFileVersionString $testFilePath | Should -Be $highValuedVersionString
        }
    }        

    Context 'version number found but no group captured' {
        Mock Test-Path { return $True }
        Mock Select-String { 
            # Want a match without a capture group.
            $match = [System.Text.RegularExpressions.Regex]::Match('xxx', 'xxx')

            $matchInfo = New-Object PSObject | 
                Add-Member -MemberType NoteProperty -Name Matches -Value @( $match ) -PassThru

            return $matchInfo
        }

        It 'returns high-valued version string' {
            $result = Get-ScriptFileVersionString $testFilePath 

            $result | Should -Be $highValuedVersionString
            Assert-MockCalled Write-LogMessage -Scope It -Times 1 `
                -ParameterFilter { $Message -like 'No capture group found for regex*' } 
        }
    }           

    Context 'version number found and group captured' {
        Mock Test-Path { return $True }
        Mock Select-String { 
            # Want a match with a capture group.
            $match = [System.Text.RegularExpressions.Regex]::Match('A number: 42', '(\d\d)')

            $matchInfo = New-Object PSObject | 
                Add-Member -MemberType NoteProperty -Name Matches -Value @( $match ) -PassThru

            return $matchInfo
        }

        It 'returns version string' {
            $result = Get-ScriptFileVersionString $testFilePath 

            $result | Should -Be '42'
        }
    } 
}

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

Describe 'Convert-VersionNumberStringToArray' {
    
    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage 
    
    $defaultVersionArray = @(99999, 0, 0, 0)

    function AssertCorrectArrayReturned (
        [array]$ExpectedArray, 
        [array]$ActualArray, 
        [string]$LogMessagePattern
    )
    {
        # Will throw exception if arrays don't match.
        AssertArrayMatch $ExpectedArray $ActualArray

        if (-not [string]::IsNullOrWhiteSpace($LogMessagePattern))
        {
            Assert-MockCalled Write-LogMessage -Scope It -Times 1 `
                -ParameterFilter { $Message -like $LogMessagePattern } 
        }
    }

    Context 'version number string not supplied' {
        
        $errorMessagePattern = 'No version number supplied*'

        It 'returns default array when version string is empty' {
            $result = Convert-VersionNumberStringToArray ''

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when version string is blank' {
            $result = Convert-VersionNumberStringToArray '  '

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }
    }

    Context 'version number string contains non-numeric' {

        $errorMessagePattern = 'Invalid, non-numeric, version number*'

        It 'returns default array when version string is single non-numeric "word"' {
            $result = Convert-VersionNumberStringToArray 'ab'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when first part of version string is non-numeric "word"' {
            $result = Convert-VersionNumberStringToArray 'ab.2.3.4'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when version string is single "word" containing non-numeric character' {
            $result = Convert-VersionNumberStringToArray '1a'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when first part of version string contains non-numeric character' {
            $result = Convert-VersionNumberStringToArray '1a.2.3.4'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when second part of version string is non-numeric' {
            $result = Convert-VersionNumberStringToArray '1.a.3.4'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }

        It 'returns default array when second part of version string contains non-numeric character' {
            $result = Convert-VersionNumberStringToArray '1.2a.3.4'

            AssertCorrectArrayReturned $defaultVersionArray $result $errorMessagePattern
        }
    }

    Context 'valid numeric version number string' {

        It 'returns array matching valid four-part version number string' {
            $result = Convert-VersionNumberStringToArray '1.2.3.4'

            AssertCorrectArrayReturned @(1,2,3,4) $result
        }

        It 'returns array without error when version numbers in string had leading zeros' {
            $result = Convert-VersionNumberStringToArray '01.02.03.04'

            AssertCorrectArrayReturned @(1,2,3,4) $result
        }

        It 'returns four-part array padded with trailing zeros for two-part version number string' {
            $result = Convert-VersionNumberStringToArray '1.2'

            AssertCorrectArrayReturned @(1,2,0,0) $result
        }

        It 'returns four-part array matching the first four parts of a five-part version number string' {
            $result = Convert-VersionNumberStringToArray '1.2.3.4.5'

            AssertCorrectArrayReturned @(1,2,3,4) $result
        }
    }
}

function CreateEmptyTestFiles ([string]$RootDirectoryPath, [array]$FileNames)
{    
    $objectArray = @()
    $FileNames.ForEach{ $objectArray += [pscustomobject]@{ ChildPath=$_ } }
    $fileFullPaths = $objectArray | Join-Path -Path $RootDirectoryPath 
    New-Item -ItemType File -Path $fileFullPaths -Force
}

function GetRelativeFilePaths
{
    # Need leading '.\' on each file name to match relative paths returned from function under 
    # test.
    return @(
                '.\Test1.txt'
                '.\Test2.txt'
                '.\SubDir\Sub1.txt'
                '.\SubDir\Sub2.txt'
            ) | Sort-Object # Sort alphabetically to make comparison with actual results easy.
}

function GetFileVersionNumbers ($FilePaths)
{
    $versionNumberArray = @()
    foreach($i in 1..$FilePaths.Count)
    {
        # Note leading comma.  Without it the array would be unrolled and each element would 
        # be added separately, resulting in a large 1-D array instead of an array of arrays.
        $versionNumberArray += ,@($i,0,0,0)
    }

    return $versionNumberArray
}

Describe 'Get-DirectoryFileRelativePath' {
    
    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage 

    $directoryPath = 'TestDrive:\TestDir'
    
    $fileRelativePaths = GetRelativeFilePaths

    Context 'directory does not exist' {

        It 'throws an error when directory does not exist' {

            { Get-DirectoryFileRelativePath $directoryPath } | 
                Assert-ExceptionThrown -WithMessage 'does not exist'
        }
    }

    Context 'directory exists' {
        
        CreateEmptyTestFiles -RootDirectoryPath $directoryPath -FileNames $fileRelativePaths

        $originalPath = $pwd.Path

        It 'does not throw an error' {

            { Get-DirectoryFileRelativePath $directoryPath } | Assert-ExceptionThrown -Not
        }

        It 'resets location to original directory when finishes' {
            Get-DirectoryFileRelativePath $directoryPath

            (Get-Location).Path | Should -Be $originalPath
        }

        It 'returns collection of relative file paths' {
            # Sort to simplify comparison with expected array.
            $actualFilePaths = Get-DirectoryFileRelativePath $directoryPath | Sort-Object

            AssertArrayMatch -ExpectedArray $fileRelativePaths -ActualArray $actualFilePaths
        }
    }
}

Describe 'Get-DirectoryScriptVersion' {
    
    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage 

    $directoryPath = 'TestDrive:\TestDir'
    
    $fileRelativePaths = GetRelativeFilePaths

    Context 'inputs not supplied' {
        
        It 'throws error if directory path is Null' {
            { Get-DirectoryScriptVersion -DirectoryPath $Null -FileNameList $fileNameList } | 
                Assert-ExceptionThrown -WithMessage 'Directory not specified'
        }
        
        It 'throws error if directory path is empty' {
            { Get-DirectoryScriptVersion -DirectoryPath '' -FileNameList $fileNameList } | 
                Assert-ExceptionThrown -WithMessage 'Directory not specified'
        }
        
        It 'throws error if directory path is blank' {
            { Get-DirectoryScriptVersion -DirectoryPath '  ' -FileNameList $fileNameList } | 
                Assert-ExceptionThrown -WithMessage 'Directory not specified'
        }
        
        It 'throws error if file name list is Null' {
            { Get-DirectoryScriptVersion -DirectoryPath $directoryPath -FileNameList $Null } | 
                Assert-ExceptionThrown -WithMessage 'No file names specified'
        }
        
        It 'throws error if file name list is empty' {
            { Get-DirectoryScriptVersion -DirectoryPath $directoryPath -FileNameList @() } | 
                Assert-ExceptionThrown -WithMessage 'No file names specified'
        }
    }

    Context 'inputs supplied' {
        
        BeforeEach {
            $mockState = @{
                            VersionNumber = 0    
                        }
        }

        Mock Get-ScriptFileVersion {
            $mockState.VersionNumber++

            return @($mockState.VersionNumber,0,0,0)
        }

        It 'returns hash table with relative file paths as the keys' {
            $results = Get-DirectoryScriptVersion -DirectoryPath $directoryPath `
                -FileNameList $fileRelativePaths

            # $fileRelativePaths already sorted.
            $resultKeys = $results.Keys | Sort-Object

            AssertArrayMatch -ExpectedArray $fileRelativePaths -ActualArray $resultKeys
        }

        It 'returns hash table with version number arrays as the values' {
            $results = Get-DirectoryScriptVersion -DirectoryPath $directoryPath `
                -FileNameList $fileRelativePaths

            $expectedVersionNumberArrays = GetFileVersionNumbers $fileRelativePaths
            # Multidimensional arrays are automatically sorted by the first element of each child 
            # array.
            $resultVersionNumberCollection = $results.Values | Sort-Object
            $expectedVersionNumberCount = $expectedVersionNumberArrays.Count

            if ($resultVersionNumberCollection -eq $Null -or $resultVersionNumberCollection.Count -eq 0)
            {
                throw "Expected array of $expectedVersionNumberCount version numbers.  No version numbers returned."
            }

            if ($expectedVersionNumberCount -ne $resultVersionNumberCollection.Count)
            {
                throw "Expected array of $expectedVersionNumberCount version numbers.  ${resultVersionNumberCollection.Count} version numbers returned."
            }

            # Cannot get a value from the hash table Values collection via an index.  So iterate through them.
            $i = 0
            foreach($resultValue in $resultVersionNumberCollection)
            {
                 AssertArrayMatch -ExpectedArray $expectedVersionNumberArrays[$i] -ActualArray $resultValue
                $i++
            }       
        }
    }
}

function AssertVersionArrayComparisonResult (
    [array]$LeftVersionArray,
    [array]$RightVersionArray, 
    [string]$ExpectedResult
    )
{
    $result = Compare-Version $LeftVersionArray $RightVersionArray
    $result | Should -Be $ExpectedResult
}

Describe 'Compare-Version' {
    
    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Write-LogMessage

    It 'returns "=" when both version arrays are Null' {
        AssertVersionArrayComparisonResult $Null $Null '='
    }

    It 'returns "=" when both version arrays are empty arrays' {
        AssertVersionArrayComparisonResult @() @() '='
    }

    It 'returns "=" when left version array is Null and right array is empty' {
        AssertVersionArrayComparisonResult $Null @() '='
    }

    It 'returns "=" when left version array is empty and right array is Null' {
        AssertVersionArrayComparisonResult $Null @() '='
    }

    It 'returns "<" when left version array is Null and right array is populated' {
        AssertVersionArrayComparisonResult $Null @(1,2,3,4) '<'
    }

    It 'returns "<" when left version array is empty and right array is populated' {
        AssertVersionArrayComparisonResult @() @(1,2,3,4) '<'
    }

    It 'returns ">" when left version array is populated and right array is Null' {
        AssertVersionArrayComparisonResult @(1,2,3,4) $Null '>'
    }

    It 'returns ">" when left version array is populated and right array is empty' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @() '>'
    }

    It 'returns "=" when both version arrays are populated and identical' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(1,2,3,4) '='
    }

    It 'returns "<" when first element of left array is less than first element of right array' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(2,2,3,4) '<'
    }

    It 'returns "<" when left[0] < right[0] even if other elements of left are greater than right' {
        AssertVersionArrayComparisonResult @(1,9,8,7) @(2,2,3,4) '<'
    }

    It 'returns ">" when first element of left array is greater than first element of right array' {
        AssertVersionArrayComparisonResult @(2,2,3,4) @(1,2,3,4) '>'
    }

    It 'returns ">" when left[0] > right[0] even if other elements of left are less than right' {
        AssertVersionArrayComparisonResult @(2,2,3,4) @(1,9,8,7) '>'
    }

    It 'returns "<" when second element of left array is less than second element of right array' {
        AssertVersionArrayComparisonResult @(1,1,3,4) @(1,2,3,4) '<'
    }

    It 'returns "<" when left[1] < right[1] even if subsequent elements of left are greater than right' {
        AssertVersionArrayComparisonResult @(1,1,8,7) @(1,2,3,4) '<'
    }

    It 'returns ">" when second element of left array is greater than second element of right array' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(1,1,3,4) '>'
    }

    It 'returns ">" when left[1] > right[1] even if other elements of left are less than right' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(1,1,8,7) '>'
    }

    It 'returns "<" when last element of left array is less than last element of right array' {
        AssertVersionArrayComparisonResult @(1,2,3,1) @(1,2,3,4) '<'
    }

    It 'returns ">" when last element of left array is greater than last element of right array' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(1,2,3,1) '>'
    }

    It 'returns "<" when equivalent elements in the arrays are identical but left array has less elements than right' {
        AssertVersionArrayComparisonResult @(1,2,3) @(1,2,3,4) '<'
    }

    It 'returns ">" when equivalent elements in the arrays are identical but left array has more elements than right' {
        AssertVersionArrayComparisonResult @(1,2,3,4) @(1,2,3) '>'
    }
}