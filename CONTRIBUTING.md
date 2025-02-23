# Contributing to Islamic Knowledge & Guidance App

First off, thank you for considering contributing to our project! It's people like you that make this app a valuable resource for the Muslim community.

## Code of Conduct

By participating in this project, you agree to follow our Code of Conduct:

- Be respectful and inclusive
- Use welcoming and inclusive language
- Be supportive of others
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs 🐛

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- A clear and descriptive title
- Detailed steps to reproduce the issue
- Expected behavior vs actual behavior
- Screenshots if applicable
- Device information (OS, Flutter version, etc.)
- Any relevant logs or error messages

### Suggesting Enhancements ✨

We welcome suggestions for improvements! When suggesting an enhancement:

- Use a clear and descriptive title
- Provide a detailed description of the proposed feature
- Explain why this enhancement would be useful
- Include mock-ups or examples if possible

### Pull Requests 🚀

1. Fork the repository
2. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes:
   - Follow the coding style of the project
   - Add comments to explain complex logic
   - Update documentation as needed
   - Add tests if applicable

4. Commit your changes:
   ```bash
   git commit -m "feat: add your feature description"
   ```
   Please follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `style:` for formatting changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks

5. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

6. Open a Pull Request

### Development Setup

1. Install Flutter and Dart
2. Clone the repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Set up environment variables:
   - Create a `.env` file based on `.env.example`
   - Add required API keys

### Code Style Guidelines

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Keep functions focused and concise
- Add comments for complex logic
- Format code using `dart format`
- Run `flutter analyze` before committing

### Testing Guidelines

- Write unit tests for new features
- Update existing tests when modifying features
- Ensure all tests pass before submitting PR
- Aim for good test coverage

### Documentation Guidelines

- Update README.md if adding new features
- Document all public APIs
- Include inline comments for complex logic
- Update any relevant documentation files

### Working with Firebase and OpenAI

When working with Firebase or OpenAI features:
- Never commit API keys or sensitive credentials
- Use environment variables for sensitive data
- Test thoroughly in development environment
- Follow security best practices

### Islamic Content Guidelines

When contributing content:
- Ensure accuracy of Islamic information
- Provide references for Quranic verses and Hadiths
- Be respectful of different Islamic schools of thought
- Avoid controversial or disputed topics
- Focus on widely accepted interpretations

## Project Structure

Please maintain the existing project structure:
- `lib/screens/` for screen widgets
- `lib/widgets/` for reusable widgets
- `lib/services/` for business logic
- `lib/models/` for data models
- `assets/` for static assets

## Questions?

If you have any questions or need clarification:
- Check existing issues and discussions
- Open a new issue for discussion
- Contact the maintainers

## Review Process

Review Process
What to expect after submitting a PR:

Automated tests will run
One of our team members will review your code

Our small team of four members handles reviews collaboratively
We aim to review PRs within 1-2 business days
If no one responds within 3 days, feel free to ping the team in the PR comments

Changes may be requested

Please respond to code review comments within a reasonable time
If you disagree with any requested changes, feel free to discuss them in the PR thread

Once approved by at least one team member, your PR will be merged

The approving team member will handle the merge
If there are merge conflicts, you may be asked to rebase your branch

Note: As we are a small team, we appreciate your patience with the review process. We prioritize code quality and accuracy of Islamic content in our reviews.


Thank you for contributing! 🙏

---
Note: These guidelines may be updated. Please check back periodically for any changes.
