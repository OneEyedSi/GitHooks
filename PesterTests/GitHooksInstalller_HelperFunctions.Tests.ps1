<#
.SYNOPSIS
Tests of the functions in the GitHooksInstaller_HelperFunctions.ps1 file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                AssertExceptionThrown module (see https://github.com/AnotherSadGit/PesterAssertExceptionThrown)
Version:		1.0.0
Date:			1 Jul 2019

Since the script being tested must run as administrator, this test script must also run as 
administrator.
#>

# NOTE: #Requires is not a comment, it's a requires directive.
#Requires -RunAsAdministrator 
#Requires -Modules AssertExceptionThrown

# Can't dot source directly using a simple relative path as relative paths are relative to the 
# current working directory, not the directory this test file is in.  The current working 
# directory could be anything.  So Use $PSScriptRoot to get the directory this file is in, and 
# use a path relative to that.
. (Join-Path $PSScriptRoot '..\Installer\GitHooksInstaller_HelperFunctions.ps1' -Resolve)

function GetProxyUrl ()
{
    return 'http://myproxy'
}

function ExecuteInstallRequiredModule ()
{
    $proxyUrl = GetProxyUrl
    Install-RequiredModule -ModuleName 'TestModule' -RepositoryName 'TestRepo' `
        -ProxyUrl $proxyUrl
}

function GetTestCredential ()
{
    $securePassword = "mypassword" | ConvertTo-SecureString -asPlainText -Force
    $psCredential = New-Object System.Management.Automation.PSCredential ('MyUserName', $securePassword)
    return $psCredential
}

Describe 'Install-RequiredModule' {
    
    BeforeEach {
        $mockState = @{
                        ModuleInstalled = $False  
                        ModuleExistsInRepository = $True 
                        InstallWithoutProxySucceeds = $True 
                        InstallWithoutProxyRaisesError = $False  
                        InstallWithProxySucceeds = $True 
                        InstallWithProxyRaisesError = $False  
                    }
    }

    # Mock the commands outside the It blocks as a reminder the mocked commands persist into 
    # subsequent It blocks.

    Mock Get-InstalledModule {
        if ($mockState.ModuleInstalled)
        {
            return 'Non-null text'
        }

        return $Null
    }

    Mock Find-Module {
        if ($mockState.ModuleExistsInRepository)
        {
            return @('Non-null text')
        }

        return @()
    }

    Mock Install-Module {
        if ($mockState.InstallWithoutProxyRaisesError)
        {
            $mockState.ModuleInstalled = $False
            return Write-Error 'Error in first installation attempt'
        }

        $mockState.ModuleInstalled = $mockState.InstallWithoutProxySucceeds
        return $Null
    }

    Mock Get-Credential { return GetTestCredential }

    Mock Install-Module {
        if ($mockState.InstallWithProxyRaisesError)
        {
            $mockState.ModuleInstalled = $False
            return Write-Error 'Error in second installation attempt'
        }

        $mockState.ModuleInstalled = $mockState.InstallWithProxySucceeds
        return $Null
    } -ParameterFilter { $Proxy -ne $Null -and $ProxyCredential -ne $Null }

    Context 'module already installed' {

        It 'does not attempt to install module' {
            $mockState.ModuleInstalled = $True

            ExecuteInstallRequiredModule

            # Find-Module should not be called because it should exit before then.
            Assert-MockCalled Find-Module -Scope It -Times 0 -Exactly
            Assert-MockCalled Install-Module -Scope It -Times 0 -Exactly
        } 
    }

    Context 'module not already installed' {

        It 'attempts to find module in repository' {
            $mockState.ModuleInstalled = $False

            ExecuteInstallRequiredModule

            # Find-Module should not be called because it should exit before then.
            Assert-MockCalled Find-Module -Scope It -Times 1 -Exactly
        }

        It 'throws exception when module does not exist in repository' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $False

            { ExecuteInstallRequiredModule } | 
                Assert-ExceptionThrown -WithMessage 'not found in repository'
        }

        It 'attempts to install module when module found in repository' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 1 -Exactly
        }
    }

    Context 'installation without proxy details' {

        It 'will not attempt a second installation when module installed successfully' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 1 -Exactly
        }

        It 'checks whether module listed in installed modules after module installation' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 1 -Exactly
            Assert-MockCalled Get-InstalledModule -Scope It -Times 2 -Exactly
        }

        It 'throws exception when module is not listed in installed modules after module installation' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $False

            { ExecuteInstallRequiredModule } | 
                Assert-ExceptionThrown -WithMessage 'Unknown error installing module'
        }

        It 'does not throw exception when module is listed in installed modules after installation' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $True

            { ExecuteInstallRequiredModule } | Assert-ExceptionThrown -Not
        }
    }

    Context 'installation with proxy details' {

        It 'will attempt a second installation when module not installed on the first attempt' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 2 -Exactly
        }

        It 'will include proxy details in second installation attempt' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True
            
            ExecuteInstallRequiredModule

            $proxyUrl = GetProxyUrl
            Assert-MockCalled Install-Module -Scope It -Times 1 -Exactly `
                -ParameterFilter { $Proxy -eq $proxyUrl -and $ProxyCredential -ne $Null }
        }

        It 'throws exception if there is an error in the second installation attempt' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True
            $mockState.InstallWithProxyRaisesError = $True
            
            { ExecuteInstallRequiredModule } | 
                Assert-ExceptionThrown -WithMessage 'Error in second installation attempt'
        }

        It 'throws exception when module is not listed in installed modules after module installation' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True
            # No error but it doesn't succeed in installing the module.
            $mockState.InstallWithProxyRaisesError = $False
            $mockState.InstallWithProxySucceeds = $False

            { ExecuteInstallRequiredModule } | 
                Assert-ExceptionThrown -WithMessage 'Unknown error installing module'
        }

        It 'does not throw exception when module is listed in installed modules after installation' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True
            $mockState.InstallWithProxySucceeds = $True

            { ExecuteInstallRequiredModule } | Assert-ExceptionThrown -Not
        }
    }
}

