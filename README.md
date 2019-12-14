# GitHooks

PowerShell Git hook scripts.

A set of shell and PowerShell Git hook scripts.  

## Introduction
Git hooks are script files that Git runs automatically every time certain events occur in a repository.  They are saved in each Git repository in the .git/hooks directory.

There are two problems with Git hooks:

1. Each Git repository has its own Git hooks; there is no central location for Git hooks.  This means that generic Git hook functionality, that you may want in every repository, has to be copied to each of your repositories separately.  This leads to maintenance problems:  Every time you change that generic Git hook functionality the changes will need to be copied into the Git hook scripts in every one of your repositories.

1. Git hooks exist only in the local repository, they are not pushed to the remote repository.  This makes it difficult for developers to share common Git hook functionality, even within the same shared project.

These problems can be mitigated by saving common Git hook script files in a single central location on your machine, then having each Git hook script in every Git repository call the scripts in that central location.  This project provides scripts to support this architecture:

![Git hooks architecture supported by this project](GitHooksArchitecture.png?raw=true "Git hooks architecture supported by this project")

### This project includes:

A PowerShell script, ***Installer\GitHooksInstaller.ps1***, that will install Git hook PowerShell scripts in a central location on your machine, and shell scripts in each of your local Git repositories to call those central Git hook scripts.

The files to be installed are in the ***GitHookSourceFilesToCopy*** directory:

1. Files in the ***CommonGitHooks*** sub-directory will be copied to the central Git hooks location;

1. Shell script ***GitHookShellScript*** will be copied to the .git/hooks directory in each Git repository on your machine.  It will be copied multiple times for each repository, once for each Git hook.  

### How it works:

Whenever an event occurs in a local Git repository that triggers a Git hook:

1. Git will execute the appropriate shell script in the .git/hooks directory.  For example, when a user makes a commit to the local repository the *prepare-commit-msg* shell script in that repository will be executed;

1. The shell script will call PowerShell script *PowerShellGitHookRunner.ps1* in the central Git hooks directory, passing in the name of the shell script doing the calling;

1. PowerShellGitHookRunner.ps1 will invoke a PowerShell module in the central Git hooks directory to handle the Git hook event, determining which module to call based on the name of the shell script that called PowerShellGitHookRunner.ps1.  

**NOTE:** Not all Git hooks have a PowerShell module in the central Git hooks directory.  A module will be added only if there is a need for shared Git hook functionality for all repositories.  If there is no PowerShell module for a particular Git hook the Git action in the local repository that triggered the Git hook will continue normally, without modification or error.

## Getting Started

1. Clone or download this repository to your local machine;

1. Open a PowerShell host, such as PowerShell ISE, ***with administrator privileges***;

1. In the PowerShell host, open script ***GitHooksInstaller.ps1*** in the ***Installer*** directory of the repository;

1. In script ***GitHooksInstaller.ps1*** edit the following variables at the head of the script, if required:
    * ***$_gitHooksDir***:  Path to the central Git hooks directory that will be created;
    * ***$_localGitRepositoriesRootDir***:  Path to the root directory under which all your local Git repositories are located.  Note that the GitHooksInstaller.ps1 script will search the entire directory tree under this root directory for Git repositories to update.  If you set *$_localGitRepositoriesRootDir* to C:\ the script will take a long time to complete;
    * ***$_proxyUrl***:  URL of the proxy server you use to connect to the internet.  This can be left unchanged if you do not use a proxy server as the GitHooksInstaller.ps1 script will attempt to call out to the internet without using a proxy first, and will only use a proxy if that first attempt fails.

1. Execute script ***GitHooksInstaller.ps1***:
    * It takes around 5 minutes to update about 50 Git repositories;
	
    * You may be prompted for your network credentials if you access the internet via a proxy server.  If prompted you will need to include the domain name with your user name;
	
	* You may also be asked whether you wish to install one or more PowerShell modules.  Select "Yes".  The modules that may be installed include the latest version of the NuGet Provider, and the Pslogg logging module;
    
	* Results will be logged to both the PowerShell host and to an *InstallationResults_\<date\>.log* file, which will be created in the same directory as the GitHooksInstaller.ps1 script;

    * GitHooksInstaller.ps1 is idempotent:  It can be run multiple times on the same machine without problem.

### GitHooksInstaller.ps1 performs the following actions:

1. **Updates the NuGet package provider** for PowerShell, if required (this package provider is used when installing modules from the PowerShellGallery);

1. **Installs logging module *Pslogg*** if it isn't already installed.  This is installed from the online PowerShellGallery;

1. **Creates environment variable *GITHOOKSDIR*** to point to the central Git hooks directory.  If the environment variable already exists it will not be modified.  This environment variable is used by the Git hook shell scripts to find the PowerShellGitHookRunner.ps1 script to execute;

