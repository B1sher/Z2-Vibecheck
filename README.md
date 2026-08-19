# Z2💜Vibecheck

Автоматический подбор DPI-bypass стратегий для **Zapret2** на OpenWrt.

Поверх существующего `remittor/zapret-openwrt` добавляет automation layer:
- 🔍 Автопоиск стратегий через `blockcheckw`
- ✅ Проверка доступности доменов
- 🔄 Пост-проверка топ-33 стратегий для каждого домена
- 💾 Backup / rollback / last-good
- 🔌 Управление Nikki/Podkop прокси
- 🎨 Цветное меню

---

## Требования

- **OpenWrt** (или Linux) с установленным **Zapret2**
- **blockcheckw** (устанавливается автоматически)
- **Nikki/Podkop** (опционально — для прокси)
- root-доступ

---

## Установка

```sh
# 1. Скопировать файлы в /opt/Z2Vibecheck/
# 2. Установить blockcheckw:
sh /opt/Z2Vibecheck/install/install-blockcheckw.sh

# 3. Применить дефолтные стратегии:
sh /opt/Z2Vibecheck/install/install.sh

# 4. Запустить:
Z2Vibecheck
```

---

## Структура

```
/opt/Z2Vibecheck/
├── Z2Vibecheck.sh              ← главный скрипт (меню)
├── config                      ← конфигурация
├── strategies/                 ← кастомные стратегии
│   ├── youtube-custom.lst      ← YouTube (конвертировано из zapret1)
│   ├── discord-custom.lst      ← Discord (TLS + UDP voice)
│   ├── autohostlist-custom.lst ← универсальные
│   └── googlevideo-custom.lst  ← googlevideo (не тестируется)
├── install/
│   ├── install.sh              ← установка стратегий в zapret2
│   ├── install-blockcheckw.sh  ← установка blockcheckw
│   ├── files/                  ← fake-пакеты (blob'ы)
│   └── ipset/                  ← hostlists
├── lib/
│   ├── domains/                ← списки доменов
│   │   ├── domains.conf
│   │   ├── domains.default.conf
│   │   └── domains.custom.conf
│   ├── colors.sh               ← ANSI цвета
│   ├── generator.sh            ← генерация NFQWS2_OPT
│   ├── apply.sh                ← apply + rollback
│   ├── health-check.sh         ← backoff-логика
│   ├── proxy-control.sh        ← Nikki/Podkop + DNS
│   ├── test-strategies.sh      ← проверка доменов
│   └── blockcheck-runner.sh    ← обёртка blockcheckw
├── bin/
│   └── blockcheckw             ← бинарь (скачивается)
└── var/
    ├── backup/                 ← timestamped backups
    ├── last-good/              ← последний рабочий конфиг
    ├── results/                ← результаты сканов
    └── strategies/             ← сохранённые стратегии
```

---

## Домены по умолчанию

```
youtube.com
gateway.discord.gg
discord.com
cloudflare-ech.com
rutracker.org
github.com
githubusercontent.com
```

---

## Режимы автопоиска

1. **Полная проверка** — все домены
2. **Только YouTube** — youtube.com
3. **Cloudflare и Rutracker** — cloudflare-ech.com + rutracker.org
4. **Только Discord** — discord.com + gateway.discord.gg
5. **Только GitHub** — github.com + githubusercontent.com
6. **Кастомный список** — домены из domains.custom.conf

---

## Как работает

```
Запуск
  ↓
[0/6] Обновление blockcheckw
  ↓
[1/6] Подготовка (остановка Nikki/Podkop/Zapret2 + DNS fix)
  ↓
[2/6] Проверка доступности доменов
  ↓
[3/6] Диагностика блокировок (blockcheckw status)
  ↓
[4/6] Поиск стратегий (blockcheckw scan, топ-33)
  ↓
[5/6] Применение + пост-проверка (перебор до рабочей)
  ↓
[6/6] Восстановление прокси
```

---

## Ключевые особенности

### Объединение стратегий

Новые стратегии **добавляются** к существующим, а не заменяют:

```
Старые стратегии + --new + Новые стратегии
```

### Backup / Rollback

- Перед каждым изменением — backup с timestamp
- `last-good` — последний рабочий конфиг
- При ошибке — автоматический rollback

### Честная проверка

- Nikki/Podkop останавливаются перед тестом
- DNS переключается на 8.8.8.8 / 1.1.1.1
- Zapret2 останавливается перед сканированием

### Пост-проверка

Каждая стратегия проверяется реальным curl-запросом.
Перебираются топ-33, пока не найдётся рабочая.

---

## Кастомные стратегии

Файлы в `strategies/` содержат конвертированные zapret1-стратегии:

### YouTube

```
--filter-tcp=443 --lua-init=fake_default_tls=tls_mod(fake_default_tls,'rnd') --lua-desync=multisplit:pos=2,sld,sniext+1:seqovl=1
```

### Discord

```
--filter-tcp=80,443 --lua-desync=fake:blob=blob_tls_clienthello_max_ru:repeats=8
--filter-udp=443 --lua-desync=fake:blob=quic_Ori_New:repeats=11
```

---

## Настройка

### Порты (в config)

```
NFQWS2_PORTS_TCP="80,443,2053,2083,2087,2096,8443"
NFQWS2_PORTS_UDP="443,500-1400,4000-5000,3478-3497,19000-20000,50000-65535"
```

### Расписание (пункт 6 меню)

- Ежедневно в 4:00
- Еженедельно (пн 4:00)
- Выключено

---

## Лицензия

MIT