Describe 'Set-File' {

    Mock Write-LogMessage  
    
    $testFilePath = 'C:\TestFile.txt'

    Context 'file already exists' {
        Mock Test-Path { return $True }
        Mock Get-Item { return (Get-ChildItem -Path 'C:\Windows' -File)[0] }
        Mock New-Item

        It 'calls Test-Path' {
            Set-File $testFilePath
            Assert-MockCalled Test-Path -Scope It -Times 1 -Exactly
        }

        It 'does not call New-Item' {
            Set-File $testFilePath

            Assert-MockCalled New-Item -Scope It -Times 0 -Exactly
        }

        It 'returns FileInfo object' {
            Set-File $testFilePath | Should -BeOfType System.IO.FileInfo
        }
    }    

    Context 'file does not already exist and creation fails' {
        Mock Test-Path { return $False }
        Mock New-Item { return $Null }

        It 'calls Test-Path' {
            Set-File $testFilePath
            Assert-MockCalled Test-Path -Scope It -Times 1 -Exactly
        }

        It 'calls New-Item' {
            Set-File $testFilePath
            Assert-MockCalled New-Item -Scope It -Times 1 -Exactly
        }

        It 'returns Null' {
            Set-File $testFilePath | Should -Be $Null
        }
    }
    
    Context 'file does not already exist and creation succeeds' {
        # Need the mocked Test-Path to return different values on different calls:
        # First call: Return false as file not supposed to exist;
        # Second call, after calling New-Item: Return true as file has been created.

        # Can't use two mocks with different parameter filters as the arguments 
        # passed to Test-Path will be the same each time.  So instead we need shared 
        # peristent state for the mocks.  
        
        # We could do this with a script-scoped variable (effectively a static variable) but 
        # that could cause problems if the tests were every run in parallel.  So instead 
        # use a local hashtable to record state.
        BeforeEach {
            $mockState = @{
                            FileExists = $False    
                        }
        }
        
        Mock Test-Path { 
            return $mockState.FileExists
        }

        Mock New-Item {
            $mockState.FileExists = $True

            return (Get-ChildItem -Path 'C:\Windows' -File)[0]
        }

        It 'calls Test-Path' {
            Set-File $testFilePath
            Assert-MockCalled Test-Path -Scope It -Times 1 -Exactly
        }

        It 'calls New-Item' {
            Set-File $testFilePath
            Assert-MockCalled New-Item -Scope It -Times 1 -Exactly
        }

        It 'returns FileInfo object' {
            Set-File $testFilePath | Should -BeOfType System.IO.FileInfo
        }
    }

    Context 'parent directory of file does not already exist' {
        
        $testDirectoryPath = 'TestDrive:\TestDir'
        $testFilePath = Join-Path -Path $testDirectoryPath -ChildPath 'TestFile.txt'

        It 'returns FileInfo object' {
            Set-File $testFilePath | Should -BeOfType System.IO.FileInfo
        }

        It 'creates parent directory' {
            Test-Path -Path $testDirectoryPath -PathType Container | Should -Be $True
        }

        It 'creates file' {
            Test-Path -Path $testFilePath -PathType Leaf | Should -Be $True
        }
    }
}