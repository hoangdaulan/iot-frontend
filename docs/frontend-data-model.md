# Frontend Data Model

How business data is typed in the Flutter app, how it flows into state, and which backend endpoints it maps to. Sources of truth: `IoT-report.docx`, `model-specification.md`, and the backend in `../iot -backend` (its README documents the server side and the ESP32 MQTT contract).

**Scope: a single-device system.** There is exactly one ESP32 (`AppConstants.deviceId = 1`) with three sensors (temperature, humidity, light) and one LED. There's no device list, device selection, or device/sensor management.

```
UI / Widget  →  Cubit state  →  Repository (interface)  →  Typed model / DTO
                                     │
                 Api*Repository (Dio, the only implementations)
```

- **Models** (`lib/data/models/`): immutable `freezed` classes.
- **DTOs** (`lib/data/models/dto/`): request bodies, response envelopes and query parameters.
- **Repositories** (`lib/data/repositories/`): interfaces returning `Result<T>`. The `api/` subfolder holds the HTTP implementations.
- **HTTP**: `lib/data/remote/api_client.dart` (Dio + `AuthInterceptor` + Talker logging in debug) and `api_failure.dart` (error mapping).
- **Constants** (`lib/app/constants/app_constants.dart`): `deviceId = 1`, and `historyFetchSize = 5000` (see §7).
- **DI** (`lib/core/di/injection.dart`): registers the API repositories (auth, sensors, devices). There is no mock data in the app.

```sh
fvm flutter run -d chrome --dart-define=BASE_URL=http://localhost:8080   # backend URL (this is the default)
fvm dart run build_runner build --delete-conflicting-outputs             # after changing a model
```

---

## 1. Enum wire values

Matching is exact and case-sensitive. A "fallback" value is used only when parsing an unknown value and is never sent.

| Dart enum | Used in | Wire values | Fallback |
|---|---|---|---|
| `UserRole` | `User.role`, `UserSummary.role` | `ADMIN`, `USER` | `unknown` |
| `DeviceStatus` | `Device.status`, latest `deviceStatus`, history `status` | `ON`, `OFF` | `unknown` |
| `DeviceCommand` | command request and result `command` | `ON`, `OFF` | strict |
| `DeviceActionType` | `DeviceAction.action`, history `action` | `TURN_ON`, `TURN_OFF` | strict |
| `DeviceActionResult` | `DeviceAction.result`, history `result`, command result `status` | `SUCCESS`, `FAILED`, `TIMEOUT`, `PENDING` | `unknown` |
| `SensorType` | `Sensor.type`, sensor-data `data` keys, history `type` query | `temperature`, `humidity`, `light` | strict |

Two fields are not enums:
- **`Device.type`** is a `String`; the only device is the `LED`.
- **`Sensor.status`** is a `String?`, deliberately unresolved: the report defines no values, and the backend leaves it null.

---

## 2. Domain models

| Model | Fields |
|---|---|
| `User` | `id`, `username`, `email`, `role`, `name?`, `phone?`, `avatar?`, `github?`, `figma?`. No password. |
| `Device` | `id`, `name`, `type`, `status`, `mqttTopic?`, `createdAt?`, `updatedAt?` |
| `Sensor` | `id`, `name`, `type: SensorType`, `unit`, `status?`, `mqttTopic?`, `createdAt?`, `updatedAt?`. No `deviceId`; every sensor belongs to the one ESP32. |
| `SensorData` | `id`, `sensorId`, `value: double`, `timestamp` |
| `DeviceAction` | `id`, `deviceId`, `action`, `result`, `timestamp`, `userId?` |

Read models:
- `DeviceActionHistoryItem` is a history row: action + `deviceName`, `status?` (LED state after the action) and `message?`.
- `SensorReading` is the frontend projection used by tables and charts: `id`, `type`, `value`, `timestamp`, `sensorId?`.
- `SensorSeries` holds one type's readings in chronological order, with `latestValue` and `trend`.

