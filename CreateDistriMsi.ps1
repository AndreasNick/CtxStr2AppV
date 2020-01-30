#=====================================================================================================
#
# App-V 5 zu Msi Converter
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
# Create the msi distribution
#
#=====================================================================================================

clear

#Libaries
[System.Reflection.Assembly]::LoadWithPartialName("System.web")


# Variables & constants 

#Komisch, der baut hier einen"." mit ein!
$rootDir = Split-Path -Path $MyInvocation.MyCommand.Definition


$Global:UserRandomGUIDS = $false
$Global:LogPath =""
$Global:LogFile =""
#=====================================================================================================

	   
			   
#Table Profile directory for Personal Data
#This contet get a removeDirectory Entry!
#Eintrag in der Registrierung!!!
$RemoveDirList = @("\\Profile\\","\\LocalAppDataLow\\","\\AppData\\","\\DesktopFolder\\","\\Common%20AppData\\") #put "All" here

#Hier ein Reg EIntrag unter HKLM!
$RemoveDirListHKLM = @("\\Common%20AppData\\") #,"\\AppData\\") #Generate Keys in for HKLM

#$appvfile = "C:\Users\admin\Desktop\AppV2MSI\IGELUMS401500a.appv"
#$appvSourcefiles = "AppVSourceFiles"
#RegKeys - Parameter!

$Applicationname = ""

# MSI Format ###########################################################################################
$InstallerVersion = "300"
$Compressed="yes"
$Cabinet="Install.cab"
$EmbedCab="yes"
#######################################################################################################


#=====================================================================================================
# #Generate Guid from a String
#=====================================================================================================

function ToGuid([string] $src)
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
function GetGuid([String] $src){
  if($src -eq ""){
    return [String]([System.Guid]::NewGuid()).ToString()
  } else {
    return toGuid($src)
  }
}


#=====================================================================================================
# Create a Bundle Chain Entry
#=====================================================================================================
function Create-WixBundleChain{ 
    Param (
        [xml] $tree, 
        [System.Xml.XmlElement] $element
    )
    
    $eNS = $tree.DocumentElement.NamespaceURI
    $e = $tree.CreateElement("Chain",$eNS)
    $root= $element.AppendChild($e)
    return $root
}

#=====================================================================================================
# Create a Bundle MSU Entry
#=====================================================================================================
function Create-WixBundleChainMSU{ 
    Param (
        [xml] $tree, 
        [System.Xml.XmlElement] $element,
        [String] $Source,
        [String] $KB,
        [String] $Condition
    )
    
    $eNS = $tree.DocumentElement.NamespaceURI
    $e = $tree.CreateElement("MsuPackage",$eNS)
    $e.SetAttribute("SourceFile",$Source)
    $e.SetAttribute("KB",$KB)
    $e.SetAttribute("InstallCondition",$Condition)
    $root= $element.AppendChild($e)
    return $root
}


#=====================================================================================================
# Create a Bundle Entry
#=====================================================================================================
function Create-WixBundle{ 
    Param (
        [xml] $tree, 
        [System.Xml.XmlElement] $element,
        [STRING] $Name,
        [STRING] $Version, 
        [String] $Manufacturer, 
        [STRING] $Web
    )
    $eNS = $tree.DocumentElement.NamespaceURI
    $e = $tree.CreateElement("Bundle",$eNS)
    $e.SetAttribute("Name",$Name)
    $e.SetAttribute("Version",$Version)
    $e.SetAttribute("Manufacturer",$Manufacturer)
    $e.SetAttribute("UpgradeCode",[String][System.Guid]::NewGuid())
    $e.SetAttribute("HelpUrl",$Web)
    $root = $element.AppendChild($e)
    $e = $tree.CreateElement("BootstrapperApplicationRef",$eNS)
    $e.SetAttribute("Id","WixStandardBootstrapperApplication.RtfLicense")
    $root.AppendChild($e)
    return $root
}



    
    
