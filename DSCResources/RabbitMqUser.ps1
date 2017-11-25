[DscResource()]
class RabbitMqUser
{
    [DscProperty(Key)]
    [string]
    $Username

    [DscProperty()]
    [pscredential]
    $Password
    
    [DscProperty()]
    [string[]]
    $Tag

    [DscProperty(Mandatory)]
    [string]
    $RabbitMqUri

    [DscProperty()]
    [pscredential]
    $Credential

    [RabbitMqUser]Get()
    {
        $ruser = $this.GetRabbitUser()
        $this.Username = $ruser.Username
        $this.Tag = $ruser.Tag

        return $this
    }

    [bool]Test()
    {
        $ruser = $this.GetRabbitUser()
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

    [void]Set()
    {
        $setSplat = @{
            Name    = $this.Username
            BaseUri = $this.RabbitMqUri
        }

        if ($this.Tag -ne $null)
        {
            $setSplat['Tag'] = $this.Tag
        }
        else
        {
            $setSplat['Tag'] = 'none'
        }

        if ($this.Password)
        {
            $setSplat['NewPassword'] = $this.Password.GetNetworkCredential().Password
        }

        if ($this.Credential -ne $null)
        {
            $setSplat['Credential'] = $this.Credential
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

    [RabbitMqUser]GetRabbitUser()
    {
        $getSplat = @{
            Name    = $this.Username
            BaseUri = $this.RabbitMqUri
        }
        if ($this.Credential -ne $null)
        {
            $getSplat['Credential'] = $this.Credential
        }

        Write-Verbose -Message "Getting details for rabbit user [$($this.Username)]"
        $ruser = Get-RabbitMQUser @getSplat
        return $ruser
    }
}

#$cred = (Get-Credential)
#$userCred = (Get-Credential)
$VerbosePreference = 'continue'
$rabUser = New-Object -TypeName RabbitMqUser
$rabUser.Username = $userCred.UserName
$rabUser.Password = $userCred
$rabUser.RabbitMqUri = 'http://localhost:15672'
if (-not($rabUser.Test()))
{
    $rabUser.Set()
}