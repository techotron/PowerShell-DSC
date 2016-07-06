$configPath = "E:\DSC\configs\"
cd $configPath
$computerName = "mdm-serv.hellermanntytongroup.com"

configuration CreatePullServer {

    param
    (
        [string[]]$ComputerName = 'localhost'
    )

    Import-DscResource -module PSDesiredStateConfiguration
    Import-DscResource -module xPSDesiredStateConfiguration
    Node $ComputerName {

        WindowsFeature DSCServiceFeature {

            Ensure = "Present"
            Name = "DSC-Service"

        }

        xDSCWebService PSDSCPullServer {

            Ensure = "Present"
            EndpointName = "PSDSCPullServer"
            Port = 18080
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint = "AllowUnencryptedTraffic"
            ModulePath = "$env:PROGRAMFILES\WindowsPowershell\DSCService\Modules"
            ConfigurationPath = "$env:PROGRAMFILES\WindowsPowershell\DscService\Configuration"
            State = "Started"
            DependsOn = "[WindowsFeature]DSCServiceFeature"

        }

    }

}



CreatePullServer -computername mdm-serv.hellermanntytongroup.com
$mof = $configPath + $computerName + ".mof"
New-DscChecksum $mof