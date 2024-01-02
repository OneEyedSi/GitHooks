<#
.SYNOPSIS
Tests of the functions in the GitHooksInstaller_FileCopyFunctions.ps1 file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pester v5
Date:			30 Dec 2023
Version:		2.0.0
#>

BeforeAll {
    # NOTE: The script under test has to be dot sourced in a BeforeAll block, not a 
    # BeforeDiscovery block.  If placed in a BeforeDiscovery block the tests will fail.
    # (this is in contrast to importing a module under test, which has to be done in the 
    # BeforeDiscovery block)

    # Use $PSScriptRoot so this script will always dot source the script file in the Installer 
    # folder adjacent to the folder containing this script, regardless of the location that 
    # Pester is invoked from:
    #                                     {parent folder}
    #                                             |
    #                   -----------------------------------------------------
    #                   |                                                   |
    #     {folder containing this script}                                Installer folder
    #                   |                                                   |
    #                   |                                                   |
    #               This script -----------> dot sources ------------->  script file under test
    . (Join-Path $PSScriptRoot '..\Installer\GitHooksInstaller_FileCopyFunctions.ps1' -Resolve)

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

        for ($i = 0; $i -lt $ExpectedArray.Count; $i++)
        {
            if ($ExpectedArray[$i] -ne $ActualArray[$i])
            {
                throw $errorMessage
            }
        }
    }

    #endregion

    #region Version number helper functions ***********************************************************

    function GetReferenceVersionArray
    {
        return @(2, 0, 0, 0)
    }

    function GetOlderVersionArray([array]$ReferenceVersion)
    {
        $newArray = $ReferenceVersion.Clone()
        $newArray[0]--
        return $newArray
    }

    function GetNewerVersionArray([array]$ReferenceVersion)
    {
        $newArray = $ReferenceVersion.Clone()
        $newArray[0]++
        return $newArray
    }

    function GetFileNotExistsVersionArray
    {
        return @(0, 0, 0, 0)
    }

    function GetFileWithoutVersionNumberArray
    {
        return @(99999, 0, 0, 0)
    }

    function GetFileVersions (
        [Parameter(Mandatory = $True, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $True, 
            ParameterSetName = "Source All")]
        [switch]$IsSource,
    
        [Parameter(Mandatory = $True, 
            ParameterSetName = "Target")]
        [Parameter(Mandatory = $True, 
            ParameterSetName = "Target All")]
        [switch]$IsTarget,
    
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target")]
        [switch]$IncludeTargerOlder,
    
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target")]
        [switch]$IncludeVersionsSame,
    
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target")]
        [switch]$IncludeTargerNewer,

        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target")]
        [switch]$IncludeTargetNotExist,

        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target")]
        [switch]$IncludeTargetNoVersion,

        [Parameter(Mandatory = $False, 
            ParameterSetName = "Source All")]
        [Parameter(Mandatory = $False, 
            ParameterSetName = "Target All")]
        [switch]$IncludeAll
    )
    {
        $sourceVersion = GetReferenceVersionArray
        $targetOlderVersion = GetOlderVersionArray $sourceVersion
        $targetNewerVersion = GetNewerVersionArray $sourceVersion
        $targetNotExistsVersion = GetFileNotExistsVersionArray
        $targetNoVersion = GetFileWithoutVersionNumberArray

        $targetOlder_Source = @{
            '.\Test_TargetOlder.txt'       = $sourceVersion
            '.\SubDir\Sub_TargetOlder.txt' = $sourceVersion
        }
        $targetOlder_Target = @{
            '.\Test_TargetOlder.txt'       = $targetOlderVersion
            '.\SubDir\Sub_TargetOlder.txt' = $targetOlderVersion
        }
                    
        $versionsSame = @{
            '.\Test_SourceSameVersion.txt'       = $sourceVersion
            '.\SubDir\Sub_SourceSameVersion.txt' = $sourceVersion
        } 

        $targetNewer_Source = @{
            '.\Test_TargetNewer.txt'       = $sourceVersion
            '.\SubDir\Sub_TargetNewer.txt' = $sourceVersion
        } 
        $targetNewer_Target = @{
            '.\Test_TargetNewer.txt'       = $targetNewerVersion
            '.\SubDir\Sub_TargetNewer.txt' = $targetNewerVersion
        } 

        $targetNotExists_Source = @{
            '.\Test_TargetNotExists.txt'       = $sourceVersion
            '.\SubDir\Sub_TargetNotExists.txt' = $sourceVersion
        }
        $targetNotExists_Target = @{
            '.\Test_TargetNotExists.txt'       = $targetNotExistsVersion
            '.\SubDir\Sub_TargetNotExists.txt' = $targetNotExistsVersion
        }
                                
        $targetNoVersion_Source = @{
            '.\Test_TargetNoVersion.txt'       = $sourceVersion
            '.\SubDir\Sub_TargetNoVersion.txt' = $sourceVersion
        }
        $targetNoVersion_Target = @{
            '.\Test_TargetNoVersion.txt'       = $targetNoVersion
            '.\SubDir\Sub_TargetNoVersion.txt' = $targetNoVersion
        }

        $output = @{}

        if ($IncludeAll)
        {
            $IncludeTargerNewer = $True
            $IncludeVersionsSame = $True
            $IncludeTargerOlder = $True
            $IncludeTargetNotExist = $True
            $IncludeTargetNoVersion = $True
        }

        if ($IsSource)
        {
            if ($IncludeTargerOlder)
            {
                $output = $output + $targetOlder_Source
            }
            if ($IncludeVersionsSame)
            {
                $output = $output + $versionsSame
            }
            if ($IncludeTargerNewer)
            {
                $output = $output + $targetNewer_Source
            }
            if ($IncludeTargetNotExist)
            {
                $output = $output + $targetNotExists_Source
            }
            if ($IncludeTargetNoVersion)
            {
                $output = $output + $targetNoVersion_Source
            }
        }
        else
        {
            if ($IncludeTargerOlder)
            {
                $output = $output + $targetOlder_Target
            }
            if ($IncludeVersionsSame)
            {
                $output = $output + $versionsSame
            }
            if ($IncludeTargerNewer)
            {
                $output = $output + $targetNewer_Target
            }
            if ($IncludeTargetNotExist)
            {
                $output = $output + $targetNotExists_Target
            }
            if ($IncludeTargetNoVersion)
            {
                $output = $output + $targetNoVersion_Target
            }
        }

        return $output
    }

    #endregion

    function GetTargetFileNames
    {
        return @(
            'applypatch-msg'                      
            'commit-msg'                          
            'post-update'                         
            'pre-applypatch'                      
            'pre-commit'                          
            'pre-push'                            
            'pre-rebase'                          
            'prepare-commit-msg'                  
            'update'    
        )
    }
}

