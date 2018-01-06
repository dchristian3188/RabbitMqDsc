class RabbitMQQueue
{
    [DscProperty(Key)]
    [string]
    $Name
    
    [DscProperty(Mandatory)]
    [string]
    $BaseUri

    [DscProperty(Mandatory)]
    [pscredential]
    $Credential

    [DscProperty()]
    [Ensure]
    $Ensure = 'Present'

    [DSCProperty()]
    [string]
    $VirtualHost

    [DscProperty()]
    [bool]
    $Durable

    [DscProperty()]
    [bool]
    $Autodelete

    [DscProperty()]
    [hashtable]
    $Arguments

    
    [RabbitMQQueue]Get()
    {

        return $this
    }

    [bool]Test()
    {
        $ruser = $this.GetRabbitUser()
        if ($this.Ensure -eq 'Present')
        {
            if (-not($ruser))
            {
                Write-Verbose -Message "User $($this.Username) does not exist"
                return $false
            }
    
            $tagDiff = Compare-Object -ReferenceObject ($ruser.Tag | Sort-Object) -DifferenceObject ($this.Tag | Sort-Object)
            if ($tagDiff)
            {
                Write-Verbose -Message "Tags do not match. Expected: [$($this.Tag)], Actual: [$($ruser.Tag)]"
                return $false
            }

            
    
            Write-Verbose -Message "User matches"
            return $true
        }
        else
        {
            if ($ruser -eq $null)
            {
                return $true
            }
            return $false
        }
    }

    [void]Set()
    {
        $setSplat = @{
            Name       = $this.Username
            BaseUri    = $this.BaseUri
            Credential = $this.Credential
        }
        if ($this.Ensure -eq 'Present')
        {
            if ($this.Tag -ne $null)
            {
                $setSplat['Tag'] = $this.Tag
            }
    
            if ($this.Password)
            {
                $setSplat['NewPassword'] = $this.Password.GetNetworkCredential().Password
            }
    
            $ruser = $this.GetRabbitUser()
            if ($ruser)
            {
                Set-RabbitMQUser @setSplat
            }
            else
            {
                Add-RabbitMQUser @setSplat
            }
        }
        else
        {
            Remove-RabbitMQUser @setSplat -Confirm:$false
        }
    }

    [RabbitMQ.Queue]GetRabbitUser()
    {
        $getSplat = @{
            Name    = $this.Name
            BaseUri = $this.BaseUri
            Credential = $this.Credential
        }

        Write-Verbose -Message "Getting details for rabbit queue [$($this.name)]"
        $rque = Get-RabbitMQQueue @getSplat
        return $rque
    }
}

$VerbosePreference = 'continue'
$rabQue = New-Object -TypeName RabbitMQQueue
$rabQue.BaseUri = 'http://localhost:15672'
$rabQue.Credential = $cred
$rabQue.Name = 'testqueue'
$rabQue.GetRabbitUser()