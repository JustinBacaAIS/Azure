Param(
    [string] [Parameter(Mandatory=$true)] $templateParamsUri
)

function Convert-PSObjectToHashTable {
    Param(
        $property
    )
    $propHash = New-Object -TypeName HashTable
    if($property.GetType().Name -eq "PSCustomObject"){
        $property | Get-Member -MemberType *Property | %{
            if($property."$($_.Name)".GetType().Name -match "Object"){
                $propHash.Add($_.Name,(Convert-PSObjectToHashTable $property."$($_.Name)"))
            } #end if
            else{
                $propHash.Add($_.Name,($property."$($_.Name)"))
            }
        } #end foreach
        return $propHash
    } #end if
    elseif($property.GetType().Name -eq "Object[]"){
        $propArray = New-Object System.Collections.Generic.List[System.Object]
        for($i=0;$i -lt $property.Count;$i++){
            $arrayPropHash = New-Object -TypeName HashTable
            if($property[$i].GetType().Name -eq "Object[]"){
                $propArray.Add((Convert-PSObjectToHashTable $property[$i]))
            } #end if
            elseif($property[$i].GetType().Name -eq "PSCustomObject"){
                $property[$i] | Get-Member -MemberType *Property | Select Name | %{
                    $arrayPropHash.Add($_.Name,(Convert-PSObjectToHashTable $property[$i]."$($_.Name)"))
                }
                $propArray.Add($arrayPropHash)
            } #end else
            else{
                $propArray.Add($property[$i])
            }
        } #end foreach
        return $propArray
    } #end elseif
    else{
        return $property
    } #end else
}
# template Parameters Object
$OptionalParameters = New-Object -TypeName Hashtable

# Get Parameters File Web Content and Parse
$JsonParameters = @{}
try{
    #$JsonParameters = Invoke-WebRequest -Uri $templateParamsUri | ConvertFrom-Json
    $JsonParameters = Invoke-RestMethod -Method Get -Uri $templateParamsUri -Verbose #| ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    } #end if
    $JsonParameters | Get-Member -MemberType *Property | %{
        $propertyName = $JsonParameters."$($_.Name)" | Get-Member -MemberType *Property | Select Name
        if($propertyName.Name -eq 'value'){                           
            if($JsonParameters."$($_.Name)".value.GetType().Name -match "Object"){
                $OptionalParameters.Add($_.Name,(Convert-PSObjectToHashTable $JsonParameters."$($_.Name)".value))
            } #end if
            else{
                $OptionalParameters.Add($_.Name,($JsonParameters | Select -Expand $_.Name -ErrorAction Ignore | Select -Expand 'value' -ErrorAction Ignore))
            } #end else
        } #end if
        elseif($propertyName.Name -eq 'reference'){
            $OptionalParameters.Add($_.Name,(Convert-PSObjectToHashTable $JsonParameters."$($_.Name)".reference))
        } #end elseif
        else{
            throw "Unable to convert parameter $($_.Name) to HashTable"
        } #end else
    } #end foreach
} #end try
catch{
    throw "Unable to retrieve content from parameters file: $($templateParamsUri) :: Exception: $($_.Exception)"
} #end catch

$OptionalParameters