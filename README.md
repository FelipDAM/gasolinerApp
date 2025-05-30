1. Clona el repositorio:

```bash
git clone https://github.com/FelipDAM/gasolinerApp.git
```

2. Instala las dependencias:

```bash
flutter pub get
```

3. Crea un archivo `.env` en la raíz del proyecto y añade tu clave para las APIS de google maps:

```env
GOOGLE_MAPS_API_KEY=tu_clave_api
```
4. Crea un archivo `android/gradle.properties`:
```env
GOOGLE_MAPS_API_KEY=tu_clave_api
```

Asegúrate de tener en tu `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.6
  google_maps_flutter: ^2.10.1
  google_maps_webservice: ^0.0.20-nullsafety.5
  flutter_polyline_points: ^1.0.0
  geolocator: ^11.0.0
  google_place: ^0.4.7
  url_launcher: ^6.2.5
  flutter_dotenv: ^5.1.0
```

5. Ejecutar la aplicación desde el terminal.
 
```bash
flutter run
```
