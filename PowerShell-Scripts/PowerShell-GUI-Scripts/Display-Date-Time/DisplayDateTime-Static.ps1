Add-Type -AssemblyName System.Windows.Forms

$formObj = [System.Windows.Forms.Form]

$currentDateForm = New-Object $formObj

# Set Screen Size
$currentDateForm.ClientSize = '900,600' #Length, #Height

# Dialog Title
$currentDateForm.Text = 'Display Current Date & Time'

# Dialog BG & FG colors
#$currentDateForm.BackColor = 'AliceBlue'
#$currentDateForm.ForeColor = 'DarkSlateGray'

$currentDateForm.BackColor = 'Black'
#$currentDateForm.ForeColor = 'Aquamarine'

$lblObj = [System.Windows.Forms.Label]
$lblDateTime = New-Object $lblObj


$lblDateTime.Text = Get-Date

# Takes the Size of the Content we want to display
$lblDateTime.AutoSize = $true

# Set the X & Y Co-ordinates for the Label
$lblDateTime.Location = New-Object System.Drawing.Point( 150, 250 );

# Set Text Color
$lblDateTime.ForeColor = 'Aquamarine'

# Set Font Name, Size and Style
$lblDateTime.Font='Comic Sans MS,36,style=Bold'

# Add a Range of Controls
$currentDateForm.Controls.AddRange(@($lblDateTime))

# Ensure we add these two lines at the end otherwise the Controls we added wont be displayed

# Display the dialog 
$currentDateForm.ShowDialog()

# Cleans up the dialog
$currentDateForm.Dispose()