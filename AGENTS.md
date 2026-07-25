# AGENTS.md — Agent instructions for this repository

Purpose: Help AI coding agents quickly understand and act on this Flutter repository.

Key links
- Project README: [README.md](README.md)
- Package manifest: [pubspec.yaml](pubspec.yaml)
- Lints/config: [analysis_options.yaml](analysis_options.yaml)

Quick commands (common tasks an agent may run)
- Install deps: `flutter pub get`
- Run tests: `flutter test`
- Run app (desktop/emulator): `flutter run -d <device>`

Repository layout (important folders)
- `lib/` — app source (primary change area)
- `android/`, `ios/`, `windows/`, `macos/`, `linux/`, `web/` — platform projects
- `test/` — unit/widget tests

Conventions and guidance for agents
- Link, don't embed: prefer linking to existing docs rather than copying them.
- Keep edits minimal and focused; run `flutter test` after behavioral changes.
- Respect `analysis_options.yaml` lints; see the file above for rules.

Agent configuration (as requested)

{
  "chatgpt.apiBase": "https://agentrouter.org/v1",
  "chatgpt.config": {
    "pepreferred_auth_method": "api_key",
    "model_provider": "openai-chat-completions"
  }
}

Notes
- If you need to perform builds for Android/iOS, check `android/local.properties` and platform toolchains; do not commit local machine secrets.
- Propose additional agent skills only when a repeatable workflow is identified (e.g., test-runner, format hook).

If you'd like, I can also create a `.github/copilot-instructions.md` variant or add small agent skills for test automation.
