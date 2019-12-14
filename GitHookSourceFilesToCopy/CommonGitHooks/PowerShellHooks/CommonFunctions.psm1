<#
.SYNOPSIS
Common functions that may be used by any PowerShell script or module.

.DESCRIPTION
All functions in this module will be exported; none will be private.

.NOTES
Author:			Simon Elms
Requires:		PowerShell 5
Version:		0.8.0
Date:			5 Jun 2019

#>

$_messageHeader = ''

<#
.SYNOPSIS
Writes text to standard output, including an optional message header.

.DESCRIPTION

.NOTES

.PARAMETER Message 
String or array of strings.  The text to write to standard output.  If Message is an array 
each element of the array is written as a separate line.

.PARAMETER MessageHeader 
String.  An optional header that will be prefixed to each line of the message text.  If no 
MessageHeader is supplied then the message header returned by Get-MessageHeader will be used.

.PARAMETER WriteFirstLineOnly 
Switch.  When writing an array of text, if WriteFirstLineOnly is set then only the first line 
(ie element) in the array will be written.  This will followed by a line with an ellipsis, "...", 
if there is more than one element in the array.  If this switch is not set then all elements in 
the array will be written.
#>
function Write-OutputMessage (
    $Message, 

    [string]$MessageHeader, 

    [switch]$WriteFirstLineOnly
    )
{
    if (-not $MessageHeader)
    {
        $MessageHeader = Get-MessageHeader
    }

    if ([string]::IsNullOrWhiteSpace($MessageHeader))
    {
        $MessageHeader = ''
    }
    else
    {
        $MessageHeader = "$($MessageHeader.Trim()): "
    }

    if ($Message -is [string])
    {
        Write-Output "$MessageHeader$Message"

        return
    }

    if ($Message -is [array])
    {
        if ($Message.Length -eq 1)
        {
            Write-Output "$MessageHeader$Message"
        }
        else
        {
            foreach($string in $Message)
            {
                Write-Output "$MessageHeader$string"

                if ($WriteFirstLineOnly)
                {
                    Write-Output "$MessageHeader  ..."
                    Break
                }
            }
        }

        return
    }

    Write-Output $MessageHeader
}

<#
.SYNOPSIS
Sets the message header.

.DESCRIPTION

.NOTES

.PARAMETER MessageHeader 
String.  Text that will be prefixed to each line of a message when it is written to the 
output.
#>
function Set-MessageHeader (
    [string]$MessageHeader
    )
{
    $script:_messageHeader = $MessageHeader
}

<#
.SYNOPSIS
Clears the message header.

.DESCRIPTION

.NOTES

#>
function Clear-MessageHeader (
    )
{
    $script:_messageHeader = ''
}

<#
.SYNOPSIS
Gets the message header that was previously set.

.DESCRIPTION

.NOTES
#>
function Get-MessageHeader (
    )
{
    return $script:_messageHeader
}