#  <Bundle Name="$(var.MyProject.ProjectName)" Version="2.6.0.0" Manufacturer="Awesome Software (Pty) Ltd" UpgradeCode="6a77118d-c132-4454-850b-935edc287945">
#    <BootstrapperApplicationRef Id="WixStandardBootstrapperApplication.RtfLicense">
#      <bal:WixStandardBootstrapperApplication
#        LicenseFile="$(var.SolutionDir)Awesome.EULA\Awesome CE Eula.rtf"
#        SuppressOptionsUI="yes"/>
#    </BootstrapperApplicationRef>
#
#    <util:FileSearch Path="[SystemFolder]\windowscodecs.dll" Variable="windowscodecs" Result="exists" />
#
#    <Chain>
#      <!-- Windows Imaging Component-->
#      <ExePackage Cache="no" Compressed="no" PerMachine="yes" Permanent="yes" Vital="yes"
#        SourceFile="redist\wic_x86_enu.exe"
#        DownloadUrl="http://download.microsoft.com/download/f/f/1/ff178bb1-da91-48ed-89e5-478a99387d4f/wic_x86_enu.exe"
#        InstallCondition="VersionNT &lt; v5.2 AND NOT VersionNT64"
#        DetectCondition="windowscodecs"
#        InstallCommand="/quiet /norestart">
#      </ExePackage>
#    
#    </Bundle>
    

function Create-WixCondition ([xml] $tree, [System.Xml.XmlElement] $element, [String] $Condition, [String] $Message){
   #Condition for The Operating System! 
   # <Condition Message="This application is only supported on Windows Vista, Windows Server 2008, or higher.">
   #   <![CDATA[Installed OR (VersionNT >= 600)]]>
   # </Condition>
    
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Condition",$eNS)
  $e.SetAttribute("Message",$Message)
  #$e.InnerText = $Condition 
  $cdata = $tree.CreateCDataSection($Condition)
  #$parent = $xml.GetElementsByTagName("TagName")[0]
  $e.AppendChild($cdata) 
    
  $newElement=$element.AppendChild($e)
  return $newElement
}


function CreateWixXml([XML] $WiXXml, [STRING] $UpgradeCode, [STRING] $Version, [STRING] $Name, [String] $Manufacturer, [STRING] $ProductID){
  
  $decl = $WiXXml.CreateXmlDeclaration("1.0", "UTF-8", $null)
  $rootNode = $WiXXml.CreateElement("Wix","http://schemas.microsoft.com/wix/2006/wi")
  $WiXXml.InsertBefore($decl, $WiXXml.DocumentElement)
  $root=$WiXXml.AppendChild($rootNode);
  
  $eNS = $WiXXml.DocumentElement.NamespaceURI
  $e = $WiXXml.CreateElement("Product",$eNS)
  $e.SetAttribute("Id",$ProductID)
  $e.SetAttribute("UpgradeCode",$UpgradeCode)
  $e.SetAttribute("Version",$Version)
  
  #Codepage="windows-1252" #German Codepage
  $e.SetAttribute("Codepage","windows-1252") #1033 english
  $e.SetAttribute("Language","1031") #1033 english
  
  $e.SetAttribute("Name",$Name)
  $e.SetAttribute("Manufacturer",$Manufacturer)
  $root= $root.AppendChild($e)
  
  #<Package InstallerVersion="300" Compressed="yes"/>
  $e = $WiXXml.CreateElement("Package",$eNS)
  $e.SetAttribute("InstallerVersion",$InstallerVersion)
  $e.SetAttribute("Compressed",$Compressed)
  $e.SetAttribute("InstallScope", "perMachine")	
  $root.AppendChild($e)
  
  #<Media Id="1" Cabinet="putty.cab" EmbedCab="yes" />
  $e = $WiXXml.CreateElement("Media",$eNS)
  $e.SetAttribute("Id","1")
  $e.SetAttribute("Cabinet",$Cabinet)
  $e.SetAttribute("EmbedCab",$EmbedCab)
  $root.AppendChild($e)
    
  # Check for Sofwtare
   Create-WixCondition -tree $WiXXml -element $root -Condition "Installed OR VersionNT >= v6.1" -Message "This application requires Windows 7 or Windows Server 2008 R2 or higher"
   #Create-WixCondition -tree $WiXXml -element $root -Condition "Installed OR NETFRAMEWORK400" -Message "This application requires .NET Framework 4.0. Please install the .NET Framework then run this installer again"
   #Create-WixCondition -tree $WiXXml -element $root -Condition "Installed OR POWERSHELLVERSION >= ""3.0""" -Message "This application requires Powershell 3.0 or greater"
    
   #Condition for The Operating System! 
   # <Condition Message="This application is only supported on Windows Vista, Windows Server 2008, or higher.">
   #   <![CDATA[Installed OR (VersionNT >= 600)]]>
   # </Condition>
        
    
    
  
  #CreateTargetDir
  $e = $WiXXml.CreateElement("Directory",$eNS)
  $e.SetAttribute("Id","TARGETDIR")
  $e.SetAttribute("Name","SourceDir")
  $root.AppendChild($e)
  
  #Licence File
  #<WixVariable Id="WixUILicenseRtf" Value="bobpl.rtf" />
  $e = $WiXXml.CreateElement("WixVariable",$eNS)
  $e.SetAttribute("Id","WixUILicenseRtf")
  $e.SetAttribute("Value","$rootDir\Licence.rtf")
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
    
    
    
  
  Return $root
}


