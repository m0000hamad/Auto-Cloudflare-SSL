# DigiTrade — معماری

## اصل حاکم

> **یک منطق استراتژی، چند مسیر اجرا.**

بک‌تست، پیپر و لایو نباید سه پیاده‌سازی متفاوت از یک استراتژی باشند. اگر
شدند، نتیجهٔ بک‌تست هیچ ارزشی ندارد. استراتژی فقط `Candle` می‌گیرد و
`Signal` می‌دهد؛ اینکه آن سیگنال به سفارش واقعی تبدیل شود، پیام تلگرام شود،
یا فقط در جدول بک‌تست ثبت شود، تصمیم لایهٔ بالاتر است.

---

## لایه‌ها

```
┌──────────────────────────────────────────────────────────┐
│  کانال‌ها:  Web UI  │  Telegram Bot  │  Bale Bot         │
└───────────────┬──────────────────────────────────────────┘
                │  REST + WebSocket
┌───────────────▼──────────────────────────────────────────┐
│  API Layer (FastAPI)                                     │
│  auth · routers · WS broadcast · rate limiting           │
└───────────────┬──────────────────────────────────────────┘
                │
┌───────────────▼──────────────────────────────────────────┐
│  Orchestration                                           │
│  StrategyRunner · ModeResolver · RiskManager             │
└───┬───────────────────────────┬──────────────────────────┘
    │                           │
┌───▼─────────────┐   ┌─────────▼────────────┐
│  Engines        │   │  Execution           │
│  LiveEngine     │   │  OrderRouter         │
│  BacktestEngine │   │  PaperBroker         │
│                 │   │  PositionStateMachine│
└───┬─────────────┘   └─────────┬────────────┘
    │                           │
┌───▼───────────────────────────▼──────────────────────────┐
│  Market Data                                             │
│  Ingestor(WS) · Normalizer · CandleStore · Redis cache   │
└───────────────┬──────────────────────────────────────────┘
                │
┌───────────────▼──────────────────────────────────────────┐
│  Exchange Layer  —  ExchangeClient (ABC)                 │
│  CoinExClient          │          LBankClient            │
└──────────────────────────────────────────────────────────┘
```

**قانون جهت وابستگی:** لایه‌های بالا از پایین استفاده می‌کنند، هرگز برعکس.
لایهٔ صرافی نباید بداند استراتژی وجود دارد. استراتژی نباید بداند CoinEx وجود دارد.

---

## قراردادهای کلیدی (ABCها)

این چهار قرارداد ستون پروژه‌اند. قبل از نوشتن پیاده‌سازی‌ها، اول این‌ها را
قفل کن.

### `ExchangeClient`

```python
class ExchangeClient(ABC):
    name: str  # "coinex" | "lbank"

    # --- market data (public) ---
    async def fetch_symbols(self) -> list[SymbolInfo]: ...
    async def fetch_candles(self, symbol: Symbol, tf: Timeframe,
                            since: datetime | None, limit: int) -> list[Candle]: ...
    async def fetch_ticker(self, symbol: Symbol) -> Ticker: ...
    async def watch_candles(self, symbol: Symbol, tf: Timeframe) -> AsyncIterator[Candle]: ...
    async def watch_ticker(self, symbol: Symbol) -> AsyncIterator[Ticker]: ...

    # --- futures market data ---
    async def fetch_mark_price(self, symbol: Symbol) -> Decimal: ...
    async def fetch_funding_rate(self, symbol: Symbol) -> FundingRate: ...
    async def fetch_funding_history(self, symbol: Symbol,
                                    since: datetime) -> list[FundingRate]: ...
    async def watch_mark_price(self, symbol: Symbol) -> AsyncIterator[Decimal]: ...

    # --- trading (private) ---
    async def fetch_balance(self) -> Balance: ...
    async def place_order(self, req: OrderRequest) -> Order: ...
    async def cancel_order(self, symbol: Symbol, order_id: str) -> Order: ...
    async def fetch_order(self, symbol: Symbol, order_id: str) -> Order: ...
    async def fetch_open_orders(self, symbol: Symbol | None) -> list[Order]: ...

    # --- futures positions ---
    async def fetch_positions(self) -> list[ExchangePosition]: ...
    async def watch_positions(self) -> AsyncIterator[ExchangePosition]: ...
    async def set_leverage(self, symbol: Symbol, leverage: int) -> None: ...
    async def set_margin_mode(self, symbol: Symbol, mode: MarginMode) -> None: ...
```

