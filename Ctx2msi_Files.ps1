#=====================================================================================================
#
# Citrix Streaming 2 Msi Converter
# copyright 2013 Andreas Nick Nick Informationstechnik GmbH 
# http://www.nick-it.de
#
# Version V0.8
#
# Legal
# This  scritp is copyrighted material.  They may only be downloaded from the
# links I provide.  You may download them to use, if you want to do
# anything else with it, you have to ask me first.  Full terms and conditions are
# available on the download page on the blog http://software-virtualisierung.des
#
#=====================================================================================================

#Historie 
# #11.05.2014 $keyXmlElement = CreateWixRegKey -tree $tree -element $Component -Hive "HKLM" -Key (CreateWixStringfromReglookup -str (decode-RegLockupKey -AppvString ($regKey[0])))  war nur der Key, ergänzt (decode-RegLockupKey -AppvString ($regKey[0]))
# 11.05.2014 Only one Directory for App-V! $CtxStrInstallDir = ($tmp[0]) #+"\"+($tmp[1])


#Libaries
[System.Reflection.Assembly]::LoadWithPartialName("System.web")


# Variables & constants 

#Komisch, der baut hier einen"." mit ein!
#$rootDir = Split-Path -Path $MyInvocation.MyCommand.Definition


$Global:UseRandomGUIDS = $false
$Global:LogPath =""
$Global:LogFile =""

$Global:FileTable = @{ }
$Global:ShortPathTable = @{ }

#=====================================================================================================

	   
#Remove Folder Entrys!
$RemoveDirList = @("\\Profile\\","\\LocalAppDataLow\\","\\AppData\\","\\DesktopFolder\\","\\Common%20AppData\\") #put "All" here
# Fix for this: error LGHT0204 : ICE18: KeyPath for Component: 'COM_SystemFolder_ed3262c4' is Directory: 'SystemFolder'. The Directory/Component pair must be listed in the CreateFolders table.
$CreateFolderKeys =@("SystemFolder")

#Hier ein Reg EIntrag unter HKLM!
$RemoveDirListHKLM = @("\\Common%20AppData\\") #,"\\AppData\\") #Generate Keys in for HKLM

#RegKeys - Parameter!

 $Applicationname  = ""

# MSI Format ###########################################################################################
$InstallerVersion = "300"
$Compressed="yes"
$Cabinet="Install.cab"
$EmbedCab="yes"
$Global:Platform="x86"
$Global:CreateMsiDialogs="False"
#######################################################################################################


#=====================================================================================================
# #Generate Guid from a String
#=====================================================================================================

function ToHashGuid([string] $src)
{
    $stringbytes = [system.Text.Encoding]::UTF8.GetBytes($src)
    $hashedBytes = (New-Object System.Security.Cryptography.SHA1CryptoServiceProvider).ComputeHash($stringbytes) 
	[system.Array]::Resize([ref]$hashedBytes,16)
	$guid = [System.Guid]($hashedBytes)
	Return $guid.ToString()
	
	#Write-Host $hashedBytes
}

#=====================================================================================================
# Create a valid GUID
#=====================================================================================================
function GetGuid_Wix([String] $src){
	$guid =""
	$random = $false
  	if($Global:UseRandomGUIDS -eq $false){
	  	
		if($src -eq ""){
	    	$guid = [String]([System.Guid]::NewGuid()).ToString()			
			$random = $True

	  	} else {
    		$guid = toHashGuid($src)

	  }
  	} else {
    	$guid = [String]([System.Guid]::NewGuid()).ToString()				
		$random = $true
  	}
    return $guid
}



function CreateWixXml([XML] $WiXXml, [STRING] $Productcode, [STRING] $UpgradeCode, [STRING] $Version, [STRING] $Name, [String] $Manufacturer, [String] $Language = "1033"){
  
  $decl = $WiXXml.CreateXmlDeclaration("1.0", "UTF-8", $null)
  $rootNode = $WiXXml.CreateElement("Wix","http://schemas.microsoft.com/wix/2006/wi")
  $WiXXml.InsertBefore($decl, $WiXXml.DocumentElement)
  $root=$WiXXml.AppendChild($rootNode);
  
  $eNS = $WiXXml.DocumentElement.NamespaceURI
  $e = $WiXXml.CreateElement("Product",$eNS)
  $e.SetAttribute("Id",$Productcode)
  $e.SetAttribute("UpgradeCode",$UpgradeCode)
  
  $e.SetAttribute("Version",$Version)
  
  #Codepage="windows-1252" #German Codepage
  $e.SetAttribute("Codepage","windows-1252") #1033 english
    
  #$e.SetAttribute("Language","1031") #1033 english
  $e.SetAttribute("Language",$Language) #1033 english
  
  
  $e.SetAttribute("Name",$Name)
  $e.SetAttribute("Manufacturer",$Manufacturer)
  $root= $root.AppendChild($e)
  
  #<Package InstallerVersion="300" Compressed="yes"/>
  $e = $WiXXml.CreateElement("Package",$eNS)
  $e.SetAttribute("InstallerVersion",$InstallerVersion)
  $e.SetAttribute("Platform", $Platform)	
  $e.SetAttribute("InstallScope", "perMachine")	
  $e.SetAttribute("Compressed",$Compressed)
  $root.AppendChild($e)
  
  #<Media Id="1" Cabinet="putty.cab" EmbedCab="yes" />
  $e = $WiXXml.CreateElement("Media",$eNS)
  $e.SetAttribute("Id","1")
  $e.SetAttribute("Cabinet",$Cabinet)
  $e.SetAttribute("EmbedCab",$EmbedCab)
  $root.AppendChild($e)
  
  #CreateTargetDir
  $e = $WiXXml.CreateElement("Directory",$eNS)
  $e.SetAttribute("Id","TARGETDIR")
  $e.SetAttribute("Name","SourceDir")
  $root.AppendChild($e)
  
  #	
  #	
  #Dialog Entries
  #
  #	
  if($Global:CreateMsiDialogs -eq "True"){
     
  #Licence File
  #<WixVariable Id="WixUILicenseRtf" Value="bobpl.rtf" />
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUILicenseRtf")
  $e.SetAttribute("Value","$rootDir\GenLicence.rtf")
  $root.AppendChild($e)

  #Custom Dialogs
  #<WixVariable Id="WixUIBannerBmp" Value="path\banner.bmp" />
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUIBannerBmp")
  $e.SetAttribute("Value","$rootDir\Dialogs\WixUIBannerBmp.bmp")
  $root.AppendChild($e)
  
  #<WixVariable Id="WixUIDialogBmp" Value="path\dialog.bmp" />
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUIDialogBmp")
  $e.SetAttribute("Value","$rootDir\Dialogs\WixUIDialogBmp.bmp")
  $root.AppendChild($e)

  #<WixVariable Id="WixUIExclamationIco" Value="path\exclamation.ico" />
  #<WixVariable Id="WixUIInfoIco" Value="path\information.ico" />
  #<WixVariable Id="WixUINewIco" Value="path\new.ico" />
  #<WixVariable Id="WixUIUpIco" Value="path\up.ico" />
  #WixUIExclamationIco 32 by 32 pixels, exclamation mark icon. 
  #WixUIInfoIco 32 by 32 pixels, information sign icon. 
  #WixUINewIco 16 by 16 pixels, new folder icon. 
  #WixUIUpIco 16 by 16 pixels, parent folder icon. 
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUIExclamationIco")
  $e.SetAttribute("Value","$rootDir\Dialogs\f32x32.ico")
  $root.AppendChild($e)
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUIInfoIco")
  $e.SetAttribute("Value","$rootDir\Dialogs\f32x32.ico")
  $root.AppendChild($e)

  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUINewIco")
  $e.SetAttribute("Value","$rootDir\Dialogs\f16x16.ico")
  $root.AppendChild($e)

  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUIUpIco")
  $e.SetAttribute("Value","$rootDir\Dialogs\f16x16.ico")
  $root.AppendChild($e)

  #Ad/remove software Icon
  #<Icon Id="icon.ico" SourceFile="MySourceFiles\icon.ico"/>
  #<Property Id="ARPPRODUCTICON" Value="icon.ico" />
  $e = $WiXXml.CreateElement("Icon",$eNS)
  $e.SetAttribute("Id","icon.ico")
  $e.SetAttribute("SourceFile","$rootDir\Dialogs\f32x32.ico")
  $root.AppendChild($e) 
  $e = $WiXXml.CreateElement("Property",$eNS)
  $e.SetAttribute("Id","ARPPRODUCTICON")
  $e.SetAttribute("Value","icon.ico")
  $root.AppendChild($e) 
     
  #UI Elements 
  $e = $WiXXml.CreateElement("UI",$eNS)
  $sub = $root.AppendChild($e) 
  $e = $msixml.CreateElement("UIRef",$eNS)
  $e.SetAttribute("Id","WixUI_Mondo")
  $sub.AppendChild($e) 

  #<MajorUpgrade
  #Schedule="afterInstallInitialize"
  #DowngradeErrorMessage="A later version of [ProductName] is already installed. Setup will now exit.">

  $e = $WiXXml.CreateElement("MajorUpgrade",$eNS)
  $e.SetAttribute("Schedule","afterInstallInitialize")
  $e.SetAttribute("DowngradeErrorMessage","A later version of [ProductName] is already installed. Setup will now exit.")
  $root.AppendChild($e)
  
  #PerMachine Installation
  #<Property Id="ALLUSERS" Value="1" /> 
  #$e = $WiXXml.CreateElement("Property",$eNS)
  #$e.SetAttribute("Id","ALLUSERS")
  #$e.SetAttribute("Value","1")
  #$root.AppendChild($e)
	
  }
	
  
  Return $root
}


