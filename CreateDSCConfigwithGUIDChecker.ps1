# This is a script to create a DSC config file for a DSC Pull Server. The code in the config block can be changed to create another type of template.
 
# NOTES: ESnow. 06/07/2016. This will create a .mof file on \\mdm-serv\e$\dsc\configs\. It will then use the check-mofguid function to check the csv file
#                           for a GUID which already exists for the servername. If it finds one, it will warn you with the file name. If it doesn't find
#                           one, it will create a new .mof file named after a brand new guid, along with a checksum file.

# TODO: ESnow. 06/07/2016. - I want to introduce a feature that will still create the .mof if found but re-use the GUID. This will override the old file though
#                           so I need to add an archiving feature to keep the old .mof on the filesystem somewhere.
#                          - Another feature I'd like to introduce is a reference to the DSC Configuration code block so it's not hard coded in this script

# ============================================================= START OF SCRIPT ===================================================================================

# Change directory to config path location ########################################################################################################################

$configPath = "\\mdm-serv\e$\DSC\Configs"
cd $configPath


# ================================================ DSC CONFIGURATION CODE BLOCK ===================================================================================

# Change this code to suit the requirements for the server ########################################################################################################

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

# =========================================================== CHECK GUID TABLE ====================================================================================


function Create-mofGuid {

    param(
        [string]$DSCConfigurationName,
        [string]$computerName
    )

$sourceConfig = "\\mdm-serv\e$\DSC\configs\$DSCConfigurationName\$computerName.mof"
$guid = [guid]::NewGuid()
$targetConfig = "\\mdm-serv\C$\Program Files\WindowsPowershell\DscService\Configuration\$guid.mof"

add-content -path "\\mdm-serv\e$\DSC\guidToHostname.csv" -value "$computerName,$guid,$targetConfig,$sourceConfig"

copy $sourceConfig $targetConfig
New-DscChecksum $targetConfig

write-host "New .mof file created: $targetConfig" -ForegroundColor yellow

}


function Check-mofGuid {

    param(
        [string]$computerName,
        [string]$dscConfigurationName
    )

if (($DSCConfigurationName -eq $null)-or ($computerName -eq $null)) {
    throw "Please enter values for the computername and the configuration name"
}

        $guidTable = import-csv "\\mdm-serv\e$\DSC\guidToHostname.csv"


        if ($guidTable.computerName -eq $computerName) {

            $Global:currentGuid = $guidTable.guid
            write-host "GUID for $computerName found in table already!" -ForegroundColor yellow

        } else {

            Create-mofGuid -computerName $computerName -DSCConfigurationName $dscConfigurationName

        }

}


# ================================================ COMPLETE THE BELOW TO CONFIGURE THE NEW MOF ====================================================================

$comp = "mdm-serv.hellermanntytongroup.com"

CreatePullServer -computername $comp
Check-mofGuid -computerName $comp -dscConfigurationName CreatePullServer
