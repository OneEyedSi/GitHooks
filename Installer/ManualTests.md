# Manual Tests of GitHooksInstaller.ps1
----
## Installing Logging Module
### Module Not Currently Installed
##### Functionality Under Test
GitHooksInstaller.ps1 will automatically install the logging module if it's not already installed.

##### Test Summary
1. Check whether the module is already installed
2. If installed, uninstall it then confirm the module is no longer installed
3. Run part of GitHooksInstaller.ps1 that installs module
4. Check the module is now installed

##### Test Steps
1. Execute `get-installedmodule pslogg`
    * If the module is installed:  Version number and description of installed module will be displayed
    * If the module is not installed:  Throws error "No match was found for the specified search criteria and module names 'pslogg'."
1. If the module is installed execute `uninstall-module pslogg` then `get-installedmodule pslogg` to confirm the module is no longer installed
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Install-RequiredModule*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Execute `get-installedmodule pslogg` and ***confirm module installed***
1. Abort execution of the script to avoid creating or updating any files

### Module Already Installed
##### Functionality Under Test
If the logging module is already installed GitHooksInstaller.ps1 will not remove it and will not error.

##### Test Summary
1. Ensure the module is already installed
1. Run part of GitHooksInstaller.ps1 that installs module
1. Check the module is still installed and there were no errors

##### Test Steps
1. Execute `get-installedmodule pslogg` and ensure the module is installed
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Install-RequiredModule*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Execute `get-installedmodule pslogg` and ***confirm module is still installed***
1. Abort execution of the script to avoid creating or updating any files
 
## Setting Environment Variable
### Environment Variable Does Not Currently Exist
##### Functionality Under Test
GitHooksInstaller.ps1 will set an environment variable if it doesn't already exist.

##### Test Summary
1. Check whether the variable already exists
2. If it exists remove it
3. Run part of GitHooksInstaller.ps1 that sets environment variable
4. Check the variable now exists

##### Test Steps
1. View environment variables: Windows Key + Pause/Break (opens System dialog) > Advanced system settings > Environment Variables > System variables
1. Check whether ***GITHOOKSDIR*** system variable exists.  If it does, delete it
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** [Environment]::GetEnvironmentVariable*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * View environment variables and ensure ***GITHOOKSDIR*** system ***variable exists***
    * Ensure ***$centralGitHookDirectory*** variable is set to the value of the environment variable
1. Abort execution of the script to avoid creating or updating any files

### Environment Variable Currently Exists With a Different Value
##### Functionality Under Test
GitHooksInstaller.ps1 will not change the value of the environment variable if it already exists with a different value than the one in GitHooksInstaller.ps1.

##### Test Summary
1. Modify the environment variable value
1. Run part of GitHooksInstaller.ps1 that sets environment variable
1. Check the variable value hasn't changed (ie it's ***not*** the value in the GitHooksInstaller.ps1 script)

##### Test Steps
1. View system environment variables (as above)
1. Set ***GITHOOKSDIR*** system variable to a different value than the one on the ***GitHooksInstaller.ps1*** script
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** [Environment]::GetEnvironmentVariable*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * View environment variables and ensure ***GITHOOKSDIR*** system variable ***value has not changed***
    * Ensure ***$centralGitHookDirectory*** variable in GitHooksInstaller.ps1 is set to the value of the environment variable
1. Abort execution of the script to avoid creating or updating any files

### Environment Variable Currently Exists With the Same Value
##### Functionality Under Test
GitHooksInstaller.ps1 will leave the environment variable unchanged if it already exists with the same value as the one in GitHooksInstaller.ps1.

##### Test Summary
1. Set the environment variable to the value in GitHooksInstaller.ps1
1. Run part of GitHooksInstaller.ps1 that sets environment variable
1. Check the variable value hasn't changed

