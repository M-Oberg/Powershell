$sum = 0
foreach ($proc in (get-process))
{
$sum += $proc.NPM
}
"totalt npm: $sum"
"The end."


$i = 0
while ($i -lt 10)
{ 
    write-host "Talet är $i"
        $i++
}

for ($i = 0; $i -lt 10; $i++)
{
    write-host "Talet är $i"

    }
"The end."