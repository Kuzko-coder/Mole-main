<div align="center">
  <h1>Mole (Крот)</h1>
  <p><em>🐹 Роет глубоко, как крот, чтобы очистить ваш Mac.</em></p>
</div>

<p align="center">
  <a href="https://github.com/Kuzko-coder/Mole-main/stargazers"><img src="https://img.shields.io/github/stars/Kuzko-coder/Mole-main?style=flat-square" alt="Звезды"></a>
  <a href="https://github.com/Kuzko-coder/Mole-main/releases"><img src="https://img.shields.io/github/v/tag/Kuzko-coder/Mole-main?label=версия&style=flat-square" alt="Версия"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/лицензия-MIT-blue.svg?style=flat-square" alt="Лицензия"></a>
  <a href="https://github.com/Kuzko-coder/Mole-main/commits"><img src="https://img.shields.io/github/commit-activity/m/Kuzko-coder/Mole-main?style=flat-square" alt="Коммиты"></a>
</p>

<p align="center">
  <img src="https://cdn.tw93.fun/img/mole.jpeg" alt="Mole - освобождено 95.50ГБ" width="800" />
</p>

## Возможности

- 🐦 **Глубокая очистка системы** - Удаление скрытых кэшей, логов и временных файлов за один проход
- 📦 **Тщательное удаление** - Очистка 22+ мест против 1 стандартного, превосходит CleanMyMac/Lemon
- 📊 **Интерактивный анализатор диска** - Навигация по папкам как в файловом менеджере, поиск и удаление больших файлов мгновенно
- ⚡️ **Быстрый и легкий** - Работает в терминале, нулевое раздувание, навигация стрелками с пагинацией

## Быстрый старт

**Советы:**

- На критически важных Mac подождите, пока Mole станет более зрелым, безопасность прежде всего
- Если этот Mac очень важен для вас, рекомендуется подождать, пока Mole станет более стабильным
- Не очень технически подкованы? Смотрите [Руководство для новичков](./GUIDE.md)

**Установка:**

```bash
curl -fsSL https://raw.githubusercontent.com/Kuzko-coder/Mole-main/main/install.sh | bash
```

Или через Homebrew:

```bash
brew install tw93/tap/mole
```

**Запуск:**

```bash
mo                      # Интерактивное меню
mo clean                # Очистка системы
mo clean --dry-run      # Режим предпросмотра
mo clean --whitelist    # Управление защищенными кэшами
mo uninstall            # Удаление приложений
mo analyze              # Анализатор диска
mo update               # Обновление Mole
mo remove               # Удаление Mole из системы
mo --help               # Показать справку
mo --version            # Показать установленную версию
# Если команда не найдена, запустите `mole update` один раз для обновления до последней версии.
```

> Рекомендуется начать с `mo clean --dry-run` для предпросмотра, `mo clean --whitelist` для защиты кэшей

## Возможности в деталях

### Глубокая очистка системы

```bash
$ mo clean

▶ Основные системные элементы
  ✓ Кэш пользовательских приложений (45.2ГБ)
  ✓ Логи пользовательских приложений (2.1ГБ)
  ✓ Корзина (12.3ГБ)

▶ Очистка браузеров
  ✓ Кэш Chrome (8.4ГБ)
  ✓ Кэш Safari (2.1ГБ)

▶ Инструменты разработчика
  ✓ Xcode derived data (9.1ГБ)
  ✓ Кэш Node.js (14.2ГБ)

▶ Прочее
  ✓ Кэш Dropbox (5.2ГБ)
  ✓ Кэш Spotify (3.1ГБ)

====================================================================
🎉 ОЧИСТКА ЗАВЕРШЕНА!
💾 Освобождено места: 95.50ГБ | Свободно сейчас: 223.5ГБ
====================================================================
```

### Умное удаление приложений

```bash
$ mo uninstall

🗑️  Выберите приложения для удаления
═══════════════════════════
▶ ☑ Adobe Creative Cloud      (12.4G) | Старое
  ☐ WeChat                    (2.1G) | Недавнее
  ☐ Final Cut Pro             (3.8G) | Недавнее

🗑️  Удаление: Adobe Creative Cloud
  ✓ Удалено приложение               # /Applications/
  ✓ Очищено 52 связанных файла       # ~/Library/ в 12 местах
    - Файлы поддержки и кэши         # Application Support, Caches
    - Настройки и логи               # Preferences, Logs
    - Хранилище WebKit и cookies     # WebKit, HTTPStorages
    - Расширения и плагины           # Internet Plug-Ins, Services
    - Системные файлы с sudo         # /Library/, Launch daemons

====================================================================
🎉 УДАЛЕНИЕ ЗАВЕРШЕНО!
💾 Освобождено места: 12.8ГБ
====================================================================
```

### Анализатор дискового пространства

```bash
$ mo analyze

📊 Анализ: /Users/You
═══════════════════════════════════════════════════════
Всего: 156.8ГБ

├─ 📁 Library                                        45.2ГБ
│  ├─ 📁 Caches                                      28.4ГБ
│  └─ 📁 Application Support                         16.8ГБ
├─ 📁 Downloads                                      32.6ГБ
│  ├─ 📄 Xcode-14.3.1.dmg                            12.3ГБ
│  ├─ 📄 backup_2023.zip                             8.6ГБ
│  └─ 📦 old_projects.tar.gz                         5.2ГБ
├─ 📁 Movies                                         28.9ГБ
│  ├─ 📄 vacation_2023.mov                           15.4ГБ
│  └─ 📄 screencast_raw.mp4                          8.8ГБ
├─ 📁 Documents                                      18.4ГБ
└─ 📁 Desktop                                        12.7ГБ
```

## Часто задаваемые вопросы

1. **Безопасен ли Mole?** – Mole фокусируется на очистке кэшей и логов, не трогая настройки приложений, пользовательские документы или системные файлы. Вы можете запустить `mo clean --dry-run` для предпросмотра того, что будет удалено, прежде чем фактически очищать.
2. **Как часто нужно чистить?** – Примерно раз в месяц, или когда заканчивается место на диске.
3. **Могу ли я защитить определенные кэши?** – Да. Запустите `mo clean --whitelist` для интерактивного выбора, какие кэши оставить. Некоторые распространенные, такие как браузеры Playwright и модели HuggingFace, уже защищены по умолчанию.

## Поддержка

- **Поставьте звезду репозиторию**, если Mole помог вам освободить место на диске
- **Поделитесь с друзьями**, которым нужно почистить их Mac
- **Сообщайте о проблемах** через [GitHub Issues](https://github.com/Kuzko-coder/Mole-main/issues)
- **Поддержите проект** через [GitHub Sponsors](https://github.com/sponsors/Kuzko-coder) или [kukzo.su](https://kukzo.su)

---

*Русская версия и поддержка: [@Kuzko-coder](https://github.com/Kuzko-coder)*  

## Лицензия

Лицензия MIT - наслаждайтесь и участвуйте в открытом исходном коде.
