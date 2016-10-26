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
        
        Context 'With valid Path' {

            $dockerDsc = [DockerService]::new()
            $dockerDsc.Ensure = [Ensure]::Present
            $dockerDsc = $dockerDsc | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { return 'TestDrive:\dockerd.exe' } -Force -PassThru
            Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}

            It 'Get should return DockerService object' {
                $object = $dockerDsc.Get()

                $object.GetType().Name | Should Be 'DockerService'
                $object.Ensure | Should Be 'Present'
                $object.Path | Should Be 'TestDrive:\dockerd.exe'
                $object.ServiceInstalled | Should Be $true
            }
        }

        Context 'With invalid Path' {

            $dockerDsc = [DockerService]::new()
            $dockerDsc.Ensure = [Ensure]::Present
            $dockerDsc = $dockerDsc | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { throw 'Dockerd.exe was not found' } -Force -PassThru
            Mock -CommandName Get-Service -MockWith { $null }

            It 'Get should throw Dockerd not found' {

                { $object = $dockerDsc.Get() } | Should Throw 'Dockerd.exe was not found'

            }
        }    

        Context 'With no Service' {

            $dockerDsc = [DockerService]::new()
            $dockerDsc.Ensure = [Ensure]::Present
            $dockerDsc = $dockerDsc | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { return 'TestDrive:\dockerd.exe'} -Force -PassThru
            Mock -CommandName Get-Service -MockWith { $null }

            It 'Get should return a DockerService object with ServiceInstalled as $false' {
                $object = $dockerDsc.Get() 
            
                $object.GetType().Name | Should Be 'DockerService'
                $object.Ensure | Should Be 'Present'
                $object.Path | Should Be 'TestDrive:\dockerd.exe'
                $object.ServiceInstalled | Should Be $false
            }
        }         
    }

    Describe 'Set Method' {
        
    }

}
