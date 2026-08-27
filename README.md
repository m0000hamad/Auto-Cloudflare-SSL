<div align="center">

# setup_ssl.sh

**Automated Let's Encrypt certificate issuance (Cloudflare DNS-01) and deployment to an internal server**
<br>
**صدور خودکار گواهی Let's Encrypt (با روش DNS-01 کلودفلر) و استقرار آن روی سرور داخلی**

[![License: MPL 2.0](https://img.shields.io/badge/license-MPL--2.0-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash-1f425f.svg)

</div>

---

## English

`setup_ssl.sh` is a single Bash script for a common private-network problem: a server that has **no
direct inbound access from the internet** (behind NAT, a reverse proxy, or on a LAN) still needs a
valid, publicly-trusted TLS certificate. The script obtains that certificate on a machine that *can*
reach the internet — using Certbot's Cloudflare **DNS-01** challenge, which needs no open port 80/443
at all — and then pushes the certificate and private key to the internal server over SSH. It also
installs a cron job so the certificate renews and redeploys itself automatically.

### What it does

1. Validates it is running as **root** (required for package installation and cron setup).
2. Prompts for the domain, the internal server's IP and SSH port, your Cloudflare credentials, the
   internal server's root password, where to store the certificate files, and a renewal schedule.
3. Generates a 4096-bit RSA SSH key pair (`/root/.ssh/id_rsa`) if one doesn't already exist, and
   copies it to the internal server's `authorized_keys` — so every step after this one uses key-based
   SSH, not the password.
4. Installs `certbot`, `python3-certbot-dns-cloudflare`, `openssh-client`, and `sshpass` via `apt-get`.
5. Writes a Cloudflare credentials file at `/root/.secrets/certbot/cloudflare.ini` (mode `600`).
6. Requests the certificate with `certbot certonly --dns-cloudflare …` — Certbot creates a temporary
   TXT record via the Cloudflare API to prove domain ownership, so **no inbound connection to your
   server is required at all**.
7. Copies `fullchain.pem` and `privkey.pem` from `/etc/letsencrypt/live/<domain>/` to the internal
   server via `scp`, under the file names you chose.
8. Adds a cron job that re-runs `certbot renew` on your schedule and, via `--deploy-hook`, re-copies
   the renewed certificate and key to the internal server — so renewal is fully hands-off.

### Requirements

- A Debian/Ubuntu-based host (the script uses `apt-get`) with root access and outbound internet.
- A domain whose DNS is managed by **Cloudflare**.
- A **Cloudflare API token or Global API Key** with permission to edit DNS records for that domain.
- SSH access to the internal server as `root`, with password authentication enabled (only for the
  one-time key copy in step 3 — see the security notes below).

### Usage

```bash
git clone https://github.com/m0000hamad/script-s.git
cd script-s
chmod +x setup_ssl.sh
sudo ./setup_ssl.sh
```

You will be prompted for each value in turn. Anything left blank at a prompt with a shown default
(certificate directory, file names, cron schedule) falls back to that default.

### Prompts reference

| Prompt | Meaning | Default |
|---|---|---|
| Domain name | The domain to request a certificate for | — |
| Internal server IP | Where the certificate and key get deployed | — |
| SSH port | SSH port on the internal server | — |
| Cloudflare email | Account email for the Cloudflare API | — |
| Cloudflare API token | Token/key used for the DNS-01 challenge | — |
| Root password (internal server) | Used once to copy the SSH key | — |
| Certificate directory | Destination path on the internal server | `/root` |
| Certificate file name | Deployed certificate's file name | `cert.crt` |
| Private key file name | Deployed private key's file name | `private.key` |
| Cron schedule | When Certbot checks for renewal | `0 0 1 * *` (monthly) |

### ⚠ Security notes

Please read before running this on anything other than a trusted, isolated lab network:

- **The internal server's root password is embedded in plain text in root's crontab** (visible to
  anyone who can run `crontab -l` as root) so the deploy-hook can re-authenticate on renewal. Treat
  this script as suitable for an isolated home/lab network, not as-is for a shared or
  security-sensitive environment. If you need this in production, replace the `sshpass` calls with
  pure SSH-key authentication (the key from step 3 is already in place — the password prompt and
  the `sshpass` calls in the deploy-hook can be dropped entirely once the key is authorized) and
  disable SSH password authentication on the internal server afterward.
- **Prefer a scoped Cloudflare API Token** (Zone → DNS → Edit, restricted to the one zone) over the
  legacy Global API Key. The script accepts whichever value you paste at the prompt.
- The private key is transferred over SSH (encrypted in transit) but ends up sitting in a plain file
  on the internal server — make sure its permissions and the destination directory are locked down.
- The script installs system packages and writes to `/root`, `crontab`, and `~/.ssh` — review it
  before running it with `sudo`, as with any script that requires root.

### License

Released under the **Mozilla Public License 2.0** — see [LICENSE](LICENSE).

### Author

**m0000hamad** — محمد نریموسایی

---

<div dir="rtl">

## فارسی

`setup_ssl.sh` یک اسکریپت Bash تک‌فایلی برای یک مسئله رایج در شبکه‌های داخلی است: سروری که
**هیچ دسترسی ورودی مستقیمی از اینترنت ندارد** (پشت NAT، ریورس‌پروکسی، یا در یک شبکه محلی) هنوز هم به
یک گواهی TLS معتبر و مورد اعتماد عمومی نیاز دارد. این اسکریپت گواهی را روی ماشینی که *می‌تواند* به
اینترنت متصل شود دریافت می‌کند — با استفاده از چالش **DNS-01** سرویس Certbot برای کلودفلر که اصلاً
نیازی به باز بودن پورت ۸۰ یا ۴۴۳ ندارد — و سپس گواهی و کلید خصوصی را از طریق SSH روی سرور داخلی
مستقر می‌کند. همچنین یک cron job نصب می‌کند تا تمدید و استقرار گواهی به‌طور کاملاً خودکار انجام شود.

### عملکرد اسکریپت

۱. بررسی می‌کند که اسکریپت با کاربر **root** اجرا شده باشد (لازم برای نصب پکیج‌ها و تنظیم cron).
<br>۲. دامنه، آی‌پی و پورت SSH سرور داخلی، اطلاعات کلودفلر، رمز عبور root سرور داخلی، مسیر ذخیره
فایل‌های گواهی، و زمان‌بندی تمدید را از کاربر می‌پرسد.
<br>۳. یک جفت‌کلید SSH با الگوریتم RSA و طول ۴۰۹۶ بیت می‌سازد (`/root/.ssh/id_rsa`، در صورت عدم وجود)
و آن را به `authorized_keys` سرور داخلی اضافه می‌کند — تا از این مرحله به بعد، همه ارتباطات SSH با
کلید انجام شود، نه رمز عبور.
<br>۴. بسته‌های `certbot`، `python3-certbot-dns-cloudflare`، `openssh-client` و `sshpass` را با
`apt-get` نصب می‌کند.
<br>۵. یک فایل اعتبارنامه کلودفلر در مسیر `/root/.secrets/certbot/cloudflare.ini` (با دسترسی `600`)
می‌سازد.
<br>۶. گواهی را با دستور `certbot certonly --dns-cloudflare …` درخواست می‌کند — Certbot یک رکورد TXT
موقت از طریق API کلودفلر می‌سازد تا مالکیت دامنه را اثبات کند، بنابراین **هیچ اتصال ورودی به سرور شما
لازم نیست**.
<br>۷. فایل‌های `fullchain.pem` و `privkey.pem` را از مسیر `/etc/letsencrypt/live/<domain>/` با نام‌های
انتخابی شما، از طریق `scp` به سرور داخلی منتقل می‌کند.
<br>۸. یک cron job اضافه می‌کند که طبق زمان‌بندی تعیین‌شده، `certbot renew` را اجرا می‌کند و با
`--deploy-hook` گواهی و کلید تمدیدشده را دوباره به سرور داخلی منتقل می‌کند — یعنی تمدید کاملاً بدون
دخالت دستی انجام می‌شود.

### پیش‌نیازها

- یک سیستم مبتنی بر Debian/Ubuntu (اسکریپت از `apt-get` استفاده می‌کند) با دسترسی root و اینترنت خروجی.
- دامنه‌ای که DNS آن روی **کلودفلر** مدیریت می‌شود.
- یک **API Token یا Global API Key کلودفلر** با دسترسی ویرایش رکوردهای DNS همان دامنه.
- دسترسی SSH به سرور داخلی با کاربر `root` و رمز عبور فعال (فقط برای کپی یک‌بارهٔ کلید در مرحله ۳ —
  به توضیحات امنیتی زیر مراجعه کنید).

### نحوه استفاده

```bash
git clone https://github.com/m0000hamad/script-s.git
cd script-s
chmod +x setup_ssl.sh
sudo ./setup_ssl.sh
```

هر مقدار به‌ترتیب از شما پرسیده می‌شود. اگر ورودی‌هایی که مقدار پیش‌فرض دارند (مسیر گواهی، نام فایل‌ها،
زمان‌بندی cron) خالی گذاشته شوند، همان مقدار پیش‌فرض استفاده می‌شود.

### راهنمای ورودی‌ها

| ورودی | توضیح | پیش‌فرض |
|---|---|---|
| نام دامنه | دامنه‌ای که گواهی برایش صادر می‌شود | — |
| آی‌پی سرور داخلی | مقصد استقرار گواهی و کلید | — |
| پورت SSH | پورت SSH سرور داخلی | — |
| ایمیل کلودفلر | ایمیل حساب کاربری برای API کلودفلر | — |
| API Token کلودفلر | توکن/کلید مورد استفاده برای چالش DNS-01 | — |
| رمز عبور root (سرور داخلی) | فقط یک‌بار برای کپی کلید SSH استفاده می‌شود | — |
| مسیر ذخیره گواهی | مسیر مقصد روی سرور داخلی | `/root` |
| نام فایل گواهی | نام فایل گواهی مستقرشده | `cert.crt` |
| نام فایل کلید خصوصی | نام فایل کلید خصوصی مستقرشده | `private.key` |
| زمان‌بندی cron | زمان بررسی تمدید توسط Certbot | `0 0 1 * *` (ماهانه) |

### ⚠ نکات امنیتی

پیش از اجرای این اسکریپت روی هر محیطی به‌جز یک شبکه آزمایشی ایزوله، حتماً این بخش را بخوانید:

- **رمز عبور root سرور داخلی به‌صورت متن ساده داخل crontab کاربر root ذخیره می‌شود** (برای هرکسی که
  بتواند `crontab -l` را با root اجرا کند قابل مشاهده است)، چون deploy-hook برای تمدید نیاز به
  احراز هویت مجدد دارد. این اسکریپت را مناسب یک شبکه خانگی/آزمایشی ایزوله در نظر بگیرید، نه به همین
  شکل برای محیط اشتراکی یا حساس از نظر امنیتی. اگر نیاز به استفاده در محیط عملیاتی دارید، فراخوانی‌های
  `sshpass` را با احراز هویت خالص با کلید SSH جایگزین کنید (کلید ساخته‌شده در مرحله ۳ از قبل روی سرور
  مجاز شده است — پرسش رمز عبور و فراخوانی‌های `sshpass` در deploy-hook را می‌توان به‌طور کامل حذف کرد)
  و پس از آن ورود با رمز عبور را روی SSH سرور داخلی غیرفعال کنید.
- به‌جای Global API Key قدیمی، **استفاده از یک API Token محدودشده کلودفلر** (با دسترسی Zone → DNS →
  Edit، محدود به همان یک دامنه) توصیه می‌شود. اسکریپت هرچه در این ورودی وارد شود را می‌پذیرد.
- کلید خصوصی از طریق SSH منتقل می‌شود (رمزنگاری‌شده در حین انتقال) اما در نهایت به‌صورت یک فایل ساده
  روی سرور داخلی قرار می‌گیرد — مطمئن شوید دسترسی‌های فایل و مسیر مقصد به‌درستی محدود شده‌اند.
- این اسکریپت پکیج‌های سیستمی نصب می‌کند و در مسیرهای `/root`، `crontab` و `~/.ssh` تغییر ایجاد
  می‌کند — مانند هر اسکریپتی که با `sudo` اجرا می‌شود، پیش از اجرا محتوای آن را بررسی کنید.

### مجوز

منتشرشده تحت **Mozilla Public License 2.0** — به [LICENSE](LICENSE) مراجعه کنید.

### نویسنده

**m0000hamad** — محمد نریموسایی

</div>
