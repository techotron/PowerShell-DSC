#  This script is intended to have all the DSC configurations which template my server builds. The full script
#  won't be included here, only a basic one to illistrate what I'm trying to achieve. 
# 
#  I've wrapped the various templates (or to use DSC's nomanclature, configurations) inside a custom function 
#  called "ConfigMe". This function has a validate set parameter called "$a" which via the use of if statements
#  will run the appropriate DSC configuration script, resulting in a .MOF for the specified "$computerName". 
#
#  The idea is that I can call upon this single script anytime I need a configuration file for a new server, 
#  or if I need to make a config change and re-create the .MOF files for the existing servers. I've yet to decide
#  if this is over engineering or whether this is an efficient way of achieving this goal but whilst I get to
#  grips with DSC, it's a way that sits will with me!
#
#  In the environment I work in, a DSC Pull model is overkill so this is designed with a push model in mind. 
#
#  ESnow. 08/10/2016.
#
# =========================================== Custom Functions ==============================================

# ----------------------------------------- Create MOF Backup -----------------------------------------------

Function Add-MofBackup {

    param(
        [string[]]$computerName,
        [string]$path
    )

    $date = (get-date).tostring("yyyyMMdd HHmm")

    foreach ($computer in $computerName) {

        Move-Item "$path\$computer.mof" "C:\DSC Configs\Old Configs\$date-$computer.mof"

    }

}


# ====================================== MOF Configuration Section ==========================================

Function ConfigMe {

    param(
        [Parameter(Mandatory=$true)][ValidateSet("SQL-Server", "DSC-Server")][string]$a,
        [Parameter(Mandatory=$true)][String[]]$Computers,
        [Parameter(Mandatory=$false)][string]$SXSsource = "\\dsc-dc01\ISOs\Server2012R2\sources\sxs",             # Windows SXS folder
        [Parameter(Mandatory=$false)][string]$sqlSource = "\\dsc-dc01\ISOs\SQLEE2014SP2"                          # SQL Install Files
    )

# -------------------------------------- SQL Server Configuration -------------------------------------------

    if ($a -eq "SQL-Server") {

        $mofPath = "C:\DSC Configs\SQL Servers"

        Configuration CreateSQLConfig {

            param(
                [string[]]$computerName,
                [string]$winSources
            )

            Add-MofBackup -computerName $computerName -path $mofPath

            node $computerName {

                WindowsFeature NetFramework35Core {

                    Name = "NET-Framework-Core"
                    Ensure = "Present"
                    Source = $winSources

                }

            }

        }

        CreateSQLConfig -computerName $Computers -outputpath "$mofPath\" -winSources $SXSsource

    }

# -------------------------------------- DSC Server Configuration -------------------------------------------

    if ($a -eq "DSC-Server") {

        $mofPath = "C:\DSC Configs\DSC Servers"

        Configuration CreateDSCConfig {

            param(
                [string[]]$computerName
            )

            Add-MofBackup -computerName $computerName -path $mofPath

            node $computerName {

                WindowsFeature DSCService {

                    Name = "DSC-Service"
                    Ensure = "Present"

                }

            }

        }


        CreateDSCConfig -computerName $Computers -outputpath "$mofPath\"

    }

# ==================================== End MOF Configuration Section ========================================

}

# ============================================= End of Script ===============================================
