# MyIoT Frontend Data Model Specification

## 1. System overview

MyIoT is an IoT environmental monitoring and remote device control system.

Main technologies:

- Flutter Web frontend
- Golang + Gin backend
- PostgreSQL
- MQTT
- ESP32 / ESP8266

Main application features:

1. Authentication
2. User profile
3. Environmental sensor monitoring
4. Sensor history
5. Device control
6. Device control history

**Scope: single device.** The system has exactly one ESP32 (`devices.id = 1`, name `ESP32`, type `LED`), three sensors (temperature, humidity, light) and one LED. There's no device or sensor management (no CRUD), no device selection, and no admin user management.

---

# 2. Core domain entities

The system contains five principal domain entities:

- User
- Device
- Sensor
- SensorData
- DeviceAction

Relationships:

User
1 → N
DeviceAction

Device
1 → N
DeviceAction

Sensor
1 → N
SensorData

Model rules:

- **Sensor** is sensor metadata.
- **SensorData** is one measurement at one timestamp.
- **Device** is a controllable IoT device.
- **DeviceAction** is one control operation (history entity).
- **DeviceActionHistoryItem** is the joined read model returned by the control-history API.
- Domain models never contain UI types (IconData, Color, Widget, BuildContext).

---

# 3. User

Represents an application user.

Fields:

| Field | Dart type | Notes |
|---|---|---|
| id | int | unique identifier |
| name | String? | full name |
| email | String | unique email |
| username | String | unique username |
| phone | String? | phone number |
| avatar | String? | avatar URL/path |
| github | String? | GitHub URL |
| figma | String? | Figma URL |
| role | UserRole | ADMIN / USER |

Password is NOT part of the User domain model.

Password should only appear in request DTOs.

### UserRole

| Dart | Wire value |
|---|---|
| admin | `ADMIN` |
| user | `USER` |
| unknown | parsing fallback only, never sent |

Possible backend JSON:

```json
{
  "id": 1,
  "name": "Nguyen Van A",
  "username": "nguyenvana",
  "email": "a@gmail.com",
  "phone": "0912345678",
  "avatar": "/uploads/avatar/1.jpg",
  "github": "https://github.com/nguyenvana",
  "figma": "https://figma.com/@nguyenvana",
  "role": "USER"
}
```

### UserSummary

The login and register responses embed a partial user: `id`, `username`, `name?`, `role`, with no email. The frontend parses it as `UserSummary`. The full `User` always comes from `GET /api/auth/profile`.

---

# 4. Device

| Field | Dart type | Notes |
|---|---|---|
| id | int | always `1` |
| name | String | `ESP32` |
| type | String | `LED`; kept as a String, not an enum |
| status | DeviceStatus | `ON` / `OFF`; unknown values parse as `unknown` |
| mqttTopic | String? | |
| createdAt | DateTime? | |
| updatedAt | DateTime? | |

Exactly one row, created by the backend migration. `temperature`, `humidity` and `light` are **sensor** types, not device types. The frontend uses `AppConstants.deviceId = 1` and never lists devices.

---

# 5. Sensor

| Field | Dart type | Notes |
|---|---|---|
| id | int | |
| name | String | |
| type | SensorType | `temperature` / `humidity` / `light` |
| unit | String | `°C`, `%`, `lux` |
| status | String? | **intentionally unresolved**: the report defines no values; the backend leaves it null |
| mqttTopic | String? | |
| createdAt | DateTime? | |
| updatedAt | DateTime? | |

### SensorType

| Dart | Wire value | Unit |
|---|---|---|
| temperature | `temperature` | °C |
| humidity | `humidity` | % |
| light | `light` | lux |

SensorType is strict: unknown values are rejected.

---

# 6. SensorData

| Field | Dart type | Notes |
|---|---|---|
| id | int | |
| sensorId | int | → Sensor.id |
| value | double | accepts integer or decimal JSON numbers |
| timestamp | DateTime | the report's entity table calls it `time`; APIs use `timestamp` |

---

# 7. DeviceAction

| Field | Dart type | Notes |
|---|---|---|
| id | int | |
| deviceId | int | → Device.id |
| userId | int? | → User.id |
| action | DeviceActionType | `TURN_ON` / `TURN_OFF` |
| result | DeviceActionResult | `SUCCESS` / `FAILED` / `TIMEOUT` / `PENDING` |
| timestamp | DateTime | the report's entity table calls it `time` |

The report's entity table calls the outcome `status`. The API payloads use `result` for the outcome and `status` for the device's resulting ON/OFF state, and the frontend follows the API.

### DeviceCommand (command request/response)

`ON`, `OFF`

### DeviceActionType (history action)

`TURN_ON`, `TURN_OFF`

### DeviceActionResult

`SUCCESS`, `FAILED`, `TIMEOUT`, `PENDING`. Unknown values parse as `unknown`.

---

# 8. API contracts

## 8.1 Documented in the report

### POST /api/auth/login

Request: `{ "username": "admin", "password": "123456" }`

200: `{ "accessToken": "...", "user": { "id": 1, "username": "admin", "name": "Administrator", "role": "ADMIN" } }`

Errors: 400, 401 (`Invalid email or password`), 500, each with a `{"message": "..."}` body.

### POST /api/auth/register

Request: `{ "username": "user01", "email": "user01@gmail.com", "password": "123456" }`

201: `{ "message": "Register successfully", "user": { "id": 2, "username": "Nguyen Van A", "role": "USER" } }`

Errors: 400, 409 (`Username or email already exists`), 500.

### GET /api/auth/profile

Header: `Authorization: Bearer <accessToken>`. 200 returns a `User`; errors are 401, 404 and 500.

