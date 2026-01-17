Add-Type -AssemblyName System.Windows.Forms

# Create JSON Data Objects
$jsonSrcFile = Get-Content .\ADUsers.json

$jsonObj = $jsonSrcFile | ConvertFrom-Json

# Create common objects
$formObj = [System.Windows.Forms.Form]
$lblObj = [System.Windows.Forms.Label]
$comboObj = [System.Windows.Forms.ComboBox]

# SetUp Base Form Style
$empDataForm = New-Object $formObj
# Set Screen Size
$empDataForm.ClientSize = '900,600' #Length, #Height
# Dialog Title
$empDataForm.Text = 'Display Employee Details'
# Dialog BG & FG colors
$empDataForm.BackColor = 'Lemonchiffon'
$empDataForm.ForeColor = 'Purple'
# Set Default Font Style
$empDataForm.Font='Comic Sans MS,20,style=Bold'

# Select Employee label
$lblSelectEmp = New-Object $lblObj
$lblSelectEmp.Text = 'User Name : '
$lblSelectEmp.AutoSize = $true
$lblSelectEmp.Location = New-Object System.Drawing.Point( 20,20 )

# Employee Combo Box
$comboEmps = New-Object $comboObj
$comboEmps.Width = '250'
$comboEmps.Location = New-Object System.Drawing.Point( 225,20 )
$comboEmps.BackColor = 'Aliceblue'
$comboEmps.ForeColor = 'DarkslateGray'
# Default Text for ComboBox
$comboEmps.Text = 'Select Employee:'

# Populate ComboBox with UserNames
foreach ($user in $jsonObj) {
    $comboEmps.Items.Add( $($user.SamAccountName) )
}

# Select Employee Name
$lblEmpName = New-Object $lblObj
$lblEmpName.AutoSize = $true
$lblEmpName.Location = New-Object System.Drawing.Point( 20,100 )

# Select Employee Email-ID
$lblEmpEmailID = New-Object $lblObj
$lblEmpEmailID.AutoSize = $true
$lblEmpEmailID.Location = New-Object System.Drawing.Point( 20,175 )

# Select Employee Department
$lblEmpDept = New-Object $lblObj
$lblEmpDept.AutoSize = $true
$lblEmpDept.Location = New-Object System.Drawing.Point( 20,250 )

# Select Employee Country
$lblEmpCountry = New-Object $lblObj
$lblEmpCountry.AutoSize = $true
$lblEmpCountry.Location = New-Object System.Drawing.Point( 20,325 )

function getSelectedEmployeeDetails{

    # Set Default Label Values
    $lblEmpName.Text = 'Full Name : '
    $lblEmpEmailID.Text = 'Email-ID : '
    $lblEmpDept.Text = 'Department : '
    $lblEmpCountry.Text = 'Country : '

    # Filter the Selected Employee from the entire JSON Data
    $selectedEmp = $jsonObj | Where { $_.SamAccountName -eq $comboEmps.SelectedItem }
    
    $lblEmpName.Text += $($selectedEmp.DisplayName)
    $lblEmpEmailID.Text += $($selectedEmp.UserPrincipalName)

    # Separate User Department and Country
    $groupPath = $($selectedEmp.MemberOf) -split ","
    # Write-Host "Group Path : " $groupPath 
    $groupName = $($groupPath[0] -split "=")[1]
    $lblEmpDept.Text += $groupName

    $country = $($groupPath[1] -split "=")[1]
    $lblEmpCountry.Text += $country

}

# Register the Event Handler
$comboEmps.Add_SelectedIndexChanged( {getSelectedEmployeeDetails} )

# Add a Range of Controls
$empDataForm.Controls.AddRange( @($lblSelectEmp, $comboEmps, $lblEmpName, $lblEmpEmailID, $lblEmpDept, $lblEmpCountry) )

# Ensure we add these two lines at the end otherwise the Controls we added wont be displayed
# Display the dialog 
$empDataForm.ShowDialog()

# Cleans up the dialog
$empDataForm.Dispose()