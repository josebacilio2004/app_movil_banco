# Participación del Equipo - App Móvil Banco (Flutter + Firebase)

* **Sosa Porras Jhoan José**: Integró el estilo visual utilizando `google_fonts` y `font_awesome_flutter`, y diseñó la experiencia de usuario (UI/UX) implementando animaciones con `loading_animation_widget` en las pantallas principales.
* **Requena Lavi Aldo Alexandre**: Desarrolló e implementó las vistas clave en Flutter, abarcando `login_screen`, `register_screen`, el complejo `dashboard_screen` y los flujos específicos de `loan_screen` y `payment_screen`.
* **Bacilio De La Cruz José Anthony**: Implementó el manejo de estado global de la aplicación utilizando el paquete `provider` para conectar reactivamente los modelos de negocio (`cuenta`, `prestamo`, `transaccion`) con la interfaz.
* **Mendoza Alarcón Maylit**: Desarrolló `firestore_service.dart` implementando Cloud Firestore para la persistencia remota de datos (sin BD local), sincronizando saldos, historial de `transaccion_screen` y préstamos en tiempo real.
* **Celis Gutierrez Cristian Jesus**: Configuró el entorno de Firebase (`firebase_core`) y desarrolló `auth_service.dart` utilizando Firebase Auth para garantizar el inicio de sesión, registro y control de acceso seguro en la app.
