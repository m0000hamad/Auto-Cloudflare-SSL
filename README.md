<div align="center">

# CfAutoSSL

**Cloudflare Auto SSL — get a Let's Encrypt certificate for any domain, from any Ubuntu server**
<br>
**گرفتن خودکار گواهی SSL برای هر دامنه، از روی هر سرور اوبونتویی**

[![License: MPL 2.0](https://img.shields.io/badge/license-MPL--2.0-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash-1f425f.svg)

</div>

---

## English

**The domain does not have to point at the server you run this on.**

Ownership is proven through a DNS record via the Cloudflare API — not by serving a file over HTTP.
So you don't need to change the domain's or subdomain's IP, you don't need ports 80/443 open, and the
server can be behind NAT or have no public address at all. Run it on any Ubuntu box and get a
certificate for any domain sitting in your Cloudflare account.

It asks for five things and does the rest by itself.

### Usage

```bash
wget -O CfAutoSSL.sh https://github.com/m0000hamad/script-s/releases/latest/download/CfAutoSSL.sh
sudo bash CfAutoSSL.sh
```

This always pulls the newest published version — see [Releases](https://github.com/m0000hamad/script-s/releases).

| Prompt | Default |
|---|---|
| Domain name | — |
| Cloudflare email | — |
| Cloudflare API token | — |
| Destination directory | `/root` |
| Certificate file name | `cert.crt` |
| Private key file name | `private.key` |

Press Enter on the last three to accept the defaults. The script installs Certbot, requests the
certificate, and writes it to the path you chose.

Your answers are saved, so the next run offers to reuse them:

```
Found settings from a previous run:
  Domain:     example.com
  Cloudflare: you@example.com
  Saves to:   /root/cert.crt and /root/private.key

Reuse these settings? [Y/n]:
```

Press Enter to repeat the last run, or `n` to enter new details.

### Requirements

- Ubuntu/Debian with root access and outbound internet.
- A domain whose DNS is managed by **Cloudflare**.
- A Cloudflare **API token** (Zone → DNS → Edit) or Global API Key.

### Notes

- If IPv6 is enabled but not actually working, Certbot stalls reaching Let's Encrypt. The script
  turns IPv6 off for the duration of the request and back on afterwards — runtime only, nothing
  permanent — and skips this entirely if your SSH session itself is over IPv6.
- The private key is written as a plain file — check the destination directory's permissions.
- To renew later, re-run the script or use `certbot renew`.

**License:** [MPL 2.0](LICENSE) · **Author:** m0000hamad — محمد نریموسایی

---

<div dir="rtl">

## فارسی

**لازم نیست دامنه به سروری که اسکریپت را روی آن اجرا می‌کنید وصل باشد.**

اثبات مالکیت دامنه از طریق یک رکورد DNS و با API کلودفلر انجام می‌شود، نه با سرو کردن فایل روی وب.
یعنی نه نیاز به عوض کردن IP دامنه یا ساب‌دامنه دارید، نه پورت ۸۰ و ۴۴۳ باید باز باشد، و سرور
می‌تواند پشت NAT باشد یا اصلاً IP عمومی نداشته باشد. کافی است روی هر سرور اوبونتویی اجرایش کنید تا
گواهی هر دامنه‌ای که در حساب کلودفلر دارید را بگیرید.

پنج چیز از شما می‌پرسد و بقیه‌اش را خودش انجام می‌دهد.

### نحوه اجرا

```bash
wget -O CfAutoSSL.sh https://github.com/m0000hamad/script-s/releases/latest/download/CfAutoSSL.sh
sudo bash CfAutoSSL.sh
```

این دستور همیشه آخرین نسخه منتشرشده را می‌گیرد — [فهرست نسخه‌ها](https://github.com/m0000hamad/script-s/releases).

| ورودی | پیش‌فرض |
|---|---|
| نام دامنه | — |
| ایمیل کلودفلر | — |
| توکن API کلودفلر | — |
| مسیر ذخیره | `/root` |
| نام فایل گواهی | `cert.crt` |
| نام فایل کلید خصوصی | `private.key` |

برای سه مورد آخر کافی است Enter بزنید تا مقدار پیش‌فرض اعمال شود. اسکریپت خودش Certbot را نصب
می‌کند، گواهی را می‌گیرد و در مسیری که انتخاب کرده‌اید ذخیره می‌کند.

پاسخ‌های شما ذخیره می‌شود و اجرای بعدی پیشنهاد می‌دهد از همان‌ها استفاده کند:

```
Found settings from a previous run:
  Domain:     example.com
  Cloudflare: you@example.com
  Saves to:   /root/cert.crt and /root/private.key

Reuse these settings? [Y/n]:
```

برای تکرار اجرای قبلی Enter بزنید، یا `n` بزنید تا مشخصات جدید وارد کنید.

### پیش‌نیازها

- سرور اوبونتو/دبیان با دسترسی root و اینترنت.
- دامنه‌ای که DNS آن روی **کلودفلر** باشد.
- یک **توکن API** کلودفلر (با دسترسی Zone → DNS → Edit) یا Global API Key.

### نکات

- اگر IPv6 فعال باشد ولی واقعاً کار نکند، Certbot در ارتباط با Let's Encrypt گیر می‌کند. اسکریپت
  IPv6 را فقط در طول گرفتن گواهی خاموش و بعد دوباره روشن می‌کند — تغییر موقتی است و چیزی دائمی
  عوض نمی‌شود — و اگر خود اتصال SSH شما روی IPv6 باشد، اصلاً دست به آن نمی‌زند.
- کلید خصوصی به صورت فایل ساده ذخیره می‌شود — سطح دسترسی مسیر مقصد را چک کنید.
- برای تمدید، دوباره اسکریپت را اجرا کنید یا از `certbot renew` استفاده کنید.

**مجوز:** [MPL 2.0](LICENSE) · **نویسنده:** m0000hamad — محمد نریموسایی

</div>