##### Test Steps
1. View system environment variables (as above)
1. Set ***GITHOOKSDIR*** system variable to the value in ***GitHooksInstaller.ps1*** script
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** [Environment]::GetEnvironmentVariable*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * View environment variables and ensure ***GITHOOKSDIR*** system variable ***value has not changed***
    * Ensure ***$centralGitHookDirectory*** variable in GitHooksInstaller.ps1 is set to the value of the environment variable
1. Abort execution of the script to avoid creating or updating any files

## Logging
##### Functionality Under Test
GitHooksInstaller.ps1 will write log messages to the host and to a log file.

##### Test Summary
1. Check that log messages are written to the host
2. Check that log messages are written to new log file *InstallationResults_<date>.log*

##### Test Steps
1. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-EnvironmentVariable*
1. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-EnvironmentVariable*** are written to the host
    * Ensure a new log file, ***InstallationResults_<date>.log***, has been ***created and it contains the same log messages*** relating to *Set-EnvironmentVariable* as were written to the host
1. Abort execution of the script to avoid creating or updating any files

## Creating Common Git Hook Scripts
### Common Git Hooks Directory Does Not Exist
##### Functionality Under Test
GitHooksInstaller.ps1 will create the common Git hooks script directory if it does not already exist, and populate it with the common Git hook scripts.

##### Test Summary
1. Delete the common Git hooks directory, if it exists
2. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
3. Check the common Git hooks directory has been created 
4. Check all Git hook scripts have been copied to the common Git hooks directory

##### Test Steps
1. Delete directory ***C:\GitHooks***, if it exists
2. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
3. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify there is a log message ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Success | INFORMATION | Updating files in C:\GitHooks from <source directory>\GitHookSourceFilesToCopy\CommonGitHooks completed successfully.***
    * Ensure directory ***C:\GitHooks*** has been ***created***
    * Ensure all sub-directories and files in source directory ***\GitHookSourceFilesToCopy\CommonGitHooks*** have been copied to ***C:\GitHooks***
1. Abort execution of the script to avoid creating or updating additional files

### Common Git Hooks Scripts Already Exist
##### Functionality Under Test
GitHooksInstaller.ps1 will not update the scripts in the common Git hooks directory if they are copies of the scripts to be installed, with the same version numbers. 

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
3. Check none of the common Git hook scripts have changed

##### Test Steps
1. If directory ***C:\GitHooks*** does not exist create it
2. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
4. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify there is a log message ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Success | INFORMATION | No files to update in C:\GitHooks.***
    * Ensure the contents of ***C:\GitHooks*** still matches the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
1. Abort execution of the script to avoid creating or updating additional files

### Extra File in Common Git Hooks Directory
##### Functionality Under Test
If a script is present in the common Git hooks directory that is not one of the scripts to be installed GitHooksInstaller.ps1 will not delete or modify it.

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Add an extra file to the common Git hooks directory
3. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
4. Check the extra file in the common Git hooks directory still exists

##### Test Steps
1. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
2. Add an extra file to *C:\GitHooks\PowerShellHooks*
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
4. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify there is a log message ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Success | INFORMATION | No files to update in C:\GitHooks.***
    * Ensure the ***extra file still exists*** in ***C:\GitHooks\PowerShellHooks***
1. Abort execution of the script to avoid creating or updating additional files

### Missing File in Common Git Hooks Directory
##### Functionality Under Test
GitHooksInstaller.ps1 will copy a script to be installed to the common Git hooks directory if it does not exist there.

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Remove a file from the the common Git hooks directory
3. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
4. Check the missing file in the common Git hooks directory has been restored

##### Test Steps
1. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
2. Remove one of the files in ***C:\GitHooks\PowerShellHooks***
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
4. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify the following log messages exist (they will not be consecutive):
        * ***<date-time stamp> | Get-SourceFileToCopy | Progress | INFORMATION | 1 files to copy from source directory.***
        * ***<date-time stamp> | Set-File | Progress | INFORMATION | File C:\GitHooks\\.\PowerShellHooks\\<missing file name> created successfully.***
    * Ensure the ***missing file has been restored*** to ***C:\GitHooks\PowerShellHooks***
