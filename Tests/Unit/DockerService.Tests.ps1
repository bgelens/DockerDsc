using module ..\..\DockerDsc.psm1

$DockerServiceResource = [DockerService]::new()
$DockerServiceResource.Ensure = [Ensure]::Present
$DockerServiceResource.Path = 'C:\Program Files\Docker'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

Describe 'Test Module' {
    it 'Test should return a bool' {
        $DockerServiceResource.Test() | should BeOfType bool
    }
}
