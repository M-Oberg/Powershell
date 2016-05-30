[int]$val = Read-Host "Skriv ett tal"

if ($val -gt 100)
     {
        Write-host "talet är större än hundra"
        }

        elseif ($val -gt 50)
        { write-host "Talet är större än femtio."
        }

        elseif ($val -gt 70)
        { write-host "Talet är större än sjuttio."
        }
        else
        {write-host "Talet är inte så stort"

        }
"The end."