The report's entity tables name the time column `time` and DeviceAction's outcome `status`. The APIs use `timestamp`, and use `result` for the outcome (`status` being the LED state), so the frontend follows the APIs.

---

## 3. Endpoints

All implemented by the backend. Everything except login and register needs `Authorization: Bearer <accessToken>`.

| Endpoint | Repository method | Request | Response |
|---|---|---|---|
| `POST /api/auth/login` | `AuthRepository.login` | `LoginRequest` | `LoginResponse` (`accessToken` + `UserSummary`) |
| `POST /api/auth/register` | `AuthRepository.register` | `RegisterRequest` | `RegisterResponse` (201) |
| `GET /api/auth/profile` | `AuthRepository.getProfile` | — | `User` |
| `PATCH /api/auth/profile` | `AuthRepository.updateProfile` | `UpdateProfileRequest` (changed fields only) | `User` |
| `PATCH /api/auth/password` | `AuthRepository.changePassword` | `ChangePasswordRequest` | 204 |
| `GET /api/sensors` | `SensorRepository.getSensors` | — | `List<Sensor>` |
| `GET /api/sensor-data/latest` | `SensorRepository.getLatestSensorData` | — | `LatestSensorDataResponse` |
| `GET /api/sensor-data/history` | `SensorRepository.getSensorHistory` | `SensorHistoryQuery` | `SensorHistoryResponse` |
| `POST /api/devices/1/command` | `DeviceRepository.sendCommand` | `DeviceCommandRequest` | `DeviceCommandResult` |
| `GET /api/devices/control-history` | `DeviceRepository.getControlHistory` | `DeviceHistoryQuery` | `PageResponse<DeviceActionHistoryItem>` |

There's no `GET /api/devices` and no device-scoped latest endpoint.

```jsonc
// GET /api/sensor-data/latest — one entry per type that has data, plus the LED status
{ "data": { "temperature": { "id": 3028, "value": 29.4, "unit": "°C", "timestamp": "2026-10-05T09:07:31.240029Z" },
            "humidity":    { "id": 3029, "value": 58.2, "unit": "%",  "timestamp": "..." },
            "light":       { "id": 3030, "value": 512,  "unit": "lux", "timestamp": "..." } },
  "deviceStatus": "OFF" }

// GET /api/sensor-data/history?type=temperature&timeRange=2026-08-14T00:00:00Z/..&value=26.5&page=0&size=20
{ "data": { "temperature": [ { "id": 101, "value": 26.5, "unit": "°C", "timestamp": "..." } ],
            "humidity": [], "light": [] },
  "page": 0, "pageSize": 20, "totalElements": 1, "totalPages": 1 }

// POST /api/devices/1/command  {"command": "ON"}
// 200 → SUCCESS or FAILED; 504 → TIMEOUT (same body shape)
{ "deviceId": 1, "command": "ON", "status": "SUCCESS", "message": "Device turned on successfully" }

// GET /api/devices/control-history?from=&to=&page=0&size=20
{ "content": [ { "id": 42, "deviceId": 1, "deviceName": "ESP32", "action": "TURN_ON", "status": "ON",
                 "result": "SUCCESS", "timestamp": "...", "message": "Device turned on successfully" } ],
  "page": 0, "size": 20, "totalElements": 42, "totalPages": 3 }
```

**Paging.** Both history endpoints are 0-based, with `size` between 1 and 5000 (default 20). For compatibility, sensor history keeps the report's grouped-by-type body. Its paging fields (`page`, `pageSize`, plus the added `totalElements`/`totalPages`) count individual measurements, newest first. `SensorHistoryResponse.toReadings()` flattens it.

**`timeRange`** is an ISO-8601 interval, `<from>/<to>`, with `..` for an open end.

---

## 4. HTTP errors → `Failure`