1. **Creates the central Git hooks directory**, if required, at the location specified by environment variable GITHOOKSDIR.  **NOTE:** Normally the central Git hooks directory will be created in the location specified by the $_gitHooksDir variable in the GitHooksInstaller.ps1 script.  However, it can be created in a different location if the environment variable GITHOOKSDIR already exists and points to a different location;

1. **Copies *PowerShellGitHookRunner.ps1* and its associated *PowerShell modules* to the central Git hooks directory**;

1. **Finds all Git repositories under the specified root directory**;

1. For each Git repository found, **copies shell script *GitHookShellScript* into the *.git\hooks* sub-directory of the repository** multiple times, once for each Git hook event.  The target files will be named for the Git hook events, eg "commit-msg", "pre-commit", "prepare-commit-msg".

**NOTE - File Version Numbers:**  Version numbers are included in the comments at the top of each file being copied by GitHooksInstaller.ps1.  During the copy process the version number of the source file is compared with the version number of the target file, if the target file already exists.  **The source file will only be copied over a pre-existing target file if the target file's version number is less than the source file's version number.**

Target files without version numbers will never be overwritten.  The rationale behind this is that all files deployed by GitHooksInstaller.ps1 will have a version number.  So if a target file does not have a version number it must have been edited or created by the user.  We don't want to overwrite it because we don’t want to overwrite a user’s custom scripts.

## Usage

Once installed you don't need to do anything.  Git hook PowerShell modules in the central Git hooks directory will be run automatically when an appropriate event occurs in one of the updated Git repositories.

## New Git Repositories

If you create or clone any new Git repository after running GitHooksInstaller.ps1 you will need to create Git hook scripts for the new repository.  The easiest way is to copy the entire .git\hooks directory from a repository which already has Git hook scripts.  Alternatively you could run GitHooksInstaller.ps1 again, with *$_localGitRepositoriesRootDir* pointing to the new repository's directory.

## Currently Included Git Hooks

The following Git hook modules will be installed in the central Git hooks directory:

### prepare-commit-msg.psm1
----
Modifies Git commit messages to prepend the branch name to the start of the commit message.

For example, if you create a commit message *"My commit"* on branch *"acme-319"* then the message actually committed to Git will be *"ACME-319: My commit"*.

#### Purpose:
To keep a repository tidy we want to delete short-lived branches, such as feature branches, once they are merged back into master.  However, we still want to be able to identify all the commits relating to a particular feature or issue after the branch they were made on has been deleted.  Automatically prepending the branch name to each commit message, at the time the commit is made, allows us to still link the commit to the feature after the branch has been deleted.

#### Branches to ignore:
We only want to prepend the branch name to commit messages for short-lived branches, where the branch will be deleted after being merged back into master.  We want to ignore permanent branches, such as master or develop, so that commit messages for those branches don't include branch names.  The list of branch names to ignore is assigned to variable *$_branchNamesToIgnore* at the head of script *prepare-commit-msg.psm1*.  You may edit this list.

#### Branch names which contain JIRA issue numbers:
For branch names based on JIRA issues (or any similar issue tracking system) only the JIRA issue number will be added to the commit message.  For example, if the branch name is *"acme319_PartsReport"* then the text prepended to the commit message will be *"ACME-319: "*.  

Issue numbers are recognized as text followed by a number at the start of the branch name, with an optional hyphen, "-", in between.  Everything after the number will be ignored.

The following branch names would be recognized as having JIRA issue numbers:

* *"acme319"*
* *"acme-319"*
* *"acme319partsreport"*
* *"acme319_partsreport"*
* *"acme-319partsreport"*
* *"acme-319_partsreport"*

These would all result in *"ACME-319: "* being prepended to the commit message.

The following branch names would ***not*** be recognized as having JIRA issue numbers:

* *"319partsreport"*		(starts with a number, not text)
* *"319-partsreport"*		(starts with a number, not text)
* *"acme-partsreport"*		(no number follows the text at the start of the branch name)
* *"partsreport_acme319"*	(JIRA issue number at the end of the branch name, not the start)
* *"acme_319"*				(text and number are separated by an underscore, not a hyphen)

These would all result in the full branch name being prepended to the commit message.

#### The commit message will not be modified when:
1. The commit is on an ignored branch, such as master or develop.  The list of ignored branch names is assigned to variable *$_branchNamesToIgnore* at the head of script *prepare-commit-msg.psm1*;

1. The commit message already has the branch name prepended (for example, if the user has manually included the branch name at the start of the message, of if the user is amending an existing commit);

1. The HEAD is a detached HEAD.  In other words, the checked out commit is not at the head of a branch.  In that case we can't read the branch name so cannot preprend it to the commit message;

1. Modifying existing commits via an interactive rebase.