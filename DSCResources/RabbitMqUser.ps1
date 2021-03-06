[DscResource()]
class RabbitMQUser
{
    [DscProperty(Key)]
    [string]
    $Username
    
    [DscProperty(Mandatory)]
    [string]
    $BaseUri

    [DscProperty(Mandatory)]
    [pscredential]
    $Credential

    [DscProperty()]
    [Ensure]
    $Ensure = 'Present'

    [DscProperty()]
    [pscredential]
    $Password
    
    [DscProperty()]
    [string[]]
    $Tag

    [RabbitMqUser]Get()
    {
        $ruser = $this.GetRabbitUser()
        $this.Tag = $ruser.Tag

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

    [RabbitMqUser]GetRabbitUser()
    {
        $getSplat = @{
            Name    = $this.Username
            BaseUri = $this.BaseUri
            Credential = $this.Credential
        }
        Write-Verbose -Message "Getting details for rabbit user [$($this.Username)]"
        $ruser = Get-RabbitMQUser @getSplat
        return $ruser
    }
}

#$cred = (Get-Credential)
#$userCred = (Get-Credential)
$VerbosePreference = 'continue'
$rabUser = New-Object -TypeName rabbitmquser
$rabUser.Username = $userCred.UserName
$rabUser.Password = $userCred
$rabUser.BaseUri = 'http://localhost:15672'
$rabUser.tag = 'management'
$rabUser.Credential = $cred
$rabUser.Ensure = 'absent'
$rabUser.Get()
if (-not($rabUser.Test()))
{
    $rabUser.Set()
}