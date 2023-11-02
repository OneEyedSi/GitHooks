# prepare-commit-msg.psm1

Modifies Git commit messages to prepend the branch name to the start of the commit message.

For example, if you create a commit message `My commit` on branch `acme-319` then the message actually committed to Git will be `ACME-319: My commit`.

## Purpose

To keep a repository tidy we want to delete short-lived branches, such as feature branches, once they are merged back into a long-lived branch like `main`. However, we still want to be able to identify all the commits relating to a particular feature or issue after the branch they were made on has been deleted. Automatically prepending the branch name to each commit message, at the time the commit is made, allows us to still link the commit to the feature after the branch has been deleted.

## Branches to ignore

We only want to prepend the branch name to commit messages for short-lived branches, where the branch will be deleted after being merged back into a long-lived branch like `main`. We want to ignore permanent branches, such as `main`, `master` or `develop`, so that commit messages for those branches don't include branch names.

The list of long-lived branch names to ignore is assigned to variable `$_branchNamesToIgnore`, at the head of script _prepare-commit-msg.psm1_. You may edit this list.

## Branch names which contain numeric issue numbers

Some issue tracking systems, such as GitHub issues or Azure Boards, use numeric issue numbers. If a branch name starts with a number then the number is assumed to be an issue number. Only the number will be added to the commit message and the rest of the branch name will be ignored. For example, if the branch name is `134985_PartsReport` then the text prepended to the commit message will be `134985: `.

The following branch names would be recognized as having numeric issue numbers:

- `134985`
- `134985partsreport`
- `134985_partsreport`
- `134985-partsreport`

These would all result in `134985: ` being prepended to the commit message.

The following branch names would **_not_** be recognized as having numeric issue numbers:

- `acme_134985_partsreport` (branch name does not start with a number)
- `partsreport_134985` (issue number at the end of the branch name, not the start)

These would result in the full branch name being prepended to the commit message.

## Branch names which contain Jira issue numbers

For branch names based on Jira issues (or any issue tracking system that uses a similar issue numbering scheme) only the Jira issue number will be added to the commit message. For example, if the branch name is `acme319_PartsReport` then the text prepended to the commit message will be `ACME-319: `.

Jira-style issue numbers are recognized as text followed by a number at the start of the branch name, with an optional hyphen, `-`, in between. Everything after the number will be ignored.

The following branch names would be recognized as having Jira issue numbers:

- `acme319`
- `acme-319`
- `acme319partsreport`
- `acme319_partsreport`
- `acme-319partsreport`
- `acme-319_partsreport`

These would all result in `ACME-319: ` being prepended to the commit message.

The following branch names would **_not_** be recognized as having Jira issue numbers:

- `acme-partsreport` (no number follows the text at the start of the branch name)
- `partsreport_acme319` (Jira issue number at the end of the branch name, not the start)
- `acme_319` (text and number are separated by an underscore, not a hyphen)

These would all result in the full branch name being prepended to the commit message.

## Branch names which contain known prefixes

Some teams identify feature branches with a prefix, similar to `feature/acme-319`. Known prefixes followed by a separator character will be stripped from the start of the branch name before it is prepended to the commit message.

The list of known prefixes to remove is assigned to variable `$_branchPrefixesToIgnore` at the head of script _prepare-commit-msg.psm1_. You may edit this list to add your own prefixes.

Valid separator characters, between the prefix and the remainder of the branch name, are:

- `/` (forward slash)
- `.` (dot)
- `-` (hyphen)
- `\` (underscore)

Known prefixes are removed from the branch name before the script searches for an issue number. This means the script will still recognize issue numbers preceded by a known prefix. For example, branch name `feature/acme319_partsreport` would result in just `ACME-319: ` being prepended to the commit message.

## The commit message will not be modified when

1. The commit is on an ignored branch, such as `main`, `master` or `develop`. The list of ignored branch names is assigned to variable `$_branchNamesToIgnore` at the head of script _prepare-commit-msg.psm1_. You may edit this list to add your own branch names to ignore;

1. The commit message already has the branch name prepended (for example, if the user has manually included the branch name at the start of the message, or if the user is amending an existing commit which already has the branch name at the start of the message);

1. The `HEAD` is a detached `HEAD`. In other words, the checked out commit is not at the head of a branch. In that case we can't read the branch name so cannot preprend it to the commit message;

1. Modifying existing commits via a rebase.