1. Abort execution of the script to avoid creating or updating additional files

### Outdated File in Common Git Hooks Directory
##### Functionality Under Test
GitHooksInstaller.ps1 will overwrite a script in the common Git hooks directory if it has an older version number than the equivalent script in the scripts to be installed directory.

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Change the version number of a file in the the common Git hooks directory to an ***older version***
3. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
3. Check the edited file in the common Git hooks directory has had its version number restored

##### Test Steps
1. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
2. Edit one of the files in ***C:\GitHooks\PowerShellHooks***.  Change the <version number> in the line ***Version: <version number>*** to an older version.  eg Change *Version: 0.8.0* to *Version: 0.7.0*.  Save the edited file
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
3. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify the following log message exists:
        * ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Progress | INFORMATION | Target file C:\GitHooks\.\PowerShellHooks\<edited file name> updated from source file <source directory>\GitHookSourceFilesToCopy\CommonGitHooks\.\PowerShellHooks\<edited file name>.***
    * Ensure the edited file in ***C:\GitHooks\PowerShellHooks*** has had its ***version number restored***
1. Abort execution of the script to avoid creating or updating additional files

### Updated File in Common Git Hooks Directory
##### Functionality Under Test
GitHooksInstaller.ps1 will not overwrite a script in the common Git hooks directory if it has an newer version number than the equivalent script in the scripts to be installed directory.

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Change the version number of a file in the the common Git hooks directory to a ***newer version***
3. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
3. Check the edited file in the common Git hooks directory ***still has the newer version number***

##### Test Steps
1. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
2. Edit one of the files in ***C:\GitHooks\PowerShellHooks***.  Change the <version number> in the line ***Version: <version number>*** to a newer version.  eg Change *Version: 0.8.0* to *Version: 0.9.0*.  Save the edited file
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
3. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify log messages similar to the following exist:
        * ***<date-time stamp> | Compare-Version | Progress | DEBUG | Comparing version arrays 0.8.0.0 and 0.9.0.0...***
        * ***<date-time stamp> | Compare-Version | Progress | INFORMATION | Left version element is less than equivalent right version element.***
        * ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Success | INFORMATION | No files to update in C:\GitHooks.***
    * Ensure the edited file in ***C:\GitHooks\PowerShellHooks*** still has the ***newer version number***
1. Abort execution of the script to avoid creating or updating additional files

### Unversioned File in Common Git Hooks Directory
##### Functionality Under Test
GitHooksInstaller.ps1 will not overwrite a script in the common Git hooks directory if it has no version number.  The rationale behind this is that all installed files will have a version number so any file without one must have been edited or created by the user and we don't want to overwrite a user's custom scripts.

##### Test Summary
1. Ensure the common Git hooks scripts exist in the common Git hooks directory
2. Edit a file in the the common Git hooks directory to remove the version number line
3. Run part of GitHooksInstaller.ps1 that copies common Git hook scripts
3. Check the edited file in the common Git hooks directory ***still does not have the version number line***

##### Test Steps
1. Ensure the contents of *C:\GitHooks* match the contents of source directory ***\GitHookSourceFilesToCopy\CommonGitHooks***
2. Edit one of the files in ***C:\GitHooks\PowerShellHooks***.  Remove the version number line from the file then save it
3. In script ***GitHooksInstaller.ps1*** add a breakpoint on the command ***following** Set-TargetFileFromSourceDirectory*
3. Execute GitHooksInstaller.ps1 to the breakpoint:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-TargetFileFromSourceDirectory*** are written to the host
    * Verify log messages similar to the following exist:
        * ***<date-time stamp> | Compare-Version | Progress | DEBUG | Comparing version arrays 0.8.0.0 and 99999.0.0.0...***
        * ***<date-time stamp> | Compare-Version | Progress | INFORMATION | Left version element is less than equivalent right version element.***
        * ***<date-time stamp> | Set-TargetFileFromSourceDirectory | Success | INFORMATION | No files to update in C:\GitHooks.***
    * Ensure the edited file in ***C:\GitHooks\PowerShellHooks*** still ***does not have the version number line***
