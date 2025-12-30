# Contributing to GridTimer

Thank you for considering contributing to GridTimer!

## Development Setup

1. Fork and clone the repository
2. Run initialization script: `./tool/flutter-init.sh`
3. Add audio assets (see SETUP.md)
4. Run the app: `flutter run`

## Code Guidelines

### Language Requirements

- **All source code comments MUST be in English**
- Documentation can be bilingual (English + Chinese)
- UI text must use ARB localization files

### Architecture

This project follows Clean Architecture:

```
Domain Layer (lib/core/domain/)
  ↓
Data Layer (lib/data/)
  ↓
Infrastructure Layer (lib/infrastructure/)
  ↓
Presentation Layer (lib/presentation/)
```

**Rules:**
- Domain layer must be 100% Flutter-independent
- Use interfaces for all services
- All business logic goes in domain/infrastructure layers
- UI should be thin (delegate to services)

### Code Style

- Follow `analysis_options.yaml` rules
- Use `const` constructors where possible
- Prefer single quotes for strings
- Run `flutter analyze` before committing

### Commit Messages

Use conventional commits format:

```
feat: add timer pause functionality
fix: correct time calculation on resume
docs: update setup instructions
refactor: extract timer cell widget
test: add timer service tests
```

### Testing

- Write unit tests for domain logic
- Test on physical Android 14+ device
- Verify exact alarm permissions work correctly

### Pull Request Process

1. Create a feature branch
2. Make your changes
3. Run code generation if needed: `./tool/gen.sh`
4. Run tests: `flutter test`
5. Run analysis: `flutter analyze`
6. Commit with clear messages
7. Push and create PR

### What to Contribute

**Welcome contributions:**
- Bug fixes
- Performance improvements
- Accessibility enhancements
- Documentation improvements
- Translation improvements (ARB files)
- Unit/integration tests

**Discuss first (via issue):**
- New features
- Breaking changes
- Major refactoring
- UI/UX changes

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Questions?

Open an issue for discussion!


