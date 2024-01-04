<#
.SYNOPSIS
Tests of the functions in the GitHookSourceFilesToCopy\CommonGitHooks\PowerShellHooks\CommonFunctions.psm1 
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
    #   System.Management.Automation.RuntimeException: No modules named 'CommonFunctions' are 
    #   currently loaded.

    # Import is required, rather than dot source, since it doesn't seem possible to dot source 
    # .psm1 files.  While the dot source doesn't produce an error, the functions in the file 
    # are not available after dot sourcing.

    # PowerShell allows multiple modules of the same name to be imported from different locations. 
    # This would confuse Pester.  So, to be sure there are not multiple CommonFunctions modules 
    # imported, remove all CommonFunctions modules and re-import only one.
    Get-Module CommonFunctions | Remove-Module -Force

    # Use $PSScriptRoot so this script will always import the CommonFunctions module in the 
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
    Import-Module (Join-Path $PSScriptRoot '..\GitHookSourceFilesToCopy\CommonGitHooks\PowerShellHooks\CommonFunctions.psm1' -Resolve) -Force
}

InModuleScope CommonFunctions {

    Describe 'Write-OutputMessage' {
    
        BeforeAll {  

            # The real Write-Output doesn't return a value but this is a good way of seeing what 
            # the message it writes is.
            Mock Write-Output { return $InputObject }
        }

        Context 'no arguments supplied' {

            It 'writes empty string' {
                $textWritten = Write-OutputMessage 

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be ''
            } 
        }

        Context 'no message supplied' {

            It 'writes supplied message header' {
                $messageHeader = 'This is the header'

                $textWritten = Write-OutputMessage -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $messageHeader
            }  

            It 'writes cached message header when no message header supplied' {
                $messageHeader = 'Cached header'
                $script:_messageHeader = $messageHeader

                $textWritten = Write-OutputMessage

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $messageHeader
            } 

            It 'writes supplied message header when different header cached' {
                $script:_messageHeader = 'Cached header'
                $messageHeader = 'This is the header'

                $textWritten = Write-OutputMessage -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $messageHeader
            }
        }

        Context 'message supplied is string' {

            It 'writes message only when no message header supplied or cached' {
                $message = 'This is the message'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $message

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $message
            } 

            It 'writes "supplied header: message" when message header supplied' {
                $message = 'This is the message'
                $messageHeader = 'Header'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $message -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            }  

            It 'writes "cached header: message" when message header cached' {
                $message = 'This is the message'
                $messageHeader = 'Cached Header'
                $script:_messageHeader = $messageHeader

                $textWritten = Write-OutputMessage -Message $message 

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            } 

            It 'writes "supplied header: message" when message header suplied and different header cached' {
                $message = 'This is the message'
                $messageHeader = 'Supplied Header'
                $script:_messageHeader = 'Cached Header'

                $textWritten = Write-OutputMessage -Message $message -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            }  

            It 'writes message as per normal when -WriteFirstLineOnly switch set' {
                $message = 'This is the message'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $message -WriteFirstLineOnly

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $message
            } 
        }

        Context 'message supplied is array with one string element' {

            BeforeEach {
                $message = 'This is the message'
                $messageArray = @( $message )
            }

            It 'writes message only when no message header supplied or cached' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $message
            } 

            It 'writes "supplied header: message" when message header supplied' {
                $messageHeader = 'Header'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            }  

            It 'writes "cached header: message" when message header cached' {
                $messageHeader = 'Cached Header'
                $script:_messageHeader = $messageHeader

                $textWritten = Write-OutputMessage -Message $messageArray 

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            } 

            It 'writes "supplied header: message" when message header suplied and different header cached' {
                $messageHeader = 'Supplied Header'
                $script:_messageHeader = 'Cached Header'

                $textWritten = Write-OutputMessage -Message $messageArray -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be "$($messageHeader): $message"
            } 

            It 'writes single message when -WriteFirstLineOnly switch set' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -WriteFirstLineOnly

                Should -Invoke Write-Output -Times 1 -Exactly
                $textWritten | Should -Be $message
            } 
        }

        Context 'message supplied is array with multiple string elements, and -WriteFirstLineOnly switch not set' {

            BeforeEach {
                $message1 = 'Message 1'
                $message2 = 'Message 2'
                $message3 = 'Message 3'
                $messageArray = @( $message1, $message2, $message3 )
                $messageCount = $messageArray.Count
            }

            It 'writes separate message for each element in the message array' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray

                Should -Invoke Write-Output -Times $messageCount -Exactly
                Should -ActualValue $textWritten -BeOfType [System.Array]
                $textWritten.Count | Should -Be $messageCount
                for($i = 0; $i -lt $messageCount; $i++)
                {
                    $textWritten[$i] | Should -Be $messageArray[$i]
                }
            } 

            It 'prepends message header to each message in the message array when message header supplied' {
                $messageHeader = 'Header'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -MessageHeader $messageHeader

                Should -Invoke Write-Output -Times $messageCount -Exactly
                Should -ActualValue $textWritten -BeOfType [System.Array]
                $textWritten.Count | Should -Be $messageCount
                for($i = 0; $i -lt $messageCount; $i++)
                {
                    $textWritten[$i] | Should -Be "${messageHeader}: $($messageArray[$i])"
                }
            } 
        }

        Context 'message supplied is array with multiple string elements, and -WriteFirstLineOnly switch is set' {

            BeforeEach {
                $message1 = 'Message 1'
                $message2 = 'Message 2'
                $message3 = 'Message 3'
                $messageArray = @( $message1, $message2, $message3 )
                $messageCount = $messageArray.Count
            }

            It 'writes only two messages when there are more than two elements in the message array' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -WriteFirstLineOnly

                Should -Invoke Write-Output -Times 2 -Exactly
                Should -ActualValue $textWritten -BeOfType [System.Array]
                $textWritten.Count | Should -Be 2
            }

            It 'first message written is first element in the message array' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -WriteFirstLineOnly

                $textWritten[0] | Should -Be $message1
            }

            It 'second message written is "..." when no message header supplied or cached' {
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -WriteFirstLineOnly

                $textWritten[1] | Should -Be '...'
            } 

            It 'second message written is "header: ..." when message header supplied' {
                $messageHeader = 'Header'
                $script:_messageHeader = ''

                $textWritten = Write-OutputMessage -Message $messageArray -MessageHeader $messageHeader -WriteFirstLineOnly

                $textWritten[1] | Should -Be "${messageHeader}: ..."
            } 
        }
    }
}