1. Abort execution of the script to avoid creating or updating additional files

## Creating Git Hooks Shell Scripts in Each Git Repository
### Initial Setup
1. Create a new directory ***C:\Temp\GitHookTests***
2. Copy any two Git repositories to the new directory
3. In ***GitHooksInstaller.ps1*** set the value of ***$_localGitReposRootDir = 'C:\Temp\GitHookTests'***

### No Git Hook Scripts in Repositories
##### Functionality Under Test
GitHooksInstaller.ps1 will find all Git repositories under a specified root directory.  For each repository it will copy the generic GitHookShellScript repeatedly to the hooks directory, creating multiple identical Git hooks scripts.  The names of the Git hooks scripts to be created are listed in GitHooksInstaller.ps1 $_gitHookNames.

##### Test Summary
1. Ensure no Git hook scripts exist in either test repository
2. Run GitHooksInstaller.ps1
3. Check Git hook scripts have been created in each test repository, and they all match the source shell script

##### Test Steps
1. In each Git repository under ***C:\Temp\GitHookTests*** check the ***.git\hooks*** sub-directory contains only **** *.sample*** files.  In particular it should ***not*** contain any files without file extensions
2. Execute script ***GitHooksInstaller.ps1*** without any breakpoints:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-GitHookFileFromSourceFile*** are written to the host
    * Ensure directory ***C:\GitHooks*** has been created
    * In the ***.git\hooks*** sub-directory of each test repository ensure the files listed in array ***$_gitHookNames*** in the *Script Arguments and Variables* region of ***GitHooksInstaller.ps1*** have been created, and that each one is a copy of script  ***\GitHookSourceFilesToCopy\GitHookShellScript***

### Git Hook Scripts Already Exist in Repositories
##### Functionality Under Test
GitHooksInstaller.ps1 will find all Git repositories under a specified root directory.  For each repository it will check whether the target files specified in GitHooksInstaller.ps1 $_gitHookNames exist in the hooks directory, and whether they have the same version number as the source file GitHookShellScript.  If the target version numbers match the source version number the target files in the hooks directory will not be updated.

##### Test Summary
1. Ensure Git hook scripts exist in both test repositories
2. Run GitHooksInstaller.ps1
3. Check none of the Git hook scripts in either test repository have changed

##### Test Steps
1. In each Git repository under ***C:\Temp\GitHookTests*** check the ***.git\hooks*** sub-directory contains the files listed in ***GitHooksInstaller.ps1 $_gitHookNames***, each with the same version number as the source file ***\GitHookSourceFilesToCopy\GitHookShellScript***
2. Execute script ***GitHooksInstaller.ps1*** without any breakpoints:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-GitHookFileFromSourceFile*** are written to the host
    * Ensure the files listed in array ***$_gitHookNames*** in the *Script Arguments and Variables* region of ***GitHooksInstaller.ps1*** still exist in the ***.git\hooks*** sub-directory of each test repository, and that each file still has the ***same contents*** as source file ***\GitHookSourceFilesToCopy\GitHookShellScript***

### Outdated Git Hook Scripts in Repositories
##### Functionality Under Test
GitHooksInstaller.ps1 will find all Git repositories under a specified root directory.  For each repository it will check whether the target files specified in GitHooksInstaller.ps1 $_gitHookNames exist in the hooks directory, and whether they have the same version number as the source file GitHookShellScript.  If the target version numbers are older than the source version number the target files in the hooks directory will be overwritten with copies of the source file.

