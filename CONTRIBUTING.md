# Contributing to Claude Spec Workflow

Thank you for your interest in contributing! This project is an evolving methodology based on real-world usage, and we welcome improvements and feedback.

## Ways to Contribute

### 1. Report Issues
- Found a bug? [Open an issue](https://github.com/trakrf/claude-spec-workflow/issues)
- Have a feature request? Describe your use case
- Documentation unclear? Let us know what's confusing

### 2. Submit Pull Requests
- Fix bugs or typos
- Add new stack presets
- Improve documentation
- Enhance commands with better error handling

### 3. Share Your Experience
- How are you using the workflow?
- What works well? What doesn't?
- Share your custom presets or workflows

## Development Setup

### Prerequisites
- Git
- Bash (Git Bash on Windows, native on macOS/Linux)
- Claude Code installed

**Windows developers**: Use Git Bash or WSL2 for development and testing.

### Testing Your Changes

1. **Clone and test installation**
   ```bash
   git clone https://github.com/trakrf/claude-spec-workflow
   cd claude-spec-workflow
   ./install.sh
   ```

   **Windows**: Run in Git Bash or WSL2 terminal.

2. **Test with a sample project**
   ```bash
   mkdir /tmp/test-project
   cd /tmp/test-project
   git init

   # Initialize with spec workflow (includes stack preset)
   ~/claude-spec-workflow/init-project.sh . typescript-react-vite

   # Create a test spec
   mkdir -p spec/active/test-feature
   cp spec/template.md spec/active/test-feature/spec.md
   ```

3. **Test commands manually**
   - Edit the spec with a simple feature
   - Run `/plan spec/active/test-feature/spec.md`
   - Verify the plan is generated correctly
   - Test other commands as applicable

4. **After merging command changes**

   If you modify files in `commands/` (slash command prompts):

   ```bash
   # Re-run install to update global commands
   ./install.sh

   # Restart Claude Code to pick up changes
   # (Command palette > "Reload Window" or restart application)
   ```

   **Why**: Slash commands (`/plan`, `/build`, `/ship`, etc.) are installed globally in Claude's commands directory. Changes only take effect after reinstalling and restarting Claude Code.

See TESTING.md for comprehensive test procedures.

## Contribution Guidelines

### Code Style
- **Shell scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Markdown**: Use consistent formatting, clear headings
- **Commands**: Keep prompts clear, concise, and actionable

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add Rust stack preset
fix: correct symlink handling in install.sh
docs: clarify monorepo workspace detection
chore: update dependencies
```

### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Keep changes focused and atomic
   - Update documentation as needed
   - Add examples if introducing new features

4. **Test thoroughly**
   - Test on both Unix and Windows if applicable
   - Verify commands work end-to-end
   - Check for broken links in documentation

5. **Submit PR**
   - Provide clear description of changes
   - Link to related issues
   - Explain the "why" behind your changes

6. **Respond to feedback**
   - Address review comments
   - Be open to suggestions
   - Ask questions if anything is unclear

## Adding New Stack Presets

New presets are always welcome! Follow this structure:

1. **Create preset file**: `presets/your-stack-name.md`
2. **Include all sections**:
   - Project Type
   - Validation Commands
   - Code Quality Checks
   - Git Workflow
   - File Patterns
3. **Test with real project**: Verify all commands work
4. **Update README**: Add preset to "Available Presets" section
5. **Add example**: Consider adding an example spec

## Documentation Improvements

Documentation is critical for this project:
- **Clarity**: Use simple, direct language
- **Examples**: Show real-world usage
- **Completeness**: Cover edge cases and gotchas
- **Accuracy**: Keep in sync with code changes

## Questions?

- Open a discussion in [GitHub Issues](https://github.com/trakrf/claude-spec-workflow/issues)
- Check existing issues for similar questions
- Be patient - this is a community-driven project

## Code of Conduct

- Be respectful and constructive
- Focus on the work, not the person
- Welcome newcomers and different perspectives
- Assume good intentions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Claude Spec Workflow better! 🚀
