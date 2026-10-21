@{
    # Pablitus Prompt Framework (PPF) - PSScriptAnalyzer configuration
    #
    # Rules excluded here are intentional design decisions of the framework.
    # Anything not listed must be fixed before merging.

    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Framework state is intentionally global and namespaced with PPF_.
        'PSAvoidGlobalVars',

        # Write-Host is used deliberately in build/release and user-facing output.
        'PSAvoidUsingWriteHost',

        # Providers and services must never leak exceptions into the prompt.
        'PSAvoidUsingEmptyCatchBlock',

        # Source files are UTF-8 without BOM; PowerShell 7 reads them correctly.
        'PSUseBOMForUnicodeEncodedFile',

        # Set-*/Clear-* are in-memory state helpers, not external side effects.
        'PSUseShouldProcessForStateChangingFunctions',

        # Public API names are frozen in v1.x (Get-PromptSegments, etc.).
        'PSUseSingularNouns',

        # Get-WmiObject is a deliberate fallback for environments without CIM.
        'PSAvoidUsingWMICmdlet'
    )
}