##### Test Summary
1. Ensure Git hook scripts exist in both test repositories
2. Change the version number of two Git hook scripts in each test repository to an ***older version***
2. Run GitHooksInstaller.ps1
3. Check all the edited Git hook scripts in each test repository have had their version numbers restored

##### Test Steps
1. In each Git repository under ***C:\Temp\GitHookTests*** check the ***.git\hooks*** sub-directory contains the files listed in ***GitHooksInstaller.ps1 $_gitHookNames***, each with the same version number as the source file ***\GitHookSourceFilesToCopy\GitHookShellScript***
2. In each Git repository under ***C:\Temp\GitHookTests*** edit two of the Git hook scripts (the files without file extensions) in the ***.git\hooks*** sub-directory.  In each file change the <version number> in the line ***Version: <version number>*** to an ***older version***. eg Change Version: 0.8.0 to Version: 0.7.0.  Save the edited files
2. Execute script ***GitHooksInstaller.ps1*** without any breakpoints:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-GitHookFileFromSourceFile*** are written to the host
    * Verify log messages similar to the following exist:
        * ***<date-time stamp> | Get-TargetFileToUpdate | Progress | INFORMATION | 2 files to update in target directory C:\Temp\GitHookTests\<repository name>\\.git\hooks.***
        * ***<date-time stamp> | Set-TargetFileFromSourceFile<Process> | Success | INFORMATION | Updating files in C:\Temp\GitHookTests\<repository name>\\.git\hooks from file <source directory>\GitHookSourceFilesToCopy\GitHookShellScript completed successfully.***
    * Ensure the edited files in the ***.git\hooks*** sub-directory of each test repository have had their ***version numbers restored*** to the same value as in source file ***\GitHookSourceFilesToCopy\GitHookShellScript***

### Updated Git Hook Scripts in Repositories
##### Functionality Under Test
GitHooksInstaller.ps1 will find all Git repositories under a specified root directory.  For each repository it will check whether the target files specified in GitHooksInstaller.ps1 $_gitHookNames exist in the hooks directory, and whether they have the same version number as the source file GitHookShellScript.  If the target version numbers are newer than the source version number the target files in the hooks directory will not be updated.

##### Test Summary
1. Ensure Git hook scripts exist in both test repositories
2. Change the version number of two Git hook scripts in each test repository to a ***newer version***
2. Run GitHooksInstaller.ps1
3. Check all the edited Git hook scripts in each test repository ***still have the newer version number***

##### Test Steps
1. In each Git repository under ***C:\Temp\GitHookTests*** check the ***.git\hooks*** sub-directory contains the files listed in ***GitHooksInstaller.ps1 $_gitHookNames***, each with the same version number as the source file ***\GitHookSourceFilesToCopy\GitHookShellScript***
2. In each Git repository under ***C:\Temp\GitHookTests*** edit two of the Git hook scripts (the files without file extensions) in the ***.git\hooks*** sub-directory.  In each file change the <version number> in the line ***Version: <version number>*** to a ***newer version***. eg Change Version: 0.8.0 to Version: 0.9.0.  Save the edited files
2. Execute script ***GitHooksInstaller.ps1*** without any breakpoints:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-GitHookFileFromSourceFile*** are written to the host
    * Verify log messages similar to the following exist:
        * ***<date-time stamp> | Compare-Version | Progress | DEBUG | Comparing version arrays 0.8.0.0 and 0.9.0.0…***
        * ***<date-time stamp> | Compare-Version | Progress | INFORMATION | Left version element is less than equivalent right version element.***
        * ***<date-time stamp> | Get-TargetFileToUpdate | Progress | INFORMATION | 0 files to update in target directory C:\Temp\GitHookTests\<repository name>\\.git\hooks.***
    * Ensure the edited files in the ***.git\hooks*** sub-directory of each test repository ***still have the newer version numbers***

