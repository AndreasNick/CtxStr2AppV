#=====================================================================================================
#
# Citrix Streaming 2 Msi Converter "Icon Extractor"
# copyright 2013 Andreas Nick Nick Informationstechnik GmbH 
# http://www.nick-it.de
#
# Version V0.5
#
# Legal
# This  scritp is copyrighted material.  They may only be downloaded from the
# links I provide.  You may download them to use, if you want to do
# anything else with it, you have to ask me first.  Full terms and conditions are
# available on the download page on the blog http://software-virtualisierung.des
#
#=====================================================================================================



function ExtractCtxIcon{
param(
   [STRING] $BinPath,
	[INT] $Offset,
	[INT] $Size,
	[STRING] $Outfile
     )

	# Read the entire file to an array of bytes.
	
	$handle = [System.IO.File]::OpenRead("$BinPath")
	[byte[]] $Buffer = New-Object byte[] ($Size)
	$handle.set_Position($Offset)
    $handle.Read($Buffer,0,$Size)
    $handle.Close()

	[BYTE[]] $icon = @()
	#Write-Host "Create header"
	#Header for Citrix icon
	[System.Byte[]] $CtxIconHeader =   #22 Bytes
	0x00, 0x00, #  Reserved. Must always be 0. 
	0x01, 0x00, #Specifies image type: 1 for icon (.ICO) image
	0x01, 0x00, #Specifies number of images in the file. #Kein Multiimage!
	#-------image / images Header
	0x20, # Image Width
	0x20, # Image Higth
	0x10, # Specifies number of colors in the color palette. Should be 0 if the image does not use a color palette.
	0x00, # Reserved. Should be 0
	0x01, 0x00, # In ICO format: Specifies color planes. Should be 0 or 1
	0x04, 0x00, # In ICO format: Specifies bits per pixel #Citrix 4 Bits
	0xE8, 0x02, 0x00,0x00, # Image Size = 640... 512=0x00,0x20 # 680=0yA8 0x02
	0x16, 0x00, 0x00, 0x00, # Specifies the offset of BMP or PNG data from the beginning of the ICO/CUR file = 22

	#Bitmap Header
	0x28, 0x00, 0x00, 0x00, # 40 (Gr��e der BITMAPINFOHEADER-Struktur in Byte)
	0x20, 0x00, 0x00, 0x00, #Der Betrag gibt die H�he der Bitmap in Pixel an. 
	0x40, 0x00, 0x00, 0x00, # H�he der Bitmap in Pixel an. 
	0x01, 0x00, #Planes 1 (Stand in einigen �lteren Formaten wie PCX f�r die Anzahl der Farbebenen, wird aber f�r BMP nicht verwendet)
	0x04, 0x00, #18 00 24 bits Number of bits per pixel 

	#0 (BI_RGB): Bilddaten sind unkomprimiert.
	#1 (BI_RLE8): Bilddaten sind laufl�ngenkodiert f�r 8 bpp. Nur erlaubt wenn biBitCount=8 und biHeight positiv.
	#2 (BI_RLE4): Bilddaten sind laufl�ngenkodiert f�r 4 bpp. Nur erlaubt wenn biBitCount=4 und biHeight positiv.
	#3 (BI_BITFIELDS): Bilddaten sind unkomprimiert und benutzerdefiniert (mittels Farbmasken) kodiert. Nur erlaubt wenn biBitCount=16 oder 32; 
	0x00, 0x00, 0x00, 0x00,
	0x80, 0x02, 0x00, 0x00, #Size of the raw data in the pixel array (including padding) Wenn biCompression=BI_RGB: Entweder 0 oder die Gr��e der Bilddaten in Byte. Ansonsten: Gr��e der Bilddaten in Byte.
	0x00, 0x00, 0x00, 0x00, #Horizontale Aufl�sung des Zielausgabeger�tes in Pixel pro Meter; wird aber f�r BMP-Dateien meistens auf 0 gesetzt.
	0x00, 0x00, 0x00, 0x00, #Horizontale Aufl�sung des Zielausgabeger�tes in Pixel pro Meter; wird aber f�r BMP-Dateien meistens auf 0 gesetzt.
	#Wenn biBitCount=4 oder 8: die Anzahl der Eintr�ge der Farbtabelle; 0 bedeutet die maximale Anzahl (2, 16 oder 256).
	#Ansonsten: Die Anzahl der Eintr�ge der Farbtabelle (0=keine Farbtabelle). Auch wenn sie in diesem Fall nicht notwendig ist, kann dennoch eine f�r die Farbquantisierung empfohlene Farbtabelle angegeben werden.
	0x00, 0x00, 0x00, 0x00,
	#Wenn biBitCount=1, 4 oder 8: Die Anzahl s�mtlicher im Bild verwendeten Farben; 0 bedeutet alle Farben der Farbtabelle.
	#Ansonsten: Wenn eine Farbtabelle vorhanden ist und diese s�mtliche im Bild verwendeten Farben enth�lt: deren Anzahl.
	#Ansonsten: 0.
	0x00, 0x00, 0x00, 0x00,

	#Pakette invert
	#Blau #Green #Red  64Bytes
	0x00,0x00,0x00,0x00, # 0 Firefox Black
	0x00,0x00,0x80,0x00, # 1 Firefox Dark red F
	0x00,0x80,0x00,0x00, # 7 Excel drak green
	0x00,0x80,0x80,0x00, # 3 Dark Yelow Firefox
	0x80,0x00,0x00,0x00, # 4 Firefox DarkBlue
	0x80,0x00,0x80,0x00, # 5 
	0x80,0x80,0x00,0x00, # 6 Firefox Dark Tail
	0x80,0x80,0x80,0x00,
	0xC0,0xC0,0xC0,0x00, # 8 Firefox Grey
	0x00,0x00,0xFF,0x00, # 9 Firefox red
	0x80,0x80,0x80,0x00, # 10 A Dark gray 0,ff,00,00
	0x00,0xFF,0xFF,0x00, # 11 B Yellowok
	0xFF,0x00,0x00,0x00, # 12 C Anwendung Blau! ff,00,00,00
	0xff,0xFF,0x00,0x00, # 13 D Purple #0,ff,0,ff
	0xFF,0xFF,0x00,0x00, # 14 E Firefox Light Tail OK
	0xff,0xff,0xff,0x00  # 15 F Firfox White OK
	[byte] $bitmask = 0
	[byte[]] $bytemask = @() #512 Bytes 
	#Get Bitmask
	#Write-Host "Create mask"
	for($i=0;$i -lt 128 ;$i++){
	  $bitmask = $Buffer[$i]
	  for($x=3;$x -ge 0; $x--){	
		[byte]	$t1 = 0
	    $b1 = ($bitmask -shr ($x*2+1)) -band 1
	    $t1 = ($b1 * 0xf0)
	    $b1 = ($bitmask -shr ($x*2)) -band 1 #shr nur mit Powershell3!
		$t1 = $t1 + ($b1 * 0xf) 		
	    $bytemask += $t1 
	 }
	}
	#Write-Host "CopyHeader"
	for($i=0; $i -lt $CtxIconHeader.count;$i++){
	  $icon +=  $CtxIconHeader[$i]
	}

	#Write-Host "Count:" $CtxIconHeader.length
	#Write-Host "CopyIcon"
	for($y=31;$y -ge 0; $y--){
		for($x=0;$x -lt 16; $x++){
		  $icon +=  ($Buffer[128+($y*16)+$x] -bor $bytemask[(($y)*16)+($x)])
		}
	}
	for($i=0; $i -lt 128 ;$i++){
	  $icon +=  0
	}
	[System.IO.File]::WriteAllBytes("$Outfile", $icon)
}

