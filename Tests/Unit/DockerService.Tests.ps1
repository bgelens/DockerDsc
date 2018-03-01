$Global:ModuleName = 'DockerDsc'
$Global:DscResourceName = 'DockerService'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:ModuleName `
    -DSCResourceName $Global:DscResourceName `
    -TestType Unit `
    -ResourceType Class

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    #region Pester Tests
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
            
            Context 'With invalid Path' {
                $DockerServiceResource = [DockerService]::new()
                $DockerServiceResource.Path = 'C:\bogus'
                $DockerServiceResource = $DockerServiceResource | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { throw 'Dockerd.exe was not found' } -Force -PassThru
                
                It 'Set Should throw with Ensure present' {
                    $DockerServiceResource.Ensure = [Ensure]::Present
                    { $DockerServiceResource.Set() } | Should Throw 'Dockerd.exe was not found'
                }

                It 'Set Should throw with Ensure Absent' {
                    $DockerServiceResource.Ensure = [Ensure]::Absent
                    { $DockerServiceResource.Set() } | Should Throw 'Dockerd.exe was not found'
                }
            }

            Context 'Ensure is present' {
                $DockerServiceResource = [DockerService]::new()
                $DockerServiceResource.Ensure = [Ensure]::Present
                $DockerServiceResource = $DockerServiceResource | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { return 'TestDrive:\dockerd.exe'} -Force -PassThru
                $DockerServiceResource = $DockerServiceResource | Add-Member -MemberType ScriptMethod -Name DockerDReg -Value {} -Force -PassThru
                Mock -CommandName Stop-Service -MockWith {}

                It 'Stop-Service should not be called' {
                    $DockerServiceResource.Set()
                    Assert-MockCalled -CommandName Stop-Service -Times 0 -Exactly
                }
            }

            Context 'Ensure is absent' {
                $DockerServiceResource = [DockerService]::new()
                $DockerServiceResource.Ensure = [Ensure]::Absent
                $DockerServiceResource = $DockerServiceResource | Add-Member -MemberType ScriptMethod -Name ResolveDockerDPath -Value { return 'TestDrive:\dockerd.exe'} -Force -PassThru
                $DockerServiceResource = $DockerServiceResource | Add-Member -MemberType ScriptMethod -Name DockerDReg -Value {} -Force -PassThru
                Mock -CommandName Stop-Service -MockWith {}

                It 'Docker Service does not exist, stop should not be called' {
                    Mock -CommandName Get-Service -MockWith { }
                    $DockerServiceResource.Set()
                    Assert-MockCalled -CommandName Stop-Service -Times 0 -Exactly
                }

                It 'Docker Service should be force stopped when present' {
                    Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
                    $DockerServiceResource.Set()
                    Assert-MockCalled -CommandName Stop-Service -Times 1 -Exactly
                }
            }
        }

        Describe 'ResolveDockerDPath Method' {
            Context 'Path Construction' {
                $DockerServiceResource = [DockerService]::new()
                Mock -CommandName Join-Path -MockWith { param($Path,$ChildPath) process {return "$Path\$ChildPath"} }
                Mock -CommandName Test-Path -MockWith { return $true }

                It 'Should not Join-Path if dockerd.exe is part of path already and path string should be returned' {
                    $object = $DockerServiceResource.ResolveDockerDPath('c:\bogus\dockerd.exe')
                    Assert-MockCalled -CommandName Join-Path -Times 0 -Exactly
                    $object | Should Be 'c:\bogus\dockerd.exe'
                }

                It 'Should Join-Path if dockerd.exe is missing from specified path and path string should return' {
                    $object = $DockerServiceResource.ResolveDockerDPath('c:\bogus')
                    Assert-MockCalled -CommandName Join-Path -Times 1 -Exactly
                    $object | Should Be 'c:\bogus\dockerd.exe'
                }
            }

            Context 'Test Path' {
                $DockerServiceResource = [DockerService]::new()

                It 'Should not throw with valid path' {
                    Mock -CommandName Test-Path -MockWith { return $true }
                    { $DockerServiceResource.ResolveDockerDPath('c:\bogus\dockerd.exe') } | Should Not Throw
                }

                It 'Should throw with invalid path' {
                    Mock -CommandName Test-Path -MockWith { return $false }
                    { $DockerServiceResource.ResolveDockerDPath('c:\bogus\dockerd.exe') } | Should Throw
                }
            }
        }

        Describe 'DockerDReg Method' {
            $DockerServiceResource = [DockerService]::new()
            $Item = New-Item -Path TestDrive:\dockerd.cmd -Value "echo %0 %*> dockerd.txt"
            $TestLocation = Split-Path -Path $Item.FullName
            Push-Location
            Set-Location -Path TestDrive:

            Context 'Ensure Present' {
                $DockerServiceResource.DockerDreg("TestDrive:\dockerd.cmd",[Ensure]::Present)
                $Result = Get-Content -Path TestDrive:\dockerd.txt
                It 'Should have called --register-service' {
                    $Result | Should Be ('"{0}" {1}' -f "$TestLocation\dockerd.cmd",'--register-service')
                }
            }

            Context 'Ensure Absent' {
                $DockerServiceResource.DockerDreg("TestDrive:\dockerd.cmd",[Ensure]::Absent)
                $Result = Get-Content -Path TestDrive:\dockerd.txt
                It 'Should have called --unregister-service' {
                    $Result | Should Be ('"{0}" {1}' -f "$TestLocation\dockerd.cmd",'--unregister-service')
                }
            }

            Pop-Location
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
