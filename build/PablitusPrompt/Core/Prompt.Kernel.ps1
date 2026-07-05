# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Kernel.ps1
# ============================================================

if (-not $script:PPF) {

    $script:PPF = @{

        Providers = @()

        Segments = @()

        Renderers = @{}

        Services = @{}

        Commands = @{}

        Themes = @{}

    }

}

# ------------------------------------------------------------
# Generic Registry
# ------------------------------------------------------------

function Register-PPFComponent {

    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "Providers",
            "Segments",
            "Renderers",
            "Services",
            "Commands",
            "Themes"
        )]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        $Value

    )

    switch ($Category) {

        "Providers" {

            $script:PPF.Providers = @(
                $script:PPF.Providers |
                Where-Object Name -ne $Name
            )

            $script:PPF.Providers += $Value

        }

        "Segments" {

            $script:PPF.Segments = @(
                $script:PPF.Segments |
                Where-Object Name -ne $Name
            )

            $script:PPF.Segments += $Value

        }

        default {

            $script:PPF[$Category][$Name] = $Value

        }

    }

}

function Get-PPFComponent {

    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "Providers",
            "Segments",
            "Renderers",
            "Services",
            "Commands",
            "Themes"
        )]
        [string]$Category,

        [string]$Name

    )

    if ($Category -in @("Providers","Segments")) {

        if ($Name) {

            return $script:PPF[$Category] |
                   Where-Object Name -eq $Name

        }

        return $script:PPF[$Category]

    }

    if ($Name) {

        return $script:PPF[$Category][$Name]

    }

    return $script:PPF[$Category]

}