import 'l10n.dart';

/// Deutsch
class L10nDe extends L10n {
  const L10nDe();

  @override
  String get localeTag => 'de';

  @override
  String get appTitle => 'Skyblue Note';

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
  String get seedTitle => 'Willkommen bei Skyblue Note';
  @override
  String get seedTag => 'Anleitung';
  @override
  String get seedBody => [
        'So funktioniert Skyblue Note',
        '',
        '1. Kopiere eine Antwort von ChatGPT oder Claude und tippe auf „Einfügen & bereinigen".',
        '2. Sternchen, Rautezeichen und einleitende Höflichkeiten verschwinden in einem Zug.',
        '3. Bei Notizen mit Tabellen kopiert der Button „Tabelle" sie für Tabellenkalkulationen (TSV).',
        '4. Jede Bereinigung lässt sich mit einem einzigen Rückgängig zurücknehmen.',
        '',
        'Unten steht eine absichtlich kaputte Tabelle. Tippe auf „Aufräumen" und sieh die Reparatur.',
        '',
        '| Aktie | Ticker | Rendite | Anteil',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '| NVIDIA | NVDA | +48.9% | 22% |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'Fertig';

  @override
  String get bodyFontSizeTitle => 'Textgröße';

  @override
  String get bodyFontSizeSample =>
      'Entdecken Sie einen Smart Arbeitsbereich, der die vielen Gedanken in Ihrem Kopf mit purer Simplicity ordnet. Einfügen, einmal Aufräumen tippen, alles Clean.';

  @override
  String get wizardNothingToDo => 'Nichts zu ändern';

  @override
  String wizardAppliedToast(int count) => '$count Anweisung(en) angewendet';

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
  String get revertedToast => 'Zurück zum Original. Der vorherige Text liegt im Verlauf.';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => 'Original wiederherstellen';

  @override
  String get revertConfirmTitle => 'Zurück zum Original?';

  @override
  String get revertConfirmBody =>
      'Die Notiz kehrt zu dem Text zurück, den Sie zuerst eingefügt haben. Jede Bereinigung und jede spätere Änderung ist dann weg.\n\nDer Text, den Sie jetzt haben, bleibt im Verlauf und lässt sich zurückholen.';

  @override
  String get revertConfirmOk => 'Wiederherstellen';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => 'Punktliste';

  @override
  String get listDashAction => 'Strichliste';

  @override
  String get listNumberAction => 'Nummerierte Liste';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => 'Quelle';

  @override
  String sourceSaved(String name) => 'Quelle gespeichert: $name';

  @override
  String sourceDetected(String name) => 'Quelle erkannt: $name';

  @override
  String get sourceCleared => 'Quelle entfernt';
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
  String get wizardAction => 'KI';
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
  String get wizardTitle => 'KI-Bearbeitung';
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
  String get presetAiName =>
      'Standard-Aufräumen';
  @override
  String get presetAiDesc =>
      'Macht eine eingefügte KI-Antwort lesbar. Meistens reicht das';
  @override
  String get presetStripName =>
      'Alle Zeichen entfernen';
  @override
  String get presetStripDesc =>
      'Für Orte ohne Formatierung wie Chat und SMS';
  @override
  String get presetMinimalName =>
      'Nur Fusseln';
  @override
  String get presetMinimalDesc =>
      'Behält die Struktur, entfernt nur Unsichtbares';
  @override
  String get presetTablesName =>
      'Nur Tabellen';
  @override
  String get presetTablesDesc =>
      'Zum direkten Einfügen in Excel oder Google Tabellen';
  @override
  String get presetBlogName =>
      'Für Blogs';
  @override
  String get presetBlogDesc =>
      'Behält Linkadressen, entfernt die Zeichen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get menuAppSettings => 'App-Einstellungen';

  @override
  String get menuAiKey => 'KI-API-Schlüssel';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'Dieselben Notizen auf iPhone, iPad und Mac';

  @override
  String get syncStateOff => 'Aktiviere iCloud Drive in den Geräteeinstellungen';

  @override
  String get syncStateSyncing => 'Wird abgeglichen …';

  @override
  String get aiKeyNotSynced => 'Ihre Notizen werden über iCloud auf allen Geräten abgeglichen. Ihr API-Schlüssel nicht — geben Sie ihn auf jedem Gerät einzeln ein.';

  @override
  String get syncStateSignedOut => 'Tippen, um zu sehen wie';

  @override
  String get syncHelpTitle => 'So aktivieren Sie iCloud';

  @override
  String get syncHelpSteps =>
      '1. Einstellungen › dein Name oben › iCloud\n2. Prüfe, ob iCloud Drive aktiviert ist — ist es aus, synchronisiert keine App\n3. Sperre und entsperre das iPhone, komm zurück und tippe auf Erneut prüfen\n\nPrüfe in der Dateien-App, nicht in den Einstellungen. Siehst du dort unter iCloud Drive einen Ordner Skyblue Note, ist alles bereit.';

  @override
  String get syncOpenSettings => 'Einstellungen öffnen';

  @override
  String get syncRecheck => 'Erneut prüfen';

  @override
  String get syncHelpNote =>
      'Direkt nach der Installation kann die Vorbereitung ein bis zwei Minuten dauern. Tippen Sie dann einfach auf Erneut prüfen.';

  @override
  String get sortFilterTooltip => 'Sortieren & filtern';

  @override
  String get sortFilterTitle => 'Sortieren und filtern';

  @override
  String get sortLabel => 'Sortierung';

  @override
  String get sortUpdated => 'Zuletzt bearbeitet';

  @override
  String get sortCreated => 'Erstellungsdatum';

  @override
  String get sortByTitle => 'Titel';

  @override
  String get filterSourceLabel => 'Quelle';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get trashSubtitle => 'Gelöschte Notizen werden 30 Tage aufbewahrt';

  @override
  String get trashEmpty => 'Der Papierkorb ist leer';

  @override
  String get trashRestore => 'Wiederherstellen';

  @override
  String get trashDeleteNow => 'Jetzt löschen';

  @override
  String get trashEmptyAll => 'Leeren';

  @override
  String get trashEmptyConfirm => 'Das Leeren des Papierkorbs kann nicht rückgängig gemacht werden. Fortfahren?';

  @override
  String get trashRestored => 'Wiederhergestellt';

  @override
  String trashDaysLeftLabel(int days) => 'Wird in $days Tagen endgültig gelöscht';

  @override
  String get exportSectionTitle =>
      'Importieren & exportieren';

  @override
  String get exportSubtitle =>
      'Ihre Notizen können jederzeit gehen. Markdown öffnet sich in Apple Notizen, Obsidian, Notion und anderen.';

  @override
  String get exportNote =>
      'Diese Notiz exportieren';

  @override
  String get exportAllMd =>
      'Alle Notizen exportieren';

  @override
  String get exportAllMdSub =>
      'Alle Notizen als Markdown in einem ZIP';

  @override
  String get exportBackup =>
      'Backup sichern';

  @override
  String get exportBackupSub =>
      'Eine Datei, die hier alles wiederherstellt (ohne Ihren API-Schlüssel)';

  @override
  String get exportFailed =>
      'Export fehlgeschlagen';

  @override
  String get exportEmpty =>
      'Es gibt keine Notizen zum Exportieren';

  @override
  String get choosePreset => 'Aufräum-Art wählen';

  @override
  String get importFiles =>
      'Aus Dateien importieren';

  @override
  String get importFilesSub =>
      'Markdown- und Textdateien werden zu Notizen. Backups werden hier ebenfalls wiederhergestellt';

  @override
  String get importAppend =>
      'Datei anhängen';

  @override
  String get importNone =>
      'Es wurde nichts importiert';

  @override
  String importDone(int n) => '$n Notizen importiert';

  @override
  String get sourceGuessSuffix => '(vermutlich)';

  @override
  String get splitEmpty => 'Wählen Sie links eine Notiz';

  @override
  String get historyTitle =>
      'Versionsverlauf';

  @override
  String get historySub =>
      'Zurück zum Text vor dem Aufräumen oder Ersetzen';

  @override
  String get historyEmpty =>
      'Noch nichts zum Zurückgehen';

  @override
  String get historyRestore =>
      'Wiederherstellen';

  @override
  String get historyOriginal =>
      'Wie eingefügt';

  @override
  String historyUnknownTime(int n) => 'Frühere Version $n';

  @override
  String get selUnitSentence => 'Satz';

  @override
  String get selUnitLine => 'Zeile';

  @override
  String get selUnitPara => 'Absatz';

  @override
  String get selUnitAll => 'Alles';

  @override
  String get selStartLeft => 'Anfang links';

  @override
  String get selStartRight => 'Anfang rechts';

  @override
  String get selEndLeft => 'Ende links';

  @override
  String get selEndRight => 'Ende rechts';

  @override
  String get selClear => 'Auswahl aufheben';

  @override
  String get paperTitle => 'Editor-Papier';

  @override
  String get paperSub => 'Hintergrund und Linien als Satz. Der Zeilenabstand folgt der Schriftgröße.';

  @override
  String get paperNone => 'Schlicht';

  @override
  String get paperMoleskine => 'Moleskine';

  @override
  String get paperSepia => 'Sepia';

  @override
  String get paperManuscript => 'Manuskript';

  @override
  String get paperGrid => 'Karo';

  @override
  String get lockSectionTitle => 'Sperre';

  @override
  String get lockTitle => 'App-Sperre';

  @override
  String get lockSub => 'Die App mit Face ID, Touch ID oder dem Gerätecode öffnen.';

  @override
  String get lockNote => 'Diese Sperre verhindert, dass jemand mit deinem Gerät die App öffnet. Die Dateien auf dem Gerät werden dadurch nicht verschlüsselt.';

  @override
  String get lockDelayTitle => 'Sperren nach';

  @override
  String get lockDelayNow => 'Sofort';

  @override
  String get lockDelay1m => 'Nach 1 Minute';

  @override
  String get lockDelay5m => 'Nach 5 Minuten';

  @override
  String get lockUnlock => 'Entsperren';

  @override
  String get lockLocked => 'Gesperrt';

  @override
  String get lockUnavailable => 'Face ID, Touch ID und Gerätecode sind auf diesem Gerät nicht verfügbar.';

  @override
  String get lockReasonOpen => 'Bestätigen, um die Notizen zu öffnen';

  @override
  String get lockReasonOn => 'Bestätigen, um die Sperre zu aktivieren';

  @override
  String get lockReasonOff => 'Bestätigen, um die Sperre zu deaktivieren';

  @override
  String get syncDiagSignedOut => 'Dieses Gerät ist nicht bei iCloud angemeldet. Bitte zuerst anmelden.';

  @override
  String get syncDiagNoContainer => 'Du bist angemeldet, aber diese App hat noch keinen iCloud-Bereich. Aktiviere ihn mit den Schritten unten.';

  @override
  String get syncDiagPreparing => 'Der Bereich ist da. Warte darauf, dass er bereit ist.';

  @override
  String get syncRecheckWhat => 'Fragt das Gerät erneut nach dem iCloud-Status, von vorn.';

  @override
  String get syncRecheckOk => 'iCloud ist aktiviert';

  @override
  String get syncRecheckStill => 'Noch nicht aktiviert. Schalte es in den Einstellungen ein und tippe erneut. Wenn du es gerade eingeschaltet hast, versuche es in ein bis zwei Minuten noch einmal.';

  @override
  String get syncOpenFailed => 'Einstellungen konnten nicht geöffnet werden. Bitte vom Home-Bildschirm aus öffnen.';

  @override
  String get syncOpenManual => 'Bitte öffne die Einstellungen selbst: Home-Bildschirm › Einstellungen › dein Name oben › iCloud.';

  @override
  String get menuFile => 'Ablage';

  @override
  String get menuClose => 'Schließen';

  @override
  String get menuPrefs => 'Einstellungen…';

  @override
  String get appliedTitle => 'Alles sauber aufgeräumt';

  @override
  String get tidyRulesTitle => 'Aufräum-Regeln';

  @override
  String get tidyRulesSub => 'Legt fest, wie sich der Text beim Aufräumen ändert.';

  @override
  String get syncOnTitle => 'Ein';

  @override
  String get syncOffTitle => 'Aus';

  @override
  String get syncSignedOutTitle => 'Anmeldung nötig';

  @override
  String pastedFrom(String src, String date) =>
      'von $src am $date';

  @override
  String pastedOn(String date) => 'eingefügt am $date';

  @override
  String staleWarn(int days) =>
      'Diese Antwort ist $days Tage alt. Das Modell kann sich geändert haben.';
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
  String get aiSectionTitle => 'KI-Bearbeitung einrichten';
  @override
  String get aiSectionDesc =>
      'Mit einem API-Schlüssel führt die KI freie Anweisungen wie "mach das kürzer" aus. Das Aufräumen nutzt Geräteregeln und braucht keinen Schlüssel — nur die KI-Bearbeitung.';
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
  String limitTidyBody(int n) => 'Der Gratisplan enthält $n Bereinigungen pro Tag. Morgen geht es weiter – Premium hebt das Limit auf.';
  @override
  String limitWizardBody(int n) =>
      'Die kostenlose Version enthält $n KI-Bearbeitungen pro Tag. Morgen geht es weiter — Premium hebt das Limit auf.';
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
      'Während der Testphase haben Sie $tidy Aufräumvorgänge und $wiz KI-Bearbeitungen genutzt. Ab jetzt bietet die kostenlose Version $tidyLimit Aufräumvorgänge und $wizLimit KI-Bearbeitungen pro Tag. Premium hebt das Limit auf.';
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
