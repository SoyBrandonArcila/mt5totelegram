# MT5 Telegram Trade Notifier

Expert Advisor para **MetaTrader 5** que notifica en tiempo real a un canal o chat de Telegram cada vez que se **abre**, **modifica** o **cierra** una posición — incluyendo **captura de pantalla del gráfico** en la apertura y el cierre.

## Características

- 🆕 **Apertura de posición** → mensaje + screenshot del símbolo
- 🔄 **Modificación de SL/TP** → mensaje `ACTUALIZACION D POS POS-XXX` (sin captura)
- 🛡 **Detección automática de Break Even** (cuando el SL se mueve a ±N puntos del precio de entrada)
- 🏁 **Cierre de posición** → mensaje con P&L, motivo (SL/TP/manual/EA/Stop Out) + screenshot
- 🆔 **ID secuencial por posición** (`POS-001`, `POS-002`...) para agrupar visualmente los mensajes de una misma operación
- 🎫 **Ticket real de MT5** incluido en cada mensaje para trazabilidad
- 📦 No requiere DLLs externas — usa `WebRequest` nativo de MT5

## Requisitos

- MetaTrader 5
- Un bot de Telegram (crear con [@BotFather](https://t.me/BotFather))
- Un canal o chat donde el bot sea **administrador** con permiso para postear mensajes

## Instalación

1. Copia `tlegram.mq5` a tu carpeta `MQL5/Experts/` (o cualquier subcarpeta).
2. Abre MetaEditor (F4 en MT5) y compila con **F7**.
3. En MT5: **Tools → Options → Expert Advisors** → marca ✅ **Allow WebRequest for listed URL** y añade:
   ```
   https://api.telegram.org
   ```
4. Arrastra el EA al gráfico de cualquier símbolo (recomendado: el gráfico que más uses).

## Configuración del bot de Telegram

1. Habla con [@BotFather](https://t.me/BotFather) en Telegram y crea un bot con `/newbot`. Te dará un **token**.
2. Crea un canal (o usa uno existente) y añade tu bot como **administrador** con permiso de "Post Messages".
3. En los inputs del EA al adjuntarlo:
   - `BotToken` → el token que te dio BotFather (`12345:AAHxxx...`)
   - `ChatID`   → el username del canal con `@` delante (`@mi_canal`) o el chat_id numérico para chats privados

## Inputs

| Input      | Default          | Descripción                                                  |
|------------|------------------|--------------------------------------------------------------|
| `BotToken` | `123456789:...`  | Token del bot (obtenido de BotFather)                         |
| `ChatID`   | `@mi_canal`      | Canal/chat destino (`@username` o ID numérico)                |
| `BEPips`   | `2`              | Tolerancia en puntos para detectar BREAK EVEN                  |
| `ChartW`   | `1024`           | Ancho de la captura de pantalla                                |
| `ChartH`   | `600`            | Alto de la captura de pantalla                                 |

## Cómo funciona

El EA se engancha al evento `OnTradeTransaction()` y diferencia tres tipos de cambio:

| Evento MT5                                  | Acción                                       |
|---------------------------------------------|----------------------------------------------|
| `TRADE_TRANSACTION_DEAL_ADD` + `DEAL_ENTRY_IN`     | 🆕 Apertura — mensaje + screenshot           |
| `TRADE_TRANSACTION_DEAL_ADD` + `DEAL_ENTRY_OUT`    | 🏁 Cierre — mensaje + screenshot             |
| `TRADE_TRANSACTION_POSITION`                       | 🔄 Modificación SL/TP — mensaje (sin foto)   |

Las capturas se generan abriendo (si es necesario) un chart temporal del símbolo de la posición, esperando hasta 4 segundos a que el PNG se materialice, y enviándolo a Telegram con `sendPhoto` (multipart/form-data construido manualmente).

## Notas técnicas

- **UTF-8**: la conversión a bytes UTF-8 está implementada manualmente porque `StringToCharArray` por defecto usa el codepage local (ANSI). Los emojis y caracteres acentuados se codifican byte a byte en `UrlEncode`.
- **Tracking de posiciones**: array interno `posiciones[]` mantenido en memoria del EA. Si el EA se reinicia con posiciones abiertas, la primera modificación las re-registra silenciosamente.
- **Fallback**: si la captura de pantalla falla, el EA envía solo el texto del mensaje — nunca se queda una operación sin notificación.

## Seguridad

- **Nunca commitees tu token real**. Por defecto el código tiene un placeholder; el token lo configuras al adjuntar el EA al gráfico.
- Si tu token queda expuesto, revócalo en [@BotFather](https://t.me/BotFather) → `/mybots` → tu bot → **Revoke current token**.

## Licencia

MIT.
