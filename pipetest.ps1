function sum
{

    Param($Property)
    BEGIN
    {
    $sum = 0
    }

    PROCESS
    {
        $sum += $_.$Property
    }
    END
    {
        $sum
    }
}

Get-Process | sum -Property NPM