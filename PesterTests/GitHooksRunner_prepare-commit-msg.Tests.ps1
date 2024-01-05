<#
.SYNOPSIS
Tests of the functions in the GitHookSourceFilesToCopy\CommonGitHooks\PowerShellHooks\prepare-commit-msg.psm1 
file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pester v5
Version:		1.0.0
Date:			4 Jan 2024
#>

BeforeDiscovery {
    # NOTE: The module under test has to be imported in a BeforeDiscovery block, not a 
    # BeforeAll block.  If placed in a BeforeAll block the tests will fail with the following 
    # message:
    #   Discovery in ... failed with:
    #   System.Management.Automation.RuntimeException: No modules named 'prepare-commit-msg' are 
    #   currently loaded.

    # Import is required, rather than dot source, since it doesn't seem possible to dot source 
    # .psm1 files.  While the dot source doesn't produce an error, the functions in the file 
    # are not available after dot sourcing.

    # PowerShell allows multiple modules of the same name to be imported from different locations. 
    # This would confuse Pester.  So, to be sure there are not multiple prepare-commit-msg modules 
    # imported, remove all prepare-commit-msg modules and re-import only one.
    Get-Module prepare-commit-msg | Remove-Module -Force

    # Use $PSScriptRoot so this script will always import the prepare-commit-msg module in the 
    # GitHooksSourceFilesToCopy folder adjacent to the folder containing this script, regardless 
    # of the location that Pester is invoked from:
    #
    #                                     {parent folder}
    #                                             |
    #                   -----------------------------------------------------
    #                   |                                                   |
    #     {folder containing this script}                     GitHookSourceFilesToCopy folder
    #                   |                                                   |
    #                   |                                          CommonGitHooks folder
    #                   |                                                   |
    #                   |                                          PowerShellHooks folder
    #                   |                                                   |
    #               This script ----------> imports ------------>  module file under test
    Import-Module (Join-Path $PSScriptRoot '..\GitHookSourceFilesToCopy\CommonGitHooks\PowerShellHooks\prepare-commit-msg.psm1' -Resolve) -Force
}

