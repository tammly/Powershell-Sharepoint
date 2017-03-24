# 
# Working script.  Bulk and single file upload using encrypted creds.
# The script will prompt for a password on the first run.  It will create password files that can be used for subsequent runs.

# Set the variables 
# ***** Add user or service account info here. *****
$domain = "domain"
$accountname = "user"
$User = $domain + "\" + $accountname
$destination = “https://sharepointurl/sites/script/Shared Documents” 
$File = get-childitem "C:\example files\*.*"
$KeyFile = ".\" + $accountname + ".key"
$PasswordFile = ".\" + $accountname + "pwd"

# Alternative authentication using a file instead of storing password in the script

# Creating encryption key to be used later
    if (!(Test-Path $KeyFile)){
    $Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    $Key | out-file $KeyFile
    }

# Store secure password in a file to be used later
    if (!(Test-Path $PasswordFile)){
    $Key = Get-Content $KeyFile
    $Password = Read-Host "Enter Password" -AsSecureString
    $Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
    }
$Key = Get-Content $KeyFile

# Create credential from files
$credentials = New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)


# Upload the file 
$webclient = New-Object System.Net.WebClient 
$webclient.Credentials = $credentials
$File | foreach {$webclient.UploadFile($destination + "/" + $_.Name, "PUT", $_.FullName)}
$webclient.Dispose()