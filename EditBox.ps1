#Generated Form Function


function GenerateEditForm {
Param (
   [String[]] $Fields
   )



#$Global:EdittextBox = @()
$Global:result = @()

#$Global:result.Clear()

#region Generated Form Objects
$EditForm = New-Object System.Windows.Forms.Form
$Editpanel1 = New-Object System.Windows.Forms.Panel
$EditCancelBut = New-Object System.Windows.Forms.Button
$EditOKBut = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$EditForm.WindowState = $InitialFormWindowState
}
 
#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 106
$System_Drawing_Size.Width = 418
$EditForm.ClientSize = $System_Drawing_Size
$EditForm.ControlBox = $False
$EditForm.DataBindings.DefaultDataSourceUpdateMode = 0
$EditForm.Name = "EditForm"
$EditForm.Text = "Edit"
#$EditForm.set_startPosition( $MainDialog.get_StartPosition())
#$EditForm.set_Location($MainDialog.get_Location())
$EditForm.StartPosition = 'CenterParent'    

$EdittextBox = @()

for($i=0; $i -lt $Fields.count;$i++){
  
  $EdittextBox += New-Object System.Windows.Forms.TextBox
  $EdittextBox[$i].DataBindings.DefaultDataSourceUpdateMode = 0
  $EdittextBox[$i].Dock = 1
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 0
  $System_Drawing_Point.Y = 0#20
  $EdittextBox[$i].Location = $System_Drawing_Point
  $EdittextBox[$i].Name = "EdittextBox$i"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 20
  $System_Drawing_Size.Width = 418
  $EdittextBox[$i].Size = $System_Drawing_Size
  $EdittextBox[$i].TabIndex = $Fields.count-$i
  $EdittextBox[$i].text = $Fields[$Fields.count-$i-1]
		
  $EditForm.Controls.Add($EdittextBox[$i])
}

#$EdittextBox[$Fields.count-1].focus = $true


$EditOKBut_OnClick= 
{
  $EditForm.Close()
  for($i=$Fields.count-1;$i -ge 0;$i--){
    $Global:result += $EdittextBox[$i].text
  }
 
}

$EditCancelBut_OnClick= 
{

 $EditForm.Close()
 $Global:result = $Null
  
}



$Editpanel1.DataBindings.DefaultDataSourceUpdateMode = 0
$Editpanel1.Dock = 2
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 71
$Editpanel1.Location = $System_Drawing_Point
$Editpanel1.Name = "Editpanel1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 35
$System_Drawing_Size.Width = 418
$Editpanel1.Size = $System_Drawing_Size
$Editpanel1.TabIndex = 0

$EditForm.Controls.Add($Editpanel1)

$EditCancelBut.DataBindings.DefaultDataSourceUpdateMode = 0
$EditCancelBut.Dock = 4

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 275
$System_Drawing_Point.Y = 0
$EditCancelBut.Location = $System_Drawing_Point
$EditCancelBut.Name = "EditCancelBut"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 35
$System_Drawing_Size.Width = 143
$EditCancelBut.Size = $System_Drawing_Size
$EditCancelBut.TabIndex = 1
$EditCancelBut.Text = "Cancel"
$EditCancelBut.UseVisualStyleBackColor = $True
$EditCancelBut.add_Click($EditCancelBut_OnClick)

$Editpanel1.Controls.Add($EditCancelBut)


$EditOKBut.DataBindings.DefaultDataSourceUpdateMode = 0
$EditOKBut.Dock = 3

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 0
$EditOKBut.Location = $System_Drawing_Point
$EditOKBut.Name = "EditOKBut"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 35
$System_Drawing_Size.Width = 132
$EditOKBut.Size = $System_Drawing_Size
$EditOKBut.TabIndex = 0
$EditOKBut.Text = "OK"
$EditOKBut.UseVisualStyleBackColor = $True
$EditOKBut.add_Click($EditOKBut_OnClick)

$Editpanel1.Controls.Add($EditOKBut)


#endregion Generated Form Code


#Save the initial state of the form
$InitialFormWindowState = $EditForm.WindowState
#Init the OnLoad event to correct the initial state of the form
$EditForm.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$EditForm.ShowDialog()| Out-Null

  return $result 

} #End Function

#Call the Function
#GenerateEditForm(("Test","Test2", "Test3"))