InModuleScope prepare-commit-msg {

    BeforeAll {
        Mock Exit-WithSuccess 
        Mock Write-OutputMessage { return $Message }
    }

    Describe 'Exit-WithMessage' {

        It 'calls Exit-WithSuccess' {
            Exit-WithMessage 'test message'

            Should -Invoke Exit-WithSuccess -Times 1 -Exactly
        } 

        It 'writes supplied message' {
            $message = 'Test message'

            $messageWritten = Exit-WithMessage $message

            $messageWritten | Should -Be $message
        }

        It 'writes hard-coded message if no message supplied' {
            $message = 'Commit message will not be modified.'

            $messageWritten = Exit-WithMessage

            $messageWritten | Should -Be $message
        } 
    }

    Describe 'Remove-KnownPrefixFromBranchName' {

        BeforeEach {
            $script:_branchPrefixesToIgnore = @(
                'feature',
                'bug'
            )
        }

        It 'returns branch name unchanged when it does not contain a known prefix' {
            $rawBranchName = 'test-branch-name'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name unchanged when known prefix is not at start of branch name' {
            $rawBranchName = 'otherText-bug/test-branch-name'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name unchanged when known prefix is not followed by a separator character' {
            $rawBranchName = 'bugtest-branch-name'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name unchanged when separator character used is not a known separator character' {
            $rawBranchName = 'bug~test-branch-name'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name unchanged when separator character is not followed by any further characters' {
            $rawBranchName = 'bug/'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name unchanged when known prefix name is not followed by any further characters' {
            $rawBranchName = 'bug'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $rawBranchName
        }

        It 'returns branch name with prefix and separator stripped out when branch name starts with known prefix + known separator, followed by further text' {
            $rawBranchName = 'bug/test-branch-name'
            $expectedResult = 'test-branch-name'

            $modifiedBranchName = Remove-KnownPrefixFromBranchName -BranchName $rawBranchName

            $modifiedBranchName | Should -Be $expectedResult
        }
    }

    Describe 'Get-CommitMessagePrefix' {

        BeforeEach {
            $script:_branchPrefixesToIgnore = @(
                'feature',
                'bug'
            )
        }

        Context 'branch name has no branch prefix, Jira-style issue number or numeric issue number' {

            It 'returns branch name unchanged' {
                $rawBranchName = 'test-branch-name'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }

        }

        Context 'branch name has known branch prefix but no Jira-style issue number or numeric issue number' {

            It 'returns branch name unchanged when known prefix is not at start of branch name' {
                $rawBranchName = 'otherText-bug/test-branch-name'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }
    
            It 'returns branch name unchanged when known prefix is not followed by a separator character' {
                $rawBranchName = 'bugtest-branch-name'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }
    
            It 'returns branch name unchanged when separator character used is not a known separator character' {
                $rawBranchName = 'bug~test-branch-name'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }
    
            It 'returns branch name unchanged when separator character is not followed by any further characters' {
                $rawBranchName = 'bug/'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }
    
            It 'returns branch name unchanged when known prefix name is not followed by any further characters' {
                $rawBranchName = 'bug'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $rawBranchName
            }
    
            It 'returns branch name with prefix and separator stripped out when branch name starts with known prefix + known separator, followed by further text' {
                $rawBranchName = 'bug/test-branch-name'
                $expectedResult = 'test-branch-name'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }
        }

        Context 'branch name has Jira-style issue number but no known branch prefix' {

            It 'returns hyphen-separated Jira ticket number unchanged when the branch name is the ticket number with no further text' {
                $rawBranchName = 'ACME-123'
                $expectedResult = $rawBranchName
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'converts Jira project code to uppercase' {
                $rawBranchName = 'acme-123'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -BeExactly $expectedResult
            }

            It 'adds hyphen between Jira project code and ticket number when no hyphen is present in branch name' {
                $rawBranchName = 'acme123'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -BeExactly $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name is the ticket number immediately followed by further text' {
                $rawBranchName = 'acme-123further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name is the ticket number followed by a hyphen and further text' {
                $rawBranchName = 'acme-123-further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name is the ticket number followed by an underscore and further text' {
                $rawBranchName = 'acme-123_further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name is the ticket number followed by a forward slash and further text' {
                $rawBranchName = 'acme-123/further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both Jira ticket numbers, separated by a hyphen, when two Jira ticket numbers are present without any separator between them' {
                $rawBranchName = 'acme-123smiths987further-text'
                $expectedResult = 'ACME-123-SMITHS-987'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both Jira ticket numbers, separated by a hyphen, when two Jira ticket numbers are present, separated by a hyphen' {
                $rawBranchName = 'acme-123-smiths987further-text'
                $expectedResult = 'ACME-123-SMITHS-987'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both Jira ticket numbers, separated by a hyphen, when two Jira ticket numbers are present, separated by an underscore' {
                $rawBranchName = 'acme-123_smiths987further-text'
                $expectedResult = 'ACME-123-SMITHS-987'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns only the first two Jira ticket numbers, separated by a hyphen, when three or more Jira ticket numbers are present' {
                $rawBranchName = 'acme-123smiths987acme-345further-text'
                $expectedResult = 'ACME-123-SMITHS-987'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }
        }

        Context 'branch name has numeric issue number but no known branch prefix' {

            It 'returns ticket number unchanged when the branch name is the ticket number with no further text' {
                $rawBranchName = '123456'
                $expectedResult = $rawBranchName
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns ticket number only, when the branch name is the ticket number immediately followed by further text' {
                $rawBranchName = '123456further-text'
                $expectedResult = '123456'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns ticket number only, when the branch name is the ticket number followed by a hyphen and further text' {
                $rawBranchName = '123456-further-text'
                $expectedResult = '123456'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns ticket number only, when the branch name is the ticket number followed by an underscore and further text' {
                $rawBranchName = '123456_further-text'
                $expectedResult = '123456'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns ticket number only, when the branch name is the ticket number followed by a forward slash and further text' {
                $rawBranchName = '123456/further-text'
                $expectedResult = '123456'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both ticket numbers, separated by a hyphen, when two numeric ticket numbers are present, separated by a hyphen' {
                $rawBranchName = '123456-987654further-text'
                $expectedResult = '123456-987654'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both ticket numbers, separated by a hyphen, when two numeric ticket numbers are present, separated by an underscore' {
                $rawBranchName = '123456_987654further-text'
                $expectedResult = '123456-987654'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns only the first two ticket numbers, separated by a hyphen, when three or more numeric ticket numbers are present' {
                $rawBranchName = '123456-987654-345678further-text'
                $expectedResult = '123456-987654'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }
        }

        Context 'branch name has known branch prefix and Jira-style issue number' {

            It 'returns hyphen-separated Jira ticket number when the branch name has a known branch prefix and the Jira ticket number with no further text' {
                $rawBranchName = 'bug/acme-123'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number when the branch name has a known branch prefix followed by a hyphen separator and the Jira ticket number' {
                $rawBranchName = 'bug-acme123'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -BeExactly $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name has a known branch prefix, the ticket number and further text' {
                $rawBranchName = 'bug.acme-123further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns hyphen-separated Jira ticket number only, when the branch name has a known branch prefix, then the ticket number followed by a forward slash and further text' {
                $rawBranchName = 'bug/acme-123/further-text'
                $expectedResult = 'ACME-123'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }

            It 'returns both Jira ticket numbers, when the branch name has a known branch prefix, two ticket numbers, then further text' {
                $rawBranchName = 'bug/acme-123smiths987further-text'
                $expectedResult = 'ACME-123-SMITHS-987'
    
                $messagePrefix = Get-CommitMessagePrefix -BranchName $rawBranchName
    
                $messagePrefix | Should -Be $expectedResult
            }
        }
    }

    Describe 'Exit-IfEditingExistingCommit' {

        BeforeAll {
            Mock Write-OutputMessage { return $Message }
            Mock Exit-WithSuccess
        }

        Context 'fixup commit' {
            
            BeforeEach {
                $existingCommitMessageFirstLine = 'fixup! Commit message'
                $commitMessagePrefix = 'ACME-123'
            }

            It 'calls Exit-WithSuccess' {

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                Should -Invoke Exit-WithSuccess -Times 1 -Exactly
            } 

            It 'writes "not modified" message' {
                $message = 'Fixup commit message will not be modified.'

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                $messageWritten | Should -Be $message
            }
        }

        Context 'squash commit' {
            
            BeforeEach {
                $existingCommitMessageFirstLine = 'squash! Commit message'
                $commitMessagePrefix = 'ACME-123'
            }

            It 'calls Exit-WithSuccess' {

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                Should -Invoke Exit-WithSuccess -Times 1 -Exactly
            } 

            It 'writes "not modified" message' {
                $message = 'Squash commit message will not be modified.'

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                $messageWritten | Should -Be $message
            }
        }

        Context 'commit message already has prefix' {
            
            BeforeEach {
                $existingCommitMessageFirstLine = 'ACME-123: Commit message'
                $commitMessagePrefix = 'ACME-123'
            }

            It 'calls Exit-WithSuccess' {

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                Should -Invoke Exit-WithSuccess -Times 1 -Exactly
            } 

            It 'writes "not modified" message' {
                $message = 'Commit message already has a prefix; commit message will not be modified.'

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                $messageWritten | Should -Be $message
            }
        }

        Context 'commit message has no prefix' {

            BeforeEach {
                $existingCommitMessageFirstLine = 'Commit message'
                $commitMessagePrefix = 'ACME-123'
            }

            It 'does not call Exit-WithSuccess' {

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                Should -Invoke Exit-WithSuccess -Times 0 
            } 

            It 'does not write any message' {

                $messageWritten = Exit-IfEditingExistingCommit `
                    -ExistingCommitMessageFirstLine $existingCommitMessageFirstLine `
                    -CommitMessagePrefix $commitMessagePrefix

                $messageWritten | Should -Be $Null
            }
        }
    }

    Describe 'Start-GitHook' {

        BeforeAll {      
            $testMessagePrefix = 'message prefix'
            $testBranchName = 'branch name'
            $testOriginalCommitMessage = 'file content'

            Mock Write-OutputMessage { return $Message }    
            Mock Exit-WithMessage { throw $Message }
            Mock Get-BranchName { return $testBranchName }
            Mock Get-CommitMessagePrefix { return $testMessagePrefix }
            Mock Test-Path { return $True }
            Mock Get-Content { return $testOriginalCommitMessage }
            Mock Set-IndentOnFileContent { return "  $testOriginalCommitMessage" }
            Mock Exit-IfEditingExistingCommit
            Mock Set-Content
            Mock Exit-WithSuccess
        }

        BeforeEach {
            $commitMessageFilePath = 'C:\messagefilepath'
            $commitType = 'message'
            $commitHash = 'a1b2c3d'
            $script:_branchNamesToIgnore = @('master', 'main')
        }

        Context 'CommitMessageFilePath parameter not set' {

            It 'exits with error message when -CommitMessageFilePath is $null' {
                $commitMessageFilePath = $null
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-BranchName when -CommitMessageFilePath is $null' {
                $commitMessageFilePath = $null
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage

                Should -Invoke Get-BranchName -Times 0
            }

            It 'exits with error message when -CommitMessageFilePath is empty string' {
                $commitMessageFilePath = ''
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-BranchName when -CommitMessageFilePath is empty string' {
                $commitMessageFilePath = ''
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage

                Should -Invoke Get-BranchName -Times 0
            }

            It 'exits with error message when -CommitMessageFilePath is white space' {
                $commitMessageFilePath = '  '
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-BranchName when -CommitMessageFilePath is white space' {
                $commitMessageFilePath = '  '
                $expectedMessage = 'The path to the commit message temp file was not passed to the Start-GitHook function.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage

                Should -Invoke Get-BranchName -Times 0
            }
        }

        Context 'CommitMessageFilePath parameter points to non-existent file' {

            BeforeAll {
                Mock Test-Path { return $False }
            }

            It 'exits with error message when no file found at -CommitMessageFilePath' {
                $expectedMessage = "Could not find commit message temp file '$commitMessageFilePath'.*"

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-Content when no file found at -CommitMessageFilePath' {
                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw

                Should -Invoke Get-Content -Times 0
            }
        }

        Context 'Git branch name is $null' {
            # Occurs when the checked out commit is not the head of a branch.

            BeforeAll {
                Mock Get-BranchName { return $Null }
                Mock Get-Content { return '' } 
            }

            It 'exits with error message when Git branch name is $null' {
                $expectedMessage = 'Could not read git branch name.*'

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-CommitMessagePrefix when Git branch name is $null' {
                Mock Get-CommitMessagePrefix { return '' }

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw

                Should -Invoke Get-CommitMessagePrefix -Times 0
            }
        }

        Context 'Git branch name is not $null' {

            It 'calls Get-CommitMessagePrefix, passing in branch name' {
                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Get-CommitMessagePrefix -Times 1 -Exactly -ParameterFilter { $BranchName -eq $testBranchName }
            }

            It 'exits with error message when Git branch name is a reserved branch name' {
                $script:_branchNamesToIgnore += $testBranchName
                $expectedMessage = "Committing to reserved branch $testBranchName.*"

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw -ExpectedMessage $expectedMessage
            }

            It 'does not call Get-Content when Git branch name is a reserved branch name' {
                $script:_branchNamesToIgnore += $testBranchName

                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Throw

                Should -Invoke Get-Content -Times 0
            }

            It 'calls Get-Content when Git branch name is not a reserved branch name' {
                { Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                        -CommitType $commitType -CommitHash $commitHash } | 
                Should -Not -Throw

                Should -Invoke Get-Content -Times 1 -Exactly
            }
        }

        Context 'single-line commit message' {

            It 'calls Exit-IfEditingExistingCommit' {
                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Exit-IfEditingExistingCommit -Times 1 -Exactly
            }

            It 'prepends message prefix to commit message' {
                $newCommitMessage = "$($testMessagePrefix): $testOriginalCommitMessage"

                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Set-Content -Times 1 -Exactly `
                    -ParameterFilter { $Path -eq $commitMessageFilePath -and $Value -eq $newCommitMessage }
            }

            It 'exits with exit code 0 (success)' {
                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Exit-WithSuccess -Times 1 -Exactly
            }
        }

        Context 'multi-line commit message' {

            BeforeEach {
                
                $testOriginalCommitMessage = @(
                                        'commit message line 1'
                                        'commit message line 2'
                                    )

                Mock Get-Content { return $testOriginalCommitMessage }
            }

            It 'calls Exit-IfEditingExistingCommit' {
                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Exit-IfEditingExistingCommit -Times 1 -Exactly
            }

            It 'prepends message prefix to first line of commit message, while leaving subsequent lines unchanged' {
                $newCommitMessage = $testOriginalCommitMessage.Clone()
                $newCommitMessage[0] = "$($testMessagePrefix): $($newCommitMessage[0])"

                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Set-Content -Times 1 -Exactly `
                    -ParameterFilter { $Path -eq $commitMessageFilePath `
                                -and $Null -eq (Compare-Object $Value $newCommitMessage) }
            }

            It 'exits with exit code 0 (success)' {
                Start-GitHook -CommitMessageFilePath $commitMessageFilePath `
                    -CommitType $commitType -CommitHash $commitHash

                Should -Invoke Exit-WithSuccess -Times 1 -Exactly
            }
        }
    }
}