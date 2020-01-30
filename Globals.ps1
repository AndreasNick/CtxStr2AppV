#=====================================================================================================
#
# Citrix Streaming 2 Msi Converter
# copyright 2013 Andreas Nick Nick Informationstechnik GmbH
# http://www.nick-it.de
#
# Version V0.2
#
# Legal
# This  scritp is copyrighted material.  They may only be downloaded from the
# links I provide.  You may download them to use, if you want to do
# anything else with it, you have to ask me first.  Full terms and conditions are
# available on the download page on the blog http://software-virtualisierung.des
#
#=====================================================================================================


# Historie

#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

[void][reflection.assembly]::Load('System.Security, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')

function Get-ScriptDirectory {
    if ($hostinvocation -ne $null) {
        Split-Path $hostinvocation.MyCommand.path
    }
    else {
        Split-Path $script:MyInvocation.MyCommand.Path
    }
}

[string]$ScriptDirectory = Get-ScriptDirectory

function Verify-XmlSignature {
    Param (
        [xml] $checkxml,
        [system.Security.Cryptography.RSA] $Key
    )
    [System.Security.Cryptography.Xml.SignedXml] $signedXml = New-Object System.Security.Cryptography.Xml.SignedXml -ArgumentList $checkxml
    $XmlNodeList = $checkxml.GetElementsByTagName("Signature")
    $signedXml.LoadXml([System.Xml.XmlElement] ($XmlNodeList[0]))
    $check = $signedXml.CheckSignature($key)
    return $check
}



$Global:rootDir = $ScriptDirectory
$rootDir = $ScriptDirectory

#Time Expire
get-date -UFormat "%Y-%m-%d"
[String[]] $licfiles= Get-ChildItem "$rootDir\LicenseFolder\*.xml"

if ($licfiles.count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Missing license file!")
}

[xml] $Global:License = New-Object xml
$Global:License.Load($licfiles[0])
#
##Veryfy License
[xml] $PublicKey = "<RSAKeyValue><Modulus>o9JRQZxXmff1l73BUySxhIsRzbKjRjWtquI7Tqb3lA1fi4SS15MpyvdTCy2tEoKh3+8Hz5YYKOKQn2x7mwC0YDcKT8HRBdSthNBk+1AePiubsxdTFBsz1mv/5OVneIMYhMHtmB3ddINxcKmKwBvsBOgEv7DIBDkE/etvwP37cT+RP9RfiHD/NkQV9OgcwZMOPbdMbcSch13hHMLHo16EKTLz2WceVpHXxN1x2PCMO693n2lmapUh6KRGY2JXudH7azHutqZO24EPcNRgDF7RiCb2XZjbFSdSHsKnSa6r3bOA1Vzi6ppwjxM1G6wT6DfH5F87BGY3qZS4TyyYz5gKBw==</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>"
$rsaProvider = New-Object System.Security.Cryptography.RSACryptoServiceProvider
$rsaProvider.FromXmlString($PublicKey.InnerXml)
$Global:check = Verify-XmlSignature -checkxml $Global:License -Key $rsaProvider
#Write-Host "Licensecheck : $check"


if (!(Test-Path "$env:ProgramData\NICKIT\Ctx2Appv")) { New-Item "$env:ProgramData\NICKIT\Ctx2Appv" -Force -Type directory | out-null } 
if (!(Test-Path "$env:ProgramData\NICKIT\Ctx2Appv\dd")) { Add-Content (Get-Date -UFormat "%Y-%m-%d") -Path "$env:ProgramData\NICKIT\Ctx2Appv\dd" -Force | out-null}



#GetInstall Date from the executable!
#[DateTime] $installdate = Get-Date ((get-Item ("$Global:rootDir"+"\AppBot-Ctxstr2appv_32.exe")).LastWriteTime) -UFormat "%Y-%m-%d"


[DateTime] $installdate = Get-Date (get-Content -Path "$env:ProgramData\NICKIT\Ctx2Appv\dd") -UFormat "%Y-%m-%d"

$eval = $null

$Global:ueberpruefungsvariante = $false #der Kunde kann ueberprüfen, ob er kaufen will!

if ($Global:check) {
    if ($Global:License.license.Type -eq "Trial") {
        $Global:ueberpruefungsvariante = $True
        $LixText = ($Global:License.Customer)
        $eval = Get-Date $installdate.AddDays(20) -UFormat "%Y-%m-%d"
        if ((Get-Date) -gt $eval) {
            [System.Windows.Forms.MessageBox]::Show("This EALUATION version is expired!`n`nlicense request : info@nick-it.de")
            break
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("This EALUATION version expire on " + $eval + ".`nThis software intended for testing and not for production environments!`nThe trial version is limited to 50 files in a Citrix Application Profile`n`nlicense request : info@nick-it.de")
        }
    }
}


$Global:CommadlineDictionary = $null
$Global:CommadlineDictionary = New-Object System.Collections.Specialized.StringDictionary