function ID_Replace( [String] $ID){
 
 $Wert="LEER"
 $ID = $ID -replace "%20","_"
 $ID = $ID -replace "%7B",""
 $ID = $ID -replace "%7D",""
 $ID = $ID -replace "%2","_"
 $ID = $ID -replace "-","_"
 $ID = $ID -replace " ","_"
 $ID = $ID -replace "\+","_"
 $ID = $ID -replace "\-","_"
 
 if($ID.length -gt 40){
   $ID = $ID.substring(0,40)
 }
 return $ID
}

function decodeName([String] $Name){

 $Name = [System.Web.HttpUtility]::UrlDecode("$Name")
 Return $Name
}

function CreateWixComment([xml] $tree, [System.Xml.XmlElement] $element,[String] $Text){
   $e = $tree.CreateComment($Text)
   $tree.InsertBefore($element,$e)
}

function CreateWixMainDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $e.SetAttribute("Id",$Folder)
  $newElement=$element.AppendChild($e)
  return $newElement
}

function CreateWixVFSDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $e.SetAttribute("Id",$Folder)
  $e.SetAttribute("Name",$Name)
  $newElement=$element.AppendChild($e)
  return $newElement
}

function CreateWixDirectory([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  $elem = (GetGuid -src "$Path$Folder").split("-")
  $e.SetAttribute("Id","DIR_" + (ID_Replace $Folder)+"_"+$elem[0])
  $e.SetAttribute("Name",(decodeName $Folder))
  $newElement=$element.AppendChild($e)
  return $newElement
}

function CreateWixDirectoryOhneGuid([xml] $tree, [System.Xml.XmlElement] $element, [String] $Folder, [String] $Name, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Directory",$eNS)
  
  $e.SetAttribute("Id","$Folder")
  $e.SetAttribute("Name",(decodeName $Folder))
  $newElement=$element.AppendChild($e)
  return $newElement
}

function CreateWixComponent([xml] $tree, [System.Xml.XmlElement] $element, [String] $Component, [String] $Path){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("Component",$eNS)
  $elem = (GetGuid -src "$path$Component").split("-")
  $e.SetAttribute("Id", "COM_"+ (ID_Replace $Component)+"_"+$elem[0])
  $e.SetAttribute("Guid", (GetGuid -src "$path$Component"))
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


#######################################################################################################
#
# function : Create empty registry key
#
#######################################################################################################
function CreateWixRegKey([xml] $tree, [System.Xml.XmlElement] $element, [String] $Hive, [String] $Key){

  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("RegistryKey",$eNS)
  $e.SetAttribute("Root",$Hive)
  $e.SetAttribute("Key",$Key)
  # do we need this?	
  #$e.SetAttribute("Action","createAndRemoveOnUninstall")
  $sub = $element.AppendChild($e)
  Return $sub
}

#######################################################################################################
#
# function : Create a xml registry key
#
#######################################################################################################
function CreateWixRegValue([xml] $tree, [System.Xml.XmlElement] $element, [String] $name, [String] $Value, [String] $Type){

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

  
  #Write-Host "--------------------------------------------------->" $MainPath
  $regPath="Software\$Applicationname\Uninstall\"+(GetGuid -$src "$ComponentName").toString()
  
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

function CreateWixFile([xml] $tree, [System.Xml.XmlElement] $element, [String] $File,[String] $Source){
  $eNS = $tree.DocumentElement.NamespaceURI
  $e = $tree.CreateElement("File",$eNS)
  $elem = (GetGuid -src "$Source").split("-")
  
  
  #Cut name. Error when to long
  $KName = ID_Replace $File
  if($KName.length -ge 11){
    $KName = $KName.SubString(0,10)
  }
  
  #Write-Host "---------------->" ($KName +"_"+($elem[0]))
  
  $e.SetAttribute("Id","File_" + $KName +"_"+($elem[0]) )
  $e.SetAttribute("Name", (decodeName $File ))
  $e.SetAttribute("Source",$Source)
  $element.AppendChild($e) 
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
  $elem = (GetGuid -src "$Source").split("-")
  $e.SetAttribute("Id","File_" + (ID_Replace $File)+"_"+$elem[0] )
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
function CreateWixDir([xml] $tree, [System.Xml.XmlElement] $element, $path){
 foreach ($File in Get-ChildItem $path){
   if (!(Test-Path $File.FullName -PathType Container)){ 
    CreateWixFile $tree $element $File.name "$path\$File" | Out-Null
   }
 }
}


#######################################################################################################
#
# function : Test for directorys without files
#
#######################################################################################################
function NoFilesTest($path){
  $Merker=0
  foreach ($File in Get-ChildItem $path){
    if (!(Test-Path $File.FullName -PathType Container)){ 
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
  foreach ($File in Get-ChildItem $path){
    if ((Test-Path $File.FullName -PathType Container)){ 
	 #File gefunden
	 Return 1
	 }
  }
  Return $Merker
}


#######################################################################################################
#
# function : Create wix file, Components, registry and directory entrys for a physikal folder
# For exclude use only Complex Strings like "\\Windows\\Installer"
#######################################################################################################
function CreateWixFileFolderStructure([xml] $tree, [System.Xml.XmlElement] $element, $path = $pwd, [string[]]$exclude ,  [System.Xml.XmlElement] $feature)
{ 
    foreach ($item in Get-ChildItem $path)
    {
        if ($exclude | Where {$item.FullName -match $_}) { continue }
		 
        if (Test-Path $item.FullName -PathType Container) 
        {
			#
			$newElement = CreateWixDirectory -tree $tree -element $element -Folder $item.PSChildName -Name $item.PSChildName -Path $item.FullName
			#
			
			#Create Componet
			if(NoFilesTest $item.FullName){
			  $Component = CreateWixComponent -tree $tree -element $newElement -Component $item.PSChildName -Path $item.FullName
			  AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
				   
			  if($RemoveDirList | where {$item.FullName -match $_}){
			     #
				 CreateWixRemoveFolder -tree $tree -element $Component -ID $newElement.Id -MainPath $path $item.FullName
				 #
			  }
			   #Create Files
			   CreateWixDir $tree $Component $item.FullName
			} 
			else{
		      #Empty Directory
		      #Is Directory in USERPROFILE?

		      if($RemoveDirList | where {$item.FullName -match $_}){

			    #Create Component for Directory
				$Component = CreateWixComponent -tree $tree -element $newElement -Component $item.PSChildName -Path $item.FullName
			    AddWiXFeature  -tree $tree -element $feature -Id $Component.Id
				CreateWixRemoveFolder -tree $tree -element $Component -ID $newElement.Id -MainPath $path
			  }
		    }
			
            CreateWixFileFolderStructure -tree $tree -element $newElement  -path $item.FullName -exclude $exclude -feature $feature 
			#
			$newElement = $newElement.get_ParentNode()
			
        } 
		#New
    } 
} 







#######################################################################################################
#
# function : Substitute some Key Values
#
#######################################################################################################

#\REGISTRY\USER\[{AppVCurrentUserSID}]

function CreateWixStringfromReglookup([String] $str)
{
   [String] $result = ""
                        
   $str = $str -replace "/REGISTRY/USER/\[\{AppVCurrentUserSID\}\]/",""
   $str = $str -replace "/REGISTRY/USER/\[\{AppVCurrentUserSID\}\]_CLASSES/","SOFTWARE/Classes/"
	
   $str = $str -replace "/REGISTRY/MACHINE/",""
   $result = $str -replace "/","\"
   return $result
   
  #r/Win32Assemblies/[{AppVPackageRoot}{|}]|OFFICE11|ADDINS|MSOSEC.DLL,KEY,  #######	{AppVPackageRoot}
	
}


#######################################################################################################
#
# function : Substitute Values
#
#######################################################################################################

function get-RegStbstitution($Value, $RegSubstitution, $line){

	$result =$Value
	$match = $false
	$toStbstitute = ""
	$item=""
	
	if($Value -match "\[\{"){
  	    foreach($item in $RegSubstitution.Keys){	
	    	$toStbstitute = $item
			
	    	$toStbstitute = $toStbstitute -replace "\{","\{"	
    		$toStbstitute = $toStbstitute -replace "\[","\["	
	    	$toStbstitute = $toStbstitute -replace "\]","\]"	
	    	$toStbstitute = $toStbstitute -replace "\}","\}"	
			
		    if($Value -match $toStbstitute){
              $result = $Value -replace $toStbstitute,$RegSubstitution.get_item($item)
			  $match = $true	
				
		    }
	    }
		
	    if(	$match -eq $false){
		  
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
	            $line
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
      #Filter for App-V Strings! Not Binary its a Reg_SZ
      #if($xByte -ne "00"){
      # $OutString+=$xByte+" "
      #}
	}
	

	
	$OutString = get-RegStbstitution -Value $OutString  -RegSubstitution $RegSubstitution -line $line
	return $OutString  
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

function Generate-MSIXml{
	
	$ProjectPath = $rootDir
	$Global:LogPath = "$rootDir\Logs\"
	$Global:LogFile = "$rootDir\Logs\CtxStr2AppVXML.log"
	
	$AppVPackagename = "AppBotCtxStr2AppV1.4.0"
	$AppVProductcode = "d157f30d-3314-4f71-8e46-c4612750f00b"
	$AppVUpgradecode = "417cbbe9-ac7d-474f-b936-1d449752f5f2"
	$AppVVersion = "1.4.0.0" 
	$AppVManufacturer = "Nick Informationstechnik GmbH"
	$AppVDisplayName = "AppBot Streaming Profiler to AppV converter 1.4"
	
	$Applicationname = "$AppVDisplayName"
	
	#Delete old log
	if(test-path $Global:LogFile) { Remove-Item -Path $LogFile -Force}
	 
    #Create variables

 	#WiX-xml erzeugen
	$msixml = New-Object xml 
	CreateWixXml -WiXXml  $msixml -UpgradeCode $AppVUpgradecode -Version $AppVVersion -Name $AppVDisplayName -Manufacturer $AppVManufacturer -ProductID $AppVProductcode 
    #$Chain = Create-WixBundle -tree $msixml -element $msixml.Wix -Name $AppVDisplayName -Version $AppVVersion -Manufacturer $AppVManufacturer -Web "Http://www.appbot.biz/en"
    #$Packs = Create-WixBundleChain -tree $msixml -element $msixml.Wix.Bundle
    #Powershell 3.0!
    #Create-WixBundleChainMSU -tree $msixml -element $Packs -Source "$rootDir\Prerequired\Windows6.1-KB2506143-x86.msu" -KB "KB2506143" -Condition "VersionNT=v6.1 AND NOT VersionNT64"
    #Create-WixBundleChainMSU -tree $msixml -element $Packs -Source "$rootDir\Prerequired\Windows6.1-KB2506143-x64.msu" -KB "KB2506143" -Condition "VersionNT=v6.1 AND VersionNT64"
    
    
	$root = "AppBot-CtxStr2AppV"

	CreateWixMainDirectory -tree $msixml -element $msixml.Wix.product.Directory -Folder "ProgramFilesFolder"
	CreateWixMainDirectory -tree $msixml -element $msixml.Wix.product.Directory.Directory -Folder "APPLICATIONROOTDIRECTORY"
	$msixml.Wix.product.Directory.Directory.Directory.SetAttribute("Name",$root)
	$Feature = CreateWiXFeature -tree $msixml -element $msixml.Wix.product "Main Application"
	
	#################################
	# Root Dir has files? 
	# Das wird aktuell im Hauptprogramm nicht ber�cksichtigt!
	#################################
    if(NoFilesTest "$rootDir"){
	  $Co = CreateWixComponent -tree $msixml -element $msixml.Wix.product.Directory.Directory.Directory -Component "root" -Path $rootDir
	  AddWiXFeature  -tree $msixml -element $Feature -Id $Co.id
	  #CreateWixDir -tree $msixml -element $msixml.Wix.product.Directory.Directory.Directory  -path $rootDir
	  
	  #Einge Files entfernen!
	  $exclFiles = (".*\.ps1", ".*\.pfpro.*",".*\.pff.*",".*\.pfs.*",".*\.txt",".*\.psbuild",".*\.psproj",".*\.psprojs",".*\.psf",".*\.pss")
	  foreach ($File in Get-ChildItem $rootDir){
	    if($exclFiles | where {$File.FullName -match $_}){ continue }
        if (!(Test-Path $File.FullName -PathType Container)){ 
        CreateWixFile -tree $msixml -element $Co -File $File.name "$rootDir\$File" | Out-Null
        }
      }
	} 	
	
    #Include Directorys
	CreateWixFileFolderStructure -tree $msixml -element $msixml.Wix.product.Directory.Directory.Directory "$rootDir" -exclude ("\\redist","\\CtxStr2msi_StartWizzard","\\Backup","\\Logs","\\test","\\CirStr2msi_StartWizzard","\\Images","\\KnowHow","\\Certificates","\\Release","\\LicenseTool") -feature $Feature 

    #Create a shortcut
	$newElement = CreateWixDirectoryOhneGuid -tree $msixml -element $msixml.Wix.product.Directory.Directory -Folder "ProgramMenuFolder" -Name "ProgramMenuFolder" -Path "Startmenue"
	$newElement2 = CreateWixDirectoryOhneGuid -tree $msixml -element $newElement -Folder "NickITAppBot" -Name "NickIT" -Path "AppBot-CtxStr2AppV"
	$Component = CreateWixComponent -tree  $msixml -element $newElement2 -Component "ApplicationShortcut" -Path "ApplicationShortcut"
	$eNS = $msixml.DocumentElement.NamespaceURI
	$e = $msixml.CreateElement("Shortcut",$eNS)
    $e.SetAttribute("Id","ApplicationStartMenuShortcut")
    $e.SetAttribute("Name","AppBot 32 Bit Streaming Profiler to App-V")
    $e.SetAttribute("Description","A tool to cenvertt Streaming Profiler Packages to App-V 5")
	$e.SetAttribute("Target","[APPLICATIONROOTDIRECTORY]AppBot-Ctxstr2appv_32.exe")
	$e.SetAttribute("WorkingDirectory","APPLICATIONROOTDIRECTORY")
    $Component.AppendChild($e)
	
	$e = $msixml.CreateElement("Shortcut",$eNS)
    $e.SetAttribute("Id","ApplicationStartMenuShortcut64")
    $e.SetAttribute("Name","AppBot 64 Bit Streaming Profiler to App-V")
    $e.SetAttribute("Description","A tool to cenvertt Streaming Profiler Packages to App-V 5")
	$e.SetAttribute("Target","[APPLICATIONROOTDIRECTORY]AppBot-Ctxstr2appv_64.exe")
	$e.SetAttribute("WorkingDirectory","APPLICATIONROOTDIRECTORY")
    $Component.AppendChild($e)
	
	CreateWixRemoveFolder -tree $msixml -element $Component -ID $Component.id -ComponentName "ApplicationShortcut" -MainPath "ApplicationShortcut"
    AddWiXFeature -tree $msixml -id $Component.id -element $feature 
	
    #Create a desktop shortcut
	$newElement = CreateWixDirectoryOhneGuid -tree $msixml -element $msixml.Wix.product.Directory.Directory -Folder "DesktopFolder" -Name "DesktopFolder" -Path "Desktop"
	$Component = CreateWixComponent -tree  $msixml -element $newElement -Component "ApplicationShortcutDesktop" -Path "ApplicationShortcutDesktop"
	$eNS = $msixml.DocumentElement.NamespaceURI
	$e = $msixml.CreateElement("Shortcut",$eNS)
    $e.SetAttribute("Id","ApplicationDesktopShortcut")
    $e.SetAttribute("Name","AppBot 32 Bit Streaming Profiler to App-V")
    $e.SetAttribute("Description","A tool to cenvertt Streaming Profiler Packages to App-V 5")
	$e.SetAttribute("Target","[APPLICATIONROOTDIRECTORY]AppBot-Ctxstr2appv_32.exe")
	$e.SetAttribute("WorkingDirectory","APPLICATIONROOTDIRECTORY")
    $Component.AppendChild($e)
	
	$e = $msixml.CreateElement("Shortcut",$eNS)
    $e.SetAttribute("Id","ApplicationDesktopShortcut64")
    $e.SetAttribute("Name","AppBot 64 Bit Streaming Profiler to App-V")
    $e.SetAttribute("Description","A tool to cenvertt Streaming Profiler Packages to App-V 5")
	$e.SetAttribute("Target","[APPLICATIONROOTDIRECTORY]AppBot-Ctxstr2appv_64.exe")
	$e.SetAttribute("WorkingDirectory","APPLICATIONROOTDIRECTORY")
    $Component.AppendChild($e)

	CreateWixRemoveFolder -tree $msixml -element $Component -ID $Component.id -ComponentName "ApplicationShortcutDesktop" -MainPath "ApplicationShortcutDesktop"
    AddWiXFeature -tree $msixml -id $Component.id -element $feature 	

    $msixml.Save("$rootDir\Release\$AppVPackagename.xml")
	
   #Generate the msi from the wix.xml	
	[String] $candle = "$rootDir\wixbin\candle.exe"
    [Array] $arguments = "-out", """$rootDir\Release\$AppVPackagename.wixobj""" ,"""$rootDir\Release\$AppVPackagename.xml""" 
	
	& $candle $arguments | Out-File "$LogPath$AppVPackagename.candle.log"

    #Write-Host  $candle $arguments

    #Create the msi

	[String] $light = "$rootDir\wixbin\light.exe"
    [Array] $arguments = """$rootDir\Release\$AppVPackagename.wixobj""","-sice:ICE91","-sice:ICE03","-sice:ICE60","-ext","WixUIExtension", "-ext", "WixNetfxExtension", "-ext", "WixPSExtension", "-ext","WixUtilExtension", "-out", """$RootDir\Release\$AppVPackagename.msi""" 

	& $light $arguments | Out-File "$LogPath$AppVPackagename.msi.log"

    Write-Host  "Finished"
}


Generate-MSIXml
Write-Host "Finished"

#    <Property Id="POWERSHELLVERSION">
#        <RegistrySearch Id="POWERSHELLVERSION" Root="HKLM" Key="SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" Name="PowerShellVersion" Type="raw" />
#    </Property>	

