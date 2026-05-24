# Between Us

[简体中文](README.zh-CN.md)

Between Us is a private-first mobile app for two people in a relationship. The
goal is to build a shared space for everyday life, memories, plans, and small
personal tools that only need to work well for us.

## Project Goals

- Build a real mobile app, not a web wrapper.
- Keep the app focused on two-person private use.
- Start with a small, stable couple app foundation.
- Add features gradually based on real daily needs.
- Keep data ownership, privacy, and maintainability in mind from the beginning.

## Planned Tech Stack

- App: Flutter
- Backend: Supabase
- Database: PostgreSQL through Supabase
- Authentication: Supabase Auth
- Storage: Supabase Storage
- Target platform: Android first, iOS later

## First Prototype

The first prototype should prove the basic app foundation:

- Two users can sign in.
- The users can share one couple space.
- The home screen shows basic relationship information.
- A simple timeline or daily note can be created.
- A basic anniversary can be added and displayed.

## Future Modules

- Couple timeline
- Anniversaries
- Daily notes
- Wishlist
- Shared photo memories
- Home menu
- Reminders and notifications
- Personal profile and couple settings

## Development Roadmap

1. Create the Flutter project structure.
2. Define the app theme, routing, and feature module layout.
3. Implement local-only screens for the first prototype.
4. Connect Supabase authentication.
5. Add couple-space data model and access rules.
6. Implement sync for timeline, notes, and anniversaries.
7. Add the home menu module after the base app is stable.

## License

This project is licensed under the MIT License.
