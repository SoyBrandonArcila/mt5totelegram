//+------------------------------------------------------------------+
//| EA_TelegramOnTrade.mq5                                          |
//+------------------------------------------------------------------+
#property copyright "SoyBrandonArcila"
#property version   "2.00"

input string BotToken  = "123456789:ABCdef...";  // Token del bot
input string ChatID    = "@Sbmq5";               // Canal o chat_id
input int    BEPips    = 2;                      // Tolerancia (puntos) para detectar BREAK EVEN
input int    ChartW    = 1024;                   // Ancho de la captura
input int    ChartH    = 600;                    // Alto de la captura

//+------------------------------------------------------------------+
//| Tracking de posiciones                                           |
//+------------------------------------------------------------------+
struct PosInfo {
   ulong  ticket;
   string id;
   double sl;
   double tp;
   double open_price;
};
PosInfo posiciones[];
int     contador_id = 0;

int FindPos(ulong ticket) {
   for(int i = 0; i < ArraySize(posiciones); i++)
      if(posiciones[i].ticket == ticket) return i;
   return -1;
}

string AddPos(ulong ticket, double sl, double tp, double openP) {
   contador_id++;
   int n = ArraySize(posiciones);
   ArrayResize(posiciones, n + 1);
   posiciones[n].ticket     = ticket;
   posiciones[n].id         = StringFormat("POS-%03d", contador_id);
   posiciones[n].sl         = sl;
   posiciones[n].tp         = tp;
   posiciones[n].open_price = openP;
   return posiciones[n].id;
}

void RemovePos(int idx) {
   int n = ArraySize(posiciones);
   for(int i = idx; i < n - 1; i++) posiciones[i] = posiciones[i + 1];
   ArrayResize(posiciones, n - 1);
}

//+------------------------------------------------------------------+
//| Eventos                                                          |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest&     request,
                        const MqlTradeResult&      result) {

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      ulong dealTicket = trans.deal;
      if(!HistoryDealSelect(dealTicket)) return;
      long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN)                                   OnApertura(dealTicket);
      else if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY) OnCierre(dealTicket);
      return;
   }

   if(trans.type == TRADE_TRANSACTION_POSITION) {
      OnModificacion(trans.position);
      return;
   }
}

//+------------------------------------------------------------------+
void OnApertura(ulong dealTicket) {
   string  simbolo   = HistoryDealGetString (dealTicket, DEAL_SYMBOL);
   double  volumen   = HistoryDealGetDouble (dealTicket, DEAL_VOLUME);
   double  precio    = HistoryDealGetDouble (dealTicket, DEAL_PRICE);
   long    tipo_raw  = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   ulong   posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   long    magic     = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);

   double sl = 0, tp = 0;
   if(PositionSelectByTicket(posTicket)) {
      sl = PositionGetDouble(POSITION_SL);
      tp = PositionGetDouble(POSITION_TP);
   }

   string id = AddPos(posTicket, sl, tp, precio);

   int    digits = (int)SymbolInfoInteger(simbolo, SYMBOL_DIGITS);
   string tipo   = (tipo_raw == DEAL_TYPE_BUY) ? "🟢 BUY" : "🔴 SELL";

   string msg = "🆕 *APERTURA " + id + "*\n"
              + tipo + "  *" + simbolo + "*\n"
              + "📦 " + DoubleToString(volumen, 2) + " lotes\n"
              + "💰 Entrada: " + DoubleToString(precio, digits) + "\n";
   if(sl > 0)     msg += "🛑 SL: " + DoubleToString(sl, digits) + "\n";
   if(tp > 0)     msg += "🎯 TP: " + DoubleToString(tp, digits) + "\n";
   if(magic > 0)  msg += "🤖 Magic: " + IntegerToString(magic) + "\n";
   msg += "🎫 Ticket: " + (string)posTicket + "\n";
   msg += "⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   string foto = CapturarChart(simbolo, id + "_apertura");
   if(foto != "") EnviarTelegramFoto(foto, msg);
   else           EnviarTelegram(msg);
}

