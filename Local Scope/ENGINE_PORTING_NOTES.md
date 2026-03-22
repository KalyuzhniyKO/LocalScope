# Engine Porting Notes

## Почему нельзя просто «скопировать код с Linux»

На уровне идеи — можно взять open-source реализацию и перенести её на macOS.
Но на практике для `RDP` / `VNC` / нативного `SSH` этого недостаточно:

1. **Нужен не только UI, а сам protocol engine**
   - для `RDP` нужен полноценный клиентский движок с декодированием графики, вводом, буферами кадра и transport/security слоями;
   - для `VNC` нужен полноценный `RFB` клиент;
   - для нативного `SSH/SFTP` нужна библиотека протокола, а не просто запуск системной утилиты.

2. **Linux-код почти всегда завязан на свою сборку**
   - чаще всего это `C/C++` + `CMake`/`autotools`;
   - для macOS это надо завести в `Xcode` / `Swift Package Manager` / prebuilt `xcframework`.

3. **Нужны Swift/Objective-C обёртки**
   - приложение написано на `SwiftUI`;
   - значит, библиотеку надо оборачивать через bridging layer, а не просто копировать исходники в проект.

4. **Есть лицензионные ограничения**
   - `libssh2` — BSD-3-Clause;
   - `FreeRDP` — Apache-2.0;
   - `LibVNCClient` — GPL-2.0, это требует отдельной проверки на совместимость с дистрибуцией приложения.

## Важный момент про VNC: не надо переписывать open-source логику на Swift

Для `LibVNCClient` правильный путь не в том, чтобы вручную «перевести Linux-код на язык для macOS».
Правильный путь такой:

1. оставить open-source `C`-движок как есть;
2. собрать его под `macOS arm64/x86_64`;
3. подключить его в Xcode как vendored library / xcframework / CMake-built artifact;
4. поверх него сделать тонкий Swift bridge и SwiftUI-рендеринг.

Именно так это обычно и делают: protocol engine остаётся на `C/C++`, а UI/оркестрация живут в `Swift`.
В этом репозитории уже добавлены:

- `VNCNativeBridge.swift` — phase-2 seam под реальные `LibVNCClient` session callbacks;
- `VNCFrameBuffer.swift` — модель framebuffer для обновлений из native backend;
- `VNCNativeSessionController.swift` — SwiftUI-friendly controller для connection / event / clipboard / frame updates;
- `VNCFrameBufferView.swift` — базовый SwiftUI renderer для будущего framebuffer pipeline;
- `scripts/build-libvncclient-macos.sh` — helper script для сборки `LibVNCClient` под macOS.

## Что выбрано как целевой стек

- `SSH / SFTP` → `libssh2`
- `RDP` → `FreeRDP`
- `VNC` → `LibVNCClient` *(только после проверки лицензии)*

## Проверка upstream на 22 марта 2026

- `libssh2` остаётся самым чистым низкоуровневым кандидатом для macOS-встраивания: проект поддерживает CMake-сборку, а актуальный релиз в upstream — `1.11.1` от `16 октября 2024`.
- Для ускоренного прототипа на Apple-платформах существует `NMSSH` (Objective-C wrapper над `libssh2`), но его последний релиз в upstream заметно старее (`2.3.1` от `29 июля 2018`), поэтому как долгосрочную основу лучше закладывать прямой bridge к `libssh2`.
- `FreeRDP` остаётся лучшим кандидатом для настоящего RDP-движка; в upstream есть macOS build pipeline, а в публичных релизах доступен свежий `2.11.8` от `25 февраля 2026`, но это всё равно большой C/CMake-стек, который нужно интегрировать как отдельный native module, а не копировать кусками в SwiftUI.
- `LibVNCClient` технически пригоден и хорошо документирован для встраивания через CMake / `find_package(LibVNCServer)`, но GPL-режим здесь не формальность: при линковке приложение становится производным произведением, поэтому для закрытого macOS-приложения нельзя двигаться дальше без юридической проверки.

## Как внедрять по-нормальному

### 1. Вендоринг / сборка библиотек
- собрать библиотеки под `macOS arm64`;
- выбрать формат интеграции: `SPM binary target`, `xcframework`, либо локальная `C`-обвязка.

### 2. Сделать нативные engine-адаптеры
- `SSHNativeEngine.swift`
- `RDPNativeEngine.swift`
- `VNCNativeEngine.swift`

Каждый адаптер должен:
- инициализировать нативную библиотеку;
- открывать/закрывать сессию;
- публиковать статус;
- прокидывать ошибки в SwiftUI;
- уметь работать без внешних приложений.

### 3. Подменить текущие probe/shell flow
- `SSH / SFTP`: заменить запуск системного `ssh`/`sftp` на вызовы `libssh2`;
- `RDP`: заменить `probePort` на реальную RDP-сессию;
- `VNC`: заменить `probePort` на реальную VNC-сессию.

### 4. Оставить текущий код как fallback до завершения миграции
- текущая shell-модель полезна как временный режим для `SSH / FTP / SFTP`;
- текущий `probe` режим полезен для `RDP / VNC`, пока не будет встроен полноценный движок.

## Практический порядок интеграции

1. **SSH / SFTP first**
   - сначала заменить системный `ssh`/`sftp` на прямой вызов `libssh2`;
   - это самый короткий путь к реальному in-app engine без отдельного графического рендера.

2. **RDP second**
   - после стабилизации SSH встраивать `FreeRDP`;
   - здесь уже понадобятся framebuffer, input routing, clipboard и reconnect handling.

3. **VNC last**
   - переносить только после решения по лицензии;
   - если licensing не подходит продукту, лучше оставить `probe-only` режим или искать альтернативу с более мягкой лицензией, а не тащить `LibVNCClient` любой ценой.