function ExtractCtxIcon2{
param(
    [STRING] $BinPath,
	[INT] $Offset,
	[INT] $Size,
	[STRING] $Outfile
     )

	# Read the entire file to an array of bytes.
	
	$handle = [System.IO.File]::OpenRead("$BinPath")
	[byte[]] $Buffer = New-Object byte[] ($Size)
	$handle.set_Position($Offset)
    $handle.Read($Buffer,0,$Size)
    $handle.Close()

	[BYTE[]] $icon = @()
	#Write-Host "Create header"
	#Header for Citrix icon
	[System.Byte[]] $CtxIconHeader =   #22 Bytes
	0x00, 0x00, #  Reserved. Must always be 0. 
	0x01, 0x00, #Specifies image type: 1 for icon (.ICO) image
	0x01, 0x00, #Specifies number of images in the file. #Kein Multiimage!
	#-------image / images Header
	0x20, # Image Width
	0x20, # Image Higth
	0x10, # Specifies number of colors in the color palette. Should be 0 if the image does not use a color palette.
	0x00, # Reserved. Should be 0
	0x01, 0x00, # In ICO format: Specifies color planes. Should be 0 or 1
	0x04, 0x00, # In ICO format: Specifies bits per pixel #Citrix 4 Bits
	0xE8, 0x02, 0x00,0x00, # Image Size = 640... 512=0x00,0x20 # 680=0yA8 0x02
	0x16, 0x00, 0x00, 0x00, # Specifies the offset of BMP or PNG data from the beginning of the ICO/CUR file = 22

	#Bitmap Header
	0x28, 0x00, 0x00, 0x00, # 40 (Gr��e der BITMAPINFOHEADER-Struktur in Byte)
	0x20, 0x00, 0x00, 0x00, #Der Betrag gibt die H�he der Bitmap in Pixel an. 
	0x40, 0x00, 0x00, 0x00, # H�he der Bitmap in Pixel an. 
	0x01, 0x00, #Planes 1 (Stand in einigen �lteren Formaten wie PCX f�r die Anzahl der Farbebenen, wird aber f�r BMP nicht verwendet)
	0x04, 0x00, #18 00 24 bits Number of bits per pixel 

	#0 (BI_RGB): Bilddaten sind unkomprimiert.
	#1 (BI_RLE8): Bilddaten sind laufl�ngenkodiert f�r 8 bpp. Nur erlaubt wenn biBitCount=8 und biHeight positiv.
	#2 (BI_RLE4): Bilddaten sind laufl�ngenkodiert f�r 4 bpp. Nur erlaubt wenn biBitCount=4 und biHeight positiv.
	#3 (BI_BITFIELDS): Bilddaten sind unkomprimiert und benutzerdefiniert (mittels Farbmasken) kodiert. Nur erlaubt wenn biBitCount=16 oder 32; 
	0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, #Size of the raw data in the pixel array (including padding) Wenn biCompression=BI_RGB: Entweder 0 oder die Gr��e der Bilddaten in Byte. Ansonsten: Gr��e der Bilddaten in Byte.
	0x00, 0x00, 0x00, 0x00, #Horizontale Aufl�sung des Zielausgabeger�tes in Pixel pro Meter; wird aber f�r BMP-Dateien meistens auf 0 gesetzt.
	0x00, 0x00, 0x00, 0x00, #Horizontale Aufl�sung des Zielausgabeger�tes in Pixel pro Meter; wird aber f�r BMP-Dateien meistens auf 0 gesetzt.
	#Wenn biBitCount=4 oder 8: die Anzahl der Eintr�ge der Farbtabelle; 0 bedeutet die maximale Anzahl (2, 16 oder 256).
	#Ansonsten: Die Anzahl der Eintr�ge der Farbtabelle (0=keine Farbtabelle). Auch wenn sie in diesem Fall nicht notwendig ist, kann dennoch eine f�r die Farbquantisierung empfohlene Farbtabelle angegeben werden.
	0x00, 0x00, 0x00, 0x00,
	#Wenn biBitCount=1, 4 oder 8: Die Anzahl s�mtlicher im Bild verwendeten Farben; 0 bedeutet alle Farben der Farbtabelle.
	#Ansonsten: Wenn eine Farbtabelle vorhanden ist und diese s�mtliche im Bild verwendeten Farben enth�lt: deren Anzahl.
	#Ansonsten: 0.
	0x00, 0x00, 0x00, 0x00,

	#Pakette invert
	#Blau #Green #Red  64Bytes
	0x00,0x00,0x00,0x00, # 0 Firefox Black
	0x00,0x00,0x80,0x00, # 1 Firefox Dark red F
	0x00,0x80,0x00,0x00, # 7 Excel drak green
	0x00,0x80,0x80,0x00, # 3 Dark Yelow Firefox
	0x80,0x00,0x00,0x00, # 4 Firefox DarkBlue
	0x00,0xff,0x00,0x00, # 5 Green
	0x80,0x80,0x00,0x00, # 6 Firefox Dark Tail
	0x80,0x80,0x80,0x00,
	0xC0,0xC0,0xC0,0x00, # 8 Firefox Grey
	0x00,0x00,0xFF,0x00, # 9 Firefox red
	0x80,0x80,0x80,0x00, # 10 A Dark gray
	0x00,0xFF,0xFF,0x00, # 11 B Yellow
	0xFF,0x00,0x00,0x00, # 12 C Anwendung Blau!
	0xff,0xFF,0x00,0x00, # 13 D Purple
	0xFF,0xFF,0x00,0x00, # 14 E Firefox Light Tail
	0xff,0xff,0xff,0x00  # 15 F Firfox White
	[byte] $bitmask = 0
	[byte[]] $bytemask = @() #512 Bytes 
	#Get Bitmask

	for($i=0;$i -lt 128 ;$i++){
	  $bitmask = 255#$Buffer[$i]
	  for($x=3;$x -ge 0; $x--){	
#		[byte]	$t1=0
#	    $b1 =($bitmask -shr ($x*2+1)) -band 1
#	    $t1 = ($b1 * 0x0f)
#	    $b1 = ($bitmask -shr ($x*2)) -band 1
#		$t1 = $t1 + ($b1 * 0xf0) 		
	    $bytemask += $t1 
	 }
	}
	
	for($i=0; $i -lt $CtxIconHeader.count;$i++){
	  $icon +=  $CtxIconHeader[$i]
	}

	for($y=31;$y -ge 0; $y--){
		for($x=0;$x -lt 16; $x++){
		  $icon +=  ($Buffer[130+((31-$y)*16)+$x] -bor $bytemask[(($y)*16)+($x)])
		}
	}
	for($i=0; $i -lt 128 ;$i++){
	  $icon +=  0
	}
	[System.IO.File]::WriteAllBytes("$Outfile", $icon)
}

