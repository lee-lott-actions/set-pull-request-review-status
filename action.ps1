function Set-Pull-Request-Review-Status {
  param(
    [string]$RepoName,
    [string]$OrgName,
    [string]$PrNumber,
    [ValidateSet("APPROVE", "REQUEST_CHANGES", "COMMENT")]
    [string]$PrStatus,
    [string]$PrMessage,
    [string]$Token
  )

  # Validate required inputs (except PrStatus, which is ValidateSet)
  if ([string]::IsNullOrEmpty($RepoName) -or 
      [string]::IsNullOrEmpty($OrgName) -or 
      [string]::IsNullOrEmpty($PrNumber) -or
      [string]::IsNullOrEmpty($PrStatus) -or
      [string]::IsNullOrEmpty($PrMessage) -or
      [string]::IsNullOrEmpty($Token)) 
  {
    Write-Output "Error: Missing required parameters"  
    Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: RepoName, OrgName, PrNumber, PrStatus, PrMessage, and Token must be provided."
    Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    return
  }
  
  $githubApiUrl = $env:MOCK_API
  if (-not $githubApiUrl) { $githubApiUrl = "https://api.github.com" }
  
  $uri = "$githubApiUrl/repos/$OrgName/$RepoName/pulls/$PrNumber/reviews"

  $headers = @{
    Authorization = "Bearer $Token"
    Accept = "application/vnd.github+json"
    "Content-Type" = "application/json"
    "X-GitHub-Api-Version" = "2026-03-10"
  }

  $body = @{
      event = $PrStatus
      body = $PrMessage
  } | ConvertTo-Json  

  try {
      Write-Host "Submitting Pull Request Review..."
      $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method POST -Body $body
      
      if ($response.StatusCode -eq 200) {
          "result=success" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          Write-Host "Review $PrStatus submitted for Pull Request #$PrNumber in $RepoName. Status: $($response.StatusCode)"
      } else {
          "result=failure" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          "error-message=Failed to submit Pull Request review.  Status code: $($response.StatusCode)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          Write-Host "Failed to submit Pull Request review. Status: $($response.StatusCode)"
      }      
  } catch {
    "result=failure" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "error-message=Pull Request review threw an exception and failed." | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    Write-Error "Failed to submit review: $_"      
  }
}