### Unversioned Git Hook Scripts in Repositories
##### Functionality Under Test
GitHooksInstaller.ps1 will find all Git repositories under a specified root directory.  For each repository it will check whether the target files specified in GitHooksInstaller.ps1 $_gitHookNames exist in the hooks directory, and whether they have the same version number as the source file GitHookShellScript.  Target files without version numbers will not be updated. 

The rationale behind this is that all installed files will have a version number so any file without one must have been edited or created by the user and we don’t want to overwrite a user’s custom scripts.

##### Test Summary
1. Ensure Git hook scripts exist in both test repositories
2. Remove the version number line from two Git hook scripts in each test repository
2. Run GitHooksInstaller.ps1
3. Check all the edited Git hook scripts in each test repository ***still do not have a version number line***

##### Test Steps
1. In each Git repository under ***C:\Temp\GitHookTests*** check the ***.git\hooks*** sub-directory contains the files listed in ***GitHooksInstaller.ps1 $_gitHookNames***, each with the same version number as the source file ***\GitHookSourceFilesToCopy\GitHookShellScript***
2. In each Git repository under ***C:\Temp\GitHookTests*** edit two of the Git hook scripts (the files without file extensions) in the ***.git\hooks*** sub-directory.  In each file remove the version number line then save it
2. Execute script ***GitHooksInstaller.ps1*** without any breakpoints:
    * If prompted for proxy credentials enter your network username, with domain name, eg "DATACOM-NZ\\<user name>", and password. 
    * Ensure no errors 
    * Ensure log messages relating to ***Set-GitHookFileFromSourceFile*** are written to the host
    * Verify log messages similar to the following exist:
        * ***<date-time stamp> | Compare-Version | Progress | DEBUG | Comparing version arrays 0.8.0.0 and 99999.0.0.0…***
        * ***<date-time stamp> | Compare-Version | Progress | INFORMATION | Left version element is less than equivalent right version element.***
        * ***<date-time stamp> | Get-TargetFileToUpdate | Progress | INFORMATION | 0 files to update in target directory C:\Temp\GitHookTests\<repository name>\\.git\hooks.***
    * Ensure the edited files in the ***.git\hooks*** sub-directory of each test repository ***still do not have a  version number line***

## Using Script Parameters with GitHooksInstaller.ps1
##### Functionality Under Test
GitHooksInstaller.ps1 has three parameters: -GitHooksDir, -LocalGitRepositoriesRootDir and -ProxyUrl.  If the script is run with these three parameters specified their values should override the values specified at the top of the script.

##### Test Summary
1. Execute GitHooksInstaller.ps1, specifying values for the script parameters
1. Validate that the script will use the values specified in the parameters, rather than the hard-coded values set at the top of the script

##### Test Steps
1. Run a PowerShell host, such as PowerShell ISE, ***with administrator privileges***
2. In the host ***change directory*** to the directory containing ***GitHooksInstaller.ps1***
3. In the host open script ***GitHooksInstaller.ps1*** and add a breakpoint ***on the** Install-RequiredModule* command
4. In the host console window execute the following line `.\GitHooksInstaller.ps1 -GitHooksDir 'C:\OtherGitHooks' -LocalGitRepositoriesRootDir 'C:\LocalRepos' -ProxyUrl 'http://some.com:8080'`  (note the leading ".\\" before the script name.  We cannot just specify the script name, we have to specify the path to it.  In this case we're specifying a relative path)
5. When the script pauses at the breakpoint examine the values of the following variables and ensure they match the values passed into the script parameters:
    * Variable ***$_gitHooksDir*** should match the value of parameter ***-GitHooksDir***
    * Variable ***$_localGitRepositoriesRootDir*** should match the value of parameter ***-LocalGitRepositoriesRootDir***
    * Variable ***$_proxyUrl*** should match the value of parameter ***-ProxyUrl***
6. Abort execution of the script to avoid creating a new directory with custom Git hook scripts

### Final Teardown
1. In ***GitHooksInstaller.ps1*** set ***$_localGitReposRootDir = 'C:\Working'*** (back to the default value)