### POST /api/devices/1/command

Request: `{ "command": "ON" }` or `{ "command": "OFF" }`

200: `{ "deviceId": 1, "command": "ON", "status": "SUCCESS", "message": "Device turned on successfully" }`

504: `{ "deviceId": 1, "command": "ON", "status": "TIMEOUT", "message": "Device did not respond in time" }`

Errors: 400 (`Invalid command`), 401, 404 (`Device not found` for any id other than 1), 500.

HTTP status: 200 for `SUCCESS` and `FAILED` (the device answered), 504 for `TIMEOUT`. The body is a `DeviceCommandResult` in all three cases.

The backend waits for the ESP32's MQTT response before answering. The frontend parses the body as `DeviceCommandResult` (`deviceId`, `command`, `status`, `message`) and changes the device switch only on `SUCCESS`. On `FAILED` or `TIMEOUT` it keeps the previous state and shows `message`.

### GET /api/devices/control-history

Query: `from`, `to`, `page` (0-based), `size`. `deviceId` is accepted for compatibility but unnecessary (there is one device), and the frontend doesn't send it.

```json
{
  "content": [
    {
      "id": 101,
      "deviceId": 1,
      "deviceName": "Đèn phòng khách",
      "action": "TURN_ON",
      "status": "ON",
      "result": "SUCCESS",
      "timestamp": "2026-08-19T14:30:05",
      "message": "Device turned on successfully"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

### GET /api/sensor-data/history

Query: `type`, `timeRange`, `value`, `page` (0-based), `size`. `timeRange` is an ISO-8601 interval, `<from>/<to>`, with `..` for an open end.

```json
{
  "data": {
    "temperature": [{ "id": 101, "value": 26.5, "unit": "°C", "timestamp": "2026-08-14T14:00:05" }],
    "humidity": [{ "id": 102, "value": 65.2, "unit": "%", "timestamp": "2026-08-14T14:00:05" }],
    "light": [{ "id": 103, "value": 420, "unit": "lux", "timestamp": "2026-08-14T14:00:05" }]
  },
  "page": 0,
  "pageSize": 20,
  "totalElements": 3,
  "totalPages": 1
}
```

**Compatibility decision:** the report's grouped-by-type body is kept, but paging follows the single convention used by control history: 0-based `page`, plus `totalElements` and `totalPages`. Paging counts individual measurements, newest first, across the requested types. Every type key is always present.

The frontend converts this grouped response into a flat list of readings.

## 8.2 Frontend-standardised contracts (not named in the report)

| Endpoint | Purpose | Response |
|---|---|---|
| `GET /api/sensors` | The three sensors | `Sensor[]` |
| `GET /api/sensor-data/latest` | Newest value per sensor and the LED status (dashboard load and Refresh) | see below |
| `PATCH /api/auth/profile` | Update profile fields (`name`, `phone`, `avatar`, `github`, `figma`; only changed fields are sent) | `User` |
| `PATCH /api/auth/password` | Change password: `{ "oldPassword", "newPassword" }`; a wrong old password is 400 | 204 |

There is **no** `GET /api/devices` and no device-scoped latest endpoint.

```json
{
  "data": {
    "temperature": { "id": 201, "value": 27.1, "unit": "°C", "timestamp": "2026-08-14T14:05:00Z" },
    "humidity": { "id": 202, "value": 63.4, "unit": "%", "timestamp": "2026-08-14T14:05:00Z" },
    "light": { "id": 203, "value": 512, "unit": "lux", "timestamp": "2026-08-14T14:05:00Z" }
  },
  "deviceStatus": "OFF"
}
```

`deviceStatus` is included because the report's Refresh flow shows the device status alongside the readings. The values are the latest ones persisted from MQTT, since the firmware has no on-demand read request.

Admin CRUD for devices, sensors and users is intentionally **not** defined.

## 8.3 MQTT (backend ↔ ESP32)

No firmware existed, so the backend defines the contract (topics configurable):

| Topic | Direction | Payload |
|---|---|---|
| `myiot/esp32/sensor-data` | ESP32 → backend | `{"temperature": 28.7, "humidity": 60.5, "light": 420}` (fields optional; optional RFC 3339 `"timestamp"`) |
| `myiot/esp32/device-control` | backend → ESP32 | `{"actionId": 42, "command": "ON"}` |
| `myiot/esp32/device-response` | ESP32 → backend | `{"actionId": 42, "status": "SUCCESS", "state": "ON", "message": "optional"}` |

---

# 9. JWT storage and startup flow

- After a successful login the frontend saves `accessToken` (Flutter Web: `localStorage` via `shared_preferences`, behind `LocalDataBase`). Passwords are never stored.
- Every request carries `Authorization: Bearer <accessToken>` while a token is saved.
- Logout removes the token. A 401 on a request that carried a token also removes it and returns to login.
- Tokens are HS256 JWTs (default lifetime 24 h). There are **no refresh tokens**: when the token expires, the backend answers 401 and the user logs in again.
- On startup:
  - no saved token → login screen, no API call;
  - token exists → `GET /api/auth/profile`:
    - 200 → restore the user and open the app;
    - 401 → clear the token and go to login;
    - other errors (network, 5xx) → stay on login and show the error, but **keep** the token so a temporary outage doesn't end the session.

---

# 10. Open questions

- Values of `Sensor.status` (intentionally unresolved).
- History screens filter a client-side window of the newest 5000 rows. Server-side search, action/result filters and time-bucket aggregation are not part of the API.
- The ESP32 firmware must implement the MQTT contract in §8.3. It has only been tested with a simulated client.
