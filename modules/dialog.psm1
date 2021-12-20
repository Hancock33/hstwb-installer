# HstWB Installer Dialog Module
# -----------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-04-03
#
# A powershell module for HstWB Installer with dialog functions.


# print settings
function PrintSettings($hstwb)
{
    Write-Host "Settings"
    Write-Host "  Settings File         : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $hstwb.Paths.SettingsFile + "'")
    Write-Host "  Assigns File          : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $hstwb.Paths.AssignsFile + "'")
    Write-Host "Installer"
    Write-Host "  Mode                  : " -NoNewline -foregroundcolor "Gray"
    switch ($hstwb.Settings.Installer.Mode)
    {
        "Test" { Write-Host "'Test'" }
        "Install" { Write-Host "'Install'" }
        "BuildSelfInstall" { Write-Host "'Build Self Install'" }
        "BuildPackageInstallation" { Write-Host "'Build Package Installation'" }
        "BuildUserPackageInstallation" { Write-Host "'Build User Package Installation'" }
    }

    # show image for installer modes: test, install and build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Test|Install|BuildSelfInstall)$")
    {
        Write-Host "Image"
        Write-Host "  Image Dir             : " -NoNewline -foregroundcolor "Gray"
        Write-Host ("'" + $hstwb.Settings.Image.ImageDir + "'")
    }

    # show amiga os for installer modes: install and build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Install|BuildSelfInstall)$")
    {
        Write-Host "Amiga OS"
        Write-Host "  Install Amiga OS      : " -NoNewline -foregroundcolor "Gray"
        Write-Host ("'" + $hstwb.Settings.AmigaOs.InstallAmigaOs + "'")
        Write-Host "  Amiga OS dir          : " -NoNewline -foregroundcolor "Gray"
        Write-Host ("'" + $hstwb.Settings.AmigaOs.AmigaOsDir + "'")
        Write-Host "  Amiga OS set          : " -NoNewline -foregroundcolor "Gray"
    
        if ($hstwb.Settings.AmigaOs.AmigaOsSet -notmatch '^$' -and $hstwb.UI.AmigaOs.AmigaOsSetInfo)
        {
            if ($hstwb.UI.AmigaOs.AmigaOsSetInfo.Color)
            {
                Write-Host $hstwb.UI.AmigaOs.AmigaOsSetInfo.Text -ForegroundColor $hstwb.UI.AmigaOs.AmigaOsSetInfo.Color
            }
            else
            {
                Write-Host $hstwb.UI.AmigaOs.AmigaOsSetInfo.Text
            }
        }
        else
        {
            Write-Host "''"
        }
    }

    # show kickstart for installer modes: test, install and build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Test|Install|BuildSelfInstall)$")
    {
        Write-Host "Kickstart"
        Write-Host "  Install Kickstart     : " -NoNewline -foregroundcolor "Gray"
        Write-Host ("'" + $hstwb.Settings.Kickstart.InstallKickstart + "'")
        Write-Host "  Kickstart dir         : " -NoNewline -foregroundcolor "Gray"
        Write-Host ("'" + $hstwb.Settings.Kickstart.KickstartDir + "'")
        Write-Host "  Kickstart set         : " -NoNewline -foregroundcolor "Gray"
    
        if ($hstwb.Settings.Kickstart.KickstartSet -notmatch '^$' -and $hstwb.UI.Kickstart.KickstartSetInfo)
        {
            if ($hstwb.UI.Kickstart.KickstartSetInfo.Color)
            {
                Write-Host $hstwb.UI.Kickstart.KickstartSetInfo.Text -ForegroundColor $hstwb.UI.Kickstart.KickstartSetInfo.Color
            }
            else
            {
                Write-Host $hstwb.UI.Kickstart.KickstartSetInfo.Text
            }
        }
        else
        {
            Write-Host "''"
        }
    }
    
    # show packages for installer modes: install, build self install and build package installation
    if ($hstwb.Settings.Installer.Mode -match "^(Install|BuildSelfInstall|BuildPackageInstallation)$")
    {

        # get install packages
        $installPackageNames = @{}
        foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
        {
            $installPackageNames.Set_Item($hstwb.Settings.Packages[$installPackageKey].ToLower(), $true)
        }

        Write-Host "Packages"
        Write-Host "  Packages Filtering    : " -NoNewline -foregroundcolor "Gray"
        $packageFiltering = if ($hstwb.Settings.Packages.PackageFiltering -eq 'All') { 'All Amiga OS versions' } else { 'Amiga OS {0}' -f $hstwb.Settings.Packages.PackageFiltering }
        $packageFilteringCount = (SortPackageNames $hstwb | Where-Object { $hstwb.Settings.Packages.PackageFiltering -eq 'All' -or !$hstwb.Packages[$_].AmigaOsVersions -or $hstwb.Packages[$_].AmigaOsVersions -contains $hstwb.Settings.Packages.PackageFiltering }).Count
        Write-Host ("'{0}' ({1}/{2} packages)" -f $packageFiltering, $packageFilteringCount, $hstwb.Packages.Count)

        $packageNames = @()
        $packageNames += SortPackageNames $hstwb | ForEach-Object { $_.ToLower() }
        
        Write-Host "  Install Packages      : " -NoNewline -foregroundcolor "Gray"
        if ($installPackageNames.Count -gt 0)
        {
            $installPackages = @()

            foreach ($packageName in ($packageNames | Where-Object { $installPackageNames.ContainsKey($_) }))
            {
                $package = $hstwb.Packages[$packageName]
                
                $installPackages += $package.FullName
            }

            Write-Host ("'{0}' ({1}/{2} packages)" -f ($installPackages -Join ', '), $installPackageNames.Count, $packageFilteringCount)
        }
        else
        {
            Write-Host "None" -foregroundcolor "Yellow"
        }
    }

    # show user packages packages for installer modes: install, build self install and build package installation
    if ($hstwb.Settings.Installer.Mode -match "^(Install|BuildSelfInstall|BuildUserPackageInstallation)$")
    {
        Write-Host "User Packages"
        Write-Host "  User Packages Dir     : " -NoNewline -foregroundcolor "Gray"

        if ($hstwb.Settings.UserPackages.UserPackagesDir -and (Test-Path -Path $hstwb.Settings.UserPackages.UserPackagesDir))
        {
            Write-Host ("'{0}'" -f $hstwb.Settings.UserPackages.UserPackagesDir)
        }
        else
        {
            Write-Host "''"
        }

        # get install user packages
        $installUserPackageNames = @()
        foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
        {
            $userPackageName = $hstwb.Settings.UserPackages.Get_Item($installUserPackageKey.ToLower())
            $userPackage = $hstwb.UserPackages.Get_Item($userPackageName)
            $installUserPackageNames += $userPackage.Name
        }
        
        Write-Host "  Install User Packages : " -NoNewline -foregroundcolor "Gray"
        if ($installUserPackageNames.Count -gt 0)
        {
            Write-Host ("'{0}' ({1}/{2} packages)" -f (($installUserPackageNames | Sort-Object) -Join ', '), $installUserPackageNames.Count, $hstwb.UserPackages.Count)
        }
        else
        {
            Write-Host "None" -foregroundcolor "Yellow"
        }
    }

    # show emulator for installer modes: test, install and build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Test|Install|BuildSelfInstall)$")
    {
        Write-Host "Emulator"
        Write-Host "  Emulator File         : " -NoNewline -foregroundcolor "Gray"

        if ($hstwb.Settings.Emulator.EmulatorFile -and (Test-Path -Path $hstwb.Settings.Emulator.EmulatorFile))
        {
            $emulatorName = DetectEmulatorName $hstwb.Settings.Emulator.EmulatorFile

            if ($emulatorName)
            {
                Write-Host ("'{0} ({1})'" -f $emulatorName, $hstwb.Settings.Emulator.EmulatorFile)
            }
            else
            {
                Write-Host ("'{0}'" -f $hstwb.Settings.Emulator.EmulatorFile)
            }
        }
        else
        {
            Write-Host "''"
        }
    }
}


