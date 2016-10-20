configuration docker {
    param (
        [ValidateNotNullOrEmpty()]
        [String] $Path = 'C:\Program Files\Docker'
    )
    Import-DscResource -ModuleName DockerDsc
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    
    node localhost {
        WindowsFeature containers {
            Name = 'Containers'
            Ensure = 'Present'
        }

        #download latest beta
        xRemoteFile DockerD {
            DestinationPath = ('{0}\dockerd.exe' -f $Path)
            Uri = 'https://master.dockerproject.org/windows/amd64/dockerd.exe'
        }

        #download latest beta
        xRemoteFile DockerClient {
            DestinationPath = ('{0}\docker.exe' -f $Path)
            Uri = 'https://master.dockerproject.org/windows/amd64/docker.exe'
        }

        Environment DockerEnv {
            Path = $true
            Name = 'Path'
            Value = ('{0}\' -f $Path)
        }

        DockerService DockerD {
            Ensure = 'Present'
            Path = $Path
            DependsOn = '[WindowsFeature]containers','[xRemoteFile]DockerD'
        }

        service DockerD {
            Name = 'Docker'
            State = 'Running'
            StartupType = 'Automatic'
            DependsOn = '[DockerService]DockerD'
        }
    }
}
