# Gestimou Mobile App

This directory contains the structure for the Flutter mobile application.
Since the Flutter SDK is not installed in this environment, this serves as the blueprint.

## Architecture (Clean Architecture)

- **lib/data**: Repositories, API providers (calls to Admin Web API).
- **lib/domain**: Entities (User, Ticket, Reserve) and UseCases.
- **lib/presentation**: Widgets, Screens (Login, Dashboard, TicketList).

## Features

1. **Authentication**
   - Connects to `/api/auth/login`.
   - Stores JWT token securely.
   - Detects role: 'RESIDENT' or 'INTERVENANT'/'ADMIN'.

2. **Resident Mode**
   - **Home**: Overview of their property (Prestige, Bloc A...).
   - **Reserves**: Fetches from `/api/mobile/properties?email=user@email`.
     - Displays list of snag items (e.g. "Peinture Escalier").
     - Status indicators (Non traité / Traité).
   - **Tickets**: Can report issues in common areas via `/api/mobile/tickets`.

3. **Intervenant Mode**
   - **Dashboard**: List of assigned tickets.
   - **Actions**: Update ticket status (En cours -> Terminé).

## API Endpoints (Admin Web)

- `POST /api/auth/login`: Authenticate user.
- `GET /api/mobile/properties`: Get owner's properties and reserves.
- `GET /api/mobile/tickets`: List all tickets (for intervenant).
- `POST /api/mobile/tickets`: Create a new ticket.

## Deployment (VPS)

The backend (Admin Web) is Dockerized.
Run `docker-compose up -d` on the VPS.
Update the Flutter app `api_config.dart` to point to the VPS IP address.