$Global:ProjectDefaultPath = [System.Environment]::GetFolderPath("mydocuments") + "\ctxstr2msi\Projects\"
$Global:ProjectDefaultPath_oshlash = [System.Environment]::GetFolderPath("mydocuments") + "$ENV:appdata\ctxstr2msi\Projects"
if (!(Test-Path -Path "$Global:ProjectDefaultPath")) { New-Item -ItemType directory -Path $Global:ProjectDefaultPath -Force | Out-Null }


# GLOBAL VARIABLES
$rootDir = $ScriptDirectory  #Split-Path -Path $MyInvocation.MyCommand.Definition

$Global:ProjectPath = $null
$Global:ProjectFolder = $null
$Global:ProjectSettingsFile = $null # File with the Settings for the actual Project
$Global:LogDir = $null
$Global:Ctxstr2msisourceFiles = $null #unpacked appv file
$Global:Ctxstr2msiFile = $null #Path to the appvFile
$Global:Projectxml = $null
$Global:FromopenedProject = $false
$Global:InstallRootDir = $null
$Global:CtxStrDevicePath = $null

$Global:GUIDPATH = "" #Path for generating the GUIDS

$Global:ignorerrors = $false

function Show-Message([String] $str) {
    if (!$Global:ignorerrors) {
        [System.Windows.Forms.MessageBox]::Show($str)
    }
}


#=====================================================================================================
# #Generate Guid from a String
#=====================================================================================================

function ToGuid([string] $src) {
    $stringbytes = [system.Text.Encoding]::UTF8.GetBytes($src)
    $hashedBytes = (New-Object System.Security.Cryptography.SHA1CryptoServiceProvider).ComputeHash($stringbytes)
    [system.Array]::Resize([ref]$hashedBytes, 16)
    $guid = [System.Guid]($hashedBytes)
    Return $guid.ToString()
    
    #Write-Host $hashedBytes
}

#=====================================================================================================
# Create a valid GUID
#=====================================================================================================
function GetGuid([String] $src) {
    if ($src -eq "") {
        return [String]([System.Guid]::NewGuid()).ToString()
    }
    else {
        return toGuid($src)
    }
}

#Cretate patternmatcher from string
function get-Matcher([String] $str) {
    $str = $str -replace "\\", "\\"
    $str = $str -replace "\(", "\("
    $str = $str -replace "\)", "\)"
    $str = $str -replace "\+", "\+"
    $str = $str -replace "\*", "\*"
    $str = $str -replace '\$', '\$'
    return $str
}


#=====================================================================================================
# Create a Table Line in the xml
#=====================================================================================================

function Set-XmlTableLine {
    param (
        [xml] $tree,
        [System.Xml.XmlElement] $element,
        [String] $Key,
        [String[]] $row
    )
    
    $next = $tree.GetElementsByTagName($key)
    $eNS = $tree.DocumentElement.NamespaceURI
    
    if ($next.count -eq "0") {
        
        $e = $tree.CreateElement("$key", $eNS)
        $next = $element.AppendChild($e)
    }
    else {
        $next = $next.Item(0)
    }
    
    $e = $tree.CreateElement("Row", $eNS)
    
    for ($i = 0; $i -lt ($row.count); $i++) {
        $e.SetAttribute("field$i", $row[$i])
    }
    
    $next.AppendChild($e)
}


#=====================================================================================================
# Create a Array string[][] from a xml Table
#=====================================================================================================

function Get-XmlTableMatrix {
    param (
        [xml] $tree,
        [String] $Key
    )
    
<#
	For more information on the try, catch and finally keywords, see:
		Get-Help about_try_catch_finally
#>
    
    # Try one or more commands
    try {
        $nodes = ($tree.GetElementsByTagName($key)).get_ItemOf(0).ChildNodes
        $attribs = ($nodes.Item(0)).Get_Attributes()
        $nodecount = $nodes.count
        $colcount = $attribs.count
        $OutMatrix = New-Object 'string[][]' $nodecount, $colcount
        
        for ($x = 0; $x -lt $nodecount; $x++) {
            $attribs = ($nodes.Item($x)).Get_Attributes()
            #$line =  @()
            for ($i = 0; $i -lt $colcount; $i++) {
                $OutMatrix[$x][$i] = [String] ($attribs.Get_ItemOf($i)).get_InnerText()
            }
        }
        return $OutMatrix
    }
    
    catch {
        Write-Host $_
    }
}

#=====================================================================================================
# Create a xml from a Array string[][]
#=====================================================================================================

function fill-XmlTable {
    param (
        [xml] $tree,
        [System.Xml.XmlElement] $element,
        $table, #[String[][]] $table,$test,
        [String] $Key
    )
    for ($i = 0; $i -lt $table.count; $i++) {
        Set-XmlTableLine -tree $tree -element $element -row ($table[$i]) -Key $key
    }
}


