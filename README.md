# 📈 MT5 Telegram Trade Notifier — Notificaciones de Trading de MetaTrader 5 a Telegram con Screenshot

> **Expert Advisor open-source para MetaTrader 5 que envía notificaciones automáticas a un canal o chat de Telegram cada vez que se abre, modifica o cierra una posición — incluyendo captura de pantalla del gráfico, detección automática de Break Even, ID único por operación y cálculo de P&L.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MQL5](https://img.shields.io/badge/Language-MQL5-1f6feb.svg)](https://www.mql5.com/)
[![MetaTrader 5](https://img.shields.io/badge/Platform-MetaTrader%205-2962FF.svg)](https://www.metatrader5.com/)
[![Telegram Bot API](https://img.shields.io/badge/Telegram-Bot%20API-26A5E4?logo=telegram&logoColor=white)](https://core.telegram.org/bots)
[![Windows](https://img.shields.io/badge/OS-Windows-blue.svg)](#)
[![Free & Open Source](https://img.shields.io/badge/Free-Open%20Source-brightgreen.svg)](#)
[![Author](https://img.shields.io/badge/Instagram-%40soybrandonarcila-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/soybrandonarcila/)

---

## 🚀 ¿Qué es esto?

**MT5 Telegram Trade Notifier** es un **bot de Telegram para MetaTrader 5** escrito en **MQL5** que conecta tu cuenta de trading con un canal o chat privado de Telegram y notifica **en tiempo real cualquier evento** de tus operaciones: aperturas, modificaciones (Stop Loss, Take Profit, Break Even) y cierres, con **screenshot automático del gráfico**.

Es ideal para:

- 📡 **Vendedores de señales de trading** que quieren publicar operaciones automáticamente en un canal de Telegram.
- 👁 **Traders** que quieren llevar **diario de operaciones** sin esfuerzo.
- 👥 **Equipos de prop firms / fondos** que necesitan **transparencia y auditoría** de la actividad de trading.
- 🤖 **Desarrolladores MQL5** que buscan un ejemplo completo de **integración Telegram Bot API + WebRequest + multipart/form-data + ChartScreenShot**.

---

## 📑 Tabla de contenidos

- [Características](#-características)
- [Demo del mensaje](#-demo-del-mensaje-en-telegram)
- [Requisitos](#-requisitos)
- [Instalación rápida](#-instalación-rápida-3-minutos)
- [Configuración del bot de Telegram](#-configuración-del-bot-de-telegram)
- [Parámetros (Inputs)](#-parámetros-inputs)
- [Cómo funciona internamente](#-cómo-funciona-internamente)
- [Notas técnicas](#-notas-técnicas-mql5)
- [Preguntas frecuentes (FAQ)](#-preguntas-frecuentes-faq)
- [Seguridad](#-seguridad)
- [Autor](#-autor)
- [Licencia](#-licencia)
- [Keywords](#-keywords--palabras-clave)

---

## ✨ Características

- 🆕 **Apertura de posición** → mensaje detallado + screenshot del gráfico del símbolo
- 🔄 **Modificación de SL / TP** → mensaje `ACTUALIZACION D POS POS-XXX` con valores antes/después
- 🛡 **Detección automática de Break Even** cuando el SL se mueve a la entrada (±N puntos configurable)
- 🏁 **Cierre de posición** → P&L total (profit + swap + comisiones), motivo (Stop Loss / Take Profit / Manual / EA / Stop Out) + screenshot
- 🆔 **ID secuencial por posición** (`POS-001`, `POS-002`...) que agrupa visualmente todos los mensajes de la misma operación
- 🎫 **Ticket real de MT5** incluido en cada mensaje para trazabilidad permanente
- 🌐 **Soporte UTF-8 completo** — emojis, acentos y caracteres especiales se codifican correctamente
- 📦 **Cero dependencias externas** — usa únicamente `WebRequest` nativo de MT5, sin DLLs
- 🛟 **Fallback automático** — si la captura de pantalla falla, envía igualmente el mensaje de texto
- 🆓 **Código abierto, gratis y modificable** — licencia MIT

---

## 📱 Demo del mensaje en Telegram

```
🆕 APERTURA POS-001
🟢 BUY  EURUSD
📦 0.10 lotes
💰 Entrada: 1.08542
🛑 SL: 1.08300
🎯 TP: 1.09000
🎫 Ticket: 123456789
⏰ 2026.05.23 14:30
[📷 Captura del gráfico EURUSD]
```

```
🔄 ACTUALIZACION D POS POS-001
📊 EURUSD  (BUY)
🛡 BREAK EVEN — SL movido a la entrada
   1.08300 → 1.08542
🎫 Ticket: 123456789
⏰ 2026.05.23 15:12
```

```
🏁 CIERRE POS-001
📊 EURUSD
💰 Cierre: 1.08920
📦 0.10 lotes
✅ P&L total: 37.80
   (profit 38.00 | swap -0.20 | comm 0.00)
🔚 Motivo: 🎯 Take Profit
🎫 Ticket: 123456789
⏰ 2026.05.23 17:45
[📷 Captura del gráfico EURUSD]
```

---

## ✅ Requisitos

- **MetaTrader 5** (Windows)
- Un **bot de Telegram** (gratis, créalo con [@BotFather](https://t.me/BotFather))
- Un **canal** o **chat** de Telegram donde el bot sea **administrador** con permiso para postear

---

## ⚡ Instalación rápida (3 minutos)

1. **Descarga** [`tlegram.mq5`](tlegram.mq5) y cópialo a `MQL5/Experts/` (o cualquier subcarpeta dentro de Experts).
2. **Compila** con **F7** en MetaEditor.
3. En MT5: **Tools → Options → Expert Advisors** → marca ✅ `Allow WebRequest for listed URL` y añade:
   ```
   https://api.telegram.org
   ```
4. **Arrastra el EA** a cualquier gráfico (recomendado uno que no cierres frecuentemente).
5. En la ventana de inputs, configura `BotToken` y `ChatID` (ver siguiente sección).

---

## 🤖 Configuración del bot de Telegram

1. Abre Telegram y habla con [@BotFather](https://t.me/BotFather).
2. `/newbot` → elige nombre y username → copia el **token** que te da (ej: `12345:AAH...`).
3. Crea un canal en Telegram (o usa uno existente).
4. Ve a la configuración del canal → **Administrators** → **Add Administrator** → busca tu bot → dale al menos permiso **Post Messages**.
5. En MT5, al adjuntar el EA, configura:
   - `BotToken` → el token de BotFather
   - `ChatID` → el username del canal con `@` (`@micanal`) o el chat_id numérico (`-1001234567890`) para canales privados sin username

---

## ⚙️ Parámetros (Inputs)

| Input      | Default              | Descripción                                                                 |
|------------|----------------------|-----------------------------------------------------------------------------|
| `BotToken` | `123456789:ABCdef...`| Token del bot obtenido de [@BotFather](https://t.me/BotFather)              |
| `ChatID`   | `@mi_canal`          | Destino: `@username` del canal público o `chat_id` numérico (chats privados)|
| `BEPips`   | `2`                  | Tolerancia en puntos para considerar que el SL fue movido a Break Even      |
| `ChartW`   | `1024`               | Ancho en píxeles de la captura del gráfico                                  |
| `ChartH`   | `600`                | Alto en píxeles de la captura del gráfico                                   |

---

## 🛠 Cómo funciona internamente

El EA se engancha al callback nativo de MT5 `OnTradeTransaction()` y distingue tres tipos de eventos del servidor de trading:

| Evento MT5                                       | Acción                                       |
|--------------------------------------------------|----------------------------------------------|
| `TRADE_TRANSACTION_DEAL_ADD` + `DEAL_ENTRY_IN`   | 🆕 Apertura → mensaje + screenshot           |
| `TRADE_TRANSACTION_DEAL_ADD` + `DEAL_ENTRY_OUT`  | 🏁 Cierre → mensaje + screenshot             |
| `TRADE_TRANSACTION_POSITION`                     | 🔄 Modificación SL/TP → solo mensaje         |

Para las capturas, busca un chart abierto del símbolo de la posición. Si no existe, abre uno temporal en `PERIOD_CURRENT`, espera hasta 4 segundos a que `ChartScreenShot()` materialice el PNG en `MQL5/Files/`, lo envía a Telegram con `sendPhoto` (multipart/form-data construido a mano) y cierra el chart temporal si lo había abierto.

---

## 🔬 Notas técnicas (MQL5)

- **UTF-8**: la función `UrlEncode` convierte cada texto a bytes UTF-8 manualmente vía `StringToCharArray(..., CP_UTF8)`. Esto es **crítico** porque el comportamiento por defecto usa el codepage ANSI local y rompe los emojis y caracteres acentuados (Telegram exige UTF-8 estricto).
- **Multipart/form-data**: el envío de fotos no usa librerías externas — se construye el body byte a byte con boundary, `Content-Disposition`, `Content-Type` y los bytes binarios del PNG concatenados.
- **Tracking de posiciones**: array interno `posiciones[]` con `{ticket, id, sl, tp, open_price}`. Si el EA se reinicia con posiciones abiertas, la primera modificación las re-registra silenciosamente sin generar notificación falsa.
- **Fallback robusto**: cualquier fallo en captura o `sendPhoto` cae al envío de texto plano vía `sendMessage` — ninguna operación se queda sin notificar.
- **Detección de Break Even**: si el SL nuevo cae a `±BEPips` del precio de apertura, el mensaje cambia a `🛡 BREAK EVEN — SL movido a la entrada` en lugar de la actualización genérica.

---

## ❓ Preguntas frecuentes (FAQ)

### ¿Funciona con MetaTrader 4 (MT4)?
No. Este EA está escrito en **MQL5** específicamente para **MetaTrader 5**. Para MT4 habría que reescribir significativamente.

### ¿Funciona con cuentas demo y reales?
Sí, ambas. El EA es agnóstico al tipo de cuenta.

### ¿Funciona con cualquier broker?
Sí, mientras MT5 te permita ejecutar Expert Advisors y `WebRequest`. La mayoría de brokers serios lo permiten.

### ¿Cuánta latencia tiene la notificación?
La notificación se dispara inmediatamente al recibir el evento de MT5. La latencia depende del API de Telegram (~200-800 ms típicamente). Para capturas con `sendPhoto` puede ser ~1-3 segundos.

### ¿Puedo enviar a varios canales a la vez?
La versión actual envía a un único `ChatID`. Para varios canales, se puede modificar `EnviarTelegram()` para iterar sobre una lista.

### ¿Notifica trades hechos manualmente desde el celular o WebTrader?
**Sí**, porque el EA escucha eventos de la cuenta vía `OnTradeTransaction()`, no eventos del propio EA. Cualquier trade ejecutado en la cuenta — sea desde MT5 desktop, MT5 mobile, WebTrader, otro EA, o un copytrader — es notificado.

### ¿Notifica trades de cuentas copiadas (signal copier / MT5 Signals)?
Sí. Cualquier deal que aparezca en la cuenta dispara el evento.

### ¿Consume muchos recursos?
Mínimos. El EA solo se activa con eventos puntuales (no hace cálculos por tick). Las capturas momentáneamente abren un chart, pero se cierra inmediatamente.

### ¿Lo puedo usar en mi servicio de señales pagado?
Sí, la licencia MIT lo permite. Si quieres dar atribución, hazla a **THE TRADING API LLC** (opcional).

---

## 🔐 Seguridad

- **NUNCA** commitees tu token real al repo. El código por defecto trae un placeholder; el token real lo configuras al adjuntar el EA al gráfico (los inputs no se guardan en el código fuente).
- Si tu token se filtra accidentalmente, revócalo de inmediato en [@BotFather](https://t.me/BotFather) → `/mybots` → tu bot → **Revoke current token**.
- Mantén tu bot **solo en canales/chats donde necesitas que postee**. Un token comprometido permite a cualquiera enviar mensajes como tu bot a todos los chats donde sea miembro.

---

## 👤 Autor

**Brandon Arcila**

[![Instagram](https://img.shields.io/badge/Instagram-%40soybrandonarcila-E4405F?logo=instagram&logoColor=white&style=for-the-badge)](https://www.instagram.com/soybrandonarcila/)

Sígueme en Instagram: **[@soybrandonarcila](https://www.instagram.com/soybrandonarcila/)**

---

## 📄 Licencia

Software **libre, abierto y gratuito** bajo licencia **MIT**.

Puedes usarlo, modificarlo y redistribuirlo sin restricciones — incluso comercialmente. Si lo usas y quieres dar atribución (opcional pero apreciado), hazlo a:

> **THE TRADING API LLC**

Ver [`LICENSE`](LICENSE) para los términos completos.

---

## 🔎 Keywords / Palabras clave

`MT5 Telegram` · `MetaTrader 5 Telegram` · `MQL5 Telegram bot` · `Telegram trading notifications` · `MT5 trade alerts` · `Expert Advisor Telegram` · `EA Telegram MQL5` · `MT5 send screenshot Telegram` · `Telegram Bot API MQL5` · `Trading signals Telegram` · `Forex notifications Telegram` · `MetaTrader Telegram integration` · `Bot trading Telegram` · `Notificaciones trading Telegram` · `Alertas MT5 Telegram` · `Señales forex Telegram` · `Notificador operaciones MetaTrader` · `Diario de trading automático` · `Auditoría trading prop firm` · `WebRequest MQL5 Telegram` · `sendPhoto MQL5` · `ChartScreenShot Telegram` · `Break Even detection MT5` · `MT5 OnTradeTransaction` · `Copy trading Telegram` · `Trade journal MT5 Telegram` · `Open source Expert Advisor`

---

⭐ Si este proyecto te resulta útil, dale una **estrella** al repo en GitHub. Eso ayuda a que más traders lo encuentren.
