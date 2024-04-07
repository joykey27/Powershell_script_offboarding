# Ask for the user's credentials and store them in the variable
$cred = Get-Credential domain\admin user

# Import the Active Directory module
Import-Module ActiveDirectory

# Display a welcome message
Clear-Host
Write-Host "Welcome to the offboarding script made by Philippe Palacios"

# Function to prompt user for yes/no answer
function PromptYesNo {
    param (
        [string]$message
    )
    # Prompt the user for input
    $answer = Read-Host -Prompt $message
    return $answer
}

# Function to perform actions based on user input
function PerformAction {
    param (
        [string]$username
    )
    # Get the user object from Active Directory
    $user = Get-ADUser -Identity $username

    # Prompt the user whether the mailbox needs to be shared or not
    $yesno = PromptYesNo -message "Does $username mailbox needs to be shared ? (Y/N)"
    switch ($yesno) {
        'y' {
            # Prompt for confirmation before proceeding
            $confirm = PromptYesNo -message "Are you sure you want to act on this username : $username ? (Y/N)"
            if ($confirm -eq 'Y') {
                # Perform actions if user confirms
                Set-ADUser -Credential $cred -Identity $user -Replace @{msExchHideFrom365GAL=$true} #will hide the deactivated user from the company GAL
                Disable-ADAccount -Credential $cred -Identity $user
                Move-ADObject -Credential $cred -Identity $user -TargetPath "OU=OU,OU=OU,DC=domain,DC=local"
                Get-AdPrincipalGroupMembership -Identity $user | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -credential $cred -Members $user -Confirm:$false
                Write-Host "$username account is now deactivated, groups are removed,hidden from GAL, and moved to shared mailbox OU"
                # Add code here to delete groups and add domain users groups
            } else {
                Write-Host "Action cancelled"
            }
            Pause
        }
        'n' {
            # Prompt for confirmation before proceeding
            $confirm = PromptYesNo -message "Are you sure you want to delete this username : $username ? (Y/N)"
            if ($confirm -eq 'Y') {
                # Perform actions if user confirms
                Remove-ADUser -Credential $cred -Identity $user -Confirm:$false
                Write-Host "$username account is now deleted"
            } else {
                Write-Host "Action cancelled"
            }
            Pause
        }
        default {
            Write-Host "Invalid input. Please enter 'y' or 'n'."
            PerformAction -username $username
        }
    }
}

# Prompt the user to enter the target username
$username = Read-Host -prompt "Enter the target username"

# Call the function to perform actions based on user input
PerformAction -username $username
