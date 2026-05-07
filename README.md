# Set Pull Request Review Status GitHub Action

This GitHub Action updates the review status of a pull request (approve, request changes, or comment) using the GitHub REST API.  
It is designed to be simple, composable, and independent of the local git state.

## Features

- Submits a review event (`APPROVE`, `REQUEST_CHANGES`, or `COMMENT`) to a pull request via the REST API.
- Allows you to specify a custom review message for the pull request.
- Fully supports GitHub Organizations and user-owned repositories.
- Outputs the result and error message (if any) for use in subsequent workflow steps.
- Designed for secure automation with the minimal required token permissions.

## Inputs

| Name         | Description                                                                                   | Required | Default |
|--------------|-----------------------------------------------------------------------------------------------|----------|---------|
| `pr-number`  | The number of the pull request whose review status is to be updated                           | Yes      |         |
| `repo-name`  | The name of the repository                                                                    | Yes      |         |
| `org-name`   | The name of the GitHub organization                                                           | Yes      |         |
| `pr-status`  | Type of review event: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`                              | Yes      |         |
| `pr-message` | The message body for the review comment                                                       | Yes      |         |
| `token`      | GitHub token with access to pull requests                                                     | Yes      |         |

## Outputs

| Name            | Description                                              |
|-----------------|----------------------------------------------------------|
| `result`        | Result of the review attempt (`success` or `failure`)    |
| `error-message` | Error message if the review status update fails          |

## Usage

Create a workflow file in your repository (e.g., `.github/workflows/set-review-status.yml`).  
**Ensure you pass all required inputs and use a valid token with PR write access.**

### Example Workflow

```yaml
name: Set Pull Request Review Status
on:
  workflow_dispatch:

jobs:
  review-pull-request:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Set Pull Request Review Status via API
        id: set-review
        uses: lee-lott-actions/set-pull-request-review-status@v1
        with:
          pr-number: '101'
          repo-name: ${{ github.event.repository.name }}
          org-name: ${{ github.repository_owner }}
          pr-status: 'APPROVE' # or 'REQUEST_CHANGES' or 'COMMENT'
          pr-message: 'Automated review submitted via workflow.'
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Output Review Result
        run: |
          echo "Review Result