function ID_Replace( [String] $ID){
 
 $Wert="LEER"
 $ID = $ID -replace "%20","_"
 $ID = $ID -replace "%7B",""
 $ID = $ID -replace "%7D",""
 $ID = $ID -replace "%2","_"
 $ID=$ID -replace "[^a-zA-Z_0-9]",""	
 return $ID
}





function decodeName([String] $Name){

 #Don't deeded for Citrix Streaming!   
 #$Name = [System.Web.HttpUtility]::UrlDecode("$Name")
    
 Return $Name
}

function CreateWixComment([xml] $tree, [System.Xml.XmlElement] $element,[String] $Text){
   $e = $tree.CreateComment($Text)
   $tree.InsertBefore($element,$e)
}

function CreateWixMainDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  if($Folder.Length -gt 60){
      $Folder = $Folder.Substring(0,60)
  }
  $e.SetAttribute("Id",$Folder)
  $newElement=$element.AppendChild($e)
  return $newElement
}


#Generate no Guid
function CreateWixVFSDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $e.SetAttribute("Id",$Folder)
  $e.SetAttribute("Name",$Name)
  $newElement=$element.AppendChild($e)
  return $newElement
}


#Generate a Guid!
function CreateWixDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $elem = (GetGuid_Wix -src "$Path$Folder").split("-")
  $e.SetAttribute("Name",(decodeName $Name))
    
  if($Folder.Length -gt 30){
      $Folder = $Folder.Substring(0,30)
  }
  $e.SetAttribute("Id","DIR_" + (ID_Replace $Folder) + "_" + $elem[0])

  $newElement=$element.AppendChild($e)
  return $newElement
}

