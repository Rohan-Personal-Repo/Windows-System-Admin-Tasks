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

# Create a Button to Update Date and Time
$btnObj = [System.Windows.Forms.Button]
$btnGetCurrDateTime = New-Object $btnObj
$btnGetCurrDateTime.Text = 'Get the Current Date And Time'

# Takes the Size of the Content we want to display
$btnGetCurrDateTime.AutoSize = $true
# Add the button below our text
$btnGetCurrDateTime.Location = New-Object System.Drawing.Point( 200,350 )

# Set Text Color and Font Styles
$btnGetCurrDateTime.ForeColor = 'Aquamarine'
$btnGetCurrDateTime.Font='Comic Sans MS,20,style=Bold'

# Create a function to make the changes
function updateDateTime()
{
    # Ensure that there is a Slight Delay
    Start-Sleep -Seconds 2
    $lblDateTime.Text = Get-Date
}

# Handle the Button Click action with Add_Click and pass the event -> function we created above
$btnGetCurrDateTime.Add_Click( {updateDateTime} )

# Add a Range of Controls
$currentDateForm.Controls.AddRange(@($lblDateTime, $btnGetCurrDateTime))

# Ensure we add these two lines at the end otherwise the Controls we added wont be displayed

# Display the dialog 
$currentDateForm.ShowDialog()

# Cleans up the dialog
$currentDateForm.Dispose()