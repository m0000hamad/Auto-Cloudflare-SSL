## What this solves

You need an SSL certificate for a server whose domain or subdomain doesn't point at its
real IP — tunneled, behind NAT, or with no public address at all. Normal issuance fails,
because verification tries to reach the domain and lands somewhere else.

CfAutoSSL proves domain ownership through a DNS record via the Cloudflare API instead.
Nothing has to reach your server:

- No changing the domain's or subdomain's IP
- No open ports 80/443
- No public IP required

Run it on any Ubuntu server and get a certificate for any domain in your Cloudflare account.

## Install

```bash
wget -O CfAutoSSL.sh https://github.com/m0000hamad/script-s/releases/latest/download/CfAutoSSL.sh
sudo bash CfAutoSSL.sh
```

It asks for five things — domain, Cloudflare email, Cloudflare API token, destination
directory (default `/root`), and the file names (defaults `cert.crt` and `private.key`) —
then installs Certbot, issues the certificate, and saves it where you chose.

## IPv6 handling

A host that advertises IPv6 without working IPv6 connectivity makes Certbot stall on its way
to the Let's Encrypt API. The script now detects that IPv6 is enabled, turns it off for the
duration of the request, and turns it back on afterwards — including when Certbot fails or
you interrupt the script. Only runtime sysctls are touched, so nothing is changed
permanently. If your own SSH session came in over IPv6, the script leaves IPv6 alone rather
than disconnecting you.

## Changes from the previous script

The script no longer deploys to a second server. Everything tied to that is gone:

- No root password prompt
- No SSH key generation or `ssh-copy-id`
- No `scp` transfer
- No cron job — the old one stored the remote root password in plaintext in root's crontab

It now issues the certificate and saves it locally. To renew, re-run the script or use
`certbot renew`.

Tested on Ubuntu.

---

## این نسخه چه مشکلی را حل می‌کند

وقتی IP دامنه یا ساب‌دامنه‌تان، IP واقعی سرور نیست — سرور tunnel شده، پشت NAT است، یا
اصلاً IP عمومی ندارد — گرفتن گواهی SSL به روش معمول شکست می‌خورد، چون فرآیند تأیید سعی
می‌کند به دامنه وصل شود و به جای دیگری می‌رسد.

CfAutoSSL به‌جای آن، مالکیت دامنه را از طریق یک رکورد DNS و با API کلودفلر اثبات می‌کند.
هیچ چیزی لازم نیست به سرور شما برسد:

- بدون نیاز به عوض کردن IP دامنه یا ساب‌دامنه
- بدون نیاز به باز بودن پورت ۸۰ و ۴۴۳
- بدون نیاز به IP عمومی

کافی است روی هر سرور اوبونتویی اجرایش کنید تا گواهی هر دامنه‌ای که در حساب کلودفلر دارید
را بگیرید.

## نصب

```bash
wget -O CfAutoSSL.sh https://github.com/m0000hamad/script-s/releases/latest/download/CfAutoSSL.sh
sudo bash CfAutoSSL.sh
```

پنج چیز می‌پرسد — دامنه، ایمیل کلودفلر، توکن API کلودفلر، مسیر ذخیره (پیش‌فرض `/root`)
و نام فایل‌ها (پیش‌فرض `cert.crt` و `private.key`) — بعد خودش Certbot را نصب می‌کند،
گواهی را می‌گیرد و در مسیری که انتخاب کرده‌اید ذخیره می‌کند.

## رفتار با IPv6

اگر سروری IPv6 داشته باشد ولی اتصال IPv6 آن واقعاً کار نکند، Certbot در مسیر رسیدن به
Let's Encrypt گیر می‌کند. اسکریپت حالا تشخیص می‌دهد IPv6 فعال است، آن را فقط در طول گرفتن
گواهی خاموش می‌کند و بعد دوباره روشن می‌کند — حتی اگر Certbot شکست بخورد یا وسط کار اسکریپت
را قطع کنید. فقط تنظیمات موقتی sysctl تغییر می‌کند و چیزی به‌صورت دائمی عوض نمی‌شود. اگر خود
اتصال SSH شما روی IPv6 باشد، اسکریپت اصلاً دست به IPv6 نمی‌زند تا ارتباطتان قطع نشود.

## تغییرات نسبت به اسکریپت قبلی

اسکریپت دیگر گواهی را روی سرور دوم منتقل نمی‌کند و هرچه مربوط به آن بود حذف شده است:

- بدون پرسیدن رمز root
- بدون ساخت کلید SSH و `ssh-copy-id`
- بدون انتقال با `scp`
- بدون cron job — نسخه قبلی رمز root سرور مقابل را به‌صورت متن ساده در crontab ذخیره می‌کرد

حالا گواهی را می‌گیرد و به‌صورت محلی ذخیره می‌کند. برای تمدید، دوباره اسکریپت را اجرا کنید
یا از `certbot renew` استفاده کنید.

تست‌شده روی اوبونتو.
