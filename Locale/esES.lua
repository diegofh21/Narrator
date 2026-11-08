-- Narrator — esES locale (español de España).
-- Solo necesita sobreescribir lo que traduce; lo que falte cae a enUS.
-- Placeholders: {name} {amount} {level} {item} {zone} {tod} {deaths} {closer}

if not Narrator then return end
local N = Narrator
N.LOCALES = N.LOCALES or {}

local L = {}

L.name = "Español"
L.code = "esES"
L.font = "Fonts\\MORPHEUS.TTF"
L.lootPrefixes = { "Recibes botín", "Recibes" }
L.deathHeaderFormat = "MUERTE Nº %d — %s"

L.headers = {
    death     = "LA HISTORIA TE ALCANZA",
    milestone = "UN HITO SOMBRÍO",
    pvpdeath  = "TRAICIÓN DE MORTAL",
    fall      = "UN FINAL VERTICAL",
    fire      = "PACTO CON LAS LLAMAS",
    drown     = "EL MAR RECLAMA",
    fatigue   = "EL MAR RECLAMA",
    unknown   = "UN FINAL CONFUSO",
    crit      = "LOS DADOS GIRAN",
    levelup   = "LA LEYENDA CRECE",
    loot      = "EL AZAR SONRÍE",
    legendary = "EL AZAR SE INCLINA",
    pvpkill   = "OTRA HISTORIA TERMINA",
    login     = "LA HISTORIA CONTINÚA",
}

L.times = {
    night = "de noche",
    dawn = "al amanecer",
    morning = "por la mañana",
    afternoon = "por la tarde",
    dusk = "al atardecer",
}

L.phrases = {
    death = {
        "Mueres ante {name}. El mundo apenas se inmuta.",
        "Tu historia termina aquí. {name} escribe el epílogo.",
        "Caes. {name} se aleja sin mirar atrás. Así es la naturaleza de Azeroth.",
        "La muerte llega de la mano de {name}. El narrador suspira: ya perdió la cuenta.",
        "{name} te vence. Ningún bardo cantará esto. Ninguno debería.",
    },
    pvpdeath = {
        "{name} te arrebata la vida. La venganza será dulce... o no será nada.",
        "Otro aventurero, {name}, decide que tu historia terminó. El narrador toma nota.",
        "{name} te mata. Los dioses miran a otra parte. Siempre lo hacen.",
        "La hoja de {name} silba una vez, y el silencio te reclama.",
    },
    milestone = {
        "Muerte número {deaths}. A estas alturas, el narrador y tú ya son viejos amigos.",
        "{deaths} muertes. La saga se escribe sola, aunque nadie la pida.",
        "{deaths} caídas. El destino colecciona tus fracasos con cariño.",
    },
    fall = {
        "La gravedad siempre cobra su precio. Hoy, el tuyo.",
        "Vuelas. Brevemente. El suelo te espera, paciente como siempre.",
        "Ni pluma, ni hechizo, ni arrepentimiento. Solo el suelo.",
    },
    fire = {
        "El fuego no negocia. Solo consume. Y consume... bien.",
        "La lava era más caliente de lo que parecía. Ahora lo sabes. Tarde.",
        "Las llamas te reclaman. El narrador, con gusto, no interviene.",
    },
    drown = {
        "El océano guarda sus secretos. Y a los imprudentes.",
        "El aire era solo un préstamo. El agua lo reclama.",
        "Las profundidades te susurran. Por fin, silencio.",
    },
    fatigue = {
        "Nadie escapa del mar. Ni los héroes. Ni tú.",
        "El horizonte mintió. La fatiga no perdona a los soñadores.",
    },
    unknown = {
        "Mueres. Las circunstancias importan poco al final. El vacío, menos.",
        "La muerte te encuentra de incógnito. Hasta ella tiene secretos.",
    },
    crit = {
        "Los dados giran a tu favor: {amount} de un solo golpe. El destino te sonríe.",
        "Golpe crítico: {amount}. En algún lugar, un dios menor aplaude.",
        "{amount} de daño. Una obra maestra de la violencia.",
        "Crítico: {amount}. Por un instante, tú también eres una fuerza de la naturaleza.",
    },
    levelup = {
        "Nivel {level}. La leyenda crece, y con ella la deuda de historias por contar.",
        "Nivel {level}. El destino te observa con renovado interés.",
        "Nivel {level}. Las sombras se apartan... solo un poco. Disfrútalo.",
    },
    loot = {
        "Botín épico: {item}. Los dioses del azar se muestran generosos. Por ahora.",
        "Un objeto épico: {item}. El narrador arquea una ceja, impresionado.",
        "{item}. Épico, dicen. Tu nombre y esta pieza quedan atados.",
    },
    legendary = {
        "{item}. El narrador guarda silencio, por primera vez, con verdadera reverencia.",
        "Un legendario: {item}. Algunos nacen con suerte. Hoy, eres tú.",
        "{item}. Los dados del universo cayeron todos de tu lado. No lo desperdicies.",
    },
    pvpkill = {
        "{name} cae ante ti. El narrador sonríe, oscuro y complacido.",
        "Has vencido a {name}. Otra historia termina para que la tuya continúe.",
        "{name} muere. Tú respiras. La aritmética de Azeroth es simple.",
    },
    login = {
        "Despierta, {name}. La niebla se aparta. La historia continúa.",
        "Capítulo nuevo, {name}. Azeroth contuvo la respiración. Nadie lo notó, pero la contuvo.",
        "{name} regresa. Los cuervos se reacomodan, atentos.",
    },
}

