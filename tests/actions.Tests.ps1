# Dummy values for required parameters
$script:OrgName    = "my-org"
$script:RepoName   = "my-repo"
$script:PrNumber   = "101"
$script:PrStatus   = "APPROVE"
$script:PrMessage  = "Unit test message"
$script:Token      = "dummy-token"
$script:ApiUrl     = "https://api.mytests.com"

Describe "Set-Pull-Request-Review-Status" {
    BeforeAll {
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        # Clean up GITHUB_OUTPUT for each test
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
    }
    
    AfterAll {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
    }
    
    It "submits a review and writes result=success to output for 200 response" {
        # Arrange
        Mock Invoke-WebRequest {
            # Simulate a web response with a 200 status code (success for review creation)
            [PSCustomObject]@{
                StatusCode = 200
                Content = '{"id": 321, "state": "APPROVED"}'
            }
        }

        # Set mock API endpoint
        $env:MOCK_API = $ApiUrl

        # Act
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token $Token

        # Assert
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "writes result=failure and error-message to output for non-200 response" {
        # Arrange
        Mock Invoke-WebRequest {
            # Simulate a failed review creation (e.g. 422)
            [PSCustomObject]@{
                StatusCode = 422
                Content = '{"message": "Validation Failed."}'
            }
        }
        $env:MOCK_API = $ApiUrl

        # Act
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token $Token

        # Assert
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Failed to submit Pull Request review.  Status code: 422"
    }

    It "writes result=failure and error-message to output on web error" {
        # Arrange
        Mock Invoke-WebRequest { throw "API Error" }
        $env:MOCK_API = $ApiUrl

        try {
            Set-Pull-Request-Review-Status `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -PrStatus $PrStatus `
                -PrMessage $PrMessage `
                -Token $Token
        } catch {}

        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Pull Request review threw an exception and failed."
    }

    It "writes result=failure for empty RepoName" {
        Set-Pull-Request-Review-Status `
            -RepoName "" `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty OrgName" {
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName "" `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty PrNumber" {
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber "" `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    }
    
    It "throws if PrStatus is empty" {
        { Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus "" `
            -PrMessage $PrMessage `
            -Token $Token
        } | Should -Throw
    }
    
    It "throws if PrStatus is not valid" {
        { Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus "INVALID" `
            -PrMessage $PrMessage `
            -Token $Token
        } | Should -Throw
    }
    
    It "writes result=failure for empty PrMessage" {
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage "" `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty Token" {
        Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus $PrStatus `
            -PrMessage $PrMessage `
            -Token ""
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    }    
}
