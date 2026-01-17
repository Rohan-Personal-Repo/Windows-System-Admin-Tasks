Function WindowsLogger 
{
	# We ensure that Message and Category are Compulsorily Passed into the Function as Variables
	Param
	(
		[ Parameter(Mandatory = $True) ] 
		[string] $logMsg,
# We ensure that the Value they send, we Validate here as Info, Warning or Error only & nothing else
		[ Parameter(Mandatory = $True) ] 
		[ ValidateSet('INFO','WARNING','ERROR') ]
		[string] $logCategory 
	)
	
	# Define the log name and source
	$logName = "Application" # Windows Application Log
	$source = "NP-Chat-App"
	
	# Check if the source exists and create it if it doesn't.

	if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
		New-EventLog -LogName $logName -Source $source
	}

	$eventID = 0
	
	switch( $logCategory ) 
	{
		"ERROR" 
		{ 
			$eventID = 1111
			Write-EventLog -ComputerName $(hostname) -LogName $logName -Source $source -EventID $eventID -EntryType $logCategory -Message $logMsg
		}
		"INFO" 
		{ 
			$eventID = 2222
			Write-EventLog -ComputerName $(hostname) -LogName $logName -Source $source -EventID $eventID -EntryType $logCategory -Message $logMsg
		}
		"WARNING" 
		{ 
			$eventID = 3333
			Write-EventLog -ComputerName $(hostname) -LogName $logName -Source $source -EventID $eventID -EntryType $logCategory -Message $logMsg
		}
		default
		{ 
			# It will never come here because of the ValiDateSet but it's good to have
			Write-Host "Did not provide Arguments as expected!" -ForegroundColor Magenta
		}
	}
}

WindowsLogger -logMsg "This is an Informational Message" -logCategory INFO
WindowsLogger -logMsg "This is an Error Message" -logCategory ERROR
WindowsLogger -logMsg "This is Warning Message" -logCategory WARNING

# Let's see if our Entries are present
Get-EventLog -LogName Application -Source "NP-Chat-App" -Newest 10