//+------------------------------------------------------------------+
void OnCierre(ulong dealTicket) {
   string  simbolo   = HistoryDealGetString (dealTicket, DEAL_SYMBOL);
   double  volumen   = HistoryDealGetDouble (dealTicket, DEAL_VOLUME);
   double  precio    = HistoryDealGetDouble (dealTicket, DEAL_PRICE);
   double  profit    = HistoryDealGetDouble (dealTicket, DEAL_PROFIT);
   double  comm      = HistoryDealGetDouble (dealTicket, DEAL_COMMISSION);
   double  swap      = HistoryDealGetDouble (dealTicket, DEAL_SWAP);
   ulong   posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   long    reason    = HistoryDealGetInteger(dealTicket, DEAL_REASON);

   int    idx = FindPos(posTicket);
   string id  = (idx >= 0) ? posiciones[idx].id : StringFormat("POS-#%I64u", posTicket);

   int    digits = (int)SymbolInfoInteger(simbolo, SYMBOL_DIGITS);
   double total  = profit + comm + swap;
   string emoji  = (total >= 0) ? "✅" : "❌";

   string razonStr;
   switch((int)reason) {
      case DEAL_REASON_SL:     razonStr = "🛑 Stop Loss";   break;
      case DEAL_REASON_TP:     razonStr = "🎯 Take Profit"; break;
      case DEAL_REASON_CLIENT: razonStr = "🖱 Manual";      break;
      case DEAL_REASON_EXPERT: razonStr = "🤖 EA";          break;
      case DEAL_REASON_SO:     razonStr = "⚠ Stop Out";    break;
      default:                 razonStr = "Otro";
   }

   string msg = "🏁 *CIERRE " + id + "*\n"
              + "📊 *" + simbolo + "*\n"
              + "💰 Cierre: "  + DoubleToString(precio, digits) + "\n"
              + "📦 " + DoubleToString(volumen, 2) + " lotes\n"
              + emoji + " P&L total: " + DoubleToString(total, 2) + "\n"
              + "   (profit " + DoubleToString(profit, 2)
              + " | swap "    + DoubleToString(swap, 2)
              + " | comm "    + DoubleToString(comm, 2) + ")\n"
              + "🔚 Motivo: " + razonStr + "\n"
              + "🎫 Ticket: " + (string)posTicket + "\n"
              + "⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   string foto = CapturarChart(simbolo, id + "_cierre");
   if(foto != "") EnviarTelegramFoto(foto, msg);
   else           EnviarTelegram(msg);

   if(idx >= 0) RemovePos(idx);
}