نکات:
- ورودی/خروجی **همیشه** مدل داخلی خودمان است، نه دیکشنری خام صرافی.
  نگاشت داخل هر کلاینت انجام می‌شود.
- `watch_*` باید خودش reconnect و re-subscribe کند و این را لاگ بزند.
- خطاهای صرافی به سلسله‌مراتب خطای خودمان نگاشت شوند
  (`conventions.md#errors`) — نه اینکه خطای خام httpx به بالا نشت کند.

### `Strategy`

```python
class Strategy(ABC):
    params: StrategyParams

    def warmup_bars(self) -> int:
        """چند کندل قبل از اولین تصمیم لازم است (طولانی‌ترین دورهٔ اندیکاتور)"""

    def on_candle(self, ctx: StrategyContext) -> Signal | None:
        """فقط با کندل‌های بستهٔ گذشته تصمیم بگیر. بدون I/O. بدون شبکه."""
```

`on_candle` باید **خالص (pure)** باشد: نه دیتابیس، نه شبکه، نه `datetime.now()`.
زمان از `ctx.now` می‌آید. این تنها چیزی است که بک‌تست را قابل‌اعتماد می‌کند.

### `BotTransport`

```python
class BotTransport(ABC):
    name: str  # "telegram" | "bale"

    async def send_message(self, chat_id: str, text: str,
                           keyboard: Keyboard | None = None) -> MessageRef: ...
    async def edit_message(self, ref: MessageRef, text: str,
                           keyboard: Keyboard | None = None) -> None: ...
    async def answer_callback(self, callback_id: str, text: str | None) -> None: ...
    def updates(self) -> AsyncIterator[BotUpdate]: ...
```

### `Broker`

```python
class Broker(ABC):
    async def submit(self, req: OrderRequest) -> Order: ...
    async def cancel(self, order_id: str) -> Order: ...
```

سه پیاده‌سازی: `PaperBroker` (شبیه‌ساز، پیش‌فرض)، `LiveBroker` (روی
`ExchangeClient`)، `BacktestBroker` (داخل موتور بک‌تست).

---

## مدل داده {#data-model}

جدول‌های اصلی و ستون‌های مهمشان:

| جدول | نکات کلیدی |
|---|---|
| `exchanges` | `id`, `code` (`coinex`/`lbank`), `enabled` |
| `exchange_credentials` | `exchange_id`, `label`, `api_key_enc`, `api_secret_enc` (هر دو AES-GCM با master key)، `permissions`, `is_active`. **هرگز plaintext** |
| `symbols` | نماد **نرمال‌شده** (`BTC/USDT:USDT`) + `raw_symbol` هر صرافی + `market_type` (`futures`/`spot`) + `price_precision`, `amount_precision`, `min_notional`, **`contract_size`**, **`max_leverage`**, **`maint_margin_tiers`** (JSONB) |
| `candles` | `(exchange_id, symbol_id, timeframe, open_time)` کلید یکتا. قیمت‌ها `NUMERIC`، نه `float8` |
| **`funding_rates`** | `(exchange_id, symbol_id, funding_time)` یکتا + `rate`, `mark_price`. **بدون این جدول بک‌تست فیوچرز دروغ می‌گوید** |
| `strategies` | تعریف استراتژی + `params` به‌صورت JSONB + `code_version` |
| `strategy_runs` | هر بار اجرای زنده: مود، مقصد اجرا (paper/live)، **`leverage`**, **`margin_mode`**, وضعیت، زمان شروع/پایان |
| `signals` | خروجی استراتژی، مستقل از اینکه اجرا شده یا نه. `status`: `pending`/`approved`/`rejected`/`executed`/`expired` |
| `orders` | `client_order_id` یکتا (idempotency)، `exchange_order_id`, `status`, `filled_amount`, `avg_price`, `reduce_only`, `position_side` |
| `positions` | ماشین حالت (پایین). فیلدهای **اجباری** فیوچرز: `side`, `leverage`, `margin_mode`, `entry_price`, `mark_price`, `liquidation_price`, `initial_margin`, `maint_margin`, `unrealized_pnl`, `realized_pnl`, `funding_paid`, `contracts` |
| **`position_events`** | تاریخچهٔ تغییرات هر پوزیشن: افزایش/کاهش، پرداخت funding، تغییر اهرم، هشدار مارجین، لیکوئیدیشن. PnL نهایی از روی این ساخته می‌شود، نه از یک ستون قابل بازنویسی |
| `backtests` | پیکربندی + متریک‌های خلاصه + نرخ کارمزد/لغزش فرض‌شده + `code_version` |
| `backtest_trades` | تک‌تک معاملات شبیه‌سازی‌شده |
| `bot_users` | `platform` (`telegram`/`bale`), `platform_user_id`, `role`, `is_approved` |
| `audit_log` | **هر** عمل حساس: تغییر مود، رفتن به live، ارسال سفارش، لغو، چرخش کلید. با `actor` و `source` |

