# 🧪 Guía de Testing - Sistema de Notificaciones

## Paso 1: Verificar Permisos

### En el Emulador/Dispositivo:
1. Ve a **Configuración** → **Aplicaciones** → **KitsuCode**
2. Toca en **Permisos**
3. Verifica que tengas:
   - ✅ **Notificaciones**: Permitido
   - ✅ **Alarmas y recordatorios**: Permitido (puede estar en "Permisos especiales")

### Si no aparece "Alarmas y recordatorios":
1. Ve a **Configuración** → **Aplicaciones** → **Acceso especial a aplicaciones**
2. Busca **Alarmas y recordatorios** o **Programar alarmas exactas**
3. Encuentra KitsuCode y **actívalo**

---

## Paso 2: Limpiar y Reconstruir

```bash
# Detén la app
# En PowerShell:
cd C:\Users\dxnie\KitsuCode

# Limpia el proyecto
flutter clean

# Obtén las dependencias
flutter pub get

# Ejecuta en modo debug
flutter run
```

---

## Paso 3: Usar el Botón de Diagnóstico

1. Abre la app
2. Ve a **Perfil/Configuración** → **Notificaciones** → **Recordatorio de Estudio**
3. Presiona el botón rojo **"Diagnosticar Notificaciones"**
4. **Revisa la consola de VS Code** (Debug Console)

### ¿Qué buscar en los logs?

#### ✅ **TODO BIEN:**
```
🔐 Permiso de alarmas exactas: ✅ CONCEDIDO
📋 Notificaciones pendientes: 1
  - ID: 0
    Título: ¡Hora de practicar!
```

#### ❌ **PROBLEMA - Sin Permiso:**
```
🔐 Permiso de alarmas exactas: ❌ DENEGADO
📋 Notificaciones pendientes: 0
```
**Solución:** Ve al Paso 1 y activa los permisos.

#### ❌ **PROBLEMA - Zona Horaria Incorrecta:**
```
🌍 Zona horaria actual: Etc/UTC
⏰ Hora actual (local): 2025-11-10 22:30:00  (debería ser tu hora local)
```
**Solución:** La zona horaria del emulador está mal. Puedes:
- Cambiar la zona horaria en Configuración del emulador
- O el código debería funcionar igual, solo que verás horas en UTC

---

## Paso 4: Programar una Notificación de Prueba

### Para Probar INMEDIATAMENTE (sin esperar horas):

1. **Mira la hora actual** en tu emulador (ej: 5:30 PM)
2. **Programa el recordatorio** para **2-3 minutos en el futuro** (ej: 5:32 PM)
3. **Activa el switch** de "Activar recordatorio"
4. **Revisa los logs en la consola:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 [NOTIFICACIÓN] Programando recordatorio de estudio...
⏰ Hora solicitada: 17:32
📍 Hora actual (zona local): 2025-11-10 17:30:00
⏱️ Tiempo hasta la notificación: 2 minutos  👈 VERIFICA ESTO
✅ [NOTIFICACIÓN] ¡Recordatorio programado exitosamente!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

5. **ESPERA 2-3 minutos** con la app en segundo plano o cerrada
6. **Deberías recibir la notificación** 🔔

---

## Paso 5: Troubleshooting

### Problema: "No tengo el botón de diagnóstico"
- **Causa:** No guardaste los cambios
- **Solución:** Presiona `Ctrl+S` en VS Code, luego recarga la app con `r` o `R` en la terminal

### Problema: "El switch se apaga solo"
- **Causa:** No tienes el permiso de "Alarmas y recordatorios"
- **Solución:** Ve al Paso 1, activa el permiso, reinicia la app

### Problema: "Programé la notificación pero nunca llegó"
1. **Presiona "Diagnosticar Notificaciones"**
2. **Revisa si hay notificaciones pendientes:**
   - Si dice `📋 Notificaciones pendientes: 0` → No se programó
   - Si dice `📋 Notificaciones pendientes: 1` → Sí se programó, espera más tiempo

3. **Revisa la zona horaria:**
   ```
   🌍 Zona horaria actual: America/Mexico_City  👈 ¿Es correcta?
   ⏰ Hora actual (local): 2025-11-10 17:30:00  👈 ¿Coincide con el emulador?
   ```

4. **Verifica el cálculo de tiempo:**
   ```
   📆 Fecha/hora programada: 2025-11-11 05:15:00
   ⏱️ Tiempo hasta la notificación: 705 minutos  👈 ¿Es correcto?
   ```

### Problema: "La hora en los logs es diferente a la del emulador"
- **Causa:** Tu emulador tiene zona horaria distinta a la del sistema
- **Solución:** Cambia la zona horaria del emulador:
  1. En el emulador: **Configuración** → **Sistema** → **Fecha y hora**
  2. Activa "Zona horaria automática" o selecciona tu zona manualmente
  3. Reinicia la app

---

## 🎯 Prueba Final: Notificación en 2 Minutos

**SCRIPT COMPLETO:**

1. Abre la app en el emulador
2. Ve a **Recordatorio de Estudio**
3. Mira la hora actual: **17:30**
4. Programa recordatorio para: **17:32** (2 minutos)
5. Activa el switch → ✅
6. Presiona botón **"Diagnosticar"**
7. Revisa la consola:
   ```
   ⏱️ Tiempo hasta la notificación: 2 minutos  ✅
   📋 Notificaciones pendientes: 1  ✅
   ```
8. **Sal de la app** (presiona botón home)
9. **ESPERA 2 minutos** ⏰
10. **¡DEBERÍA LLEGAR LA NOTIFICACIÓN!** 🔔

---

## 📊 Checklist de Diagnóstico

Marca cada item que funcione:

- [ ] Permisos concedidos (POST_NOTIFICATIONS)
- [ ] Permisos especiales concedidos (SCHEDULE_EXACT_ALARM)
- [ ] Botón de diagnóstico aparece
- [ ] Logs aparecen en la consola
- [ ] Zona horaria correcta en los logs
- [ ] `canScheduleExactAlarms()` retorna `true`
- [ ] Switch se mantiene activo al programar
- [ ] Notificaciones pendientes: 1 (después de programar)
- [ ] Cálculo de tiempo es correcto
- [ ] **¡NOTIFICACIÓN LLEGA!** 🎉

---

## 📞 Si Nada Funciona

1. **Copia y pega los logs completos de la consola** (desde que inicias la app hasta que programas)
2. **Toma screenshot de:**
   - Pantalla de permisos de la app
   - Pantalla de "Recordatorio de Estudio" con el switch activado
   - Los logs de diagnóstico en la consola
3. Revisa que el archivo `AndroidManifest.xml` tenga todos los permisos