//+------------------------------------------------------------------+
void OnModificacion(ulong posTicket) {
   if(!PositionSelectByTicket(posTicket)) return;

   string simbolo = PositionGetString (POSITION_SYMBOL);
   double sl_now  = PositionGetDouble (POSITION_SL);
   double tp_now  = PositionGetDouble (POSITION_TP);
   double open_p  = PositionGetDouble (POSITION_PRICE_OPEN);
   long   tipo    = PositionGetInteger(POSITION_TYPE);
   int    digits  = (int)SymbolInfoInteger(simbolo, SYMBOL_DIGITS);
   double point   = SymbolInfoDouble(simbolo, SYMBOL_POINT);

   int idx = FindPos(posTicket);
   if(idx < 0) {
      // EA recién iniciado con posición existente — la registramos sin notificar
      AddPos(posTicket, sl_now, tp_now, open_p);
      return;
   }

   double sl_prev = posiciones[idx].sl;
   double tp_prev = posiciones[idx].tp;
   string id      = posiciones[idx].id;

   bool sl_change = (MathAbs(sl_now - sl_prev) >= point);
   bool tp_change = (MathAbs(tp_now - tp_prev) >= point);
   if(!sl_change && !tp_change) return;

   string cambios = "";

   if(sl_change) {
      double dist_to_entry = (sl_now > 0) ? MathAbs(sl_now - open_p) / point : 1e9;
      bool   esBE          = (sl_now > 0 && dist_to_entry <= BEPips);
      if(esBE)
         cambios += "🛡 *BREAK EVEN* — SL movido a la entrada\n"
                  + "   " + DoubleToString(sl_prev, digits)
                  + " → " + DoubleToString(sl_now, digits) + "\n";
      else if(sl_prev == 0 && sl_now > 0)
         cambios += "🛑 SL añadido: " + DoubleToString(sl_now, digits) + "\n";
      else if(sl_prev > 0 && sl_now == 0)
         cambios += "🛑 SL eliminado\n";
      else
         cambios += "🛑 SL: " + DoubleToString(sl_prev, digits)
                  + " → "    + DoubleToString(sl_now,  digits) + "\n";
   }

   if(tp_change) {
      if(tp_prev == 0 && tp_now > 0)
         cambios += "🎯 TP añadido: " + DoubleToString(tp_now, digits) + "\n";
      else if(tp_prev > 0 && tp_now == 0)
         cambios += "🎯 TP eliminado\n";
      else
         cambios += "🎯 TP: " + DoubleToString(tp_prev, digits)
                  + " → "    + DoubleToString(tp_now,  digits) + "\n";
   }

   string msg = "🔄 *ACTUALIZACION D POS " + id + "*\n"
              + "📊 *" + simbolo + "*  ("
              + (tipo == POSITION_TYPE_BUY ? "BUY" : "SELL") + ")\n"
              + cambios
              + "🎫 Ticket: " + (string)posTicket + "\n"
              + "⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   EnviarTelegram(msg);

   posiciones[idx].sl = sl_now;
   posiciones[idx].tp = tp_now;
}

//+------------------------------------------------------------------+
//| Captura de chart                                                 |
//+------------------------------------------------------------------+
string CapturarChart(string simbolo, string nombre) {
   long cid    = ChartFirst();
   long target = -1;
   while(cid != -1) {
      if(ChartSymbol(cid) == simbolo) { target = cid; break; }
      cid = ChartNext(cid);
   }
   bool abierto_aqui = false;
   if(target == -1) {
      target = ChartOpen(simbolo, PERIOD_CURRENT);
      if(target == 0) {
         Print("⚠ No se pudo abrir chart de ", simbolo, " err=", GetLastError());
         return "";
      }
      abierto_aqui = true;
      Sleep(700); // dar tiempo a cargar datos
   }
   ChartRedraw(target);

   string archivo = nombre + ".png";
   FileDelete(archivo);

   if(!ChartScreenShot(target, archivo, ChartW, ChartH, ALIGN_RIGHT)) {
      Print("⚠ ChartScreenShot falló err=", GetLastError());
      if(abierto_aqui) ChartClose(target);
      return "";
   }

   ulong deadline = GetTickCount() + 4000;
   bool listo = false;
   while(GetTickCount() < deadline) {
      int fh = FileOpen(archivo, FILE_READ|FILE_BIN);
      if(fh != INVALID_HANDLE) {
         ulong sz = FileSize(fh);
         FileClose(fh);
         if(sz > 200) { listo = true; break; }
      }
      Sleep(150);
   }

   if(abierto_aqui) ChartClose(target);

   if(!listo) {
      Print("⚠ Screenshot no se materializó a tiempo");
      return "";
   }
   return archivo;
}

//+------------------------------------------------------------------+
//| Envío Telegram: texto                                            |
//+------------------------------------------------------------------+
void EnviarTelegram(string mensaje) {
   string url   = "https://api.telegram.org/bot" + BotToken + "/sendMessage";
   string datos = "chat_id=" + ChatID +
                  "&text="   + UrlEncode(mensaje) +
                  "&parse_mode=Markdown";

   char post[];
   int  body_len = StringToCharArray(datos, post, 0, -1, CP_UTF8) - 1;
   ArrayResize(post, body_len);
   char res_arr[]; string headers;
   ResetLastError();

   int res = WebRequest("POST", url,
                        "Content-Type: application/x-www-form-urlencoded\r\n",
                        5000, post, res_arr, headers);

   if(res == -1) {
      int err = GetLastError();
      Print("❌ WebRequest falló. Error ", err,
            (err == 4014 ? " (URL no permitida — añade https://api.telegram.org en Tools→Options→Expert Advisors)" : ""));
      return;
   }
   if(res != 200) {
      Print("⚠ Telegram HTTP ", res, " — ", CharArrayToString(res_arr, 0, -1, CP_UTF8));
   }
}

