# Working script.  Bulk files download files from Sharepoint using encrypted creds.
# The script will prompt for a password on the first run.  It will create password files that can be used for subsequent runs.

# Set the variables 
# ***** Add user or service account info here. *****
$domain = "domain"
$accountname = "user"
$User = $domain + "\" + $accountname
$source = “https://sharepointurl/sites/script/Shared Documents/” 
$destination = “C:\Storage\Sharepoint\Scripts\test\” 
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


# Parsing the site page and downloading all files. 
$webclient = New-Object System.Net.WebClient 
$webclient.Credentials = $credentials
#$webclient.UseDefaultCredentials = $true
# the addition at the end of the next line is required if you are not using default credentials.  Use just $source with defaultcreds.
$webString = $webClient.DownloadString($source + "Forms/AllItems.aspx") 
$lines = [Regex]::Split($webString, "<br>")
$sub = $source.Split('/')
$sub = $sub[3..($sub.Length-1)]
$sub = $sub -join '/'

foreach ($line in $lines) {
    if ($line.ToUpper().Contains("HREF")) {
            # File or Folder            
            if (!$line.ToUpper().Contains("[TO PARENT DIRECTORY]")) {
                # Not Parent Folder entry
                $items =[Regex]::Split($line, """")
                foreach ($item in $items){
                    if ($item.contains($sub)){ 
                    $item = ($item.split('/'))[-1]                    
                        if ($item -ne "AllItems.aspx"){$webClient.DownloadFile("$source$item", "$destination$item")}
                    
                    }
                }

            }            
    }
}
$webclient.Dispose()