L.generator = {
    closers = {
        "y el mundo no se inmuta",
        "y el narrador suspira",
        "como estaba escrito",
        "otra vez",
        "sin ceremonia",
        "para regocijo del narrador",
        "como decretaron los dados",
        "como manda la tradición",
    },
    templates = {
        death = {
            "{name} te vence, {closer}.",
            "En {zone}, {name} escribe tu última línea. {closer}.",
            "Caes ante {name} {tod}. {closer}.",
            "{name} fue más rápido. {closer}.",
        },
        pvpdeath = {
            "{name}, otro mortal, cierra tu capítulo. {closer}.",
            "Abatido por {name} {tod}. {closer}.",
        },
        fall = {
            "En {zone}, la gravedad cobra su deuda. {closer}.",
            "Vuelas. Brevemente. {closer}.",
        },
        fire = {
            "En {zone}, las llamas se quedan con lo que toman. {closer}.",
            "El fuego tuvo la última palabra. {closer}.",
        },
        drown = {
            "Frente a {zone}, el agua reclama su préstamo. {closer}.",
            "Las profundidades te guardan ya. {closer}.",
        },
        fatigue = {
            "El mar de {zone} no perdona a los soñadores. {closer}.",
        },
        crit = {
            "{amount} de un solo golpe. Los dados cantan, {closer}.",
            "Un crítico de {amount}, {closer}.",
            "{amount} de daño, {closer}.",
        },
        levelup = {
            "Nivel {level}. {closer}.",
            "La leyenda alcanza el nivel {level}. {closer}.",
        },
        loot = {
            "{item}. Los dioses del azar son generosos, {closer}.",
            "{item} tiene nuevo dueño. {closer}.",
        },
        legendary = {
            "{item}. Los dados del universo cayeron de tu lado, {closer}.",
        },
        pvpkill = {
            "{name} cae ante ti, {closer}.",
            "{name} muere para que tu historia continúe, {closer}.",
        },
        login = {
            "Despierta, {name}. {closer}.",
            "{name} regresa {tod}. {closer}.",
        },
        milestone = {
            "{deaths} muertes ya. {closer}.",
        },
    },
}

L.slash = {
    prefix = "El Narrador",
    help_title = "El Narrador v%s — comandos:",
    help_lines = {
        "  /nar on|off — encender o apagar",
        "  /nar mode toast|rw|both — dónde narra",
        "  /nar lang [código] — idioma del narrador (auto = idioma del cliente)",
        "  /nar style static|mixed|impro — origen de las frases (curadas, mezcla, improvisadas)",
        "  /nar test <tipo> — death, pvpdeath, fall, fire, drown, crit, levelup, loot, legendary, pvpkill, login, milestone",
        "  /nar demo — pequeña función de gala",
        "  /nar voice — activar/desactivar narración hablada (ejecuta antes tools/generate-voice.mjs)",
        "  /nar interval <s> · /nar crit <0.1-1> · /nar sound · /nar media",
        "  /nar stats · /nar reset",
    },
    on_msg = "El narrador despierta. Nada escapará a su ojo.",
    off_msg = "El narrador calla... por ahora.",
    mode_usage = "Uso: /nar mode toast|rw|both — actual: %s",
    mode_set = "Modo: %s (toast = recuadro, rw = aviso de banda, both = ambos)",
    sound_on = "Sonido: activado",
    voice_on = "Voz del narrador: activada (líneas habladas en media/audio/)",
    voice_off = "Voz del narrador: desactivada (texto + sonidos del juego)",
    sound_off = "Sonido: silenciado",
    media_on = "Mp3 propios en media/: activados (lee el README)",
    media_off = "Mp3 propios en media/: desactivados",
    interval_usage = "Uso: /nar interval <segundos>",
    interval_set = "Intervalo mínimo entre narraciones menores: %ss",
    crit_usage = "Uso: /nar crit <0.1-1> — actual: %s",
    crit_set = "Umbral de crítico: %d%% de tu vida máxima",
    stats_format = "Muertes: |cffff6a6a%d|r (caídas %d, fuego %d, ahogamientos %d, fatiga %d) · Críticos narrados: %d · Kills PvP: %d · Nivel: %d",
    reset_msg = "Contadores reiniciados. El narrador finge no recordar nada.",
    demo_msg = "Demo del narrador...",
    lang_usage = "Uso: /nar lang auto|<código> — disponibles: %s",
    lang_set = "El narrador hablará %s.",
    lang_auto = "Siguiendo el idioma del cliente (%s).",
    lang_unknown = "Idioma desconocido '%s'. Disponibles: %s",
    style_usage = "Uso: /nar style static|mixed|impro — actual: %s",
    style_set = "Estilo: %s (static = curadas, mixed = mezcla, impro = improvisa)",
}

N.LOCALES.esES = L
