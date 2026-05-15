Describe "Set-PullRequestReviewStatus" {
    BeforeAll {
        $script:OrgName    = "my-org"
        $script:RepoName   = "my-repo"
        $script:PrNumber   = "101"
        $script:PrStatus   = "APPROVE"
        $script:PrMessage  = "Unit test message"
        $script:Token      = "dummy-token"
        $script:ApiUrl     = "https://api.mytests.com"
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
    
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    Context "Success Cases" {
        It "unit: Set-PullRequestReviewStatus succeeds with HTTP 200" {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content = '{"id": 321, "state": "APPROVED"}'
                }
            }
    
             Set-PullRequestReviewStatus `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -PrStatus $PrStatus `
                -PrMessage $PrMessage `
                -Token $Token
    
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=success"
        }
    }

    Context "Failure Cases" {
        It "unit: Set-PullRequestReviewStatus fails with HTTP 422" {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{
                    StatusCode = 422
                    Content = '{"message": "Validation Failed."}'
                }
            }

            Set-PullRequestReviewStatus `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -PrStatus $PrStatus `
                -PrMessage $PrMessage `
                -Token $Token
    
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Error: Failed to submit Pull Request review. Status code: 422"
        }
    }

    Context "Parameter Validation Failure Cases" {
        It "unit: Set-PullRequestReviewStatus fails with empty RepoName" {
            Set-PullRequestReviewStatus `
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
        
        It "unit: Set-PullRequestReviewStatus fails with empty OrgName" {
            Set-PullRequestReviewStatus `
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
        
        It "unit: Set-PullRequestReviewStatus fails with empty PrNumber" {
            Set-PullRequestReviewStatus `
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
        
        It "unit: Set-PullRequestReviewStatus throws exception if PrStatus is empty" {
            { Set-PullRequestReviewStatus `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -PrStatus "" `
                -PrMessage $PrMessage `
                -Token $Token
            } | Should -Throw
        }
        
        It "unit: Set-PullRequestReviewStatus throws exception if PrStatus is not valid" {
            { Set-PullRequestReviewStatus `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -PrStatus "INVALID" `
                -PrMessage $PrMessage `
                -Token $Token
            } | Should -Throw
        }
        
        It "unit: Set-PullRequestReviewStatus fails with empty PrMessage" {
            Set-PullRequestReviewStatus `
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
        
        It "unit: Set-PullRequestReviewStatus fails with empty Token" {
            Set-PullRequestReviewStatus `
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

    Context "Exception Failure Cases" {
        It "unit: Set-PullRequestReviewStatus fails with exception" {
            Mock Invoke-WebRequest { throw "API Error" }
    
            try {
                Set-PullRequestReviewStatus `
                    -RepoName $RepoName `
                    -OrgName $OrgName `
                    -PrNumber $PrNumber `
                    -PrStatus $PrStatus `
                    -PrMessage $PrMessage `
                    -Token $Token
            } catch {}
    
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Where-Object { $_ -match "^error-message=Error: Failed to merge pull request. Exception:" } |
				Should -Not -BeNullOrEmpty
                
            $output | Should -Contain "error-message=Error: Pull Request review failed. Exception:"
        }
    }    
}