#=====================================================================================================
#Create a new Table Entry after an existing in a xml table
#=====================================================================================================

function Set-XmlTableLineAfter {
    param (
        [xml] $tree,
        [String] $Key,
        [String[]] $row,
        [int] $line
    )
    
    $eNS = $tree.DocumentElement.NamespaceURI
    $e = $tree.CreateElement("Row", $eNS)
    
    for ($i = 0; $i -lt ($row.count); $i++) {
        $e.SetAttribute("field$i", $row[$i])
    }
    
    $a = $tree.GetElementsByTagName($key)
    $c = $a.get_ItemOf(0).ChildNodes
    $a.Item(0).InsertAfter($e, $c.get_ItemOf($line)) | Out-Null
}

#=====================================================================================================
# Delete a Row in a XML Table
#=====================================================================================================
function delete-Xmlrow {
    param (
        [xml] $tree,
        [String] $Key,
        [int] $row
    )
    
    $a = $tree.GetElementsByTagName($Key)
    $b = $a.get_ItemOf(0).ChildNodes
    $a.Item(0).RemoveChild($b.Item($row)) | Out-Null
}


#=====================================================================================================
# Logging
#=====================================================================================================
function LogInfo([String] $Path, [STRING]$Wert, [STRING] $Ausg) {
    $Timestamp = Get-Date -format 'yyyy-MM-dd#hh-mm-ss'
    $Ausgabe = "$Timestamp : $Wert  $Ausg"
    $Ausgabe | Add-Content "$Path"
    
    Write-Host $Ausgabe
    if ($MainDialog -ne $null) {
        write-logbox $Ausgabe
    }
}


#=====================================================================================================
# Decode a Reglookup Binary String
#=====================================================================================================

function decode_RegLookup_Binary {
    param ([String] $AppvString)
    
    [String]$xByte = ""
    $OutString = ""
    $count = $AppvString.Length
    
    for ($index = 0; $index -lt $count; $index++) {
        switch ($AppvString.Chars($index)) {
            '%' {
                $xByte = $AppvString.get_Chars($index + 1) + $AppvString.get_Chars($index + 2)
                
                $index += 2
                break
            }
            default {
                $xByte = '{0:x2}' -f [system.Convert]::ToByte($AppvString.get_Chars($index))
                break
            }
        }
        $OutString += $xByte + ""
    }
    return $OutString
}




#=====================================================================================================
# Decode a Reglookup String
#=====================================================================================================

function decode_RegLookupString {
    param ([String] $str)
    $OutStr = ""
    for ($i = 0; $i -lt $str.Length; $i++) {
        if ($str.get_Chars($i) -eq '%') {
            $conv = $str.get_Chars($i + 1) + $str.get_Chars($i + 2)
            $OutStr += [CHAR]([CONVERT]::toint16($conv, 16))
            $i += 2
            
        }
        else {
            $OutStr += $str.get_Chars($i)
        }
    }
    Return $OutStr
}



[String[]] $Global:HelpText = @(
" `n",
"-------------------------------------------------------------------------------------`n",
"       AppBotStr2AppV :: AppBot Application Streaming to App-V 5`n",
"       Copyright 2014  Andreas Nick, Nick Informationstechnik GmbH`n",
"-------------------------------------------------------------------------------------`n",
" `n",
"Syntax :: AppBotStr2AppV -ProfilePath <PATH_TO_THE_PROFILE_FILE> ...`n",
" `n",
"All parameters:`n",
" `n",
"-projectpath :: Path to the projectfolder (created, if not exist).`n",
"                The defaultpath is %mydocuments%\ctxstr2msi\Projects\PROFILENAME`n",
" `n",
"-autostart   :: Automatic start of the conversion`n",
" `n" +
"-ConvertAppV ::Try to vonvert to app-v 5 (only on a App-V 5 sequencer`n",
" `n",
"-autoexit    :: Automatic exit this application after the conversion`n",
" `n",
"-ignorerrors :: No messages and no errors the program go on`n",
" `n",
"-------------------------------------------------------------------------------------`n",
" `n")



function Show-ErrorMessage {
    
    Param ([String] $Message)
    
    $Global:MessageBox = @()
    
    #$Global:MessageBox += "Error :`n"
    $Global:MessageBox += " `n"
    for ([int]$x = 0; $x -lt $Message.Length; $x += 84) {
        #$Global:MessageBox += $Message
        $index = $x + 84
        if ($index -ge $Message.Length) { $index = $Message.Length }
        Write-Host $x  $index
        $Global:MessageBox += ($Message.Substring($x, $index - $x))
    }
    $Global:MessageBox += " `n"
    $Global:MessageBox += $Global:HelpText
    Call-MessageFrom_psf
    
}

function Show-MessageBox {
    Param ([String] $Message)
    
    if (!$Global:ignorerrors) {
        [System.Windows.Forms.MessageBox]::Show($Message)
    }
    
}