#region Copy all files under source directory to target directory *********************************

Describe 'Get-SourceFileToCopy' {

    BeforeAll {

        Mock Write-LogMessage

        $sourceDirectoryPath = 'TestDrive:\SourceDir'
        $targetDirectoryPath = 'TestDrive:\TargetDir'

        Mock Get-DirectoryFileRelativePath { return @() }

        function Mock-GetDirectoryScriptVersion ()
        {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeTargerNewer } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeTargerNewer } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }
    }

    Context 'no versioned files found in source directory' {
        
        BeforeAll {
            Mock Get-DirectoryScriptVersion { return @() }
        }

        It 'returns empty array' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            if (-not $result.Count -eq 0)
            {
                $arrayDisplayText = $result -join ', '
                throw "Expected an empty array.  Actual array is $arrayDisplayText"
            }
        }
    }

    Context 'target directory does not exist' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeAll }
        }

        It 'returns all source file relative paths' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory 'TestDrive:\NonExistentTargetDir'

            $sourceFileVersions = GetFileVersions -IsSource -IncludeAll
            # Sort to simplify comparisons of file names in each collection.
            $expectedFileNames = $sourceFileVersions.Keys | Sort-Object
            $actualFileNames = $result | Sort-Object

            AssertArrayMatch -ExpectedArray $expectedFileNames -ActualArray $actualFileNames
        }
    }

    Context 'all target file versions are newer than source file versions' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeTargerNewer } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeTargerNewer } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }

        It 'returns Null' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $result
        }
    }

    Context 'all source and target files have same versions' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeVersionsSame } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeVersionsSame } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }

        It 'returns Null' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $result
        }
    }

    Context 'all target file versions are older than source file versions' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeTargerOlder } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeTargerOlder } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }

        It 'returns all source file relative paths' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            $sourceFileVersions = GetFileVersions -IsSource -IncludeTargerOlder
            # Sort to simplify comparisons of file names in each collection.
            $expectedFileNames = $sourceFileVersions.Keys | Sort-Object
            $actualFileNames = $result | Sort-Object

            AssertArrayMatch -ExpectedArray $expectedFileNames -ActualArray $actualFileNames
        }
    }

    Context 'target files do not exist' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeTargetNotExist } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeTargetNotExist } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }

        It 'returns all source file relative paths' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            $sourceFileVersions = GetFileVersions -IsSource -IncludeTargetNotExist
            # Sort to simplify comparisons of file names in each collection.
            $expectedFileNames = $sourceFileVersions.Keys | Sort-Object
            $actualFileNames = $result | Sort-Object

            AssertArrayMatch -ExpectedArray $expectedFileNames -ActualArray $actualFileNames
        }
    }

    Context 'target files have no version numbers' {

        BeforeAll {
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsSource -IncludeTargetNoVersion } `
                -ParameterFilter { $DirectoryPath -eq $sourceDirectoryPath }
            
            Mock Get-DirectoryScriptVersion { return GetFileVersions -IsTarget -IncludeTargetNoVersion } `
                -ParameterFilter { $DirectoryPath -eq $targetDirectoryPath }

            Mock Test-Path { return $True }
        }

        It 'returns Null' {
            $result = Get-SourceFileToCopy -SourceDirectory $sourceDirectoryPath `
                -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $result
        }
    }
}

Describe 'Set-TargetFileFromSourceDirectory' {

    BeforeAll {

        $sourceFileNamesToCopy = (GetFileVersions -IsSource -IncludeTargerOlder -IncludeTargetNotExist).Keys
        Mock Get-SourceFileToCopy { return $sourceFileNamesToCopy }

        Mock Test-Path { return $False }

        Mock Set-File { return $False }

        Mock Get-ChildItem { return  [pscustomobject]@{ IsReadOnly = $False } }

        Mock Copy-Item

        Mock Write-LogMessage

        $sourceDirectoryPath = 'TestDrive:\SourceDir'
        $targetDirectoryPath = 'TestDrive:\TargetDir'
    }

    Context 'no files need updating' {
        
        BeforeAll {
            Mock Get-SourceFileToCopy { return $Null }

            Mock Test-Path { return $True }
    
            Mock Set-File { return $True }
        }
        
        It 'does not attempt to update files in target directory' {
            Set-TargetFileFromSourceDirectory `
                -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Test-Path -Scope It -Times 0 -Exactly
            Assert-MockCalled Copy-Item -Scope It -Times 0 -Exactly
        }
    }

    Context 'source file does not exist' {
        
        BeforeAll {
            Mock Set-File { return $true }
        }

        It 'checks existence of source file' {
            
            try
            {
                Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath
            }
            catch {}

            Assert-MockCalled Test-Path -Scope It -Times 1
            Assert-MockCalled Set-File -Scope It -Times 0 -Exactly
        }

        It 'does not attempt to update target file' {

            try
            {
                Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath
            }
            catch {}

            Assert-MockCalled Set-File -Scope It -Times 0 -Exactly
        }

        It 'throws exception' {

            { Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -WithMessage 'File not found'
        }
    }

    Context 'target file creation fails' {
        
        BeforeAll {
            Mock Test-Path { return $True }
        }

        It 'does not attempt to update target file' {

            Set-TargetFileFromSourceDirectory `
                -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Get-ChildItem -Scope It -Times 0 -Exactly
        }

        It 'does not throw an exception' {

            { Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }

    Context 'target file is read-only' {
        
        BeforeAll {
            Mock Test-Path { return $True }
    
            Mock Set-File { return $True }

            Mock Get-ChildItem { return  [pscustomobject]@{ IsReadOnly = $True } }
        }

        It 'does not attempt to update target file' {

            Set-TargetFileFromSourceDirectory `
                -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Copy-Item -Scope It -Times 0 -Exactly
        }

        It 'does not throw an exception' {

            { Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }

    Context 'target file is writable' {
        
        BeforeAll {
            Mock Test-Path { return $True }
            Mock Set-File { return $True }
        }

        It 'updates each target file' {

            Set-TargetFileFromSourceDirectory `
                -SourceDirectory $sourceDirectoryPath -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Copy-Item -Scope It -Times $sourceFileNamesToCopy.Count -Exactly
        }
    }

    Context 'check target file names' {
        
        BeforeAll {
            Mock Test-Path { return $True }
            Mock Set-File { return $True }
            
            Mock Copy-Item {
                $sourceFileFullPath = $Path
                $targetFileFullPath = $Destination
                $sourceFile = Split-Path -Path $sourceFileFullPath -Leaf
                $targetFile = Split-Path -Path $targetFileFullPath -Leaf
    
                if ($targetFile -ne $sourceFile)
                {
                    throw "Expected target file name to be the same as the source file name: '$sourceFile'.  Actual target file name is '$targetFile'."
                }
            }        
        }

        It 'copies each source file to a target file of the same name' {

            { Set-TargetFileFromSourceDirectory `
                    -SourceDirectory $sourceDirectoryPath `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }
}

#endregion

#region Copy single source file multiple times to target directory with different names ***********

Describe 'Get-TargetFileToUpdate' {

    BeforeAll {
        Mock Write-LogMessage

        $sourceFilePath = 'TestDrive:\SourceDir\Source.txt'
        $targetFileNameList = GetTargetFileNames
        $targetDirectoryPath = 'TestDrive:\TargetDir'
    }

    Context 'source file has no version number' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetFileWithoutVersionNumberArray }
        }

        It 'throws exception' {
            
            { Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath } | 
            Assert-ExceptionThrown -WithMessage 'has no version number'
        }
    }

    Context 'target directory does not exist' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $False }
        }

        It 'returns target file list unchanged' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            $expectedFileList = GetTargetFileNames
            AssertArrayMatch -ExpectedArray $expectedFileList -ActualArray $resultantFileList
        }
    }

    Context 'all target file versions are newer than source file version' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $True }
            $targetFileVersions = GetFileVersions -IsTarget -IncludeTargerNewer
            Mock Get-DirectoryScriptVersion { return $targetFileVersions }
        }

        It 'returns Null' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $resultantFileList
        }
    }

    Context 'all target file versions are equal to source file version' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $True }
            $targetFileVersions = GetFileVersions -IsTarget -IncludeVersionsSame
            Mock Get-DirectoryScriptVersion { return $targetFileVersions }
        }

        It 'returns Null' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $resultantFileList
        }
    }

    Context 'all target file versions are older than source file version' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $True }
            $targetFileVersions = GetFileVersions -IsTarget -IncludeTargerOlder
            Mock Get-DirectoryScriptVersion { return $targetFileVersions }
        }

        It 'returns all target file names' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            # Sort the results to make array comparison easier.
            $expectedFileList = $targetFileVersions.Keys | Sort-Object
            $resultantFileList = $resultantFileList | Sort-Object
            AssertArrayMatch -ExpectedArray $expectedFileList -ActualArray $resultantFileList
        }
    }

    Context 'target files do not exist' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $True }
            $targetFileVersions = GetFileVersions -IsTarget -IncludeTargetNotExist
            Mock Get-DirectoryScriptVersion { return $targetFileVersions }
        }

        It 'returns all target file names' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            # Sort the results to make array comparison easier.
            $expectedFileList = $targetFileVersions.Keys | Sort-Object
            $resultantFileList = $resultantFileList | Sort-Object
            AssertArrayMatch -ExpectedArray $expectedFileList -ActualArray $resultantFileList
        }
    }

    Context 'target files have no version numbers' {
        
        BeforeAll {
            Mock Get-ScriptFileVersion { return GetReferenceVersionArray }
            Mock Test-Path { return $True }
            $targetFileVersions = GetFileVersions -IsTarget -IncludeTargetNoVersion
            Mock Get-DirectoryScriptVersion { return $targetFileVersions }
        }

        It 'returns Null' {
            
            $resultantFileList = Get-TargetFileToUpdate -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            AssertArrayMatch -ExpectedArray $Null -ActualArray $resultantFileList
        }
    }
}

Describe 'Set-TargetFileFromSourceFile' {

    BeforeAll {
        Mock Write-LogMessage

        $sourceFilePath = 'TestDrive:\SourceDir\Source.txt'
        $targetFileNameList = GetTargetFileNames
        $targetDirectoryPath = 'TestDrive:\TargetDir'
    }

    Context 'source file does not exist' {

        BeforeAll {
            Mock Test-Path { return $False }
            Mock Get-TargetFileToUpdate
        }

        It 'checks existence of source file' {
            
            try
            {
                Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath
            }
            catch {}

            Assert-MockCalled Test-Path -Scope It -Times 1
        }

        It 'does not attempt to update target files' {

            try
            {
                Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath
            }
            catch {}

            Assert-MockCalled Get-TargetFileToUpdate -Scope It -Times 0 -Exactly
        }

        It 'throws exception' {

            { Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -WithMessage 'not found'
        }
    }

    Context 'creating target files' {
        
        BeforeAll {
            $targetFileNames = GetTargetFileNames
            Mock Test-Path { return $True }
            Mock Get-TargetFileToUpdate { return $targetFileNames }
            Mock Set-File
        }

        It "creates target files when they don't exist" {

            Set-TargetFileFromSourceFile `
                -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath
            
            Assert-MockCalled Set-File -Scope It -Times $targetFileNames.Count -Exactly
        }
    }

    Context 'target file creation fails' {
        
        BeforeAll {
            $targetFileNames = GetTargetFileNames
            Mock Test-Path { return $True }
            Mock Get-TargetFileToUpdate { return $targetFileNames }
            Mock Set-File { return $False }
            Mock Get-ChildItem { return  [pscustomobject]@{ IsReadOnly = $False } }
        }

        It 'does not attempt to update target file' {

            Set-TargetFileFromSourceFile `
                -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Get-ChildItem -Scope It -Times 0 -Exactly
        }

        It 'does not throw an exception' {

            { Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }

    Context 'target file is read-only' {
        
        BeforeAll {
            $targetFileNames = GetTargetFileNames
            Mock Test-Path { return $True }
            Mock Get-TargetFileToUpdate { return $targetFileNames }
            Mock Set-File { return $True }
            Mock Get-ChildItem { return  [pscustomobject]@{ IsReadOnly = $True } }
            Mock Copy-Item
        }

        It 'does not attempt to update target file' {

            Set-TargetFileFromSourceFile `
                -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath

            Assert-MockCalled Copy-Item -Scope It -Times 0 -Exactly
        }

        It 'does not throw an exception' {

            { Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }

    Context 'target file is writable' {        
        
        BeforeAll {
            $targetFileNames = GetTargetFileNames
            Mock Test-Path { return $True }
            Mock Get-TargetFileToUpdate { return $targetFileNames }
            Mock Set-File { return $True }
            Mock Get-ChildItem { return  [pscustomobject]@{ IsReadOnly = $False } }
            Mock Copy-Item {           
                if ($mockSwitches.CheckSourceFileName)
                {
                    $copySourceFilePath = $Path
                    if ($copySourceFilePath -ne $sourceFilePath)
                    {
                        throw "Expected source file to be '$sourceFilePath'.  Actual source file is '$copySourceFilePath'."
                    }
                }
            }
        }
        
        BeforeEach {
            $mockSwitches = @{
                CheckSourceFileName = $False
            }
        }
        It 'updates each target file' {

            Set-TargetFileFromSourceFile `
                -SourceFilePath $sourceFilePath `
                -TargetFileNameList $targetFileNameList -TargetDirectory $targetDirectoryPath
            
            Assert-MockCalled Copy-Item -Scope It -Times $targetFileNames.Count -Exactly
        }

        It 'always copies the same source file' {

            $mockSwitches.CheckSourceFileName = $True

            { Set-TargetFileFromSourceFile `
                    -SourceFilePath $sourceFilePath `
                    -TargetFileNameList $targetFileNameList `
                    -TargetDirectory $targetDirectoryPath } | Assert-ExceptionThrown -Not
        }
    }
}

#endregion