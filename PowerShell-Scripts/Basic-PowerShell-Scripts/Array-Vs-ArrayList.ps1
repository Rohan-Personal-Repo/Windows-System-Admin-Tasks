# Arrays are good if the Number of elements is < 100, anything more ArrayList is better.
# If possible its best to use the ArrayList irrespective of the count of elements we are saving
# Because arrays are fixed size, if we add an element to the Array it will destroy that Array and create a brand new array with the old + newly added elements

$nums_array = @( 1..10 )

Write-Host "Array Val : " $nums_array

Write-Host "Array Type : " $nums_array.GetType()

Write-Host "Array isFixedSize : " $nums_array.IsFixedSize

# Create ArrayList Object
$nums_arrayList = New-Object System.Collections.ArrayList
# Add values from Normal Array and Typecase to ArrayList
$nums_arrayList = [System.Collections.ArrayList] $nums_array

Write-Host "ArrayList Val #1 :  " $nums_arrayList

Write-Host "ArrayList Type : " $nums_arrayList.GetType()

Write-Host "ArrayList isFixedSize : " $nums_arrayList.IsFixedSize

$nums_arrayList.Add( 12 )
$nums_arrayList.Add( 15 )

Write-Host "ArrayList Val Add() :  " $nums_arrayList

$nums_arrayList.Insert( $nums_arrayList.Count-1, 11 )

Write-Host "ArrayList Val Insert() :  " $nums_arrayList

$nums_arrayList.RemoveAt( $nums_arrayList.Count-1 )

Write-Host "ArrayList Val RemoveAt() :  " $nums_arrayList