`guardRequest`/`failureFromDio` (`lib/data/remote/api_failure.dart`) turn every Dio error into `Failure(code: <HTTP status>, message: <backend "message">)`, with a default message per status when the body has none:

| Status | Example backend message | Where the app reacts |
|---|---|---|
| 400 | `Invalid request data`, `Old password is incorrect` | error snackbar |
| 401 | `Invalid email or password`, `Unauthorized` | login error; on authenticated requests `AuthInterceptor` signs out and clears the token; at startup the token is cleared |
| 403 | `You do not have permission` | error snackbar |
| 404 | `Device not found`, `User not found` | error snackbar |
| 409 | `Username or email already exists` | register error |
| 500 | `Internal server error` | error snackbar |
| 504 | `Device did not respond in time` | command: parsed as `DeviceCommandResult(status: TIMEOUT)`, a `Success`; the switch keeps its state and the message is shown |
| none | `Cannot reach the server…` / `…took too long…` | `code == null`; startup keeps the saved token |

---

## 5. Authentication

- **Token storage.** `SharedPreferencesLocalDataBase` (`localStorage` on web) stores only the access token. There are no refresh tokens: an expired token returns 401 and the user logs in again.
- **Login.** `POST login` → save the token → `GET profile` → signed in.
- **Logout** clears the token.
- **Startup** (`AuthCubit.init`): no token → login screen. Token present → `GET profile`, then: 200 → signed in; 401 → clear the token, go to login; network or server error → go to login with an error, keeping the token.
- **Register.** The Register tab calls `POST register`.

---

## 6. State mapping

| Cubit / state | Domain data | UI-only state |
|---|---|---|
| `AuthCubit` / `AuthState` | `User? user` | `isAuthenticated`, form `username`/`password`, `failure` |
| `AppCubit` / `AppState` | `User? user` | `appInfo`, `failure` |
| `DashboardCubit` / `DashboardState` | `Map<SensorType, SensorSeries> series` (today), `DeviceStatus ledStatus` | `isLoading`, `failure` |
| `SensorsCubit` / `SensorsState` | `PagedList<SensorReading>`, per-type `series` | filters, precision, search, `failure` |
| `ControlHistoryCubit` / `ControlHistoryState` | `PagedList<DeviceActionHistoryItem>` | action/result/date filters, search, `failure` |

**Dashboard.** Loading calls the last 24 hours of history (`from: now − 24 h`, `bucket: 5m`, so the backend returns 5-minute averages) plus `latest`, which supplies the LED status and the newest values. **Refresh** calls `latest` again and appends newer readings. The **LED switch** sends `ON`/`OFF` and changes only on `SUCCESS`; on `FAILED`, `TIMEOUT` or an error it keeps its state and shows the message. A second toggle is ignored while a command is in flight.

---

## 7. Test fakes

The app has no mock data and no mock mode: every screen reads from the backend. Tests use fakes kept out of `lib/`, in `test/helpers/`: `FakeAuthRepository`, `FakeSensorRepository` (24 hours of 5-minute averages) and `FakeDeviceRepository` (three LEDs and a 200-action history). The searches, filters and averaging themselves belong to the backend and are tested there.

---

## 8. Limitations

1. **Client-side history window.** Sensors and Control History fetch the newest `historyFetchSize` (5000) rows once, then filter, search, aggregate and paginate locally, because the API has no parameters for text search, action/result filters or time-bucket aggregation. Older rows beyond the window aren't shown. The dashboard's "today" charts use the same cap, which covers about 4.6 h if the ESP32 reports every 10 s.
2. **Latest is the latest persisted value.** The firmware has no on-demand read request, so Refresh shows the newest data the ESP32 has already published.
3. **Profile edits** have no Save action in the UI, so `updateProfile` is implemented but not called.
4. **Hardware.** The ESP32 firmware must implement the MQTT contract in the backend README. It has been exercised only with a simulated client, not real hardware.
