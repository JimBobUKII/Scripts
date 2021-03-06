## SharePoint Server 2010: PowerShell Script to Provision Users from a CSV file into an OU in AD - Good for User Profile Testing ##

# Usage: Edit the following 2 parameters and run the script: '$StaffOrgUnit'; 'ProvisionInputCSV' - provide a CSV file path after calling this function

# http://www.sharepointgurus.net
# http://guru-web.blogspot.com
# Resource: http://guru-web.blogspot.com/2011/03/how-to-make-100-friends-in-sharepoint.html
# This script generates user accounts in Active Directory based on details in a CSV file
# The following articles were heavily referenced to create this script
# http://technet.microsoft.com/en-us/magazine/2009.04.windowspowershell.aspx 
# http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-active-directory/
# TODO: User already exists, Manager not found

# Import the Active Directory Powershell Module (Requires a server or work station with the ActiveDirectory module installed)

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# The command that kicks off the process is at the end of this file

# Perform the actions required to provision one user.
# currently only one action (CreateUser) defined, but others may be implemented in the future
Function Provision {
  PROCESS {
    CreateUser $_
  }
}

# Read a CSV file with user details and output a hash table for each entry
# Renames the CSV field names to standard AD field names
# Input parameter - a path to the CSV file with user details
Function ProvisionInputCSV {
  Param ([string]$filename)
  $users = Import-CSV $filename
  foreach ($user in $users) {
    $ht = @{'givenName'=$user.FirstName;
            'sn'= $user.LastName;
            'displayName'= $user.FullName;
            'samAccountName'= $user.AccountName
            'department'= $user.Division;
            'title'= $user.JobTitle;
            'PhysicalDeliveryOfficeName' = $user.Office;
            'telephoneNumber' = $user.Phone;
            'mobile' = $user.Mobile
            'manager' = $user.ManagerCN            
            }
    Write-Output $ht
  }
}         

# Create an Active Directory user 
# Input parameter - a hash table with the user details 
Function CreateUser {
  Param($userinfo)
  
    $Class = “User”
    $StaffOrgUnit = “OU=SPSTestUsers,OU=TGF,DC=npe,DC=theglobalfund,DC=org” #the location where the accounts will be created

    #Create the basic user account object
    $objADSI = [ADSI]("LDAP://"+$StaffOrgUnit)
    $objUser = $objADSI.Create($Class, "CN=" + $userinfo['displayName'])
    $objUser.Put(“sAMAccountName”, $userinfo['sAMAccountName'])
    $objUser.setInfo()
  
    #add additional properties to the new user account object
    if ($userinfo['givenName'] -ne "") { $objUser.Put("givenName",$userinfo['givenName']) }
    if ($userinfo['sn'] -ne "") { $objUser.Put("sn",$userinfo['sn']) } 
    if ($userinfo['displayName'] -ne "") { $objUser.Put("displayName",$userinfo['displayName'])  }
    if ($userinfo['PhysicalDeliveryOfficeName'] -ne "") { $objUser.Put("PhysicalDeliveryOfficeName",$userinfo['PhysicalDeliveryOfficeName']) }
    if ($userinfo['title'] -ne "") { $objUser.Put("title",$userinfo['title']) }
    if ($userinfo['department'] -ne "") { $objUser.Put("department",$userinfo['department']) }
    #$objUser.AccountDisabled = $true #By default the User ID is disabled and must be enabled to use. 
    #generate a secure password based on the person's full name. This will ensure that the account doesn't have a well-known password, which could reduce security
    #$objUser.SetPassword([string]'testinG123')
    $objUser.Put("description","Sample account for SharePoint User Profile")  
    $objUser.Put("c","AU") # Country/Region 'Set the person's country to Australia
    
    #may want to set these properties in the future.
    #$objUser.Put("streetAddress", $userinfo['streetAddress'])  
    #$objUser.Put("telephoneNumber", $userinfo['telephoneNumber'])
    #$objUser.Put("mobile",$userinfo['mobile'])
    #$objUser.Put("l",$userinfo['l'])
    #$objUser.Put("st",$userinfo['st'])
    #$objUser.Put("postalCode",$userinfo['postalCode'])
    #$objUser.Put("company",$userinfo['company'])    
    $objUser.SetInfo()

    #Set the manager if one is defined
    if ($userinfo['manager'] -ne "")
    {
        $objUser.Put("manager",$userinfo['manager'] + "," + $StaffOrgUnit) # Manager Name: - DN Name (i.e. CN=Some one,OU=SomeOU,DC=Domain2,DC=Domain1) 
    }
    $objUser.SetInfo()
}


# The Main command that kicks it all off
# Import the CSV file with the people details and provision a user for each row
ProvisionInputCSV ("C:\Boxbuild\Scripts\PowerShell\Working\sharepoint\sharepoint2010\UserProfiles\People.csv") | Provision