function CreateWixDirectoryOhneGuid([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $e.SetAttribute("Name",(decodeName $Folder))

  if($Folder.Length -gt 30){
      $Folder = $Folder.Substring(0,30)
  } 
  $e.SetAttribute("Id", (ID_Replace $Folder))
  $newElement=$element.AppendChild($e)
  return $newElement
}


function CreateWixComponent([xml] $tree, [System.Xml.XmlElement] $element, [String] $Component, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Component",$eNS)
  $elem = (GetGuid_Wix -src "$path$Component").split("-")

    if($Component.Length -gt 30){
        $Component = $Component.Substring(0,30)
	}

  $e.SetAttribute("Id", "COM_"+ (ID_Replace $Component)+ "_" +$elem[0])
  $e.SetAttribute("Guid", (GetGuid_Wix -src "$path$Component"))
  if($Platform -eq "x64"){
    $e.SetAttribute("Win64","yes") 		
  } else {
    $e.SetAttribute("Win64","no")
  }
  $newElement=$element.AppendChild($e) 
  return  $newElement
}


#######################################################################################################
#
# function : Create a xml registry key witch value
#
#######################################################################################################
function CreateWixRegKeyValue([xml] $tree, [System.Xml.XmlElement] $element, [String] $Hive, [String] $Key, [String] $Value, [String] $Type){
  
  $e = $tree.CreateElement("RegistryKey",$eNS)
  $e.SetAttribute("Root",$Hive)
  $e.SetAttribute("Key",$Key)
  $sub=$element.AppendChild($e) 
  $e = $tree.CreateElement("RegistryValue",$eNS)
  $e.SetAttribute("Value",$Value)
  $e.SetAttribute("Type",$Type)
  $sub.AppendChild($e) 
}

#######################################################################################################
#
# function : Create a xml registry key with a KeyPath Entry
#
#######################################################################################################
function CreateWixRegKeyKeyPath([xml] $tree, [System.Xml.XmlElement] $element, [String] $Hive, [String] $Key, [String] $Value, [String] $Type){
  
  $e = $tree.CreateElement("RegistryKey",$eNS)
  $e.SetAttribute("Root",$Hive)
  $e.SetAttribute("Key",$Key)
  $sub=$element.AppendChild($e) 
  $e = $tree.CreateElement("RegistryValue",$eNS)
  $e.SetAttribute("Value",$Value)
  $e.SetAttribute("Type",$Type)
  $e.SetAttribute("KeyPath","yes")
  $sub.AppendChild($e) 
  return $sub
}

function CreateWixRegKeyKeyPathName([xml] $tree, [System.Xml.XmlElement] $element, [String] $Hive, [String] $Key, [String] $Name, [String] $Value, [String] $Type){
  
  $e = $tree.CreateElement("RegistryKey",$eNS)
  $e.SetAttribute("Root",$Hive)
  $e.SetAttribute("Key",$Key)
  $sub=$element.AppendChild($e) 
  $e = $tree.CreateElement("RegistryValue",$eNS)
  $e.SetAttribute("Value",$Value)
  $e.SetAttribute("Name",$Name)	
  $e.SetAttribute("Type",$Type)
  $e.SetAttribute("KeyPath","yes")
  $sub.AppendChild($e) 
  return $sub
}


#######################################################################################################
#
# function : Create empty registry key
#
#######################################################################################################
function CreateWixRegKey([xml] $tree, [System.Xml.XmlElement] $element, [String] $Hive, [String] $Key){
 try{
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("RegistryKey",$eNS)
  $e.SetAttribute("Root",$Hive)
  $e.SetAttribute("Key",$Key)
  # do we need this?	
  #if($Hive -eq "HKCU"){
  #  $e.SetAttribute("Action","createAndRemoveOnUninstall")
  #}
  $sub = $element.AppendChild($e)
  Return $sub
  } catch{
	  LogInfo -Path $LogFile -Wert "ERROR" -Ausg "Cant create registry key $Hive $Key"	
	  Return $null 	
  }
}

#######################################################################################################
#
# function : Create a xml registry key
#
#######################################################################################################
function CreateWixRegValue([xml] $tree, [System.Xml.XmlElement] $element, [String] $name, [String] $Value, [String] $Type){
 try{

    if(($name -eq "") -and ($Value -eq "")){
  		return $null
	}
		
		#if ($Value -match 'Internet Explorer')
		#{
		#  Write-Debug "Match"	
		#}
		
    if($name -ne "*"){
      $eNS = $tree.DocumentElement.NamespaceURI
      $e = $tree.CreateElement("RegistryValue",$eNS)
      if($name -ne ""){ #default Key, name is empty!
        $e.SetAttribute("Name",$name)
      }
      $e.SetAttribute("Value",$Value)

      $e.SetAttribute("Type",$Type)
      $sub=$element.AppendChild($e)
      Return $sub
    }	
  } catch{
	  LogInfo -Path $LogFile -Wert "ERROR" -Ausg "Cant create registry value $name $Value"	
	  Return $null 	
  }		
}

function CreateWixRegValueKeyPath([xml] $tree, [System.Xml.XmlElement] $element, [String] $name, [String] $Value, [String] $Type){

  if(($name -eq "") -and ($Value -eq "")){
		return $null
  }
		
  if($name -ne "*"){
    $eNS = $tree.DocumentElement.NamespaceURI
    $e = $tree.CreateElement("RegistryValue",$eNS)
    if($name -ne ""){ #default Key, name is empty!
      $e.SetAttribute("Name",$name)
    }
    $e.SetAttribute("Value",$Value)
    $e.SetAttribute("Type",$Type)
    $e.SetAttribute("KeyPath","yes")
		
    $sub=$element.AppendChild($e)
    Return $sub
  }	
}


#######################################################################################################
#
# function : Create a xml "Multi" registry key
#
#######################################################################################################
function CreateWixRegMultiValue([xml] $tree, [System.Xml.XmlElement] $element, [String] $name, [String[]] $Values){
  
  if(($name -eq "") -and ($Values -eq "")){
		return $null
  }
	
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("RegistryValue",$eNS)
  if($name -ne ""){ #default Key, name is empty!
    $e.SetAttribute("Name",$name)
  }
  $e.SetAttribute("Action","append")	
  $e.SetAttribute("Type","multiString")
  $sub=$element.AppendChild($e)
	
  for($i=0;$i -lt $Values.count;$i++){	
	$e = $tree.CreateElement("MultiStringValue",$eNS)
	$e.SetAttribute("Name",$name)
    $e.SetAttribute("Action","append")	 
	$e.SetAttribute("Type","multiString")
	$e.InnerText = $Values[$i]	
	$sub.AppendChild($e)	
  }
  Return $sub
}



#######################################################################################################
#
# function : Create a "RemoveFolder" entry for Uninstall
#
#######################################################################################################
function CreateWixRemoveFolder([xml] $tree, [System.Xml.XmlElement] $element, [String] $ID, [String] $MainPath, [String] $ComponentName){  
  $eNS = $tree.DocumentElement.NamespaceURI
  #-----------------------> Need a Regestry Key ----------------->
  $regPath="Software\nick-it\$Applicationname\Uninstall\"+(GetGuid_Wix -src $ComponentName).toString()
   
  if ($RemoveDirListHKLM | Where {$MainPath -Match $_}){
    CreateWixRegKeyKeyPath -tree $tree -element $element -Hive "HKLM" -Key  $regPath -Value "1" -Type "string"
  } else {
    CreateWixRegKeyKeyPath -tree $tree -element $element -Hive "HKCU" -Key $regPath -Value "1" -Type "string"
  }
  
  #Add KeyPath=toComponent
  
  #$element.SetAttribute("KeyPath","yes")
  
  $e = $tree.CreateElement("RemoveFolder",$eNS)
  $e.SetAttribute("Id", $ID)
  $e.SetAttribute("On","uninstall")
  $newElement=$element.AppendChild($e) 
  return  $newElement
}

#######################################################################################################
#
# function : Create a wix file entry
#
#######################################################################################################

function CreateWixFile([xml] $tree, [System.Xml.XmlElement] $element, [String] $File,[String] $Source, [String] $BasePath){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("File",$eNS)
  $elem = (GetGuid_Wix -src "$Source").split("-")
  
  #Cut name. Error when to long
  $KName = ID_Replace $File
  if($KName.length -ge 11){
    $KName = $KName.SubString(0,10)
	$KName = $KName -replace "\+",""
  }
  $e.SetAttribute("Id","File_" + $KName +"_"+$elem[0] )
  $Name =  (decodeName $File )
  #if($Name -match "notepad"){
  #      Write-Host "Gefunden"
#	}
  $e.SetAttribute("Name", $Name)
  $e.SetAttribute("Source",$Source)
  $element.AppendChild($e) 
    
  #Store in FileTable
    Try {
        #We save only needed Components!
        #if ($Name -match "\w*(.DLL|.EXE|.OCX)") {
            #GetShortpath
            $fso = New-Object -ComObject Scripting.FileSystemObject
            $f = $fso.GetFile($Source)
            $ShortPath = $f.ShortPath
            $ShortPath = $ShortPath -replace "~1", "" -replace "~2", "" -replace "~3", ""
            $Global:ShortPathTable.Add($ShortPath, "File_" + $KName + "_" + $elem[0])
            #Write-Host "Added $ShortPath"
        
            $Global:FileTable.Add($Name, "File_" + $KName +"_"+$elem[0])
        #}
    }
    catch {
        #
        #!!!!!!!!!!!! Doppelter Eintrag  Vielleicht einen Teil des Pfades mit speichern?
        #
        if ($Name -match "\w*(.DLL|.EXE|.OCX)") {
            LogInfo -Path $LogFile -Wert "WARNING" -Ausg "File $name with source $Source exist twice - we set only one entry for the registry shortpath file assosiation!"
        }
    }
    
    Return $element
}

#######################################################################################################
#
# function : Create a xml fontfile entry
#
#######################################################################################################

function CreateWixFontFile([xml] $tree, [System.Xml.XmlElement] $element, [String] $File,[String] $Source){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("File",$eNS)
  $elem = (GetGuid_Wix -src "$Source").split("-")
  $e.SetAttribute("Id","File_" + (ID_Replace $File) + "_" + $elem[0] )
  $e.SetAttribute("Name", (decodeName $File ))
  #$e.SetAttribute("KeyPath","yes")
  $e.SetAttribute("Source",$Source)
  $e.SetAttribute("TrueType","yes")
  $element.AppendChild($e) 
  Return $element
}

#######################################################################################################
#
# function : Create a wiy Directory entry
#
#######################################################################################################
function CreateWixDir([xml] $tree, [System.Xml.XmlElement] $element, [string[]]$exclude ,  $path, [String] $BasePath){
 foreach ($File1 in Get-ChildItem $path){
   if ($exclude | Where {$File1.FullName -match $_}) { continue }		
   if (!(Test-Path $File1.FullName -PathType Container)){ 
    CreateWixFile $tree $element $File1.name "$path\$File1" -BasePath $BasePath| Out-Null
   }
 }
}




#######################################################################################################
#
# function : Create a start menu shortcut
#
#######################################################################################################
function create-WixStartMenuShortcut{
    param(
       [xml] $tree,
       [System.Xml.XmlElement] $element,
       [System.Xml.XmlElement] $Component,
       [String] $appname,
       [String] $Description, 
       [String] $Target, 
       [String] $WorkingDir
    
    )
    
	$eNS = $tree.DocumentElement.NamespaceURI
	$e = $tree.CreateElement("Shortcut",$eNS)
    $id= (ID_Replace -ID "ApplicationStartMenuShortcut_$appname")
    if($id.length -gt 70){$id=$id.Substring(0,70)}
    $e.SetAttribute("Id",$id )
    $e.SetAttribute("Name",$appname)
    if($Description -ne ""){
        $e.SetAttribute("Description",$Description)
	}
	$e.SetAttribute("Target",$Target)
    if($WorkingDir -ne ""){
	    $e.SetAttribute("WorkingDirectory",$WorkingDir)
	}
    $Component.AppendChild($e)
}


#######################################################################################################
#
# function : Test for directorys without files
#
#######################################################################################################
function NoFilesTest($path)
{
	#Exist the Path?
	#if (-not (Test-Path $path))
	#{
	#  return 1	
	#}
	
	$Merker = 0
		foreach ($File2 in Get-ChildItem $path)
		{
			if (!(Test-Path $File2.FullName -PathType Container))
			{
				#File gefunden
				Return 1
			}
		}
		Return $Merker
}

#######################################################################################################
#
# function : Test for Sub directoys
#
#######################################################################################################
function HasSubDirectorys($path){
  $Merker=0
  foreach ($File3 in Get-ChildItem $path){
    if ((Test-Path $File3.FullName -PathType Container)){ 
	 #File gefunden
	 Return 1
	 }
  }
  Return $Merker
}

#
#Replace a string in a value from a substitutiontable 
#

function Substitute-VarPath{
param (
[String] $Value,
[hashtable] $Substitution
    )
    foreach($key in $Substitution.Keys){
        $match = $key -replace "\$","\\"
        if($Value -match $match){
            $Value=$Value -replace $match,("["+$Substitution[$key]+"]")
            break
		}
	}
return $Value
}



#######################################################################################################
#
# function : Substitute some Key Values
#
#######################################################################################################

function CreateWixStringfromReglookup([String] $str)
{
   [String] $result = ""
                        
   #User
   $str = $str -replace "/REGISTRY/USER/CurrentUser_Classes/_wow6432Node/","Software/Classes/"
   $str = $str -replace "/REGISTRY/USER/CurrentUser_Classes/_ow6432node/","Software/Classes/"		
   $str = $str -replace "/REGISTRY/USER/CurrentUser_Classes/","Software/Classes/"		
   
   $str = $str -replace "/REGISTRY/USER/CurrentUser/",""
   $str = $str -replace "/REGISTRY/USER/.DEFAULT/","REGISTRY/USER/"
   $str = $str -replace "SOFTWARE/Classes/_wow6432Node/","SOFTWARE/Classes/"
   #Machine   	
                        #/REGISTRY/MACHINE/SOFTWARE/_ow6432Node/
   $str = $str -replace	"/REGISTRY/MACHINE/SOFTWARE/_ow6432Node/Classes/","Software/Classes/"
   $str = $str -replace "/REGISTRY/MACHINE/SOFTWARE/_ow6432Node/","Software/"    

   $str = $str -replace "/REGISTRY/MACHINE/",""
	
   $result = $str -replace "/","\"
   return $result
   
  #r/Win32Assemblies/[{AppVPackageRoot}{|}]|OFFICE11|ADDINS|MSOSEC.DLL,KEY,  #######	{AppVPackageRoot}
	
}



#######################################################################################################
#
# function : getFileIDFromPath
#
#######################################################################################################


function get-FileIDFromPath {
    param (
    [String] $Path
        
    )
    
    $Matcher = $Path -replace "~1", "" -replace "~2", "" -replace "~3", "" -replace "#1", "" -replace "#2", "" -replace "#3", "" -replace ":", ""
    $Matcher = get-Matcher -str $Matcher
    [String[]] $ResArray = @()
    $ResArray = $Global:ShortPathTable.Keys | ? { $_ -match $Matcher }
    
    if ($ResArray.Count -ge 1) {
        if ($ResArray.Count -gt 1) {
            LogInfo -Path $Global:LogFile -Wert "ERROR" -Ausg "More than one entry for FilePath in the registry found $Path"
        }
        
        Return $Global:ShortPathTable[$ResArray[0]]
    }
    else {
        
        LogInfo -Path $Global:LogFile -Wert "ERROR" -Ausg "FilePath in registry not found $Path"
        return $null
    }
}


#######################################################################################################
#
# function : Substitute Values
#
#######################################################################################################

function get-RegStbstitution($Value,  $RegSubstitution, $line, $MatchShortpath = $false, $MultiString = $false){

	
	$match = $false
	$item=""

    #`$ is the Escape Sequence for powershell $$ ist the escape sequence für Wix! double doof!!!
    # "[\[]" (without quotes) for the open square bracket. 
    # "[\]]" (without quotes) for the ending square bracket. 
    $Value = $Value  -replace "\$\(",'$$$$(' #mybe, this can produce a wrong key!

    
    if($Value -match "(\[)|(\])"){
        $N=""
        for($i=0;$i -lt $Value.length;$i++){

              if($Value[$i] -eq "[" ){
                 $N+='[\[]'
			  } else {
              if($Value[$i] -eq "]" ){
                 $N+='[\]]'  
			  } else {
                 $N+=$Value[$i]   
			  }}
         }
        $Value = $N
	}
                    
    
    $result =$Value
    
    $break=$false
  	foreach($item in $RegSubstitution.Keys){	
		if($result -match ($item)){ #get-Matcher -str
            $result = $result -replace $item,$RegSubstitution.get_item($item)
		    $result = $result -replace "\\\\","\"
            LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg ("Replace registry value $Value with " + $RegSubstitution.get_item($item) + " in Line $line")
            
            #Das können ja nicht nur Multistrings sein!
            if (!$MultiString) {
                return $result
            }
            else {
                LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg ("match :" + $item + "->" + $RegSubstitution.get_item($item))
                $break = $true
            }
        }
    }
    
    if ($break) {
        return $result
    }
    
    #Find and Substitute Shortpath Element
    if ($MatchShortpath) {
        #New Matcher, only a shortPath with an EXE, DLL an OCX
        #"C:\PROGRA~2\MICROS#1\OFFICE11\OUTLRPC.DLL"
	    if(($Value -match "\\\w+~\d{1}\\") -and ($Value -match "([a-zA-Z]:){1}(\\.+\\)(\w+\.\w{3})")){ #"([a-zA-Z]:){1}(\\\w+|\\\w+~\d{1}|\\\w+#\d{1})+\\(\w*\.\w{3})")) { #"\w{1}:\\\w*~\d{1}.*\\\w*\.\w{3}"){
            #Get Filename and Path
            $expression = $matches[0]
            #[String[]] $PathEntrys = $expression.Split("\")
            
            $FileID = get-FileIDFromPath -Path $expression

            #$FileName = ($PathEntrys[$PathEntrys.count - 1])
            
            #$FileID=$Global:FileTable[$FileName]
            
            $expression = get-Matcher -str $expression
            LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Replace registry shortpath $Value with FileID [!$FileID] in Line $line"
            
            $result = $Value -replace $expression, "[!$FileID]"
            Write-Host "------->Value " $Value "Expression -------->" $expression "Result -------->" $result
          }
	}
	return $result
}


#=====================================================================================================
# Decode a Reglookup APPV String
#=====================================================================================================

function decode_RegLookup_Appv{
param( [String] $AppvString,
        $RegSubstitution, 
	    $line,
        $MatchShortpath = $false,
        $Multistring = $false
	)
    
    $OutString =""
    $count = $AppvString.Length
    for ($index = 0; $index -lt $count; $index++) {
      switch ($AppvString.Chars($index)) {
        '%' {
		    $conv= $AppvString.get_Chars($index+1)+$AppvString.get_Chars($index+2)
			if($conv -ne "00"){
              $OutString += [CHAR]([CONVERT]::toint16($conv,16))
            }
            $index+=2
           
            break
        }
        default {
            $OutString += $AppvString.get_Chars($index)
            break
        }
      } 

	}
	
	$OutString = get-RegStbstitution -Value $OutString -RegSubstitution $RegSubstitution -line $line -MatchShortpath $MatchShortpath -MultiString $Multistring
	return $OutString
}


#OnlyDecode
function decode-RegLockupKey {
    param (
    [String] $AppvString
    )

$OutString = ""
    $count = $AppvString.Length
    for ($index = 0; $index -lt $count; $index++) {
        switch ($AppvString.Chars($index)) {
            '%' {
                $conv = $AppvString.get_Chars($index + 1) + $AppvString.get_Chars($index + 2)
                if ($conv -ne "00") {
                    $OutString += [CHAR]([CONVERT]::toint16($conv, 16))
                }
                $index += 2
                
                break
            }
            default {
                $OutString += $AppvString.get_Chars($index)
                break
            }
        }
        
    }
    
    return $OutString
}


function XmlEncode([string]$value)
{
	$value = $value -Replace '&', '&amp;'
	$value = $value -Replace '''', '&apos;'
	$value = $value -Replace '<', '&lt;'
	$value = $value -Replace '>', '&gt;'
	
	#text.Replace("'", "&apos;");
	#text.Replace(@"""", "&quot;");
	#text.Replace("<", "&lt;");
	#text.Replace(">", "&gt;");
	return $value
}


#######################################################################################################
#
# function : Create wix registry from appv regestry.dat file

#######################################################################################################
#region RegKeys
function Create-CtxStr2msiRegKeys
{
    param (
        [xml] $tree,
        [System.Xml.XmlElement] $element,
        [String] $regFile,
        [String[]] $exclude,
        [System.Xml.XmlElement] $feature,
         $RegSubstitution
    )
	
	#2016-05-16 NameSpace
	$nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList @($tree.NameTable)
	$nsmgr.AddNamespace('ns', 'http://schemas.microsoft.com/wix/2006/wi')
	
	
	[System.Xml.XmlElement] $keyXmlElement

	 #Keys, we don't need!
	 $exclude_Keys = @("//RuleFile","PATH","/","/REGISTRY","/REGISTRY/MACHINE","/REGISTRY/MACHINE/SOFTWARE","/REGISTRY/MACHINE/SYSTEM","/REGISTRY/USER",
                       "/REGISTRY/USER/S-1-5-19","/REGISTRY/USER/CurrentUser","/REGISTRY/USER/CurrentUser_Classes","/REGISTRY/MACHINE/software/_ow6432node")
	  
	  
	 # CreateReglook File
	 # supress warnings ....
	 if( test-path  "$GLOBAL:LogPath\regout.txt") {Remove-Item -Path "$GLOBAL:LogPath\regout.txt" -Force}
	
	 LogInfo -Path $LogFile -Wert "INFO" -Ausg "Using reglookup! http://projects.sentinelchicken.org/reglookup/"
	 LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Create regdump with reglookup.exe. Please wait..."

	$job=Start-Job -ScriptBlock {param($rootDir, $regFile, $LogPath)
	 & "$rootDir\tool\reglookup\reglookup.exe" "$regFile"  | Add-content ("$LogPath"+"Regout.txt")
	 } -ArgumentList $rootDir,$regFile,$LogPath | Wait-Job

	 #No output of warnings
	 #Can't get a String!
	 #Receive-Job -Job $job
	  
	 #ReadReglook File and analyse it
	 [array] $regFile = Get-Content ("$LogPath"+"Regout.txt")
    
	 
	#Progressbar
	 if($progressbaroverlay1){
	   $progressbaroverlay1.Maximum = $regFile.count
       $progressbaroverlay1.Style = "Block"
       $progressbaroverlay1.Value = 0
	   $progressbaroverlay1.Step = 1
	   $progressbaroverlay1.TextOverlay = "Processing Registry..."
	 }
	                      
     $Component = CreateWixComponent -tree $tree -element $tree.Wix.Product.Directory -Component "RegKeys" -Path ""
	 
	
	$LineNo=0
	foreach($line in $regFile) { 
        
    if($progressbaroverlay1){
	   $progressbaroverlay1.PerformStep() 	
	   [System.Windows.Forms.Application]::DoEvents() 
	}
		
	 $regKey = $line.split(",")
	 
	 #Exlude Hives
	 #Nun die ganze Line!
	 if ( $exclude | Where {$line -match $_}) { continue }	
	 #Exclude Keys
	 if ( $exclude_Keys | Where {($regKey[0]) -match ("^"+$_+"$")}) { continue }

	 #decodeKey
	 $keyElem = $regKey[0].split("/")
		
		#findKey
		$RegHive = $null
		$NewKey = $Null
		$xelement = $Null
		if ($regKey[0] -match ("^/REGISTRY/MACHINE/"))
		{
			$RegHive = "HKLM"
		}
		else
		{
			if ($regKey[0] -match ("^/REGISTRY/USER/"))
			{
				$RegHive = "HKCU"
			}
			else
			{
				Write-Debug "UnknownKey "	$regKey[0]
				LogInfo -Path $LogFile -Wert "ERROR" -Ausg "Unprocessed reg hive $regKey[0]  $regKey[1]"
				break
				
			} #Abbruch, ungültiger Schlüssel
		}
		
		
		[String] $NewKey = CreateWixStringfromReglookup -str (decode-RegLockupKey -AppvString ($regKey[0]))
		#$xelement = $tree.SelectSingleNode('//ns:RegistryKey[@Key="Software\Classes" and @Root="HKLM"]', $nsmgr)
		
		if ($NewKey -match '\{84894428-B1F9-4C88-8A45-D6B8524E53B3\}\\ToolboxBitmap32')
		{
			#Write-Host Match
		}
		
		
		if (($NewKey.Length -ge 1) -and ($NewKey.Chars($NewKey.Length -1) -eq '\'))
		{
			$NewKey = $NewKey.Substring(0, $NewKey.Length -1) 
		}
		
		$NewKey = $NewKey.ToLower()
		
		[String]$Searchstring = '//ns:RegistryKey[@Root=''' + $(XmlEncode -value $RegHive) + ''' and @Key=''' + $(XmlEncode($NewKey)) + ''']'
		$xelement = $tree.SelectSingleNode($Searchstring, $nsmgr)
		
		#$name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count - 1]) -RegSubstitution $RegSubstitution -line $LineNo
		
		
		switch ($($regKey[1])) {
			{ $_ -match ("^KEY$") } {
				#Search for The Key
				if ($xelement -eq $null) #Create a Key
				{
					$keyXmlElement = CreateWixRegKey -tree $tree -element $Component -Hive $RegHive -Key $NewKey
				}
				else
				{
					#Key exist, get node
					#LogInfo -Path $LogFile -Wert "INFOINFO" -Ausg "Key Exist $regKey[0]  $regKey[1]"
					#Key exist
					#LogInfo -Path $LogFile -Wert "INFOINFO" -Ausg "Search4Key $regKey[0] $Searchstring "
					$keyXmlElement 	= $xelement
				}
				
				
#				if ($regKey[0] -match ("^/REGISTRY/MACHINE/"))
#				{
#					
#					
#	         $keyXmlElement = CreateWixRegKey -tree $tree -element $Component -Hive "HKLM" -Key (CreateWixStringfromReglookup -str (decode-RegLockupKey -AppvString ($regKey[0]))) #11.05.2014 war nur der Key, ergänzt (decode-RegLockupKey -AppvString ($regKey[0]))
#				}
#				else
#				{
#					if ($regKey[0] -match ("^/REGISTRY/USER/"))
#					{
#						
#	         $keyXmlElement = CreateWixRegKey -tree $tree -element $Component -Hive "HKCU" -Key (CreateWixStringfromReglookup -str (decode-RegLockupKey -AppvString ($regKey[0]))) #11.05.2014 war nur der Key, ergänzt (decode-RegLockupKey -AppvString ($regKey[0]))
#					}
#					else
#					{
#						#Unknown
#						
#		     LogInfo -Path $LogFile -Wert "ERROR" -Ausg "Unprocessed reg hive $regKey[0]  $regKey[1]"			
#		     }			
#	       }  			
		break		
		}
		{$_ -match ("^SZ$")} {
	       	#!!! Name empty = reg standard entry 
	       	$val = decode_RegLookup_Appv -AppvString $($regKey[2]) -RegSubstitution $RegSubstitution -line $LineNo -MatchShortpath $true	
	       	$name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count-1]) -RegSubstitution $RegSubstitution -line $LineNo
				
				if ($name -eq  "")#Default Key

				{
					#if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Value=''' + $val + ''' and (not (@Name))]', $nsmgr) -ne $null)
					
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[not (@Name)]', $nsmgr) -ne $null)
					
					{
						break
					}
					
				}
				else
				{
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Name='''+$( XmlEncode($name)) +''' and @Value=''' + $(XmlEncode($val)) + ''']', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				
				CreateWixRegValue -tree $tree -element $keyXmlElement -name $name -Value $val -Type "string" | Out-Null
				
				
		break		
		}
            
            { $_ -match ("^MULTI_SZ") } {
                #Write-Host "----------->" $($regKey[2])
                $val = $($regKey[2])
                if ($val  -match "C:\\Program Files \(x86\)\\Common Files") {
                    Write-Host "Match"
                }
                
                
                $multi = decode_RegLookup_Appv -AppvString $($regKey[2]) -RegSubstitution $RegSubstitution -line $LineNo -Multistring $true
                $name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count - 1]) -RegSubstitution $RegSubstitution -line $LineNo

                
           		[String []] $val = $multi.split("|")
                CreateWixRegMultiValue -tree $tree -element $keyXmlElement -name $name -Values $val  | Out-Null	
		break
		}
			
		{$_ -match ("^EXPAND_SZ")} { 
	       $val = decode_RegLookup_Appv -AppvString $($regKey[2]) -RegSubstitution $RegSubstitution -line $LineNo	
	       $name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count-1]) -RegSubstitution $RegSubstitution -line $LineNo
				
				#Search, Value exist
				if ($name -eq "") #Default Key
				{
					#if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Value=''' + $val + ''' and (not (@Name))]', $nsmgr) -ne $null)
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[not (@Name)]', $nsmgr) -ne $null)
					
					{
						break
					}
					
				}
				else
				{
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Name=''' + $(XmlEncode($name)) + ''' and @Value=''' + $(XmlEncode($val)) + ''']', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				
                
                CreateWixRegValue -tree $tree -element $keyXmlElement -name $name -Value $val  -Type "expandable" | Out-Null			
		break
		}

		{$_ -match ("^BINARY")} {
				
			$val = decode_RegLookup_Binary($($regKey[2]))	
	        $name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count-1]) -RegSubstitution $RegSubstitution -line $LineNo
				
				#Search, value exist
				if ($name -eq "") #Default Key
				{
					#if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Value=''' + $val + ''' and (not (@Name))]', $nsmgr) -ne $null)
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[not (@Name)]', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				else
				{
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Name=''' + $(XmlEncode($name)) + ''' and @Value=''' + $(XmlEncode($val)) + ''']', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				
            CreateWixRegValue -tree $tree -element $keyXmlElement -name $name -Value $val  -Type "binary" | Out-Null				
		break
		}
		{$_ -match ("^DWORD")} {
			$val = [convert]::ToInt32($($regKey[2]),16)
	        $name = decode_RegLookup_Appv -AppvString $($keyElem[$keyElem.count-1]) -RegSubstitution $RegSubstitution -line $LineNo
				
				if ($name -eq "") #Default Key
				{
					#if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Value=''' + $val + ''' and (not (@Name))]', $nsmgr) -ne $null)
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[not (@Name)]', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				else
				{
					if ($keyXmlElement.SelectSingleNode('//ns:RegistryValue[@Name=''' + $( XmlEncode($name)) + ''' and @Value=''' + $( XmlEncode( $val)) + ''']', $nsmgr) -ne $null)
					{
						break
					}
					
				}
				
				CreateWixRegValue -tree $tree -element $keyXmlElement -name $name -Value $val  -Type "integer" | Out-Null					
		break
		}
		default {
			LogInfo -Path $LogFile -Wert "IMPORTANT INFO:" -Ausg "Key $regKey[0] with name ""$($keyElem[$keyElem.count-1])"" and Value ""$($regKey[2])"" in not in the msi"
		}
	  }	
		
	$LineNo++	
   }
   AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
}


#endregion

#Create Active Setup Registry entries
function create-WixActionSetup( [xml] $tree, [System.Xml.XmlElement] $element,  [System.Xml.XmlElement] $feature){

	#if($Projectfile.CtxStr2msi.AppActiveSetup -eq "True"){
        LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Create ActiveSetup keys..."	
		$Component = CreateWixComponent -tree $msixml -element $element -Component "AvtiveSetup" -Path ""
		$keyXmlElement = CreateWixRegKey -tree $tree -element $Component -Hive "HKLM"  -Key "SOFTWARE\Microsoft\Active Setup\Installed Components\[PackageCode]"
		CreateWixRegValueKeyPath -tree $tree -element $keyXmlElement -name "StubPath" -Type "string" -Value "msiexec /fup [ProductCode] /qb-!"  
		CreateWixRegValue -tree $tree -element $keyXmlElement -Name "[ProductName] [ProductVerion] Configuration" -Type "string" -Value "[ProductName]" 
	    CreateWixRegValue -tree $tree -element $keyXmlElement -Name "Version" -Type "string" -Value "[ProductVerion]" 
		 AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
	#}
}

function CreateWiXFeature ([xml] $tree, [System.Xml.XmlElement] $element, [STRING] $Title){
  
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Feature",$eNS)
  $e.SetAttribute("Id","MainApplication")
  $e.SetAttribute("Title", $Title)
  $e.SetAttribute("Level", "1")
  $element = $element.AppendChild($e)
  Return $element
}

function AddWiXFeature ([xml] $tree, [System.Xml.XmlElement] $element, [STRING] $Id){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("ComponentRef",$eNS)
  $e.SetAttribute("Id", $Id)
  $element = $element.AppendChild($e)
  Return $element
}


function Create-WixXmlFromSpecialDir{
	Param(
	[xml] $tree, 
	[System.Xml.XmlElement] $element, 
	$path = $pwd, 
	[string[]]$exclude ,
     $specialFolder,
        [System.Xml.XmlElement] $feature,
    [String] $BasePath
	)
	
	#################################
	# Root Dir has files? 
	# Das wird aktuell im Hauptprogramm nicht ber�cksichtigt!
	#################################
    if(NoFilesTest "$path"){
	  $Co = CreateWixComponent -tree $tree -element $element -Component "MainAppRoot" -Path "$path"	
	  AddWiXFeature  -tree $tree -element $feature -Id $Co.id
	  
	  foreach ($File in Get-ChildItem "$path"){
	    if ($exclude | Where {$File.FullName -match $_}) { continue }
			
        if (!(Test-Path $File.FullName -PathType Container)){
                CreateWixFile -tree $tree -element $Co -File $File.name "$path\$File" -BasePath $BasePath | Out-Null
        }
      }
	} 
	
	Create-WixSpecialFileFolderStructure -tree $tree -element $element -path $path -exclude $exclude -specialFolder $specialFolder -feature $feature -BasePath $BasePath
}	


function Create-WixSpecialFileFolderStructure([xml] $tree, [System.Xml.XmlElement] $element, $path = $pwd, [string[]]$exclude,  $specialFolder, [System.Xml.XmlElement] $feature, [String] $BasePath)
{ 
    foreach ($item in Get-ChildItem $path)
    {
		
        if ($exclude | Where {$item.FullName -match $_}) { continue }

        if (Test-Path $item.FullName -PathType Container) 
        {
			
			#Special Folders
			$break = $false

			foreach($key in $specialFolder.Keys) {
			 if ($item.FullName -match $key) { 
			   $Element1 = $null
			   $Element1 = $tree.SelectSingleNode("/*/*/*/*[@Id="""+($specialFolder[$key])+"""]")	  	
			   #Create, if special entry not exist!		
			   if(!$Element1){
			      $Element1 = CreateWixVfsDirectory -tree $msixml -element $msixml.Wix.product.Directory -Folder $specialFolder[$key] -Name $specialFolder[$key]   
			   }
	           Create-WixXmlFromSpecialDir -tree $msixml -element $Element1 -path $item.FullName  -exclude $exclude -specialFolder $specialFolder -feature $Feature -BasePath $BasePath
			   $break=$true	
			   continue	
			 }
			}
		     
		    if($break){continue}
		    
			$newElement = CreateWixDirectory -tree $tree -element $element -Folder $item.PSChildName -Name $item.PSChildName -Path $item.FullName
			
			#Create Componet
			if(NoFilesTest $item.FullName){
			  $Component = CreateWixComponent -tree $tree -element $newElement -Component $item.PSChildName -Path $item.FullName
			  AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
				   
			  if($RemoveDirList | where {$item.FullName -match $_}){
				 CreateWixRemoveFolder -tree $tree -element $Component -ID $newElement.Id -MainPath $path -ComponentName $item.FullName
			  }
			   #Create Files
			   #	
                CreateWixDir -tree $tree -element $Component -exclude $exclude -path $item.FullName [String] $BasePath
			} 
			else{
		      #Empty Directory
		      #Is Directory in USERPROFILE?

		      if($RemoveDirList | where {$item.FullName -match $_}){

			    #Create Component for Directory
				$Component = CreateWixComponent -tree $tree -element $newElement -Component $item.PSChildName -Path $item.FullName
			    AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
				CreateWixRemoveFolder -tree $tree -element $Component -ID $newElement.Id -MainPath $path -ComponentName $item.FullName
			  }
		    }
			
            Create-WixSpecialFileFolderStructure -tree $tree -element $newElement  -path $item.FullName -exclude $exclude -feature $feature -BasePath $BasePath
			$newElement = $newElement.get_ParentNode()
			
        } 
    } 
} 





#=====================================================================================================
#
# Create the Msi for Citrix Streaming
#
#=====================================================================================================

function Generate-CtxStrMSIXml{
param( [xml] $Projectfile 
     )

    if($progressbaroverlay1){
       $progressbaroverlay1.Style = "Block"
       $progressbaroverlay1.Value = 0
	}

	$ProjectPath = $Projectfile.CtxStr2msi.ProjectRoot 
	$Global:LogPath = "$ProjectPath\Logs\"
	$Global:LogFile = "$ProjectPath\Logs\CtxStr2XML.log"
    
    $Global:FileTable = @{} #Store every file for Comparsion
    $Global:ShortPathTable = @{ } #Store every file for Comparsion
	
    if(Test-Path -Path "$ProjectPath\Logs"){
        Remove-Item -Path "$ProjectPath\Logs" -Force -Recurse | Out-Null
    }
	
	New-Item -ItemType directory -Path "$ProjectPath\Logs" -Force | Out-Null	
	$CtxStrsourceFiles = $Projectfile.CtxStr2msi.CtxStrDevicePath
	
	$Ctxstr2msiFile = $Projectfile.CtxStr2msi.CtxStrSourcefile
	
	$CtxStrPackagename = $Projectfile.CtxStr2msi.CtxStrPackagename
	$CtxStrProductcode = $Projectfile.CtxStr2msi.CtxStrProductcode 
	$CtxStrUpgradecode = $Projectfile.CtxStr2msi.CtxStrUpgradecode 
	$CtxStrVersion = $Projectfile.CtxStr2msi.CtxStrVersion 
	$CtxStrManufacturer = $Projectfile.CtxStr2msi.CtxStrManufacturer
	$CtxStrDisplayName = $Projectfile.CtxStr2msi.CtxStrDisplayName
	$CtxStrInstallDir = $Projectfile.CtxStr2msi.CtxStrInstallDir
    $Applicationname = "$CtxStrDisplayName"
	$CtxStrInstallRootDir = $Projectfile.CtxStr2msi.CtxStrInstallRootDir #Application main Directory
	$CtxStrPath = $Projectfile.CtxStr2msi.CtxStrPath
	$CtxStrLanguage = $Projectfile.CtxStr2msi.CtxStrLanguage
    
    #Set Language - only German and English
    $Language = if(($Projectfile.CtxStr2msi.CtxStrLanguage) -eq "de,1031") {"1031"} else {"1033"}
	
	#Plattform
	if ($Global:Projectxml.CtxStr2msi.CtxStrApp64Bit -eq "True"){
		$Global:Platform = "x64"
	}

	#Dialogs
    if ($Global:Projectxml.CtxStr2msi.CtxStrAppMsiDialogs -eq "True") {
        $Global:CreateMsiDialogs = "True"
    }
    else {
        $Global:CreateMsiDialogs = "False"
    }
    
    $Global:CreateMsiDialog
	
	if(($Projectfile.CtxStr2msi.CtxStrHashGuid) -eq "True"){
	  $Global:UseRandomGUIDS = $True
	}
	
	#Delete old log
	if(test-path $Global:LogFile) { Remove-Item -Path $LogFile -Force}
	
    
    #-------------------------------------------------------------
    # Read exclusion and supstitution tables
    # 
    #-------------------------------------------------------------
    
	
	$DirExclusion = @()
    $DirSubstitution = [ORDERED] @{}
    
    
	$RegExclusion = @()
    $RegSubstitution = [ORDERED] @{}
    
    
	
    #Create Directorys exclusion Table
	$temp = Get-XmlTableMatrix -tree $Projectfile  -Key "CtxStr_EXCLUDE_DIR" #Directorys to exclude
	foreach($item in $temp){
	  if(($item[0]) -eq "True"){
	   $DirExclusion += ($item[1])
	  }
	}
	
	LogInfo -Path $LogFile -Wert "INFO" -Ausg "Exclude Directorys : $DirExclusion"
    
	#Create Substitution Table
	$temp = Get-XmlTableMatrix -tree $Projectfile  -Key "CtxStr_PATH_SUBST" #Directorys to exclude
	foreach($item in $temp){
	  if($item[0] -eq "True"){
	   $DirSubstitution.add($item[1],$item[2])
	   LogInfo -Path $LogFile -Wert "INFO" -Ausg ("Add directorys substitution: "+$item[1] +"->" +$item[2])
	  }
	}	
	
    # Create Registry exclusion Table
	
	$temp = Get-XmlTableMatrix -tree $Projectfile  -Key "CtxStr_EXCLUDE_REG_HIVES" #keys to exclude
	foreach($item in $temp){
	  if(($item[0]) -eq "True"){
	   $RegExclusion += ($item[1])
	   LogInfo -Path $LogFile -Wert "INFO" -Ausg ("Reg Exclustion: "+$item[1])
	  }
	}	
	#Cretae Registry Substitution
	$temp = Get-XmlTableMatrix -tree $Projectfile  -Key "CtxStr_REG_SUBST" #Directorys to exclude
	foreach($item in $temp){
	  if($item[0] -eq "True"){
	   	# Special for the Installdir!
	   	# ProgramFilesFolder - gets the well-known folder for CSIDL_PROGRAM_FILESX86. 
       	# ProgramFiles64Folder - gets the well-known folder for CSIDL_PROGRAM_FILES. 
       	# ProgramFiles6432Folder 	
		
            
        #2013-11-18 - Glaube, den Teil kann man vergessen!    
	   	if(	$item[2] -eq "[INSTALLDIRSUBROOT]"){ 
			#delete last Slath
			$temproot =	$CtxStrInstallDir
			#Write-Host "---------- InstallRoot :$CtxStrInstallDir"""
			if($CtxStrInstallDir[$CtxStrInstallDir.Lenght-1] -eq "\"){
			  $temproot = $CtxStrInstallDir.Substring(0,$CtxStrInstallDir.length-1)	
			}
			
			if($Global:Platform	-eq "x86"){
			  $item[2] = "[ProgramFilesFolder]$temproot"
			} else {
			  $item[2] = "[ProgramFiles64Folder]$temproot"	
			}
		}
	   		
	   $RegSubstitution.add($item[1],$item[2])
	   LogInfo -Path $LogFile -Wert "INFO" -Ausg ("Add registry substitution: "+$item[1] +"->" +$item[2])
	  }
	}
	
	    LogInfo -Path $LogFile -Wert "INFO" -Ausg "Create wix xml"

    #-------------------------------------------------------------
    # #Create WiX-xml 
    # 
    #-------------------------------------------------------------

 	
	$msixml = New-Object xml 
	CreateWixXml -WiXXml  $msixml -Productcode $CtxStrProductcode -UpgradeCode $CtxStrUpgradecode -Version $CtxStrVersion -Name $CtxStrDisplayName -Manufacturer $CtxStrManufacturer -Language $Language

    #Special for 64Bit!
	if($Global:Platform	-eq "x86"){
	  	CreateWixMainDirectory -tree $msixml -element $msixml.Wix.product.Directory -Folder "ProgramFilesFolder"
	} else {
	    CreateWixMainDirectory -tree $msixml -element $msixml.Wix.product.Directory -Folder "ProgramFiles64Folder"
	}
	
	#Create folder name
	[String[]] $CtxStrRootPath = $CtxStrInstallDir.split("\")
	$CtxStrRootPath = $CtxStrRootPath | where {$_ -ne ""}
	if(($CtxStrRootPath.count) -eq 0){
		$CtxStrRootPath.add("my-nick-it-application")
	}
	
	CreateWixMainDirectory -tree $msixml -element $msixml.Wix.product.Directory.Directory -Folder "APPLICATIONROOTDIRECTORY"
    Write-Host "PATH ROOT:" $CtxStrRootPath[0]
    #break
    
    $msixml.Wix.product.Directory.Directory.Directory.SetAttribute("Name", $CtxStrRootPath[0])
	$Feature = CreateWiXFeature -tree $msixml -element $msixml.Wix.product "Main Application"
    
	#
	#Create Application Folders
	#
	$element = $msixml.Wix.product.Directory.Directory.Directory
    $applicationrootelement = $element

	for($v=1; $v -lt $CtxStrRootPath.count ;$v++){
      $element = CreateWixDirectory -tree $msixml -element $element -Folder ($CtxStrRootPath[$v]) -Name ($CtxStrRootPath[$v]) -Path ($CtxStrRootPath[$v]) 
	}
	
	
    LogInfo -Path $LogFile -Wert "INFO" -Ausg "Process streaming Device directory"
    Create-WixXmlFromSpecialDir -tree $msixml -element $element -path "$CtxStrInstallRootDir" -exclude $DirExclusion -feature $Feature -specialFolder @{ } -BasePath $CtxStrsourceFiles
	
	#Exclude Main Directory for Special Folders
	$MainExclude = $CtxStrInstallRootDir -replace (get-matcher -str $CtxStrsourceFiles ),""
	$MainExclude = "\\"+(get-Matcher -str $MainExclude )
	$DirExclusion += $MainExclude
    
    Create-WixXmlFromSpecialDir -tree $msixml -element $msixml.Wix.product.Directory -path ("$CtxStrsourceFiles" + "Device\C") -exclude $DirExclusion -specialFolder $DirSubstitution -feature $Feature -BasePath $CtxStrsourceFiles

    
	#Special for Fonts
    LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Process the fonts..."	
    
    $Element1 = $msixml.SelectSingleNode("/*/*/*/*[@Id=""FontsFolder""]")	  	
	  #Create, if special entry not exist!		
	    if($Element1){
		  foreach($Filenode in $Element1.Component.File){
		    $Filenode.SetAttribute("TrueType","yes")
		  }
		
	}

    #-------------------------------------------------------------
    # Create Registry Keys       
	#
	# ToDo: Need to be seperatet HKLM and HKCU!
	#-------------------------------------------------------------
    # Main registry substitutin
    
    $CtxStrInstallRootDir -match "^.*\\Device\\"
    $expression = get-Matcher -str $matches[0] 
    $RootSubst = $CtxStrInstallRootDir -replace $expression,""
    $RootSubst = $RootSubst -replace "c\\", "c:\" -replace "\\", "\\" -replace "\(", "\(" -replace "\)", "\)"
    #2014 - 04 - 26#09-55-50 : INFO  Process the fonts...
    #Value: [ProgramFilesFolder]\CorelDRAW Graphics Suite X5\
    #RootSubt: c:\\program files \(x86\)\\corel
    #Must be "[ProgramFilesFolder]\CorelDRAW Graphics Suite X5"
    $tempstr = $CtxStrInstallDir -replace "^\\","" -replace "\\$",""
    
    $val = "[ProgramFilesFolder]$tempstr\"
    $val = $val -replace "\\\\","\"
    
    
    #This entry has to be the first entry!
    
    $tempregSubst = [ORDERED] @{ }
    
    $tempregSubst.Add(($RootSubst + "\\"), $val)
    
    foreach($key in $RegSubstitution.keys){
        $tempregSubst.Add($key, ($RegSubstitution[$key]))
    }
    
    $RegSubstitution = $null
    $RegSubstitution = $tempregSubst
    
    #foreach ($item in $RegSubstitution.Keys) {
    #    Write-Host "Item: " $item "Key" $RegSubstitution.Values[$item]
    #}
    
    
    #Write-Host "Value :" $val
    #Write-Host "RootSubt :" $RootSubst
    #break
    
    
    LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Processing registry Please wait..."	
    Create-CtxStr2msiRegKeys -tree $msixml  -element $msixml.Wix.product.Directory -RegFile ("$CtxStrsourceFiles"+"InstallRoot.dat") -exclude $RegExclusion -featur  $Feature -RegSubstitution $RegSubstitution
	

    #-------------------------------------------------------------
    # Create Shortcuts
    # First install the Icon Files
    #-------------------------------------------------------------
    
    $Iconlement = CreateWixDirectory -tree $msixml -element $element -Folder "Icons" -Name "Icons" -Path "Icons"
    $iconpath = $Projectfile.CtxStr2msi.ProjectRoot+"\icons"
    #Write-Host "-------->"$iconpath
    Create-WixXmlFromSpecialDir -tree $msixml -element $Iconlement -path $iconpath -exclude $DirExclusion -specialFolder $DirSubstitution -feature $Feature -BasePath $CtxStrsourceFiles
    #
    # detect foldername for the Application Shortcuts
    #
    $elem = $CtxStrInstallDir.split("\")
    $elem=$elem | where {$_ -ne ""}
    if($elem -ne $null){
        If( $elem.GetType().Name -eq "String"){$StartFoldername = $elem} 
        else {
            if($elem.count -gt 1){
                $StartFoldername =  ($elem[$elem.count-1])
            } else {
                $StartFoldername = ($elem[0])
	        }
        }
    } else {
        $StartFoldername = "NIT-Applicationfolder"
    }

    #Write-Host "--> InstallDir" $CtxStrInstallDir "Elem[1]" $elem[1]
    
    
    $newElement = CreateWixDirectoryOhneGuid -tree $msixml -element $applicationrootelement -Folder "ProgramMenuFolder" -Name "ProgramMenuFolder" -Path "Startmenue"
	#$newElement2 = CreateWixDirectory -tree $msixml -element $newElement -Folder $StartFoldername -Name $StartFoldername -Path $StartFoldername
    #The "New" is for generating a "new" ID!
    $newElement2 = CreateWixDirectory -tree $msixml -element $newElement -Folder  ("new"+$StartFoldername) -Name  $StartFoldername -Path $StartFoldername
	$Component = CreateWixComponent -tree  $msixml -element $newElement2 -Component "ApplicationShortcut" -Path "ApplicationShortcut"

    $temp = Get-XmlTableMatrix -tree $Projectfile  -Key "CtxStr_Shortcuts" 
	foreach($item in $temp){
	  if(($item[0]) -eq "True"){
	   LogInfo -Path $LogFile -Wert "INFO" -Ausg ("Create Start Menu Shortcut for: "+$item[1])
       
       #Match and substitute Working Directory     
       $WorkingDirectory = $item[4]
       if($item[4] -ne ""){ 
         #Todo : eigentlich hier das korrekte Verzeichnis identifizieren!       
         #       Dazu deine ID Generieren oder gleich einen Wert in die Verknüpfungtabelle eintragen      
         $file =  $FileTable[(Split-Path ($item[3]) -Leaf)]    
         $xPath = "//*[@Id='"+$file+"']" 
         #Write-Host "----------------------->" $xPath       
         $node = $msixml.SelectSingleNode($xPath) 
         $WorkingDirectory = $node.ParentNode.ParentNode.Id
	   }
            
       create-WixStartMenuShortcut -tree $msixml -element $newElement2 -Component $Component -appname $item[1] -Description $item[1] -Target ("[#"+$FileTable[(Split-Path ($item[3]) -Leaf)]+"]") -WorkingDir $WorkingDirectory
	  }
	}	
    CreateWixRemoveFolder -tree $msixml -element $Component -ID $Component.id -ComponentName "ApplicationShortcut_$appname" -MainPath "ApplicationShortcut_$appname"


    AddWiXFeature -tree $msixml -id $Component.id -element $feature 

    

    
	
    #-------------------------------------------------------------
	#
	# Create Active Setup Entries
	#
    #-------------------------------------------------------------
    if($Projectfile.CtxStr2msi.AppActiveSetup -eq "True"){
        create-WixActionSetup -tree $msixml  -element $msixml.Wix.product.Directory -featur  $Feature
	}

    
    
 	$msixml.Save("$LogPath\$CtxStrPackagename.xml")
	LogInfo -Path $Global:LogFile -Wert "INFO" -Ausg "Wix ist creating the msi. Please wait..."	
        
        
    #Progressbar
	 if($progressbaroverlay1){
	   $progressbaroverlay1.Style = "Marquee"
	   $progressbaroverlay1.TextOverlay = "Creating the msi..."
	 }

    #-------------------------------------------------------------
	#
	# Generate the msi from the wix.xml	
	#
    #-------------------------------------------------------------

	[String] $candle = "$rootDir\wixbin\candle.exe"
    [Array] $arguments = "-out", """$LogPath$CtxStrPackagename.wixobj""" , """$LogPath$CtxStrPackagename.xml""" 
	if(test-path "$LogPath$CtxStrPackagename.candle.log"){remove-item "$LogPath$CtxStrPackagename.candle.log" -force}
	& $candle $arguments | Out-File "$LogPath$CtxStrPackagename.candle.log"
        
    #Create the msi
    LogInfo -Path $LogFile -Wert "INFO" -Ausg "build MSI"
	if(Test-Path "$ProjectPath\$CtxStrPackagename.msi") {Remove-Item -Path "$ProjectPath\$CtxStrPackagename.msi" } 
    if(test-path "$LogPath$CtxStrPackagename.msi.log"){remove-item "$CtxStrPackagename.msi.log" -force}

    $ScriptblockLight = {    
        param(
          [String] $rootDir,
          [String] $LogPath,
          [String] $CtxStrPackagename,
          [String] $ProjectPath
        )
        [String] $light = "$rootDir\wixbin\light.exe"
        [Array] $arguments = """$LogPath$CtxStrPackagename.wixobj""","-sice:ICE91","-sice:ICE03","-sice:ICE60","-ext","WixUIExtension","-ext","WixUtilExtension","-out", """$ProjectPath\$CtxStrPackagename.msi""" 
	    & $light $arguments | Out-File "$LogPath$CtxStrPackagename.msi.log"
	}

    $job = Start-Job -scriptblock $ScriptblockLight -ArgumentList "$rootDir", "$LogPath","$CtxStrPackagename","$ProjectPath" 
    
    while($job.state -ne "Completed"){
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50  
	}
    
    Stop-Job $job
    Receive-Job $job
	
    [System.Reflection.Assembly]::LoadWithPartialName("System.web")
	$htmlPath=  [System.Web.HttpUtility]::UrlPathEncode($ProjectPath)
	LogInfo -Path $LogFile -Wert "INFO" -Ausg "Finished msi creation. You can find the msi in the project folder or show the logs if nothing is created"
    LogInfo -Path $LogFile -Wert "INFO" -Ausg "You can find the Result in the folder file:////$htmlPath"
    
    
    
    if($progressbaroverlay1){
	   $progressbaroverlay1.Style = "Block"
	   $progressbaroverlay1.TextOverlay = "Finished MSI Creation"
	}
    
    #-------------------------------------------------------------
	#
	# Build App-V
	#
    #-------------------------------------------------------------
    
    if($Projectfile.CtxStr2msi.CtxStrCreateAppV -eq "True"){
        
        LogInfo -Path $LogFile -Wert "INFO" -Ausg "Creating App-V 5 files"
      	
        if($progressbaroverlay1){
	        $progressbaroverlay1.Style = "Marquee"
	        $progressbaroverlay1.TextOverlay = "Creating App-V File"
		}
        
        #Create App-V Directory
        if(Test-Path "$ProjectPath\$CtxStrPackagename-appv"){ Remove-Item -Path "$ProjectPath\$CtxStrPackagename-appv" -Force -Recurse}
        Start-Sleep -Seconds 1
        New-Item "$ProjectPath\$CtxStrPackagename-appv" -Type directory -Force
        $scriptBlock = {
            param (
                [string] $Name,
                [String] $OutputPath,
                [String] $Installer,
                [String] $PrimaryVirtualApplicationDirectory,
                [Boolean] $FullLoad = $false,
                [Boolean] $Template = $false,
                [String] $TemplatePath = ""
            )
            
            Import-Module AppVSequencer
            if ($FullLoad -and $Template) {
                New-AppvSequencerPackage -Name "$Name" -OutputPath "$OutputPath" -Installer "$Installer" -PrimaryVirtualApplicationDirectory "$PrimaryVirtualApplicationDirectory" -FullLoad -TemplateFilePath "$TemplatePath"
            }
            else {
                if ($FullLoad -and (!$Template)) {
                    New-AppvSequencerPackage -Name "$Name" -OutputPath "$OutputPath" -Installer "$Installer" -PrimaryVirtualApplicationDirectory "$PrimaryVirtualApplicationDirectory" -FullLoad
                }
                else {
                    if ((!$FullLoad) -and $Template) {
                        New-AppvSequencerPackage -Name "$Name" -OutputPath "$OutputPath" -Installer "$Installer" -PrimaryVirtualApplicationDirectory "$PrimaryVirtualApplicationDirectory" -TemplateFilePath "$TemplatePath"
                    }
                    else {
                        New-AppvSequencerPackage -Name "$Name" -OutputPath "$OutputPath" -Installer "$Installer" -PrimaryVirtualApplicationDirectory "$PrimaryVirtualApplicationDirectory"
                    }
                }
                
            }
            #
            #Deinstall from app-v installed Msi
            #
            if(Test-Path "$Installer"){
                [String] $msiexec = "$env:SystemRoot\system32\msiexec.exe"
                [Array] $arguments = "/X","""$Installer""","/qb"
	            & $msiexec $arguments 
			}
            
		}
        #$CtxStrRootPath #Nick-it\.....
        #Detect Sequenceing Plattform!
        $PrimVirtAppDir = "C:\Program Files"
        
        if ([System.IntPtr]::Size -eq 4) { "32" } else { 
            if($Projectfile.CtxStr2msi.CtxStrApp64Bit -ne "True"){
                $PrimVirtAppDir = "C:\Program Files (x86)"        
		    }
        }
        
        #App-V Accept only two Directorys after the Root!
        [String []]$tmp = $CtxStrInstallDir.split("\")
        $tmp = $tmp | where {$_ -ne ""}
        if($tmp.count -gt 1){
            $CtxStrInstallDir = $tmp[0] #($tmp[0])+"\"+($tmp[1])
		}
        
        
        $PrimVirtAppDir +="\$CtxStrInstallDir"
        $PrimVirtAppDir = $PrimVirtAppDir -replace "\\\\","\" -replace "\\$",""
        
        $TemplatePath = $Projectfile.CtxStr2msi.AppVTemplatePath
        
        LogInfo -Path $LogFile -Wert "INFO" -Ausg "App-V 5 creation. Please wait. This can take a long time...."
        LogInfo -Path $LogFile -Wert "INFO" -Ausg ("Parameter: "+"$CtxStrPackagename "+" $ProjectPath\$CtxStrPackagename-appv"+" $ProjectPath\$CtxStrPackagename.msi"+" $PrimVirtAppDir"+ ($Projectfile.CtxStr2msi.FullLoad -eq "True")+ ($Projectfile.CtxStr2msi.AppVTemplate -eq "True")+ " $TemplatePath")
        $job = Start-Job -scriptblock $scriptBlock -ArgumentList "$CtxStrPackagename", "$ProjectPath\$CtxStrPackagename-appv", "$ProjectPath\$CtxStrPackagename.msi", "$PrimVirtAppDir", ($Projectfile.CtxStr2msi.FullLoad -eq "True"), ($Projectfile.CtxStr2msi.AppVTemplate -eq "True"), "$TemplatePath"
        
        while($job.state -ne "Completed"){
          [System.Windows.Forms.Application]::DoEvents()
          Start-Sleep -Milliseconds 50  
	    }
        Stop-Job $job
        Receive-Job $job 2> "$LogPath\AppV.log"
        if($progressbaroverlay1){
	        $progressbaroverlay1.Style = "Block"
	        $progressbaroverlay1.TextOverlay = "Finished App-V Creation"
	    }
	    LogInfo -Path $LogFile -Wert "INFO" -Ausg "Finished App-V 5 creation. You can find the Files in the project folder or show the logs if nothing is created"
        LogInfo -Path $LogFile -Wert "INFO" -Ausg "You can find the Result in the folder file:////$htmlPath"
	}
}
