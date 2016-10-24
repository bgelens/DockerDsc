[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCDscExamplesPresent', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCDscTestsPresent', '')]
param ()

enum Ensure
{
    Present
    Absent
}

[DscResource()]
class DockerService
{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [String] $Path

    [DscProperty(NotConfigurable)]
    [bool] $ServiceInstalled

    [DockerService] Get ()
    {
        $DockerDPath = $this.ResolveDockerDPath($this.Path)
        $DockerService = Get-Service Docker -ErrorAction SilentlyContinue
        $_ServiceInstalled = if ($null -ne $DockerService)
        {
            $true
        }
        else
        {
            $false
        }
        $ReturnObj = [DockerService]::new()
        $ReturnObj.Ensure = $this.Ensure
        $ReturnObj.Path = $DockerDPath
        $ReturnObj.ServiceInstalled = $_ServiceInstalled
        return $ReturnObj
    }

    [bool] Test ()
    {
        $Service = Get-Service -Name Docker -ErrorAction SilentlyContinue
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if ($null -ne $Service)
            {
                return $true
            }
            else
            {
                return $false 
            }
        }
        else
        {
            if ($null -eq $Service)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }

    [void] Set ()
    {
        $DockerDPath = $this.ResolveDockerDPath($this.Path)
        if ($DockerDPath -eq [String]::Empty)
        {
            throw 'Dockerd.exe was not found at path.'
        }
        
        if (($this.Ensure -eq [Ensure]::Absent) -and (Get-Service -Name docker -ErrorAction SilentlyContinue))
        {
            Write-Verbose -Message "Docker Service is running. Stopping now."
            Stop-Service -Name docker
        }
        $this.DockerDReg($DockerDPath,$this.Ensure)
    }

    [String] ResolveDockerDPath ([String] $Path)
    {
        $DockerDPath = [String]::Empty
        if ((Split-Path -Path $Path -Leaf) -eq 'dockerd.exe')
        {
            $DockerDPath = $Path
        }
        else
        {
            $DockerDPath = Join-Path -Path $Path -ChildPath 'dockerd.exe'
        }

        if (-not (Test-Path -Path $DockerDPath))
        {
            throw 'Dockerd.exe was not found'
        }
        return $DockerDPath
    }
    [void] DockerDReg ([String] $Path, [Ensure] $Ensure)
    {
        if ($Ensure -eq [Ensure]::Present)
        {
            Write-Verbose -Message 'Registering Docker Service'
            & $Path --register-service
        }
        else
        {
            Write-Verbose -Message 'Removing Docker Service'
            & $Path --unregister-service
        }
    }
}
