import 'l10n.dart';

/// Español (neutro — es-ES/es-419 분리가 필요해지면 파일을 나눈다)
class L10nEs extends L10n {
  const L10nEs();

  @override
  String get localeTag => 'es';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => 'Versión';

  @override
  String get homeTitle => 'Notas';
  @override
  String get settingsTooltip => 'Reglas de limpieza';
  @override
  String get searchHint => 'Buscar';
  @override
  String get emptyList => 'No hay notas.\nEmpieza con "Pegar y ordenar".';
  @override
  String get pinnedLabel => 'Fijadas';
  @override
  String get notesLabel => 'Notas';
  @override
  String get newNoteTooltip => 'Nueva nota';
  @override
  String get pasteAndTidy => 'Nueva nota desde el portapapeles';
  @override
  String get clipboardEmpty => 'El portapapeles está vacío. Copia primero una respuesta de IA.';
  @override
  String get yesterday => 'Ayer';
  @override
  String get untitled => 'Sin título';
  @override
  String get deleteConfirmTitle => '¿Eliminar esta nota?';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Eliminar';

  @override
  String dateShort(int y, int m, int d) => '$d/$m/$y';

  @override
  String get seedTitle => 'Bienvenido a Skyblue Note';
  @override
  String get seedTag => 'Cómo usar';
  @override
  String get seedBody => [
        '¡Hola! 😊 Aquí tienes el resumen que pediste[1][2].',
        '',
        '# Skyblue Note',
        '',
        'La tabla está descuadrada. Pulsa la **varita** de abajo a la izquierda. 🎉',
        '',
        '| Empresa | Símbolo | Rentab. | Peso',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '|Nvidia|NVDA|+48.9%|22%|',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '|Tesla|TSLA|-8.3%|8%|',
        '',
        '> Al ordenar, las columnas se alinean. El menú «Tabla» la pega tal cual en una hoja de cálculo.',
        '',
        '## Lo que se va',
        '',
        '- [ ] Saludos de relleno y emojis 🙂',
        '- [ ] Notas al pie pegadas a la frase[3][4]',
        '- [ ] Un asterisco suelto al final de la línea**',
        '- [x] La tabla rota se reconstruye',
        '',
        '## Lo que se queda',
        '',
        'Los títulos, la **negrita** y las citas se quedan. En pantalla se ven como formato; al pegarlos en Notas o en un foro, las marcas desaparecen.',
        '',
        '---',
        '',
        '\t•\tViñetas envueltas en tabuladores — así pegan Grok y ChatGPT',
        '\t•\tEspacios   y tabuladores repetidos',
        '\t•\tEstas líneas sueltas también encuentran su sitio',
        '',
        '> ¿No te convence? [Restaurar original](https://ezlong.com/skybluenote) lo devuelve.',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get bodyFontSizeTitle => 'Tamaño del texto';

  @override
  String get bodyLineHeightTitle => 'Interlineado del cuerpo';

  @override
  String get bodyFontSizeSample =>
      'Descubre un espacio de trabajo Smart que ordena las muchas ideas de tu cabeza con pura Simplicity. Pega el texto, pulsa Limpiar y todo queda Clean.';

  @override
  String get wizardNothingToDo => 'No hay nada que cambiar';

  @override
  String wizardAppliedToast(int count) => 'Se aplicaron $count instrucción(es)';

  @override
  String get skipPreviewCheck => 'Omitir la vista previa en adelante';

  @override
  String get previewTitle2 => 'Vista previa antes de aplicar';

  @override
  String get previewSub2 => 'Muestra el resultado y pregunta antes de aplicar';
  @override
  String get metaTooltip => 'Título y etiquetas';
  @override
  String get pinTooltip => 'Fijar arriba';
  @override
  String get unpinTooltip => 'Dejar de fijar';

  @override
  String get unpinConfirmTitle => '¿Quitar esta nota de los fijados?';

  @override
  String get unpinConfirmBody =>
      'Mantén pulsada una nota en la lista para volver a fijarla.';
  @override
  String get deleteTooltip => 'Eliminar';
  @override
  String get titleHint => 'Título (automático)';
  @override
  String get titleTapHint => 'Añadir título';
  @override
  String get sourceNone => 'Sin fuente';
  @override
  String get sourceOther => 'Otro';
  @override
  String get tagsHint => 'Etiquetas (separadas por comas)';
  @override
  String get tagAiButton => 'Etiquetas con IA';
  @override
  String get tagAiWorking => 'Buscando etiquetas…';
  @override
  String get tagAiNone => 'No se encontraron palabras clave';
  @override
  String get tagAiLocalNote => 'Sin clave de IA: elegidas en el dispositivo';
  @override
  String get tagsBoxHint => 'Escribe una etiqueta y una coma';
  @override
  String get tagRemoveTip => 'Eliminar etiqueta';
  @override
  String get bodyHint => 'Pega o escribe aquí';
  @override
  String get noteNotFound => 'Nota no encontrada';
  @override
  String get revertedToast => 'De vuelta al original. El texto anterior está en el historial.';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => 'Volver al original';

  @override
  String get revertConfirmTitle => '¿Volver al original?';

  @override
  String get revertConfirmBody =>
      'La nota vuelve al texto que pegaste al principio. Se perderán la limpieza y los cambios que hiciste después.\n\nAún podrás volver a tus ediciones anteriores: el menú → Historial de versiones guarda el texto actual como primera entrada.';

  @override
  String get revertConfirmOk => 'Volver';

  @override
  String get okAction =>
      'Aceptar';

  @override
  String get revertDoneTitle =>
      'Se volvió al original';

  @override
  String get revertDoneBody =>
      'El texto en el que trabajabas no se ha perdido.\n\nAbre el menú → Historial de versiones: la primera entrada es el texto de justo antes. Tócala para recuperarlo cuando quieras.';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => 'Lista con viñetas';

  @override
  String get listDashAction => 'Lista con guiones';

  @override
  String get listNumberAction => 'Lista numerada';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => 'Fuente';

  @override
  String sourceSaved(String name) => 'Fuente guardada: $name';

  @override
  String sourceDetected(String name) => 'Fuente detectada: $name';

  @override
  String get sourceCleared => 'Fuente borrada';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'Carpeta';

  @override
  String get folderNone => 'Sin carpeta';

  @override
  String get folderNew => 'Nueva carpeta';

  @override
  String get folderNameHint => 'Nombre de la carpeta';

  @override
  String get folderCleared => 'Quitado de la carpeta';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => 'Gestionar carpetas';

  @override
  String get folderRename => 'Cambiar nombre';

  @override
  String get folderDelete => 'Eliminar carpeta';

  @override
  String get folderReorderHint => 'Arrastra para reordenar';

  @override
  String get folderManageEmpty => 'Aún no hay carpetas';

  @override
  String get folderDupName => 'Ya existe una carpeta con ese nombre';

  @override
  String get folderDeleted => 'Carpeta eliminada';

  @override
  String get folderRenamed => 'Nombre cambiado';

  @override
  String folderDeleteBody(String name, int count) =>
      'Las $count notas de «$name» seguirán en Todas. Las notas no se eliminan.';

  @override
  String folderNoteCount(int count) => '$count notas';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => 'Comprobando si de verdad se puede usar…';

  @override
  String get aiPingOk => 'La edición funciona. Ya puedes empezar.';

  @override
  String aiPingFailed(String err) => 'La lista llegó, pero la llamada de edición fue rechazada — $err';

  @override
  String get aiAdvancedNote => 'Normalmente no hace falta tocar esto. Basta con la clave.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => 'Papel';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWalnut => 'Nogal';

  @override
  String get paperNight => 'Noche';

  @override
  String get paperSky => 'Cielo';

  @override
  String get themeSystemNote =>
      'Si sigue al dispositivo, la app se oscurece cuando lo hace el dispositivo.';

  @override
  String folderMoved(String name) => 'Movido a $name';
  @override
  String appliedDone(String summary) => 'Aplicado — $summary';

  @override
  String get undoTip => 'Deshacer';
  @override
  String get redoTip => 'Rehacer';
  @override
  String get moveLeftTip => 'Mover a la izquierda';
  @override
  String get moveRightTip => 'Mover a la derecha';
  @override
  String get lineStartTip => 'Inicio de línea';
  @override
  String get lineEndTip => 'Fin de línea';
  @override
  String get indentTip => 'Sangría';

  @override
  String get todoAction => 'Tarea';
  @override
  String get hideKeyboardTip => 'Ocultar teclado';

  @override
  String get tidyAction => 'Ordenar';
  @override
  String get wizardAction => 'IA';
  @override
  String get tableAction => 'Tabla';
  @override
  String get replaceAction => 'Reemplazar';
  @override
  String get copyAction => 'Copiar';
  @override
  String get undoAction => 'Deshacer';

  @override
  String get noTablesFound => 'No se encontraron tablas en esta nota';
  @override
  String tableInfo(int n, int cols, int rows) => 'Tabla $n — $cols col × $rows filas';
  @override
  String get forSpreadsheet => 'Para hojas de cálculo';
  @override
  String get copiedSpreadsheet => 'Copiado — pégalo en una celda de Google Sheets o Excel';
  @override
  String get copiedCsv => 'Copiado como CSV';
  @override
  String get copiedMarkdown => 'Copiado como tabla Markdown';

  @override
  String get wizardTitle => 'Edición con IA';
  @override
  String get wizardHint =>
      'Da instrucciones en tu idioma. Ej.:\nDeja 2 líneas antes de los subtítulos y 1 después\nReemplaza MS por Microsoft';
  @override
  String get favSaveButton => 'Guardar como favorito';
  @override
  String get favListTitle => 'Instrucciones favoritas';
  @override
  String get favUse => 'Usar';
  @override
  String get favEmpty => 'Aún no hay instrucciones guardadas';
  @override
  String get favRemove => 'Quitar';
  @override
  String get favSavedToast => 'Guardado';
  @override
  String appliedPrefix(String what) => 'Aplicado · $what';
  @override
  String unknownPrefix(String what) => 'De esto se encarga la IA · $what';
  @override
  String get aiKeyPromo => 'Añade una clave de API de IA en Ajustes para procesar también estas ediciones libres.';
  @override
  String get aiBusyLabel => 'IA editando…';
  @override
  String get aiWorking => 'La IA está editando según tus instrucciones. Puede tardar un poco…';
  @override
  String get aiEmptyResponse => 'Respuesta vacía';
  @override
  String aiCallFailed(String error) => 'Error al llamar a la IA: $error';
  @override
  String get aiAppliedToast => 'Edición de IA aplicada — recuperable con Deshacer';
  @override
  String get close => 'Cerrar';
  @override
  String get interpretApply => 'Interpretar y aplicar';

  @override
  String get replaceTitle => 'Reemplazar';
  @override
  String get findLabel => 'Buscar';
  @override
  String get replaceWithLabel => 'Reemplazar por (\\n = salto de línea)';
  @override
  String get regexLabel => 'Expresión regular';
  @override
  String get saveAsRule => 'Guardar como regla de reemplazo automático';
  @override
  String get saveAsRuleSub => 'Se aplicará siempre en cada "Ordenar" futuro';
  @override
  String get invalidRegex => 'La expresión regular no es válida';
  @override
  String get noMatches => 'No hay coincidencias';
  @override
  String replacedCount(int count) => 'Se reemplazó en $count lugares';
  @override
  String get savedRuleSuffix => ' · guardado como regla de reemplazo automático';
  @override
  String get replaceAllAction => 'Reemplazar todo';

  @override
  String get copyAll => 'Copiar todo';

  @override
  String get copyPlainSub =>
      'Texto sin marcas de markdown';

  @override
  String get copyRaw => 'Copiar como markdown';

  @override
  String get copyRawSub =>
      'Para Notion, Slack, GitHub y otras apps que leen markdown';
  @override
  String get copiedAll => 'Se copió todo el texto';
  @override
  String get tidyCopy => 'Ordenar y copiar';
  @override
  String get tidyCopySub => 'La nota queda igual; solo se copia el resultado ordenado';
  @override
  String tidyCopied(String summary) => 'Ordenado y copiado — $summary';
  @override
  String get copyTableSpreadsheet => 'Copiar tablas para hojas de cálculo';
  @override
  String get copiedTableSpreadsheet => 'Tablas copiadas para hojas de cálculo';

  @override
  String previewTitle(String preset) => '$preset — Vista previa';
  @override
  String warningPrefix(String warning) => 'Atención: $warning';
  @override
  String get tidyResultLabel => 'Resultado';
  @override
  String get originalLabel => 'Original';
  @override
  String get apply => 'Aplicar la limpieza';

  @override
  String get presetAiName =>
      'Limpieza estándar';
  @override
  String get presetAiDesc =>
      'Deja legible una respuesta de IA pegada. Casi siempre basta con esto';
  @override
  String get presetStripName =>
      'Quitar todos los símbolos';
  @override
  String get presetStripDesc =>
      'Para chats y SMS. Se van todas las marcas y emojis; la tabla queda alineada';
  @override
  String get presetMinimalName =>
      'Solo la pelusa';
  @override
  String get presetMinimalDesc =>
      'Conserva la estructura, quita solo lo invisible';
  @override
  String get presetTablesName =>
      'Solo tablas';
  @override
  String get presetTablesDesc =>
      'Para pegar directamente en Excel o Google Sheets';
  @override
  String get presetBlogName =>
      'Para blogs';
  @override
  String get presetBlogDesc =>
      'Conserva las direcciones de los enlaces, quita los símbolos';

  @override
  String get tidySample => [
        '## Resumen de hoy 😊',
        '',
        'Las **claves** son tres[1][2].',
        '',
        '- Primer punto',
        '- Segundo punto',
        '',
        '> Una línea citada',
        '',
        'Más en el [blog](https://ezlong.com)',
        '',
        '| Concepto | Valor |',
        '|---|---|',
        '|Ventas|120|',
      ].join('\n');

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get menuAppSettings => 'Ajustes de la app';

  @override
  String get menuAiKey => 'Clave API de IA';

  @override
  String get syncTitle => 'Sincronización';
  @override
  String get syncAppleOnly => 'Solo Apple';

  @override
  String get syncScopeTitle =>
      'Alcance de la sincronización';

  @override
  String get syncScopeShared =>
      'Sincronizado entre dispositivos Apple: notas, reglas de limpieza, reglas de reemplazo añadidas, carpetas, instrucciones de IA guardadas';

  @override
  String get syncScopeDevice =>
      'Por dispositivo: tamaño de texto, interlineado, papel, apariencia, orden';

  @override
  String get syncScopePlatform =>
      'Por ahora la sincronización automática solo funciona entre dispositivos Apple (iPhone, iPad, Mac). En Android y Windows, usa Exportar copia de seguridad e Importar desde el menú';

  @override
  String get typographyTitle => 'Texto y espaciado';

  @override
  String get syncScopeNever =>
      'La clave de API de IA no se sube a iCloud, así que debe introducirse en cada dispositivo';
  @override
  String get syncWhereTitle =>
      'Dónde guardarlo';
  @override
  String get syncBackendNone =>
      'No sincronizar';
  @override
  String get syncBackendNoneSub =>
      'Solo en este dispositivo';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      'Entre iPhone, iPad y Mac';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      'También Android, Windows y la web';
  @override
  String get syncSoon =>
      'En preparación';
  @override
  String get syncSectionState =>
      'Estado actual';
  @override
  String get syncNowAction =>
      'Sincronizar ahora';
  @override
  String get syncLastNever =>
      'Aún no se ha sincronizado';
  @override
  String get syncTroubleTitle =>
      'Si algo va mal';
  @override
  String get syncTroubleNote =>
      'Sincronizar no es respaldar. Si borras en un sitio, se borra en todos. Exporta un archivo de vez en cuando con lo que importa.';
  @override
  String syncLastAt(String when) => 'Última sincronización: $when';

  @override
  String get syncStateOn => 'Las mismas notas en iPhone, iPad y Mac';

  @override
  String get syncStateOff => 'Activa iCloud Drive en los ajustes del dispositivo';

  @override
  String get syncStateSyncing => 'Conectando con iCloud… tarda de unos segundos a un minuto';

  @override
  String get aiKeyNotSynced => 'Tus notas se sincronizan en todos tus dispositivos mediante iCloud. Tu clave API no: introdúcela en cada dispositivo.';

  @override
  String get autoTagTitle => 'Etiquetar automáticamente';

  @override
  String get autoTagSub =>
      'Al pausar tras editar, la IA vuelve a extraer las etiquetas. Las notas cuyas etiquetas editaste tú quedan intactas';

  @override
  String get syncStateSignedOut => 'Toca para ver cómo';

  @override
  String get syncHelpTitle => 'Cómo activar iCloud';

  @override
  String get syncHelpSteps =>
      '1. Ajustes › tu nombre arriba › iCloud\n2. Comprueba que iCloud Drive esté activado — si está apagado, ninguna app sincroniza\n3. Bloquea y desbloquea el iPhone, vuelve aquí y pulsa Comprobar de nuevo\n\nCompruébalo en la app Archivos, no en Ajustes. Si ves una carpeta Skyblue Note en Archivos › iCloud Drive, ya está listo.';

  @override
  String get syncOpenSettings => 'Abrir Ajustes';

  @override
  String get syncRecheck => 'Comprobar de nuevo';

  @override
  String get syncHelpNote =>
      'Si acabas de instalar la app, puede tardar un par de minutos en estar lista. Toca Comprobar de nuevo.';

  @override
  String get sortFilterTooltip => 'Ordenar y filtrar';

  @override
  String get sortFilterTitle => 'Ordenar y filtrar';

  @override
  String get sortLabel => 'Orden';

  @override
  String get sortUpdated => 'Editado recientemente';

  @override
  String get sortCreated => 'Fecha de creación';

  @override
  String get sortByTitle => 'Título';

  @override
  String get filterSourceLabel => 'Fuente';

  @override
  String get filterTagLabel => 'Etiqueta';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterReset => 'Restablecer';

  @override
  String get selectWord => 'Seleccionar';

  @override
  String get tagAiNeedKey => 'Introduce una clave API en Ajustes para usar el etiquetado automático con IA.';

  @override
  String get toggleListTooltip => 'Ocultar o mostrar la lista';

  @override
  String get aiDetecting => 'Comprobando a qué proveedor pertenece esta clave…';

  @override
  String get aiErrNoCredits => 'La clave está bien, pero la cuenta no tiene saldo. Añade un método de pago o créditos en el sitio del proveedor. Si prefieres no pagar, prueba una clave de Google Gemini (empieza por AIza…) — tiene nivel gratuito.';

  @override
  String get aiErrBadKey => 'La clave fue rechazada. Revisa si hay espacios o comillas sobrantes y, si sigue igual, genera una clave nueva.';

  @override
  String get aiErrRateLimit => 'El proveedor está saturado ahora mismo. No es un fallo de la app: inténtalo de nuevo en un momento.';

  @override
  String get aiErrNoModel => 'Ese modelo no está disponible en esta cuenta. Elige otro en \'Avanzado — elegir modelo\'.';

  @override
  String get aiErrNetwork => 'No se pudo conectar a internet. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get multiSelectStart => 'Eliminar varias notas';

  @override
  String get selectAllTooltip => 'Seleccionar todo / nada';

  @override
  String get deleteSelected => 'Eliminar selección';

  @override
  String get deleteSelectedDone => 'Listo';

  @override
  String get deleteSelectedConfirm => '¿Eliminar las notas seleccionadas?';

  @override
  String deleteSelectedBody(int n) => n == 1
          ? '1 nota irá a la papelera. Puedes restaurarla en 30 días.'
          : '$n notas irán a la papelera. Puedes restaurarlas en 30 días.';

  @override
  String get trashTitle => 'Papelera';

  @override
  String get trashSubtitle => 'Las notas eliminadas se guardan 30 días';

  @override
  String get trashEmpty => 'La papelera está vacía';

  @override
  String get trashRestore => 'Recuperar';

  @override
  String get trashDeleteNow => 'Eliminar ahora';

  @override
  String get trashEmptyAll => 'Vaciar';

  @override
  String get trashEmptyConfirm => 'Vaciar la papelera no se puede deshacer. ¿Continuar?';

  @override
  String get trashRestored => 'Recuperada';

  @override
  String trashDaysLeftLabel(int days) => 'Se eliminará definitivamente en $days días';

  @override
  String get exportSectionTitle =>
      'Importar y exportar';

  @override
  String get exportSubtitle =>
      'Tus notas pueden salir cuando quieras. Markdown se abre en Notas de Apple, Obsidian, Notion y más.';

  @override
  String get exportNote =>
      'Exportar esta nota';

  @override
  String get exportAllMd =>
      'Exportar todas las notas';

  @override
  String get exportAllMdSub =>
      'Todas las notas en Markdown, en un zip';

  @override
  String get exportBackup =>
      'Guardar copia de seguridad';

  @override
  String get exportBackupSub =>
      'Un archivo que lo restaura todo aquí (sin tu clave API)';

  @override
  String get exportFailed =>
      'No se pudo exportar';

  @override
  String get printAction =>
      'Imprimir';

  @override
  String get exportPdf =>
      'Exportar como PDF';

  @override
  String get pdfFailed =>
      'No se pudo crear el PDF';

  @override
  String get exportEmpty =>
      'No hay notas para exportar';

  @override
  String get choosePreset => 'Elegir cómo limpiar';

  @override
  String get importFiles =>
      'Importar desde archivos';

  @override
  String get importFilesSub =>
      'Los archivos Markdown y de texto se convierten en notas. Las copias de seguridad también se restauran aquí';

  @override
  String get importAppend =>
      'Cargar un archivo y añadirlo al texto';

  @override
  String get importNone =>
      'No se importó nada';

  @override
  String importDone(int n) => 'Se importaron $n notas';

  @override
  String get sourceGuessSuffix => '(estimado)';

  @override
  String get splitEmpty => 'Elige una nota a la izquierda';

  @override
  String get historyTitle =>
      'Historial de versiones';

  @override
  String get historySub =>
      'Vuelve al texto anterior a una limpieza o reemplazo';

  @override
  String get historyEmpty =>
      'Aún no hay nada a lo que volver';

  @override
  String get historyRestore =>
      'Restaurar';

  @override
  String get historyOriginal =>
      'Tal como se pegó';

  @override
  String get historyWhyTidy => 'Antes de ordenar';

  @override
  String get historyWhyAi => 'Antes de la edición con IA';

  @override
  String get historyWhyReplace => 'Antes de reemplazar';

  @override
  String get historyWhyRevert => 'Antes de volver al original';

  @override
  String get historyWhyRestore => 'Antes de restaurar';

  @override
  String get widgetEmpty => 'Aún no hay notas';

  @override
  String get widgetAllLocked => 'Las notas bloqueadas no aparecen en el widget';

  @override
  String get attachTitle => 'Adjuntos';

  @override
  String get attachAdd => 'Adjuntar archivo';

  @override
  String get attachRemove => 'Quitar adjunto';

  @override
  String get attachRemoveBody => 'El archivo se borrará de este dispositivo. No se puede deshacer.';

  @override
  String get attachFailed => 'No se pudo adjuntar el archivo';

  @override
  String get attachNotHere => 'Este archivo está en otro dispositivo';

  @override
  String attachAndMore(int n) => 'y ${n} más';

  @override
  String attachOther(String device, String what) => 'Adjunto: ${what} está adjunto en tu ${device} (solo visible en ese dispositivo)';

  @override
  String deviceName(String kind) {
    switch (kind) {
      case 'iphone':
        return 'iPhone';
      case 'ipad':
        return 'iPad';
      case 'mac':
        return 'Mac';
      case 'android':
        return 'teléfono Android';
      case 'windows':
        return 'PC con Windows';
      case 'web':
        return 'web';
      default:
        return 'otro dispositivo';
    }
  }

  @override
  String historyUnknownTime(int n) => 'Versión anterior $n';

  @override
  String get selUnitSentence => 'Frase';

  @override
  String get selUnitLine => 'Línea';

  @override
  String get selUnitPara => 'Párrafo';

  @override
  String get selUnitAll => 'Todo';

  @override
  String get selStartLeft => 'Inicio izq.';

  @override
  String get selStartRight => 'Inicio der.';

  @override
  String get selEndLeft => 'Fin izq.';

  @override
  String get selEndRight => 'Fin der.';

  @override
  String get selClear => 'Quitar selección';

  @override
  String get paperTitle => 'Fondo del editor';

  @override
  String get paperSub => 'Fondo y pauta como conjunto. El interlineado sigue el tamaño de letra.';

  @override
  String get paperNone => 'Liso';

  @override
  String get paperMoleskine => 'Moleskine';

  @override
  String get paperSepia => 'Sepia';

  @override
  String get paperManuscript => 'Manuscrito';

  @override
  String get paperFrost => 'Escarcha';

  @override
  String get lockSectionTitle => 'Bloqueo';

  @override
  String get lockTitle => 'Bloqueo de la app';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? 'Abre la app con tu huella, tu rostro o el bloqueo de pantalla.'
      : vendor == 'windows'
          ? 'Abre la app con Windows Hello o el PIN del dispositivo.'
          : 'Abre la app con Face ID, Touch ID o el código del dispositivo.';

  @override
  String get lockNote => 'Este bloqueo impide que alguien que tome tu dispositivo abra la app. No cifra los archivos guardados en el dispositivo.';

  @override
  String get lockDelayTitle => 'Bloquear tras';

  @override
  String get lockDelayNow => 'Inmediatamente';

  @override
  String get lockDelay1m => 'Tras 1 minuto';

  @override
  String get lockDelay5m => 'Tras 5 minutos';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockLocked => 'Bloqueado';

  @override
  String lockUnavailable(String vendor) => vendor == 'android'
      ? 'La huella, el reconocimiento facial y el bloqueo de pantalla no están disponibles aquí.'
      : vendor == 'windows'
          ? 'Windows Hello y el PIN del dispositivo no están disponibles aquí.'
          : 'Face ID, Touch ID y el código del dispositivo no están disponibles aquí.';

  @override
  String get lockReasonOpen => 'Verifica para abrir tus notas';

  @override
  String get lockReasonOn => 'Verifica para activar el bloqueo';

  @override
  String get lockReasonOff => 'Verifica para desactivar el bloqueo';

  @override
  String get noteLock => 'Bloquear esta nota';

  @override
  String get noteUnlock => 'Desbloquear esta nota';

  @override
  String get noteLocked => 'Nota bloqueada';

  @override
  String get lockReasonNote => 'Abrir la nota bloqueada';

  @override
  String get noteLockDone => 'Nota bloqueada';

  @override
  String get noteUnlockDone => 'Nota desbloqueada';

  @override
  String get syncDiagSignedOut => 'Este dispositivo no ha iniciado sesión en iCloud. Inicia sesión primero.';

  @override
  String get syncDiagNoContainer => 'Has iniciado sesión, pero esta app aún no tiene su espacio de iCloud. Actívalo con los pasos de abajo.';

  @override
  String get syncDiagPreparing => 'El espacio ya existe. Esperando a que termine de prepararse.';

  @override
  String get syncRecheckWhat => 'Vuelve a consultar el estado de iCloud al dispositivo, desde cero.';

  @override
  String get syncRecheckOk => 'iCloud está activado';

  @override
  String get syncRecheckStill => 'Aún no está activado. Actívalo en Ajustes y vuelve a tocar. Si acabas de activarlo, inténtalo de nuevo en uno o dos minutos.';

  @override
  String get syncOpenFailed => 'No se pudo abrir Ajustes. Ábrelo desde la pantalla de inicio.';

  @override
  String get syncOpenManual => 'Abre Ajustes tú mismo: pantalla de inicio › Ajustes › tu nombre arriba › iCloud.';

  @override
  String get menuFile => 'Archivo';

  @override
  String get menuClose => 'Cerrar';

  @override
  String get menuPrefs => 'Ajustes…';

  @override
  String get appliedTitle => 'Todo bien ordenado';

  @override
  String get tidyRulesTitle => 'Reglas de limpieza';

  @override
  String get tidyRulesSub =>
      'Define qué hace Ordenar con tu texto. Lo que elijas aquí solo afecta al orden básico; las demás formas hacen justo lo que dice su nombre.';

  @override
  String get syncOnTitle => 'Activado';

  @override
  String get syncOffTitle => 'Desactivado';

  @override
  String get syncSignedOutTitle => 'Falta iniciar sesión';

  @override
  String pastedFrom(String src, String date) =>
      'de $src el $date';

  @override
  String pastedOn(String date) => 'pegado el $date';

  @override
  String staleWarn(int days) =>
      'Esta respuesta tiene $days días. El modelo puede haber cambiado.';
  @override
  String get settingsSecView => 'Pantalla';
  @override
  String get settingsSecTidy => 'Reglas de limpieza';
  @override
  String get settingsSecWhen => 'Al limpiar';
  @override
  String get settingsSecInfo => 'Información';
  @override
  String get emphTitle => 'Énfasis en negrita (**texto**)';
  @override
  String get emphSub => 'En frases completas de más de 40 caracteres solo se quitan las marcas';
  @override
  String get emphQuoteSingle => "Comillas simples 'énfasis'";
  @override
  String get emphQuoteDouble => 'Comillas dobles "énfasis"';
  @override
  String get removeLabel => 'Quitar';
  @override
  String get keepLabel => 'Mantener';
  @override
  String get hrTitle => 'Separadores (---)';
  @override
  String get headingTitle => 'Títulos (#, ##)';

  @override
  String get quoteTitle => 'Citas (> texto)';
  @override
  String get headingStrip => 'Dejar solo el texto';
  @override
  String get headingKeep => 'Mantener tal cual';
  @override
  String get headingPrefix => 'Anteponer ■';
  @override
  String get headingBracket => '[Corchetes]';
  @override
  String get bulletTitle => 'Viñetas (-, *)';
  @override
  String get bulletHyphen => 'Guion -';
  @override
  String get bulletMiddot => 'Punto medio ·';
  @override
  String get bulletDot => 'Viñeta •';
  @override
  String get bulletWhite => 'Viñeta blanca ◦';
  @override
  String get bulletKeep => 'Mantener el símbolo original';
  @override
  String get bulletIndentTitle => 'Sangría de viñetas';
  @override
  String get indent2 => '2 espacios';
  @override
  String get indent4 => '4 espacios';
  @override
  String get indentNone => 'Ninguna';
  @override
  String get headingPadTitle => 'Espaciado de subtítulos';
  @override
  String get headingPadSub =>
      '2 líneas antes y 1 después — usa un carácter invisible (ㅤ) que se conserva en apps de chat y blogs';
  @override
  String get citationsTitle => 'Quitar enlaces de citas';
  @override
  String get citationsSub => 'Elimina los números de nota del texto y la lista de fuentes del final';
  @override
  String get monoEditorTitle => 'Tablas en monoespaciado';
  @override
  String get monoEditorSub => 'Alinea con precisión las columnas de tablas y código. El texto conserva la fuente del dispositivo';
  @override
  String get dashListTitle => 'Convertir series con guiones en listas';
  @override
  String get dashListSub => 'Divide series de una línea como "– a – b – c" en una lista por líneas';
  @override
  String get fillerHeadingTitle => 'Ordenar subtítulos con carácter invisible';
  @override
  String get fillerHeadingSub => 'Aplica las reglas de espaciado y títulos a pseudotítulos envueltos en ㅤ';
  @override
  String get aiSectionTitle => 'Conexión de edición IA';
  @override
  String get aiSectionDesc =>
      'Con una clave API, la IA atiende instrucciones libres como "hazlo más corto". La limpieza usa reglas del dispositivo y no necesita clave; solo la edición IA la usa.';
  @override
  String get aiKeyHint => 'Clave API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get menuTidyPreview => 'Vista previa de la limpieza';
  @override
  String get dividerTip => 'Separador';
  @override
  String get syncScroll => 'Desplazar a la vez';
  @override
  String get pasteTipTitle => 'Que no pregunte al pegar';
  @override
  String get pasteTipSub => 'Quita de una vez el aviso que el iPhone muestra en cada pegado';
  @override
  String get pasteTipBody =>
      'El iPhone pide permiso cada vez que una app lee el portapapeles. Esta app empieza por pegar, así que ese aviso sale muy a menudo.\n\nCámbialo una vez y no vuelve a preguntar.\n\n1. Pulsa \'Abrir Ajustes\' abajo\n2. Pulsa \'Pegar desde otras apps\'\n3. Elige \'Permitir\'\n\nAun permitido, esta app lee el portapapeles solo en el momento en que pulsas Pegar. Nunca mira por su cuenta.';
  @override
  String get pasteTipLater => 'Más tarde';
  @override
  String get adClose => 'Cerrar anuncios';
  @override
  String get noteDuplicate => 'Duplicar';
  @override
  String get noteDuplicated => 'Duplicada';
  @override
  String get adSponsored => 'Patrocinado';
  @override
  String get sponsorTitle => 'Un anuncio financia la próxima actualización';
  @override
  String get sponsorBody =>
      'Las mejores funciones y las actualizaciones constantes necesitan tu apoyo. Mira un anuncio hasta el final y hoy la app no mostrará más anuncios.';
  @override
  String get sponsorWatch => 'Ver un anuncio para apoyar';
  @override
  String get sponsorSkip => 'Omitir';
  @override
  String get sponsorLoading => 'Cargando anuncio…';
  @override
  String get sponsorFailed => 'No se pudo cargar el anuncio. Inténtalo de nuevo en un momento.';
  @override
  String get moreTooltip => 'Más';
  @override
  String get sponsorGoPremium => 'Hazte Premium, sin anuncios';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Sin anuncios, en todos tus dispositivos';
  @override
  String get premiumPitchSub => 'US\$29.99 una vez o US\$1.99/mes · iPhone, iPad y Mac juntos';
  @override
  String get premiumBody => 'Premium elimina todos los anuncios y desbloquea Skyblue Note en iPhone, iPad y Mac. Una sola compra cubre los tres. Tu apoyo construye la próxima actualización.';
  @override
  String get premiumLifetime => 'De por vida · US\$29.99';
  @override
  String get premiumMonthly => 'Mensual · US\$2.99/mes';
  @override
  String get premiumComingSoon => 'Las compras se activarán en la versión de la App Store. Ya falta poco.';
  @override
  String get limitTitle => 'Has agotado los usos gratuitos de hoy';
  @override
  String limitTidyBody(int n) => 'El plan gratuito incluye $n limpiezas al día. Se renueva mañana; Premium quita el límite.';
  @override
  String limitWizardBody(int n) =>
      'El plan gratuito incluye $n ediciones IA al día. Se reinicia mañana; Premium quita el límite.';
  @override
  String get limitSeePremium => 'Ver Premium';
  @override
  String get premiumYearly => 'Anual · US\$14.99/año';
  @override
  String get premiumLifetimeNote => 'Precio de lanzamiento · normal US\$39.99';

  @override
  String trialBadge(int days) => 'Prueba ilimitada · quedan $days días';

  @override
  String get trialEndedTitle => 'Tu prueba ilimitada ha terminado';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      'Durante la prueba hiciste $tidy limpiezas y $wiz ediciones IA. A partir de ahora el plan gratuito incluye $tidyLimit limpiezas y $wizLimit ediciones IA al día. Premium quita el límite.';
  @override
  String get themeTitle => 'Apariencia';
  @override
  String get themeSystem => 'Según el dispositivo';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';
  @override
  String get aiKeyVerify => 'Comprobar clave';
  @override
  String get aiKeyChecking => 'Comprobando…';
  @override
  String get aiKeyUnknownFormat => 'No se pudo identificar el proveedor. Se consultó a los cuatro y ninguno aceptó esta clave. Copia y pega la clave de nuevo.';
  @override
  String get aiAdvancedLabel => 'Avanzado — elegir modelo manualmente';
  @override
  String get aiManualModelHint => 'Escriba el nombre del modelo (ej.: gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => 'Automático: $provider · $model';
  @override
  String aiModelsFound(int n) => '$n modelos disponibles confirmados.';
  @override
  String aiListFailed(String error) => 'No se pudo obtener la lista de modelos ($error). Se usará la lista de reserva integrada.';
  @override
  String aiModelSwitched(String model) => 'El modelo anterior dejó de responder; se cambió a $model.';
  @override
  String get rulesSectionTitle => 'Reglas de reemplazo automático';
  @override
  String get rulesSectionDesc =>
      'Se aplican de arriba abajo. Usa \\n en el reemplazo para saltos de línea. Los bloques de código no se tocan.';
  @override
  String get addRule => 'Añadir regla';
  @override
  String get settingsFooter =>
      'Los ajustes se guardan al instante y se aplican desde el próximo "Ordenar". Las notas ya ordenadas no cambian retroactivamente.';
}
