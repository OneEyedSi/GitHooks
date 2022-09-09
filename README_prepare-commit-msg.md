# prepare-commit-msg.psm1

Modifies Git commit messages to prepend the branch name to the start of the commit message.

For example, if you create a commit message *"My commit"* on branch *"acme-319"* then the message actually committed to Git will be *"ACME-319: My commit"*.

## Purpose
To keep a repository tidy we want to delete short-lived branches, such as feature branches, once they are merged back into master.  However, we still want to be able to identify all the commits relating to a particular feature or issue after the branch they were made on has been deleted.  Automatically prepending the branch name to each commit message, at the time the commit is made, allows us to still link the commit to the feature after the branch has been deleted.

## Branches to ignore
We only want to prepend the branch name to commit messages for short-lived branches, where the branch will be deleted after being merged back into master.  We want to ignore permanent branches, such as master or develop, so that commit messages for those branches don't include branch names.  

The list of branch names to ignore is assigned to variable *$_branchNamesToIgnore* at the head of script *prepare-commit-msg.psm1*.  You may edit this list.

## Branch names which contain Jira issue numbers
For branch names based on Jira issues (or any similar issue tracking system) only the Jira issue number will be added to the commit message.  For example, if the branch name is *"acme319_PartsReport"* then the text prepended to the commit message will be *"ACME-319: "*.  

Issue numbers are recognized as text followed by a number at the start of the branch name, with an optional hyphen, "-", in between.  Everything after the number will be ignored.

The following branch names would be recognized as having Jira issue numbers:

* *"acme319"*
* *"acme-319"*
* *"acme319partsreport"*
* *"acme319_partsreport"*
* *"acme-319partsreport"*
* *"acme-319_partsreport"*

These would all result in *"ACME-319: "* being prepended to the commit message.

The following branch names would ***not*** be recognized as having Jira issue numbers:

* *"319partsreport"*		(starts with a number, not text)
* *"319-partsreport"*		(starts with a number, not text)
* *"acme-partsreport"*		(no number follows the text at the start of the branch name)
* *"partsreport_acme319"*	(Jira issue number at the end of the branch name, not the start)
* *"acme_319"*				(text and number are separated by an underscore, not a hyphen)

These would all result in the full branch name being prepended to the commit message.

## Branch names which contain known prefixes
Some teams identify feature branches with a prefix, similar to *"feature/acme-319"*.  Known prefixes followed by a separator character will be stripped from the start of the branch name before it is prepended to the commit message.

The list of known prefixes to remove is assigned to variable *$_branchPrefixesToIgnore* at the head of script *prepare-commit-msg.psm1*.  You may edit this list to add your own prefixes.

Valid separator characters, between the prefix and the remainder of the branch name, are:

* */ (forward slash)*
* *. (dot)*
* *- (hyphen)*
* *_ (underscore)*

Known prefixes are removed from the branch name before the script searches for a Jira ticket number.  This means the script will still recognize Jira ticket numbers preceded by a known prefix.  For example, branch name *"feature/acme319_partsreport"* would result in just *"ACME-319: "* being prepended to the commit message.

## The commit message will not be modified when
1. The commit is on an ignored branch, such as master or develop.  The list of ignored branch names is assigned to variable *$_branchNamesToIgnore* at the head of script *prepare-commit-msg.psm1*;

1. The commit message already has the branch name prepended (for example, if the user has manually included the branch name at the start of the message, of if the user is amending an existing commit which already has the branch name at the start of the message);

1. The HEAD is a detached HEAD.  In other words, the checked out commit is not at the head of a branch.  In that case we can't read the branch name so cannot preprend it to the commit message;

1. Modifying existing commits via an interactive rebase.