function ExtractCtxIcon3{
param(
    [STRING] $BinPath,
	[INT] $Offset,
	[INT] $Size,
	[STRING] $Outfile
     )
	
	$handle = [System.IO.File]::OpenRead("$BinPath")
	[byte[]] $Buffer = New-Object byte[] ($Size)
	$handle.set_Position($Offset)
    $handle.Read($Buffer,0,$Size)
    $handle.Close()
    [System.IO.File]::WriteAllBytes("$Outfile", $Buffer)
}


function  Extract-CitrixIcons{
Param(
   [STRING] $BinPath,
   [STRING] $ProfilePath,
   [STRING] $OutPath
     )

  $IconCount = Count-Icons($ProfilePath)
   	#Progressbar
	 if($progressbaroverlay1){
	   $progressbaroverlay1.Maximum = $IconCount
       $progressbaroverlay1.Style = "Block"
       $progressbaroverlay1.Value = 0
	   $progressbaroverlay1.Step = 1
	   $progressbaroverlay1.TextOverlay = "Processing Icons from icon.bin file..."
	 }
 
    
  #New-Item c:\temp\icons -type directory -force 

  $ctxProfile = New-Object xml
  $ctxProfile.Load("$ProfilePath")

  #$IconPath = "c:\temp\icons\"+$ctxProfile.Package.Targets.Target.Guid
  $IconPath =  $OutPath
    
  New-Item $IconPath -type directory -force 


  foreach($Appnode in $ctxProfile.package.apps.ChildNodes){
    $i=0    
    New-Item ($IconPath+"\"+$Appnode.name) -type directory -force 
    foreach($Iconsnode in $Appnode.icons.ChildNodes){
       if($Iconsnode.Size -eq 640){
	     ExtractCtxIcon -BinPath "$BinPath" -Offset $Iconsnode.Offset -Size $Iconsnode.Size -Outfile ("$IconPath"+"\"+$Appnode.name+"\Icon_$i.ico")
  	     $i++
  	   } else {
	      #Write-Host -Offset ($Iconsnode.Offset+4) -Size (([INT]$Iconsnode.Size)-4) 
	     	ExtractCtxIcon3 -BinPath "$BinPath" -Offset (([INT]$Iconsnode.Offset)+4) -Size (([INT]$Iconsnode.Size)-4) -Outfile ("$IconPath"+"\"+$Appnode.name+"\Icon_$i.ico")
	     $i++
	   }
       if($progressbaroverlay1){
	      $progressbaroverlay1.PerformStep() 	
	      [System.Windows.Forms.Application]::DoEvents() 
		}
	}     
    }
    #break
}


function Count-Icons{
param(
    [STRING] $ProfilePath
    
     )
    
    $ctxProfile = New-Object xml
    $ctxProfile.Load("$ProfilePath")
    $i=0
    foreach($Appnode in $ctxProfile.package.apps.ChildNodes){
      foreach($Iconsnode in $Appnode.icons.ChildNodes){
	   $i++
	   }
     }
    return $i
}

#Write-Host "A1"
