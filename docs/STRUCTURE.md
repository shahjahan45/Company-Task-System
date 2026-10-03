# Plain PHP architecture

The application uses direct PHP pages at the project root. Shared initialization, authentication, database access and layout code are under `includes/`. Form submissions use dedicated scripts under `handlers/`. JSON endpoints are under `api/`. There is no framework router and no public document-root indirection.
