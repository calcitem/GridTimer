# Agent Guidelines

This document outlines the coding standards and conventions for AI agents working on this project.

## Code Comments

- All code comments MUST be written in **English**.

## Git Commit Messages

- All Git commit messages MUST be written in **English**.
- Git commit messages MUST be wrapped at 72 ASCII characters.
- **Do NOT include co-author information** (e.g., `Co-authored-by:`) in commit messages.

## Internationalization (i18n)

- All user-facing text in the UI MUST be internationalized.
- For Chinese localization, there MUST be exactly **one space** between Chinese characters and English words/numbers.
  - ✅ Correct: `这是一个 Flutter 应用`
  - ❌ Incorrect: `这是一个Flutter应用`

## Development Environment

- Use the `flutter-init.sh` script to set up the Flutter development environment.

## Before Committing

- **Resolve all lint issues** before committing code.
- Run `flutter analyze` to check for lint problems.
- Use `dart fix --apply` to automatically fix applicable issues.
