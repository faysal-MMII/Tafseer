# Contributing to Tafseer

## Development Process
1. Create a feature branch from `dev` with the format `feature/short-description`
2. Make your changes and commit them with descriptive messages
3. Push your branch and create a pull request to the `dev` branch
4. Ensure all CI checks pass
5. Wait for code review and approval before merging

## Commit Message Guidelines
- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

## Pull Request Process
1. Update the README.md or documentation with details of changes where appropriate
2. The PR must pass all CI checks before being merged
3. The PR requires at least one approval from a maintainer
4. Once approved, the author or a maintainer can merge the PR

## CI/CD Pipeline
Our CI/CD pipeline automatically:
1. Runs code analysis and tests on all PRs to dev
2. Builds a debug APK for testing
3. Stores build artifacts for 5 days
