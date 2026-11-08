# Narrator (El Narrador)

Un narrador al estilo **Baldur's Gate 3** para **WoW Forever** (Classic+):
una voz ominosa y con sorna que comenta tus muertes, críticos, botines y
desgracias favoritas mientras exploras el mundo.

> *Despierta, caminante. La niebla se aparta. La historia continúa.*

El narrador habla **inglés por defecto** y **español de serie**
(`/nar lang esES`, o automático si tu cliente está en español). Cualquier
idioma es bienvenido: la guía está en [LOCALES.md](LOCALES.md).

## Cómo se ve

Un recuadro oscuro con borde dorado aparece en la parte superior de la
pantalla: título en versalitas doradas y la frase debajo, en Morpheus, la
tipografía "de libro" del WoW. El narrador es una voz, no una interfaz:
solo texto, centrado, elegante. (Se arrastra para moverlo y recuerda su sitio.)

## Qué comenta

| Evento | Ejemplo |
|---|---|
| Muertes — mob, jugador, caída, lava/fuego, ahogo, fatiga | «Mueres ante {name}. El mundo apenas se inmuta.» |
| Hito cada 10 muertes | «Muerte número {deaths}. A estas alturas, el narrador y tú ya son viejos amigos.» |
| Críticos grandes (≥ 35% de tu vida, configurable) | «Los dados giran a tu favor: {amount} de un solo golpe.» |
| Level up | «Nivel {level}. El destino te observa con renovado interés.» |
| Botín épico / legendario | «Un legendario: {item}. Algunos nacen con suerte. Hoy, eres tú.» |
| Matar a otro jugador | «{name} cae ante ti. El narrador sonríe, oscuro y complacido.» |
| Saludo al entrar | «Despierta, {name}. La niebla se aparta.» |

Las frases saben dónde estás (zona), a qué hora del día y cuántas veces
has muerto: el generador las usa.

## Narración hablada

El narrador habla. Genera las líneas de voz con:

```
node tools/generate-voice.mjs
```

En macOS usa las voces nativas de `say` — Daniel (inglés británico) para
inglés, Mónica para español — gratis y offline (cámbialas con `--voice`).
Con `OPENAI_API_KEY` o `ELEVENLABS_API_KEY` obtienes voces de mayor calidad.
Cada idioma habla con su propia voz: esES (Mónica), esMX (Paulina) y enUS
(Daniel) en macOS. En los proveedores de nube eliges voz por idioma con
`--voice-id esMX=<id>,esES=<id>,enUS=<id>` o variables como
`ELEVENLABS_VOICE_ID_ESMX` (la global `ELEVENLABS_VOICE_ID` sirve de fallback).
El audio queda en `media/audio/` (fuera del repo) más un manifiesto que el
addon lee. Los nombres de archivo codifican la voz usada y los audios viejos
se barren en cada corrida: cambiar de voz simplemente funciona, sin borrar
`media/` a mano: `/reload` en el juego y cada evento reproduce su línea real —
hasta tres variantes por evento, elegidas al azar. `/nar voice` lo alterna.

Las líneas habladas están escritas *para la voz* (sin nombres ni cifras
dinámicas): el audio es por evento, mientras el recuadro de texto mantiene
la frase exacta con nombres y cantidades.

## No todo estático — tres fuentes de frases

`/nar style` decide de dónde salen:

- **static** — las tablas curadas en `Locale/<idioma>.lua`.
- **impro** — el generador procedural: plantillas × remates × contexto vivo
  (zona, hora, contador de muertes). 100% offline, variedad prácticamente
  infinita.
- **mixed** *(por defecto)* — mezcla de todo lo disponible.

### Packs generados por IA (opcional)

Los addons de WoW no tienen red — el sandbox de Lua no permite HTTP — así
que la generación con IA real ocurre **fuera** del juego. El script
compañero `tools/refresh-phrases.mjs` genera packs nuevos en
`Locale/gen.lua`, que el addon carga como un pool más:

```
ZAI_API_KEY=... node tools/refresh-phrases.mjs --locales esES,enUS --per 6
# o OLLAMA_BASE_URL=http://localhost:11434/v1, o OPENAI_API_KEY=...
```

Luego `/reload` en el juego. Puedes borrar `Locale/gen.lua` cuando quieras.

## Instalación

```
ln -s ~/Repositories/Personal/Narrator \
  "/Volumes/SSD/Applications/World of Warcraft/_forever_/Interface/AddOns/Narrator"
```

Si el cliente lo marca desactualizado, activa **Cargar addons
desactualizados** en la pantalla de personaje (el interface `16001` es la
mejor deducción del cliente 1.60.x hasta confirmar en juego).

## Comandos

```
/nar            ayuda
/nar on|off     encender / apagar
/nar mode       toast | rw | both      (dónde narra)
/nar lang       auto | enUS | esES ... (idioma del narrador)
/nar style      static | mixed | impro (origen de las frases)
/nar test <tipo>  death, pvpdeath, fall, fire, drown, crit,
                   levelup, loot, legendary, pvpkill, login, milestone
/nar demo       pequeña función de gala
/nar interval <s>   segundos mínimos entre narraciones menores
/nar crit <0.1-1>   umbral del crítico como fracción de tu vida máxima
/nar voice     narración hablada sí / no
/nar sound      silenciar / activar
/nar media      usar tus propios mp3
/nar stats      contadores de muerte y gloria
/nar reset      reiniciar contadores
```

## Sonidos propios

Crea `media/` dentro del addon con: `death.mp3`, `crit.mp3`, `level.mp3`,
`loot.mp3`, `kill.mp3`, `login.mp3`, y ejecuta `/nar media`. Sin ellos se
usan sonidos del juego. Solo MP3 (OGG no funciona en este cliente).

## Estructura

```
Narrator.toc              metadatos (interface 16001 = cliente 1.60.x)
Core.lua                    eventos, fusión de idiomas, selección y generador
Toast.lua                   el recuadro estilo BG3 (negro, borde dorado, Morpheus)
Locale/enUS.lua             idioma POR DEFECTO y base de fallback
Locale/esES.lua, esMX.lua   español (esMX alias de esES)
Locale/gen.lua              packs de frases IA (gestionado por tools/)
Locale/voice.lua            manifiesto de líneas habladas (gestionado por tools/)
tools/refresh-phrases.mjs   generador de frases con IA (Z.ai / OpenAI / Ollama)
tools/generate-voice.mjs    generador de voz TTS (say / OpenAI / ElevenLabs)
media/audio/                líneas de voz generadas (fuera del repo)
LOCALES.md                  cómo añadir un idioma (PR en 3 pasos)
```

Inspirado en el toque narrativo de addons como **Spoken**.