**قوانین:**
- همهٔ زمان‌ها `TIMESTAMPTZ` و در UTC. تبدیل به وقت محلی فقط در لایهٔ نمایش.
- همهٔ اعداد پولی `NUMERIC(38, 18)`.
- `candles` روی `open_time` پارتیشن یا حداقل ایندکس BRIN بگیرد؛ حجمش زیاد می‌شود.
- migration با `alembic`. هیچ تغییر اسکیمای دستی روی Neon بدون migration.
- **بازار اصلی `futures` است** (D9). فیلدهای اهرم/مارجین/لیکوئید اجباری‌اند،
  نه اختیاری. اسپات در فاز ۹ روی همین انتزاع می‌آید.
- هیچ نماد یا تایم‌فریمی در کد hardcode نشود؛ همه از `symbols` و پیکربندی
  watchlist می‌آیند (D12).
- **`mark_price` و `last_price` دو ستون جدا هستند و هرگز جای هم استفاده
  نمی‌شوند** (D19). لیکوئیدیشن و PnL شناور با mark، سیگنال با last.
- حجم پوزیشن در `contracts` نگه داشته می‌شود و تبدیل به واحد base فقط از
  طریق `symbols.contract_size`. بعضی صرافی‌ها قرارداد را در واحد ثابت
  (مثلاً ۱ قرارداد = ۰.۰۰۱ BTC) تعریف می‌کنند — این تبدیل نباید در کد
  استراتژی پخش شود.

---

## جریان یک سیگنال (مسیر کامل)

```
کندل بسته می‌شود (WS)
   → Normalizer → CandleStore (+ Redis)
   → StrategyRunner: strategy.on_candle(ctx)
   → Signal تولید می‌شود، در جدول signals ثبت می‌شود
   → RiskManager: بررسی سقف ریسک، حداکثر پوزیشن باز، دراودان روزانه
        رد شد؟ → signal.status = rejected، اعلان به ربات، پایان
   → ModeResolver: مود فعلی چیست؟
        ├── signal_only → اعلان به تلگرام/بله با دکمهٔ «تأیید/رد»
        │      کاربر تأیید کرد → ادامه به OrderRouter
        │      تایم‌اوت شد → status = expired
        ├── semi_auto  → اجرا، ولی اعلان قبل از اجرا
        └── full_auto  → مستقیم به OrderRouter
   → OrderRouter → Broker (paper یا live)
   → Order ثبت، PositionStateMachine به‌روز
   → اعلان نتیجه به همهٔ کانال‌ها + broadcast روی WS به UI
   → audit_log
```

جزئیات مودها: `modes.md`

---

## نکات همزمانی (asyncio)

- هر صرافی یک task مستقل برای WS دارد؛ کرش یکی نباید دیگری را بخواباند.
  از `asyncio.TaskGroup` با هندلر خطا استفاده کن.
- ورود/خروج پوزیشن باید پشت **قفل per-symbol** باشد تا دو سیگنال همزمان
  دو پوزیشن تکراری باز نکنند.
- `client_order_id` را خودمان تولید کنیم (UUID) تا retry بعد از تایم‌اوت
  شبکه سفارش تکراری نسازد.
- هیچ کار blocking (محاسبات سنگین pandas) در event loop اصلی نباشد →
  `asyncio.to_thread`.

---

## فرانت‌اند

- React + TypeScript + Vite + Tailwind
- چارت: `lightweight-charts` (سبک، مخصوص مالی)
- داده لحظه‌ای: یک اتصال WebSocket به بک‌اند، نه polling
- صفحات: داشبورد · بازار زنده · استراتژی‌ها · پوزیشن‌ها/سفارش‌ها ·
  بک‌تست · تنظیمات · لاگ رویدادها
- UI باید **حالت فعلی سیستم را همیشه پررنگ نشان دهد**: paper یا live،
  و کدام مود. اشتباه گرفتن این دو گران تمام می‌شود — نوار رنگی بالای صفحه.
