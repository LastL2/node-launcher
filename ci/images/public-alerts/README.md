# Public Alerts

A simple alerting framework that leveraging thornode and midgard.

## Setup

**Environment Variables**
At the base of the project add a `.env` file with relevant webooks.

See `.example_env` for associated keys.

Load env vars before running.

```bash
source .env
```

## Run

from `public-alerts/`

```bash
go run cmd/alert/main.go
```

## Running Tests

run test

```bash
go test ./test
```

## Project Layout

### Monitors

Monitors are independent scripts that poll for info and trigger notifiers if conditions are met.

### Notifiers

Notifiers are simple interface to send messages to various platforms like discord and slack using webhooks.

### cmd/alert

This is the scheduler to specify how often Monitors should poll.
