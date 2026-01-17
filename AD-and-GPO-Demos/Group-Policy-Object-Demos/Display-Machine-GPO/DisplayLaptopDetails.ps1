Add-Type -AssemblyName System.Windows.Forms

$formObj = [System.Windows.Forms.Form]

$laptopInfoForm = New-Object $formObj

# Set Screen Size
$laptopInfoForm.ClientSize = '900,600' #Length, #Height

# Dialog Title
$laptopInfoForm.Text = 'Laptop Specs:'

# Dialog BG & FG colors
$laptopInfoForm.BackColor = 'AliceBlue'
$laptopInfoForm.ForeColor = 'DarkSlateGray'

$lblObj = [System.Windows.Forms.Label]
$lblLaptopModel = New-Object $lblObj
$lblLaptopCPU = New-Object $lblObj
$lblLaptopRAM = New-Object $lblObj
$lblLaptopHDD = New-Object $lblObj
$lblDateTime = New-Object $lblObj


$lblDateTime.Text = Get-Date
$lblDateTime.AutoSize = $true
$lblDateTime.Location = New-Object System.Drawing.Point( 50, 50 );
$lblDateTime.ForeColor = 'DarkSlateGray'
$lblDateTime.Font='Arial,36,style=Bold'

$lblLaptopModel.Text = 'Model - ASUS Zenbook DUO'
$lblLaptopModel.AutoSize = $true
$lblLaptopModel.Location = New-Object System.Drawing.Point( 50, 150 );
$lblLaptopModel.ForeColor = 'DarkSlateGray'
$lblLaptopModel.Font='Arial,20,style=Italic'

$lblLaptopCPU.Text = "CPU - Intel Core Ultra 7 or Ultra 9 Processor"
$lblLaptopCPU.AutoSize = $true
$lblLaptopCPU.Location = New-Object System.Drawing.Point( 50, 250 );
$lblLaptopCPU.ForeColor = 'DarkSlateGray'
$lblLaptopCPU.Font='Arial,20,style=Italic'

$lblLaptopRAM.Text = 'RAM - 16GB or 32GB Variants'
$lblLaptopRAM.AutoSize = $true
$lblLaptopRAM.Location = New-Object System.Drawing.Point( 50, 350 );
$lblLaptopRAM.ForeColor = 'DarkSlateGray'
$lblLaptopRAM.Font='Arial,20,style=Italic'

$lblLaptopHDD.Text = 'HDD - 1TB NVMe Drive'
$lblLaptopHDD.AutoSize = $true
$lblLaptopHDD.Location = New-Object System.Drawing.Point( 50, 450 );
$lblLaptopHDD.ForeColor = 'DarkSlateGray'
$lblLaptopHDD.Font='Arial,20,style=Italic'


# Add a Range of Controls
$laptopInfoForm.Controls.AddRange(@($lblDateTime, $lblLaptopModel, $lblLaptopCPU, $lblLaptopRAM, $lblLaptopHDD))

# Ensure we add these two lines at the end otherwise the Controls we added wont be displayed

# Display the dialog 
$laptopInfoForm.ShowDialog()

# Cleans up the dialog
$laptopInfoForm.Dispose()