# Moodiki

Moodiki is a Flutter-based mental health platform that helps users track mood, access guided meditation, connect with experts, and receive AI-powered support.

## Highlights

- Multi-role authentication: User, Expert, Admin
- Mood tracking and streaks
- Meditation library with audio playback
- Expert discovery and appointment booking
- Real-time chat between users and experts
- AI chatbot support
- Community posts and comments
- In-app notifications
- English and Vietnamese localization

## Tech Stack

- Flutter (iOS, Android, Web)
- Supabase (Auth, PostgreSQL, Realtime, Storage)
- Provider (state management)
- Google Gemini API (AI chatbot)
- Node.js backend (payment integration)

## Project Structure

```text
lib/
  core/          # app constants, providers, shared config
  models/        # data models
  services/      # business logic + Supabase/API wrappers
  shared/        # reusable widgets/components
  views/         # feature screens
  l10n/          # localization files
backend/         # Node.js payment service
assets/          # static assets
test/            # unit/widget tests
```

## Prerequisites

- Flutter SDK (latest stable)
- Dart SDK (bundled with Flutter)
- Node.js (for backend service)
- Supabase project
- Gemini API key

## Quick Start

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Create environment file:

```bash
cp .env.example .env
```

3. Add required values to `.env`:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

4. Start backend service:

```bash
cd backend
npm install
npm run start
```

5. Run app:

```bash
flutter run
```

## Useful Commands

```bash
flutter pub get
flutter run
flutter test
flutter analyze
dart format lib/
```

## Environment Variables

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY`

Never commit real credentials to source control.

## Notes

- Keep `.env` private.
- Configure Supabase schema and RLS policies in your own environment.
- Payment backend credentials must be managed via environment variables.

## License

Private project. All rights reserved.
