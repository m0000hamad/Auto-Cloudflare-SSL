<div align="center">

# CfAutoSSL

**Cloudflare Auto SSL — fully automatic Let's Encrypt certificate issuance via the Cloudflare DNS-01 challenge**
<br>
**کلودفلر اتو SSL — صدور کاملاً خودکار گواهی Let's Encrypt با چالش DNS-01 کلودفلر**

[![License: MPL 2.0](https://img.shields.io/badge/license-MPL--2.0-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash-1f425f.svg)

</div>

---

## English

`CfAutoSSL.sh` is a single Bash script that issues a publicly-trusted TLS certificate for a domain
using Certbot's Cloudflare **DNS-01** challenge — which needs no open port 80/443 and no inbound
connection to your server at all — and saves the resulting certificate and private key wherever you
choose. It only asks for what it actually needs: your Cloudflare credentials, the domain, and where
to save the files. Nothing else.

### What it does

1. Validates it is running as **root** (required for package installation and writing to `/etc`).
2. Prompts for the domain name, your Cloudflare email, your Cloudflare API token, the destination
   directory, and the certificate/key file names.
3. Installs `certbot` and `python3-certbot-dns-cloudflare` via `apt-get`.
4. Writes a Cloudflare credentials file at `/root/.secrets/certbot/cloudflare.ini` (mode `600`).
5. Requests the certificate non-interactively with `certbot certonly --dns-cloudflare …` — Certbot
   creates a temporary TXT record via the Cloudflare API to prove domain ownership.
6. Copies `fullchain.pem` and `privkey.pem` from `/etc/letsencrypt/live/<domain>/` to the destination
   directory, under the file names you chose (creating the directory if it doesn't exist).

That's the whole script — no SSH, no remote server, no password of any kind, and no cron job.

### Requirements

- A Debian/Ubuntu-based host (the script uses `apt-get`) with root access and outbound internet.
- A domain whose DNS is managed by **Cloudflare**.
- A **Cloudflare API token or Global API Key** with permission to edit DNS records for that domain.

### Usage

```bash
git clone https://github.com/m0000hamad/script-s.git
cd script-s
chmod +x CfAutoSSL.sh
sudo ./CfAutoSSL.sh
```

You will be prompted for each value in turn. Leaving the destination directory or file-name prompts
blank falls back to their shown default.

### Prompts reference

| Prompt | Meaning | Default |
|---|---|---|
| Domain name | The domain to request a certificate for | — |
| Cloudflare email | Account email for the Cloudflare API | — |
| Cloudflare API token | Token/key used for the DNS-01 challenge | — |
| Destination directory | Where the certificate and key are saved | `/root` |
| Certificate file name | Saved certificate's file name | `cert.crt` |
| Private key file name | Saved private key's file name | `private.key` |

### Notes

- Prefer a scoped Cloudflare **API Token** (Zone → DNS → Edit, restricted to the one zone) over the
  legacy Global API Key where your Cloudflare plan supports it.
- The private key is written as a plain file at the destination you choose — make sure that
  directory's permissions match how sensitive the key is.
- To renew the certificate later, either re-run this script, or use Certbot directly
  (`certbot renew`) since the certificate it issued is registered with Certbot like any other.
- This script installs system packages and writes to `/root` and `/etc/letsencrypt` — review it
  before running it with `sudo`, as with any script that requires root.

### License

Released under the **Mozilla Public License 2.0** — see [LICENSE](LICENSE).

### Author

**m0000hamad** — محمد نریموسایی

---

<div dir="rtl">

## فارسی

`CfAutoSSL.sh` یک اسکریپت Bash تک‌فایلی است که با استفاده از چالش **DNS-01** سرویس Certbot برای
کلودفلر — که اصلاً نیازی به باز بودن پورت ۸۰ یا ۴۴۳ و هیچ اتصال ورودی به سرور شما ندارد — یک گواهی
TLS معتبر و مورد اعتماد عمومی برای دامنه شما صادر می‌کند و گواهی و کلید خصوصی حاصل را هرجا که بخواهید
ذخیره می‌کند. این اسکریپت فقط همان چیزی را می‌پرسد که واقعاً لازم دارد: اطلاعات کلودفلر، دامنه، و
مسیر ذخیره‌سازی. چیز دیگری نمی‌پرسد.

### عملکرد اسکریپت

۱. بررسی می‌کند که اسکریپت با کاربر **root** اجرا شده باشد (لازم برای نصب پکیج‌ها و نوشتن در `/etc`).
<br>۲. نام دامنه، ایمیل کلودفلر، API Token کلودفلر، مسیر مقصد، و نام فایل‌های گواهی/کلید را از کاربر
می‌پرسد.
<br>۳. بسته‌های `certbot` و `python3-certbot-dns-cloudflare` را با `apt-get` نصب می‌کند.
<br>۴. یک فایل اعتبارنامه کلودفلر در مسیر `/root/.secrets/certbot/cloudflare.ini` (با دسترسی `600`)
می‌سازد.
<br>۵. گواهی را به‌صورت کاملاً غیرتعاملی با دستور `certbot certonly --dns-cloudflare …` درخواست
می‌کند — Certbot یک رکورد TXT موقت از طریق API کلودفلر می‌سازد تا مالکیت دامنه را اثبات کند.
<br>۶. فایل‌های `fullchain.pem` و `privkey.pem` را از مسیر `/etc/letsencrypt/live/<domain>/` با
نام‌های انتخابی شما به مسیر مقصد کپی می‌کند (در صورت نبودن مسیر، آن را می‌سازد).

همین — بدون SSH، بدون سرور دیگر، بدون هیچ نوع رمز عبوری، و بدون cron job.

### پیش‌نیازها

- یک سیستم مبتنی بر Debian/Ubuntu (اسکریپت از `apt-get` استفاده می‌کند) با دسترسی root و اینترنت خروجی.
- دامنه‌ای که DNS آن روی **کلودفلر** مدیریت می‌شود.
- یک **API Token یا Global API Key کلودفلر** با دسترسی ویرایش رکوردهای DNS همان دامنه.

### نحوه استفاده

```bash
git clone https://github.com/m0000hamad/script-s.git
cd script-s
chmod +x CfAutoSSL.sh
sudo ./CfAutoSSL.sh
```

هر مقدار به‌ترتیب از شما پرسیده می‌شود. اگر مسیر مقصد یا نام فایل‌ها خالی گذاشته شوند، همان مقدار
پیش‌فرض نمایش‌داده‌شده استفاده می‌شود.

### راهنمای ورودی‌ها

| ورودی | توضیح | پیش‌فرض |
|---|---|---|
| نام دامنه | دامنه‌ای که گواهی برایش صادر می‌شود | — |
| ایمیل کلودفلر | ایمیل حساب کاربری برای API کلودفلر | — |
| API Token کلودفلر | توکن/کلید مورد استفاده برای چالش DNS-01 | — |
| مسیر مقصد | مسیر ذخیره گواهی و کلید | `/root` |
| نام فایل گواهی | نام فایل گواهی ذخیره‌شده | `cert.crt` |
| نام فایل کلید خصوصی | نام فایل کلید خصوصی ذخیره‌شده | `private.key` |

### نکات

- در صورت پشتیبانی پلن کلودفلر شما، به‌جای Global API Key قدیمی، از یک **API Token** محدودشده
  (با دسترسی Zone → DNS → Edit، محدود به همان یک دامنه) استفاده کنید.
- کلید خصوصی به‌صورت یک فایل ساده در مسیری که انتخاب می‌کنید نوشته می‌شود — مطمئن شوید دسترسی‌های
  آن مسیر متناسب با حساسیت کلید تنظیم شده باشد.
- برای تمدید گواهی در آینده، یا دوباره همین اسکریپت را اجرا کنید، یا مستقیماً از خود Certbot استفاده
  کنید (`certbot renew`)، چون گواهی صادرشده مثل هر گواهی دیگری نزد Certbot ثبت شده است.
- این اسکریپت پکیج‌های سیستمی نصب می‌کند و در مسیرهای `/root` و `/etc/letsencrypt` تغییر ایجاد
  می‌کند — مانند هر اسکریپتی که با `sudo` اجرا می‌شود، پیش از اجرا محتوای آن را بررسی کنید.

### مجوز

منتشرشده تحت **Mozilla Public License 2.0** — به [LICENSE](LICENSE) مراجعه کنید.

### نویسنده

**m0000hamad** — محمد نریموسایی

</div>