//+------------------------------------------------------------------+
//| Envío Telegram: foto + caption (multipart/form-data)             |
//+------------------------------------------------------------------+
void EnviarTelegramFoto(string archivo, string caption) {
   int fh = FileOpen(archivo, FILE_READ|FILE_BIN);
   if(fh == INVALID_HANDLE) {
      Print("⚠ No se pudo leer ", archivo, " err=", GetLastError());
      EnviarTelegram(caption);
      return;
   }
   ulong size = FileSize(fh);
   char  img[];
   ArrayResize(img, (int)size);
   FileReadArray(fh, img, 0, (int)size);
   FileClose(fh);

   string boundary = "----MQL5Boundary" + (string)GetTickCount();
   string url      = "https://api.telegram.org/bot" + BotToken + "/sendPhoto";

   char body[];

   AppendStr(body, "--" + boundary + "\r\n");
   AppendStr(body, "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n");
   AppendStr(body, ChatID + "\r\n");

   AppendStr(body, "--" + boundary + "\r\n");
   AppendStr(body, "Content-Disposition: form-data; name=\"caption\"\r\n");
   AppendStr(body, "Content-Type: text/plain; charset=utf-8\r\n\r\n");
   AppendStr(body, caption + "\r\n");

   AppendStr(body, "--" + boundary + "\r\n");
   AppendStr(body, "Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n");
   AppendStr(body, "Markdown\r\n");

   AppendStr(body, "--" + boundary + "\r\n");
   AppendStr(body, "Content-Disposition: form-data; name=\"photo\"; filename=\"" + archivo + "\"\r\n");
   AppendStr(body, "Content-Type: image/png\r\n\r\n");
   AppendBytes(body, img);
   AppendStr(body, "\r\n--" + boundary + "--\r\n");

   string headers = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";
   char   resp[]; string resp_headers;
   ResetLastError();

   int res = WebRequest("POST", url, headers, 30000, body, resp, resp_headers);
   if(res == -1) {
      Print("❌ sendPhoto WebRequest falló err=", GetLastError(),
            " — fallback a texto");
      EnviarTelegram(caption);
      return;
   }
   if(res != 200) {
      Print("⚠ sendPhoto HTTP ", res, " — ", CharArrayToString(resp, 0, -1, CP_UTF8));
   }
}

//+------------------------------------------------------------------+
//| Utilidades                                                       |
//+------------------------------------------------------------------+
void AppendStr(char &dst[], string s) {
   char tmp[];
   int  n = StringToCharArray(s, tmp, 0, -1, CP_UTF8) - 1;
   if(n <= 0) return;
   int oldN = ArraySize(dst);
   ArrayResize(dst, oldN + n);
   ArrayCopy(dst, tmp, oldN, 0, n);
}

void AppendBytes(char &dst[], const char &src[]) {
   int srcN = ArraySize(src);
   if(srcN <= 0) return;
   int oldN = ArraySize(dst);
   ArrayResize(dst, oldN + srcN);
   ArrayCopy(dst, src, oldN, 0, srcN);
}

string UrlEncode(string texto) {
   uchar bytes[];
   int n = StringToCharArray(texto, bytes, 0, -1, CP_UTF8) - 1;
   string enc = "";
   for(int i = 0; i < n; i++) {
      uchar c = bytes[i];
      if((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||
          c=='-'||c=='_'||c=='.'||c=='~')
         enc += CharToString(c);
      else if(c == ' ')
         enc += "+";
      else
         enc += StringFormat("%%%02X", c);
   }
   return enc;
}

//+------------------------------------------------------------------+
int  OnInit()  { Print("EA Telegram v2 activo — tracking de posiciones ON"); return INIT_SUCCEEDED; }
void OnTick()  { }
