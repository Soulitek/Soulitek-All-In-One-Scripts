BeforeAll {
    . "$PSScriptRoot\..\modules\SouliTEK-Common.ps1"
}

Describe "Test-SafeFilePath" {
    BeforeEach {
        $base = "C:\Users\TestUser\Desktop"
    }

    It "accepts a plain filename" {
        Test-SafeFilePath -UserInput "report.html" -BaseDir $base | Should -BeTrue
    }

    It "accepts a filename with spaces" {
        Test-SafeFilePath -UserInput "Battery Report 2026.html" -BaseDir $base | Should -BeTrue
    }

    It "rejects relative traversal ..\..\system32\cmd.exe" {
        Test-SafeFilePath -UserInput "..\..\windows\system32\cmd.exe" -BaseDir $base | Should -BeFalse
    }

    It "rejects an absolute path outside BaseDir" {
        Test-SafeFilePath -UserInput "C:\windows\system32\cmd.exe" -BaseDir $base | Should -BeFalse
    }

    It "rejects empty string" {
        Test-SafeFilePath -UserInput "" -BaseDir $base | Should -BeFalse
    }

    It "rejects whitespace-only string" {
        Test-SafeFilePath -UserInput "   " -BaseDir $base | Should -BeFalse
    }

    It "rejects input over 260 characters" {
        Test-SafeFilePath -UserInput ("a" * 261) -BaseDir $base | Should -BeFalse
    }
}
