import 'l10n.dart';

/// Deutsch
class L10nDe extends L10n {
  const L10nDe();

  @override
  String get localeTag => 'de';

  @override
  String get appTitle => 'SimpleText';

  @override
  String get versionLabel => 'Version';

  @override
  String get homeTitle => 'Notizen';
  @override
  String get settingsTooltip => 'Bereinigungsregeln';
  @override
  String get searchHint => 'Suchen';
  @override
  String get emptyList => 'Keine Notizen.\nStarte mit „Einfügen & bereinigen".';
  @override
  String get pinnedLabel => 'Angeheftet';
  @override
  String get notesLabel => 'Notizen';
  @override
  String get newNoteTooltip => 'Neue Notiz';
  @override
  String get pasteAndTidy => 'Neue Notiz aus Zwischenablage';
  @override
  String get clipboardEmpty => 'Die Zwischenablage ist leer. Kopiere zuerst eine KI-Antwort.';
  @override
  String get yesterday => 'Gestern';
  @override
  String get untitled => 'Ohne Titel';
  @override
  String get deleteConfirmTitle => 'Diese Notiz löschen?';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get delete => 'Löschen';

  @override
  String dateShort(int y, int m, int d) => '$d.$m.$y';

  @override
  String get seedTitle => 'Willkommen bei SimpleText';
  @override
  String get seedTag => 'Anleitung';
  @override
  String get seedBody => [
        'So funktioniert SimpleText',
        '',
        '1. Kopiere eine Antwort von ChatGPT oder Claude und tippe auf „Einfügen & bereinigen".',
        '2. Vergleiche Original und Ergebnis in der Vorschau und tippe auf „Anwenden" — fertig.',
        '3. Bei Notizen mit Tabellen kopiert der Button „Tabelle" sie für Tabellenkalkulationen (TSV).',
        '4. Jede Bereinigung lässt sich mit einem einzigen Rückgängig zurücknehmen.',
        '',
        'Unten steht eine absichtlich kaputte Tabelle. Tippe auf „Aufräumen" und sieh die Reparatur.',
        '',
        '| Aktie | Ticker | Rendite | Anteil',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5%',
        '| Nvidia | NVDA | +48.9% | 22% | Extra-Zelle |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'Fertig';

  @override
  String get autoTidy => 'Auto-Bereinigung';

  @override
  String get bodyFontSizeTitle => 'Textgröße';

  @override
  String get bodyFontSizeSample =>
      'Entdecken Sie einen Smart Arbeitsbereich, der die vielen Gedanken in Ihrem Kopf mit purer Simplicity ordnet. Einfügen, einmal Aufräumen tippen, alles Clean.';

  @override
  String get wizardNothingToDo => 'Nichts zu ändern';

  @override
  String wizardAppliedToast(int count) => '\$count Anweisung(en) angewendet';

  @override
  String get skipPreviewCheck => 'Vorschau künftig überspringen';

  @override
  String get previewTitle2 => 'Vorschau vor dem Anwenden';

  @override
  String get previewSub2 => 'Zeigt das Ergebnis zuerst und fragt vor dem Anwenden';
  @override
  String get metaTooltip => 'Quelle & Tags';
  @override
  String get pinTooltip => 'Oben anheften';
  @override
  String get unpinTooltip => 'Lösen';
  @override
  String get deleteTooltip => 'Löschen';
  @override
  String get titleHint => 'Titel (automatisch)';
  @override
  String get sourceNone => 'Keine Quelle';
  @override
  String get sourceOther => 'Sonstige';
  @override
  String get tagsHint => 'Tags (durch Komma getrennt)';
  @override
  String get tagAiButton => 'Tags per KI';
  @override
  String get tagAiWorking => 'Tags werden gesucht …';
  @override
  String get tagAiNone => 'Keine Schlagwörter gefunden';
  @override
  String get tagAiLocalNote => 'Kein KI-Schlüssel – lokal ausgewählt';
  @override
  String get tagsBoxHint => 'Tag eingeben, dann Komma';
  @override
  String get tagRemoveTip => 'Tag entfernen';
  @override
  String get bodyHint => 'Hier einfügen oder tippen';
  @override
  String get noteNotFound => 'Notiz nicht gefunden';
  @override
  String get revertedToast => 'Vorherige Version wiederhergestellt';
  @override
  String appliedDone(String summary) => 'Angewendet — $summary';

  @override
  String get undoTip => 'Rückgängig';
  @override
  String get redoTip => 'Wiederholen';
  @override
  String get moveLeftTip => 'Nach links';
  @override
  String get moveRightTip => 'Nach rechts';
  @override
  String get lineStartTip => 'Zeilenanfang';
  @override
  String get lineEndTip => 'Zeilenende';
  @override
  String get indentTip => 'Einzug';
  @override
  String get hideKeyboardTip => 'Tastatur ausblenden';

  @override
  String get tidyAction => 'Aufräumen';
  @override
  String get wizardAction => 'Assistent';
  @override
  String get tableAction => 'Tabelle';
  @override
  String get replaceAction => 'Ersetzen';
  @override
  String get copyAction => 'Kopieren';
  @override
  String get undoAction => 'Rückgängig';

  @override
  String get noTablesFound => 'In dieser Notiz wurden keine Tabellen gefunden';
  @override
  String tableInfo(int n, int cols, int rows) => 'Tabelle $n — $cols Spalten × $rows Zeilen';
  @override
  String get forSpreadsheet => 'Für Tabellenkalkulation';
  @override
  String get copiedSpreadsheet => 'Kopiert — in eine Zelle von Google Sheets oder Excel einfügen';
  @override
  String get copiedCsv => 'Als CSV kopiert';
  @override
  String get copiedMarkdown => 'Als Markdown-Tabelle kopiert';

  @override
  String get wizardTitle => 'Assistent';
  @override
  String get wizardHint =>
      'Gib Anweisungen in deiner Sprache. Z. B.:\nVor Zwischenüberschriften 2 Leerzeilen, danach 1\nErsetze MS durch Microsoft';
  @override
  String get favSaveButton => 'Als Favorit sichern';
  @override
  String get favListTitle => 'Favoriten';
  @override
  String get favUse => 'Verwenden';
  @override
  String get favEmpty => 'Noch keine gespeicherten Anweisungen';
  @override
  String get favRemove => 'Entfernen';
  @override
  String get favSavedToast => 'Gesichert';
  @override
  String appliedPrefix(String what) => 'Angewendet · $what';
  @override
  String unknownPrefix(String what) => 'Nicht als Regel erkannt · $what';
  @override
  String get aiKeyPromo =>
      'Mit einem KI-API-Schlüssel in den Einstellungen werden auch solche freien Anweisungen verarbeitet.';
  @override
  String get aiRunUnknown => 'Nicht erkannte Befehle mit KI ausführen';
  @override
  String get aiBusyLabel => 'KI bearbeitet…';
  @override
  String get aiEmptyResponse => 'Leere Antwort';
  @override
  String aiCallFailed(String error) => 'KI-Aufruf fehlgeschlagen: $error';
  @override
  String get aiApplyResult => 'KI-Ergebnis anwenden';
  @override
  String get aiAppliedToast => 'KI-Bearbeitung angewendet — mit Rückgängig wiederherstellbar';
  @override
  String get close => 'Schließen';
  @override
  String get interpretApply => 'Interpretieren & anwenden';

  @override
  String get replaceTitle => 'Ersetzen';
  @override
  String get findLabel => 'Suchen';
  @override
  String get replaceWithLabel => 'Ersetzen durch (\\n = Zeilenumbruch)';
  @override
  String get regexLabel => 'Regulärer Ausdruck';
  @override
  String get saveAsRule => 'Als Auto-Ersetzungsregel speichern';
  @override
  String get saveAsRuleSub => 'Wird künftig bei jedem „Aufräumen" angewendet';
  @override
  String get invalidRegex => 'Ungültiger regulärer Ausdruck';
  @override
  String get noMatches => 'Keine Treffer gefunden';
  @override
  String replacedCount(int count) => 'An $count Stellen ersetzt';
  @override
  String get savedRuleSuffix => ' · als Auto-Ersetzungsregel gespeichert';
  @override
  String get replaceAllAction => 'Alle ersetzen';

  @override
  String get copyAll => 'Alles kopieren';
  @override
  String get copiedAll => 'Gesamten Text kopiert';
  @override
  String get tidyCopy => 'Bereinigt kopieren';
  @override
  String get tidyCopySub => 'Die Notiz bleibt unverändert; nur das bereinigte Ergebnis wird kopiert';
  @override
  String tidyCopied(String summary) => 'Bereinigt und kopiert — $summary';
  @override
  String get copyTableSpreadsheet => 'Tabellen für Tabellenkalkulation kopieren';
  @override
  String get copiedTableSpreadsheet => 'Tabellen für Tabellenkalkulation kopiert';

  @override
  String previewTitle(String preset) => '$preset — Vorschau';
  @override
  String warningPrefix(String warning) => 'Hinweis: $warning';
  @override
  String get tidyResultLabel => 'Ergebnis';
  @override
  String get originalLabel => 'Original';
  @override
  String get apply => 'Anwenden';

  @override
  String get presetAiName => 'KI-Antwort aufräumen';
  @override
  String get presetAiDesc => 'Entfernt Markdown-Zeichen, Emojis, KI-Vorreden; repariert Tabellen';
  @override
  String get presetStripName => 'Markdown vollständig entfernen';
  @override
  String get presetStripDesc => 'Entfernt Markdown-Syntax so weit wie möglich; Tabellen werden TSV';
  @override
  String get presetMinimalName => 'Minimal aufräumen';
  @override
  String get presetMinimalDesc => 'Erhält die Struktur; entfernt nur Störendes (Leerzeichen, Nullbreite-Zeichen)';
  @override
  String get presetTablesName => 'Nur Tabellen';
  @override
  String get presetTablesDesc => 'Extrahiert Tabellen aus dem Dokument als TSV';
  @override
  String get presetBlogName => 'In Blog einfügen';
  @override
  String get presetBlogDesc => 'Entfernt Zeichen, behält Link-URLs, repariert Tabellen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get menuAppSettings => 'App-Einstellungen';

  @override
  String get menuAiKey => 'KI-API-Schlüssel';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'Ein — dieselben Notizen auf iPhone, iPad und Mac';

  @override
  String get syncStateOff => 'Aus — aktivieren Sie iCloud Drive in den Geräteeinstellungen';

  @override
  String get syncStateSyncing => 'Wird abgeglichen …';

  @override
  String get aiKeyNotSynced => 'Ihre Notizen werden über iCloud auf allen Geräten abgeglichen. Ihr API-Schlüssel nicht — geben Sie ihn auf jedem Gerät einzeln ein.';
  @override
  String get settingsSecView => 'Anzeige';
  @override
  String get settingsSecTidy => 'Aufräumregeln';
  @override
  String get settingsSecWhen => 'Beim Aufräumen';
  @override
  String get settingsSecInfo => 'Info';
  @override
  String get emphTitle => 'Fette Hervorhebung (**Text**)';
  @override
  String get emphSub => 'Bei ganzen Sätzen über 40 Zeichen werden immer nur die Zeichen entfernt';
  @override
  String get emphQuoteSingle => "Einfache Anführungszeichen 'Hervorhebung'";
  @override
  String get emphQuoteDouble => 'Doppelte Anführungszeichen "Hervorhebung"';
  @override
  String get removeLabel => 'Entfernen';
  @override
  String get keepLabel => 'Behalten';
  @override
  String get hrTitle => 'Trennlinien (---)';
  @override
  String get headingTitle => 'Überschriften (#, ##)';
  @override
  String get headingStrip => 'Nur Text behalten';
  @override
  String get headingKeep => 'Unverändert lassen';
  @override
  String get headingPrefix => '■ voranstellen';
  @override
  String get headingBracket => '[Eckige Klammern]';
  @override
  String get bulletTitle => 'Aufzählungszeichen (-, *)';
  @override
  String get bulletHyphen => 'Bindestrich -';
  @override
  String get bulletMiddot => 'Mittelpunkt ·';
  @override
  String get bulletDot => 'Punkt •';
  @override
  String get bulletWhite => 'Weißer Punkt ◦';
  @override
  String get bulletKeep => 'Originalzeichen behalten';
  @override
  String get bulletIndentTitle => 'Einzug der Aufzählung';
  @override
  String get indent2 => '2 Leerzeichen';
  @override
  String get indent4 => '4 Leerzeichen';
  @override
  String get indentNone => 'Keiner';
  @override
  String get headingPadTitle => 'Abstand um Zwischenüberschriften';
  @override
  String get headingPadSub =>
      '2 Zeilen davor, 1 danach — ein unsichtbares Zeichen (ㅤ) erhält den Abstand in Chat-Apps und Blogs';
  @override
  String get citationsTitle => 'Quellenlinks entfernen';
  @override
  String get citationsSub => 'Entfernt Fußnotenzahlen im Text und die Quellenliste am Ende';
  @override
  String get monoEditorTitle => 'Tabellen in Monospace';
  @override
  String get monoEditorSub => 'Richtet Tabellen- und Codespalten exakt aus. Fließtext behält die Geräteschrift';
  @override
  String get dashListTitle => 'Gedankenstrich-Reihen in Listen umwandeln';
  @override
  String get dashListSub => 'Teilt einzeilige Reihen wie „– a – b – c" in eine Zeilenliste';
  @override
  String get fillerHeadingTitle => 'Unsichtbare-Zeichen-Überschriften aufräumen';
  @override
  String get fillerHeadingSub => 'Wendet Abstands- und Überschriftenregeln auf ㅤ-umschlossene Pseudo-Überschriften an';
  @override
  String get aiSectionTitle => 'KI-Assistent verbinden (freie Bearbeitung)';
  @override
  String get aiSectionDesc =>
      'Mit einem API-Schlüssel verarbeitet der Assistent freie Befehle wie „mach das knapper". Der Schlüssel wird nur auf diesem Gerät gespeichert.';
  @override
  String get aiKeyHint => 'API-Schlüssel (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get adClose => 'Werbung schließen';
  @override
  String get sponsorTitle => 'Eine Anzeige finanziert das nächste Update';
  @override
  String get sponsorBody => 'Ihre Unterstützung hält die Updates am Leben. Sehen Sie eine Vollbildanzeige pro Tag und nutzen Sie die App diesen Tag bannerfrei – mit Premium verschwindet die Werbung für immer.';
  @override
  String get sponsorWatch => 'Anzeige ansehen und unterstützen';
  @override
  String get sponsorSkip => 'Überspringen';
  @override
  String get sponsorLoading => 'Anzeige wird geladen…';
  @override
  String get sponsorFailed => 'Anzeige konnte nicht geladen werden. Bitte gleich noch einmal versuchen.';
  @override
  String get moreTooltip => 'Mehr';
  @override
  String get sponsorGoPremium => 'Premium — ohne Werbung';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Ohne Werbung, auf allen Geräten';
  @override
  String get premiumPitchSub => 'Einmalig US\$29.99 oder US\$1.99/Monat · iPhone, iPad und Mac zusammen';
  @override
  String get premiumBody => 'Premium entfernt alle Werbung und schaltet Skyblue Note auf iPhone, iPad und Mac frei. Ein Kauf gilt für alle drei. Ihre Unterstützung baut das nächste Update.';
  @override
  String get premiumLifetime => 'Lebenslang · US\$29.99';
  @override
  String get premiumMonthly => 'Monatlich · US\$2.99/Monat';
  @override
  String get premiumComingSoon => 'Käufe werden in der App-Store-Version freigeschaltet. Bald ist es so weit.';
  @override
  String get limitTitle => 'Die kostenlosen Durchläufe für heute sind aufgebraucht';
  @override
  String limitTidyBody(int n) => 'Der Gratisplan enthält \$n Bereinigungen pro Tag. Morgen geht es weiter – Premium hebt das Limit auf.';
  @override
  String limitWizardBody(int n) => 'Der Gratisplan enthält \$n Assistent-Läufe pro Tag. Morgen geht es weiter – Premium hebt das Limit auf.';
  @override
  String get limitSeePremium => 'Premium ansehen';
  @override
  String get premiumYearly => 'Jährlich · US\$14.99/Jahr';
  @override
  String get premiumLifetimeNote => 'Einführungspreis · regulär US\$39.99';

  @override
  String trialBadge(int days) => 'Unbegrenzt testen · noch $days Tage';

  @override
  String get trialEndedTitle => 'Ihre unbegrenzte Testphase ist beendet';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      'Während der Testphase haben Sie $tidy Aufräumvorgänge und $wiz Assistenten-Durchläufe genutzt. Ab jetzt bietet die kostenlose Version $tidyLimit Aufräumvorgänge und $wizLimit Assistenten-Durchläufe pro Tag. Premium hebt das Limit auf.';
  @override
  String get themeTitle => 'Erscheinungsbild';
  @override
  String get themeSystem => 'Gerät folgen';
  @override
  String get themeLight => 'Hell';
  @override
  String get themeDark => 'Dunkel';
  @override
  String get aiKeyVerify => 'Schlüssel prüfen';
  @override
  String get aiKeyChecking => 'Prüfe…';
  @override
  String get aiKeyUnknownFormat => 'Schlüsselformat nicht erkannt. Modell unter „Erweitert“ manuell festlegen.';
  @override
  String get aiAdvancedLabel => 'Erweitert — Modell selbst wählen';
  @override
  String get aiManualModelHint => 'Modellnamen eingeben (z. B. gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => 'Automatisch: $provider · $model';
  @override
  String aiModelsFound(int n) => '$n verfügbare Modelle bestätigt.';
  @override
  String aiListFailed(String error) => 'Modellliste konnte nicht geladen werden ($error). Die eingebaute Ersatzliste wird verwendet.';
  @override
  String aiModelSwitched(String model) => 'Das bisherige Modell antwortete nicht mehr – gewechselt zu $model.';
  @override
  String get rulesSectionTitle => 'Auto-Ersetzungsregeln';
  @override
  String get rulesSectionDesc =>
      'Von oben nach unten angewendet. \\n in der Ersetzung erzeugt einen Zeilenumbruch. Codeblöcke bleiben unberührt.';
  @override
  String get addRule => 'Regel hinzufügen';
  @override
  String get settingsFooter =>
      'Einstellungen gelten sofort und werden ab dem nächsten „Aufräumen" angewendet. Bereits bereinigte Notizen ändern sich nicht rückwirkend.';
}
