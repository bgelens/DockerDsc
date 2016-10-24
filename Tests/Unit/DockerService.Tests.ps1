using module ..\..\DSCResources\DockerService\DockerService.psd1

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

InModuleScope -ModuleName DockerService {
    Describe 'Test Method' {
        $DockerServiceResource = [DockerService]::new()
        $DockerServiceResource.Path = 'C:\bogus'

        Context 'Type Test' {
            it 'Test should return a bool' {
                $DockerServiceResource.Ensure = [Ensure]::Present
                $DockerServiceResource.Test() | should BeOfType bool
            }
        }

        Context 'Ensure Absent' {
            $DockerServiceResource.Ensure = [Ensure]::Absent

            It "Test should return true when service is absent" {
                Mock -CommandName Get-Service -MockWith { }
                $DockerServiceResource.Test() | should Be $true
            }

            It 'Test should return false when service is present' {
                Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
                $DockerServiceResource.Test() | should Be $false
            }
        }

        Context 'Ensure Present' {
            $DockerServiceResource.Ensure = [Ensure]::Present

            It 'Test should return false when service is missing' {
                Mock -CommandName Get-Service -MockWith { }
                $DockerServiceResource.Test() | should Be $false
            }

            It 'Test should return true when service is present' {
                Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
                $DockerServiceResource.Test() | should Be $true
            }
        }
        
    }
    Describe 'Get Method' {

    }
    Describe 'Set Method' {
        
    }
}
