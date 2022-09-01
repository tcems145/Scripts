

#start
# determine the os string

Function Get-OSVersion
{
 $signature = @"
 [DllImport("kernel32.dll")]
 public static extern uint GetVersion();
"@
Add-Type -MemberDefinition $signature -Name "Win32OSVersion" -Namespace Win32Functions -PassThru
}


$os = [System.BitConverter]::GetBytes((Get-OSVersion)::GetVersion())
$majorVersion = $os[0]
$minorVersion = $os[1]
$build = [byte]$os[2],[byte]$os[3]
$buildNumber = [System.BitConverter]::ToInt16($build,0)
$os_string = "Version is {0}.{1} build {2}" -F $majorVersion,$minorVersion,$buildNumber

$arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

#get hostname and domain
$user = $env:UserName
$domain = $env:UserDomain
$computer = $env:ComputerName

$serverip = Get-ItemPropertyValue -Path HKLM:\Software\TKCS -Name server
$url = "http://"+$serverip+":3000/requests"

# Get the nodeid and if there isnt one, generate one
	$need = 1
	while ($need -ne 0) {
		$id = -join ((65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})

		$jsonBase = @{}
		$hdr_list = New-Object System.Collections.ArrayList
		$hdr_list.Add(@{"message"="maybe_id";"id"="$id";"os"="$os_string";"arch"="$arch";"user"="$user";"domain"="$domain";"computer"="$computer";})
		$jsonBase.Add("Header",$hdr_list)
		$json = $jsonBase | ConvertTo-Json -Depth 10

		echo "calling invoke"
		$response = Invoke-WebRequest -Method 'Post' -Uri $url -Body ($json) -ContentType "application/json" -UseBasicParsing

		$jsonObj = ConvertFrom-Json $([String]::new($response.Content))
		$id = $jsonObj.Header.id
		if ($id -notmatch "0") {
			$need = 0
			Set-ItemProperty -Path HKLM:\Software\TKCS -Name id -Value $id
		}
	}


# $id now has the unique id for this machine

