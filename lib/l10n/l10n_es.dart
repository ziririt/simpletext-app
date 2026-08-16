import 'l10n.dart';

/// Español (neutro — es-ES/es-419 분리가 필요해지면 파일을 나눈다)
class L10nEs extends L10n {
  const L10nEs();

  @override
  String get localeTag => 'es';

  @override
  String get appTitle => 'SimpleText';

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
  String get seedTitle => 'Bienvenido a SimpleText';
  @override
  String get seedTag => 'Cómo usar';
  @override
  String get seedBody => [
        'Cómo usar SimpleText',
        '',
        '1. Copia una respuesta de ChatGPT o Claude y pulsa "Pegar y ordenar".',
        '2. Compara el original y el resultado en la vista previa y pulsa "Aplicar". Listo.',
        '3. En notas con tablas, el botón "Tabla" las copia para hojas de cálculo (TSV).',
        '4. Toda limpieza se puede revertir con un solo Deshacer.',
        '',
        'Abajo hay una tabla rota a propósito. Pulsa "Ordenar" para ver la reparación.',
        '',
        '| Acción | Ticker | Retorno | Peso',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5%',
        '| Nvidia | NVDA | +48.9% | 22% | celda extra |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get autoTidy => 'Limpieza automática';

  @override
  String get bodyFontSizeTitle => 'Tamaño del texto';

  @override
  String get bodyFontSizeSample =>
      'Descubre un espacio de trabajo Smart que ordena las muchas ideas de tu cabeza con pura Simplicity. Pega el texto, pulsa Limpiar y todo queda Clean.';

  @override
  String get wizardNothingToDo => 'No hay nada que cambiar';

  @override
  String wizardAppliedToast(int count) => 'Se aplicaron \$count instrucción(es)';

  @override
  String get skipPreviewCheck => 'Omitir la vista previa en adelante';

  @override
  String get previewTitle2 => 'Vista previa antes de aplicar';

  @override
  String get previewSub2 => 'Muestra el resultado y pregunta antes de aplicar';
  @override
  String get metaTooltip => 'Fuente y etiquetas';
  @override
  String get pinTooltip => 'Fijar arriba';
  @override
  String get unpinTooltip => 'Dejar de fijar';
  @override
  String get deleteTooltip => 'Eliminar';
  @override
  String get titleHint => 'Título (automático)';
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
  String get revertedToast => 'Se restauró la versión anterior';
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
  String get hideKeyboardTip => 'Ocultar teclado';

  @override
  String get tidyAction => 'Ordenar';
  @override
  String get wizardAction => 'Asistente';
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
  String get wizardTitle => 'Asistente';
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
  String unknownPrefix(String what) => 'No se reconoce como regla · $what';
  @override
  String get aiKeyPromo => 'Añade una clave de API de IA en Ajustes para procesar también estas ediciones libres.';
  @override
  String get aiRunUnknown => 'Ejecutar con IA los comandos no reconocidos';
  @override
  String get aiBusyLabel => 'IA editando…';
  @override
  String get aiEmptyResponse => 'Respuesta vacía';
  @override
  String aiCallFailed(String error) => 'Error al llamar a la IA: $error';
  @override
  String get aiApplyResult => 'Aplicar resultado de IA';
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
  String get apply => 'Aplicar';

  @override
  String get presetAiName => 'Ordenar respuesta de IA';
  @override
  String get presetAiDesc => 'Quita marcas de markdown, emojis y preámbulos de IA; repara tablas';
  @override
  String get presetStripName => 'Quitar todo el Markdown';
  @override
  String get presetStripDesc => 'Elimina al máximo la sintaxis markdown; las tablas pasan a TSV';
  @override
  String get presetMinimalName => 'Limpieza mínima';
  @override
  String get presetMinimalDesc => 'Conserva la estructura; solo quita ruido (espacios, caracteres de ancho cero)';
  @override
  String get presetTablesName => 'Solo tablas';
  @override
  String get presetTablesDesc => 'Extrae las tablas del documento como TSV';
  @override
  String get presetBlogName => 'Pegar en blog';
  @override
  String get presetBlogDesc => 'Quita marcas, conserva las URL de los enlaces, repara tablas';

  @override
  String get settingsTitle => 'Reglas de limpieza';
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
  String get aiSectionTitle => 'Conexión del Asistente de IA (edición libre)';
  @override
  String get aiSectionDesc =>
      'Con una clave de API, el Asistente procesa comandos libres como "hazlo más conciso". La clave se guarda solo en este dispositivo.';
  @override
  String get aiKeyHint => 'Clave API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get adClose => 'Cerrar anuncios';
  @override
  String get sponsorTitle => 'Un anuncio financia la próxima actualización';
  @override
  String get sponsorBody => 'Tu apoyo mantiene vivas las actualizaciones. Mira un anuncio de pantalla completa al día y usa la app sin banner ese día; con Premium, los anuncios desaparecen para siempre.';
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
  String limitTidyBody(int n) => 'El plan gratuito incluye \$n limpiezas al día. Se renueva mañana; Premium quita el límite.';
  @override
  String limitWizardBody(int n) => 'El plan gratuito incluye \$n usos del asistente al día. Se renueva mañana; Premium quita el límite.';
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
      'Durante la prueba hiciste $tidy limpiezas y $wiz sesiones del asistente. A partir de ahora el plan gratuito incluye $tidyLimit limpiezas y $wizLimit usos del asistente al día. Premium quita el límite.';
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
  String get aiKeyUnknownFormat => 'Formato de clave no reconocido. Especifique el modelo en Avanzado.';
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