# enter path
function EnterPath($prompt)
{
    do
    {
        $path = Read-Host $prompt

        if ($path -ne '')
        {
            $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
        
        if (!(test-path -path $path))
        {
            Write-Error "Path '$path' doesn't exist"
        }
    }
    until ($path -eq '' -or (test-path -path $path))
    return $path
}


# enter choice
function EnterChoice($prompt, $options, $returnIndex = $false)
{
    $optionPadding = $options.Count.ToString().Length

    for ($i = 0; $i -lt $options.Count; $i++)
    {
        Write-Host (("{0," + $optionPadding + "}: ") -f ($i + 1)) -NoNewline -foregroundcolor "Gray"
        Write-Host $options[$i]
    }
    Write-Host ""

    do
    {
        Write-Host ("{0}: " -f $prompt) -NoNewline -foregroundcolor "Cyan"
        $choice = (Read-Host) -as [int]
    }
    until ($choice -ne '' -and $choice -ge 1 -and $choice -le $options.Count)

    if ($returnIndex)
    {
        $choice - 1
    }

    return $options[$choice - 1]
}

# enter choice color
function EnterChoiceColor($prompt, $options, $returnIndex = $false)
{
    $optionPadding = $options.Count.ToString().Length

    for ($i = 0; $i -lt $options.Count; $i++)
    {
        Write-Host (("{0," + $optionPadding + "}: ") -f ($i + 1)) -NoNewline -foregroundcolor "Gray"

        if ($options[$i].Text)
        {
            if ($options[$i].Color)
            {
                Write-Host $options[$i].Text -ForegroundColor $options[$i].Color
            }
            else
            {
                Write-Host $options[$i].Text
            }
        }
        else
        {
            Write-Host $options[$i]
        }
    }
    Write-Host ""

    do
    {
        Write-Host ("{0}: " -f $prompt) -NoNewline -foregroundcolor "Cyan"
        $choice = (Read-Host) -as [int]
    }
    until ($choice -ne '' -and $choice -ge 1 -and $choice -le $options.Count)

    if ($returnIndex)
    {
        $choice - 1
    }

    return $options[$choice - 1]
}