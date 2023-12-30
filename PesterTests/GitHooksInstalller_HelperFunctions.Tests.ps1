<#
.SYNOPSIS
Tests of the functions in the GitHooksInstaller_HelperFunctions.ps1 file.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
                Pester v5
Version:		2.0.0
Date:			20 Dec 2023
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
    . (Join-Path $PSScriptRoot '..\Installer\GitHooksInstaller_HelperFunctions.ps1' -Resolve)
}

Describe 'Install-RequiredModule' {
    
    BeforeAll {
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

        Mock Get-InstalledModule {
            if ($mockState.ModuleInstalled)
            {
                return 'Non-null text'
            }

            return $Null
        }

        Mock Get-PSRepository {
            $trustedText = 'Trusted'
            if (-not $mockState.RepositoryIsTrusted)
            {
                $trustedText = 'Untrusted'
            }

            return [pscustomobject]@{ InstallationPolicy=$trustedText }
        }

        Mock Set-PSRepository

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
    }

    BeforeEach {
        $mockState = @{
            ModuleInstalled                = $False  
            RepositoryIsTrusted            = $True 
            ModuleExistsInRepository       = $True 
            InstallWithoutProxySucceeds    = $True 
            InstallWithoutProxyRaisesError = $False  
            InstallWithProxySucceeds       = $True 
            InstallWithProxyRaisesError    = $False  
        }
    }

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

        It 'does not call Set-PSRepository when repository is trusted' {
            $mockState.RepositoryIsTrusted = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Set-PSRepository -Scope It -Times 0 -Exactly
        }

        It 'sets repository installation policy to Trusted when repository is untrusted' {
            $mockState.RepositoryIsTrusted = $False

            ExecuteInstallRequiredModule

            Assert-MockCalled Set-PSRepository -Scope It -Times 1 -Exactly `
                -ParameterFilter { $InstallationPolicy -eq 'Trusted' }
        }

        It 'attempts to find module in repository' {
            $mockState.ModuleInstalled = $False

            ExecuteInstallRequiredModule

            Assert-MockCalled Find-Module -Scope It -Times 1 -Exactly
        }

        It 'throws exception when module does not exist in repository' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $False

            { ExecuteInstallRequiredModule } | 
            Assert-ExceptionThrown -WithMessage 'not found in repository'
        }

        It 'attempts to install module for current user when module found in repository' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxySucceeds = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 1 -Exactly `
                -ParameterFilter { $Scope -eq 'CurrentUser' }
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

        It 'attempts a second installation when module not installed on the first attempt' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 2 -Exactly
        }

        It 'installs module for current user only on second installation attempt' {
            $mockState.ModuleInstalled = $False
            $mockState.ModuleExistsInRepository = $True
            $mockState.InstallWithoutProxyRaisesError = $True

            ExecuteInstallRequiredModule

            Assert-MockCalled Install-Module -Scope It -Times 2 -Exactly `
                -ParameterFilter { $Scope -eq 'CurrentUser' }
        }

        It 'includes proxy details in second installation attempt' {
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

    BeforeAll {
        Mock Write-LogMessage  
    
        $testFilePath = 'C:\TestFile.txt'
    }

    Context 'file already exists' {
        BeforeAll {
            Mock Test-Path { return $True }
            Mock Get-Item { return (Get-ChildItem -Path 'C:\Windows' -File)[0] }
            Mock New-Item
        }

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
        BeforeAll {
            Mock Test-Path { return $False }
            Mock New-Item { return $Null }
        }
        
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

        BeforeAll {
            Mock Test-Path { 
                return $mockState.FileExists
            }
    
            Mock New-Item {
                $mockState.FileExists = $True
    
                return (Get-ChildItem -Path 'C:\Windows' -File)[0]
            }
        }
        
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
        
        BeforeAll {
            $testDirectoryPath = 'TestDrive:\TestDir'
            $testFilePath = Join-Path -Path $testDirectoryPath -ChildPath 'TestFile.txt'
        }
        
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