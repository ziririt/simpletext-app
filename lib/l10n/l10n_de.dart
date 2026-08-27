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
  String get shareAppTitle => 'App teilen';
  @override
  String get rateAppTitle => 'Bewerten Sie uns';
  @override
  String get shareAppMsg =>
      'Skyblue Note — eine leichte, schnelle Notizen-App, die auf allen Geräten synchronisiert.';
  @override
  String get seedBody => [
        'Hallo! 😊 Hier ist die gewünschte Zusammenfassung[1][2].',
        '',
        '# Skyblue Note',
        '',
        'Die Tabelle ist verrutscht. Tippen Sie unten links auf den **Zauberstab**. 🎉',
        '',
        '| Firma | Kürzel | Rendite | Anteil',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '|Nvidia|NVDA|+48.9%|22%|',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '|Tesla|TSLA|-8.3%|8%|',
        '',
        '> Nach dem Aufräumen stimmen die Spalten. Über «Tabelle» im Menü landet sie direkt in der Tabellenkalkulation.',
        '',
        '## Was verschwindet',
        '',
        '- [ ] Höfliche Floskeln und Emojis 🙂',
        '- [ ] Am Satzende klebende Fußnoten[3][4]',
        '- [ ] Ein übrig gebliebenes Sternchenpaar am Zeilenende**',
        '- [x] Die zerbrochene Tabelle wird neu gesetzt',
        '',
        '## Was bleibt',
        '',
        'Überschriften, **Fettdruck** und Zitate bleiben. Am Bildschirm sieht man die Bedeutung; beim Einfügen in Notizen oder ein Forum fallen die Zeichen weg.',
        '',
        '---',
        '',
        '\t•\tAufzählungen in Tabulatoren verpackt — so fügen Grok und ChatGPT ein',
        '\t•\tDoppelte   Leerzeichen und Tabulatoren',
        '\t•\tAuch diese verstreuten Zeilen finden ihren Platz',
        '',
        '> Gefällt es nicht? [Original wiederherstellen](https://ezlong.com/skybluenote) holt es zurück.',
      ].join('\n');

  @override
  String get done => 'Fertig';

  @override
  String get bodyFontSizeTitle => 'Textgröße';

  @override
  String get bodyLineHeightTitle => 'Zeilenabstand im Text';

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
  String get metaTooltip => 'Titel & Tags';
  @override
  String get pinTooltip => 'Oben anheften';
  @override
  String get unpinTooltip => 'Lösen';

  @override
  String get unpinConfirmTitle => 'Anheftung dieser Notiz aufheben?';

  @override
  String get unpinConfirmBody =>
      'Halten Sie eine Notiz in der Liste gedrückt, um sie erneut anzuheften.';
  @override
  String get deleteTooltip => 'Löschen';
  @override
  String get titleHint => 'Titel (automatisch)';
  @override
  String get titleTapHint => 'Titel eingeben';
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
      'Die Notiz kehrt zu dem Text zurück, den Sie zuerst eingefügt haben. Alle späteren Aufräumarbeiten und Änderungen gehen verloren.\n\nSie kommen weiterhin zu Ihren früheren Fassungen — im Menü → Versionsverlauf steht der jetzige Text ganz oben.';

  @override
  String get revertConfirmOk => 'Wiederherstellen';

  @override
  String get okAction =>
      'OK';

  @override
  String get revertDoneTitle =>
      'Auf das Original zurückgesetzt';

  @override
  String get revertDoneBody =>
      'Der Text, an dem Sie gearbeitet haben, ist nicht verloren.\n\nÖffnen Sie das Menü → Versionsverlauf: Der oberste Eintrag ist der Text von unmittelbar davor. Tippen Sie darauf, um ihn jederzeit zurückzuholen.';

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

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'Ordner';

  @override
  String get folderNone => 'Kein Ordner';

  @override
  String get folderNew => 'Neuer Ordner';

  @override
  String get folderNameHint => 'Ordnername';

  @override
  String get folderCleared => 'Aus dem Ordner entfernt';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => 'Ordner verwalten';

  @override
  String get folderRename => 'Umbenennen';

  @override
  String get folderDelete => 'Ordner löschen';

  @override
  String get folderReorderHint => 'Zum Sortieren ziehen';

  @override
  String get folderManageEmpty => 'Noch keine Ordner';

  @override
  String get folderDupName => 'Ein Ordner mit diesem Namen existiert bereits';

  @override
  String get folderDeleted => 'Ordner gelöscht';

  @override
  String get folderRenamed => 'Umbenannt';

  @override
  String folderDeleteBody(String name, int count) =>
      'Die $count Notizen in „$name“ bleiben unter Alle. Notizen werden nicht gelöscht.';

  @override
  String folderNoteCount(int count) => '$count Notizen';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => 'Wird geprüft, ob es wirklich nutzbar ist …';

  @override
  String get aiPingOk => 'Bearbeiten funktioniert. Sie können loslegen.';

  @override
  String aiPingFailed(String err) => 'Die Liste kam an, aber der Bearbeitungsaufruf wurde abgelehnt — $err';

  @override
  String get aiAdvancedNote => 'Normalerweise nicht nötig. Der Schlüssel allein genügt.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => 'Papier';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWalnut => 'Walnuss';

  @override
  String get paperNight => 'Nacht';

  @override
  String get paperSky => 'Himmel';

  @override
  String get themeSystemNote =>
      'Mit „Gerät folgen“ wird die App dunkel, sobald Ihr Gerät es wird.';

  @override
  String folderMoved(String name) => 'Nach $name verschoben';
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
  String get todoAction => 'Aufgabe';
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
  String unknownPrefix(String what) => 'Das übernimmt die KI · $what';
  @override
  String get aiKeyPromo =>
      'Mit einem KI-API-Schlüssel in den Einstellungen werden auch solche freien Anweisungen verarbeitet.';
  @override
  String get aiBusyLabel => 'KI bearbeitet…';
  @override
  String get aiWorking => 'Die KI bearbeitet den Text wie gewünscht. Das kann einen Moment dauern…';
  @override
  String get aiEmptyResponse => 'Leere Antwort';
  @override
  String aiCallFailed(String error) => 'KI-Aufruf fehlgeschlagen: $error';
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
  String get ruleScopeAll => 'Auf alle Notizen anwenden';
  @override
  String get ruleScopeNote => 'Nur auf diese Notiz anwenden';
  @override
  String get noteRules => 'Regeln dieser Notiz';
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
  String get copyPlainSub =>
      'Reiner Text — ohne Markdown-Zeichen';

  @override
  String get copyRaw => 'Als Markdown kopieren';

  @override
  String get copyRawSub =>
      'Für Notion, Slack, GitHub und andere Markdown-Apps';
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
  String get apply => 'Bereinigung anwenden';

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
      'Für Chat und SMS. Alle Zeichen und Emojis fallen weg, Tabellen werden ausgerichtet';
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
  String get tidySample => [
        '## Zusammenfassung von heute 😊',
        '',
        'Die **Kernpunkte** sind drei[1][2].',
        '',
        '- Erster Punkt',
        '- Zweiter Punkt',
        '',
        '> Eine zitierte Zeile',
        '',
        'Mehr im [Blog](https://ezlong.com)',
        '',
        '| Posten | Wert |',
        '|---|---|',
        '|Umsatz|120|',
      ].join('\n');

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get menuAppSettings => 'App-Einstellungen';

  @override
  String get menuAiKey => 'KI-API-Schlüssel';

  @override
  String get syncTitle => 'Synchronisierung';
  @override
  String get syncAppleOnly => 'Nur Apple';

  @override
  String get syncScopeTitle =>
      'Umfang der Synchronisierung';

  @override
  String get syncScopeShared =>
      'Zwischen Ihren Geräten synchronisiert: Notizen, Aufräumregeln, selbst angelegte Ersetzungsregeln, Ordner, gespeicherte KI-Anweisungen';

  @override
  String get syncStateOffGdrive => 'Bitte melden Sie sich erneut in Ihrem Google-Konto an';
  @override
  String get syncStateExpiredGdrive => 'Ihr Konto ist weiterhin verbunden, aber die Berechtigung für Drive ist abgelaufen. Einmal tippen, um sie zu erneuern.';

  @override
  String get syncScopePlatformGdrive =>
      'Der Google-Drive-Speicher wird von iPhone, iPad, Mac und Android gemeinsam genutzt. Installieren Sie diese App und melden Sie sich mit demselben Google-Konto an';

  @override
  String get syncScopeDevice =>
      'Pro Gerät: Textgröße, Zeilenabstand, Papier, Erscheinungsbild, Sortierung';

  @override
  String get syncScopePlatform =>
      'Die automatische Synchronisierung funktioniert derzeit nur zwischen Apple-Geräten (iPhone, iPad, Mac). Unter Android und Windows nutzen Sie Backup exportieren und Importieren im Menü';

  @override
  String get typographyTitle => 'Text & Zeilenabstand';

  @override
  String get syncScopeNever =>
      'Der KI-API-Schlüssel wird in keiner Cloud gesichert und muss auf jedem Gerät eingegeben werden';
  @override
  String get syncWhereTitle =>
      'Wo aufbewahren';
  @override
  String get syncBackendNone =>
      'Nicht synchronisieren';
  @override
  String get syncBackendNoneSub =>
      'Nur auf diesem Gerät';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      'Zwischen iPhone, iPad und Mac';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      'Auch Android, Windows und Web';
  @override
  String get syncSoon =>
      'In Vorbereitung';

  @override
  String get driveSignInFailed => 'Google-Konto konnte nicht verbunden werden';

  @override
  String get driveNeedsSignIn => 'Bitte zuerst ein Google-Konto verbinden';

  @override
  String get driveSignedInAs => 'Verbunden';
  @override
  String get syncSectionState =>
      'Aktueller Stand';
  @override
  String get syncNowAction =>
      'Jetzt abgleichen';
  @override
  String get syncNowBusy => 'Wird abgeglichen…';

  @override
  String get syncLastNever =>
      'Noch nie abgeglichen';
  @override
  String get syncLogTitle => 'Synchronisierungsverlauf';
  @override
  String get syncLogNote => 'Nur was wann übertragen wurde. Notizinhalte werden hier nicht gespeichert.';
  @override
  String get syncLogEmpty => 'Bisher wurde nichts übertragen';
  @override
  String get syncLogNever => 'Noch nicht';
  @override
  String get syncLogUp => 'Gesendet';
  @override
  String get syncLogDown => 'Empfangen';
  @override
  String get syncLogFailed => 'Fehlgeschlagen';
  @override
  String syncLogLastUp(String when) => 'Zuletzt gesendet · ' + when;
  @override
  String syncLogLastDown(String when) => 'Zuletzt empfangen · ' + when;
  @override
  String get syncTroubleTitle =>
      'Wenn etwas schiefgeht';
  @override
  String get syncTroubleNote =>
      'Abgleichen ist kein Backup. Was Sie auf einem Gerät löschen, ist überall weg. Exportieren Sie wichtige Notizen ab und zu als Datei.';
  @override
  String syncLastAt(String when) => 'Zuletzt abgeglichen: $when';

  @override
  String syncStateOn(String where) => 'In $where abgelegt — dieselben Notizen auf jedem Gerät mit dieser App';

  @override
  String get syncStateOff => 'Aktiviere iCloud Drive in den Geräteeinstellungen';

  @override
  String syncStateSyncing(String where) => 'Wird mit $where abgeglichen… das dauert einige Sekunden bis eine Minute';

  @override
  String get aiKeyNotSynced => 'Ihre Notizen werden über den gewählten Speicher auf allen Geräten abgeglichen. Ihr API-Schlüssel nicht — geben Sie ihn auf jedem Gerät einzeln ein.';
  @override
  String get aiKeySyncTitle => 'API-Schlüssel ebenfalls synchronisieren';
  @override
  String get aiKeySyncSubApple => 'Er reist über den iCloud-Schlüsselbund — ein anderer Weg als der Ihrer Notizen. Nur Ihre Geräte besitzen den Schlüssel, nicht einmal Apple kann ihn lesen.';
  @override
  String get aiKeySyncSubGdrive => 'Sobald der API-Schlüssel auf Google Drive liegt, ist jeder selbst für seine Sicherheit verantwortlich.';

  @override
  String get autoTagTitle => 'Automatisch verschlagworten';

  @override
  String get autoTagSub =>
      'Nach einer Pause beim Bearbeiten holt die KI die Schlagwörter neu. Notizen, deren Schlagwörter Sie selbst bearbeitet haben, bleiben unberührt';

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
  String get selectWord => 'Auswählen';

  @override
  String get tagAiNeedKey => 'Geben Sie in den Einstellungen einen API-Schlüssel ein, um die automatische KI-Verschlagwortung zu nutzen.';

  @override
  String get toggleListTooltip => 'Liste aus- oder einblenden';

  @override
  String get aiDetecting => 'Es wird geprüft, zu welchem Anbieter dieser Schlüssel gehört…';

  @override
  String get aiErrNoCredits => 'Der Schlüssel ist in Ordnung, aber das Konto hat kein Guthaben. Hinterlegen Sie beim Anbieter eine Zahlungsmethode oder laden Sie Guthaben auf. Wenn Sie nichts zahlen möchten, probieren Sie einen Google-Gemini-Schlüssel (beginnt mit AIza…) — er hat ein kostenloses Kontingent.';

  @override
  String get aiErrBadKey => 'Der Schlüssel wurde abgelehnt. Prüfen Sie überflüssige Leerzeichen oder Anführungszeichen und erstellen Sie sonst einen neuen Schlüssel.';

  @override
  String get aiErrRateLimit => 'Der Anbieter ist gerade überlastet. Das liegt nicht an der App — versuchen Sie es gleich noch einmal.';

  @override
  String get aiErrNoModel => 'Dieses Modell ist für dieses Konto nicht verfügbar. Wählen Sie unter \'Erweitert — Modell direkt wählen\' ein anderes.';

  @override
  String get aiErrNetwork => 'Keine Internetverbindung. Prüfen Sie die Verbindung und versuchen Sie es erneut.';

  @override
  String get multiSelectStart => 'Mehrere Notizen löschen';

  @override
  String get selectAllTooltip => 'Alle aus- / abwählen';

  @override
  String get deleteSelected => 'Auswahl löschen';

  @override
  String get deleteSelectedDone => 'Fertig';

  @override
  String get deleteSelectedConfirm => 'Ausgewählte Notizen löschen?';

  @override
  String deleteSelectedBody(int n) => n == 1
          ? '1 Notiz wandert in den Papierkorb. Wiederherstellung innerhalb von 30 Tagen möglich.'
          : '$n Notizen wandern in den Papierkorb. Wiederherstellung innerhalb von 30 Tagen möglich.';

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
  String get printAction =>
      'Drucken';

  @override
  String get exportPdf =>
      'Als PDF exportieren';

  @override
  String get pdfFailed =>
      'PDF konnte nicht erstellt werden';

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
      'Datei laden und an den Text anhängen';

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
  String get historyWhyTidy => 'Vor dem Aufräumen';

  @override
  String get historyWhyAi => 'Vor der KI-Bearbeitung';

  @override
  String get historyWhyReplace => 'Vor dem Ersetzen';

  @override
  String get historyWhyRevert => 'Vor der Rückkehr zum Original';

  @override
  String get historyWhyRestore => 'Vor dem Wiederherstellen';

  @override
  String get widgetEmpty => 'Noch keine Notizen';

  @override
  String get widgetAllLocked => 'Gesperrte Notizen erscheinen nicht im Widget';

  @override
  String get attachTitle => 'Anhänge';

  @override
  String get attachAdd => 'Datei anhängen';

  @override
  String get attachRemove => 'Anhang entfernen';

  @override
  String get attachRemoveBody => 'Die Datei wird von diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get attachFailed => 'Datei konnte nicht angehängt werden';

  @override
  String get attachNotHere => 'Diese Datei liegt auf einem anderen Gerät';

  @override
  String attachAndMore(int n) => 'und ${n} weitere';

  @override
  String attachOther(String device, String what) => 'Anhang: ${what} hängt an der Notiz auf Ihrem ${device} (nur dort einsehbar)';

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
        return 'Android-Telefon';
      case 'windows':
        return 'Windows-PC';
      case 'web':
        return 'Web';
      default:
        return 'anderes Gerät';
    }
  }

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
  String get paperTitle => 'Editor-Hintergrund';

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
  String get paperFrost => 'Frost';

  @override
  String get lockSectionTitle => 'Sperre';

  @override
  String get lockTitle => 'App-Sperre';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? 'Die App mit Fingerabdruck, Gesicht oder der Displaysperre öffnen.'
      : vendor == 'windows'
          ? 'Die App mit Windows Hello oder der Geräte-PIN öffnen.'
          : 'Die App mit Face ID, Touch ID oder dem Gerätecode öffnen.';

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
  String lockUnavailable(String vendor) => vendor == 'android'
      ? 'Fingerabdruck, Gesichtserkennung und Displaysperre sind auf diesem Gerät nicht verfügbar.'
      : vendor == 'windows'
          ? 'Windows Hello und Geräte-PIN sind auf diesem Gerät nicht verfügbar.'
          : 'Face ID, Touch ID und Gerätecode sind auf diesem Gerät nicht verfügbar.';

  @override
  String get lockReasonOpen => 'Bestätigen, um die Notizen zu öffnen';

  @override
  String get lockReasonOn => 'Bestätigen, um die Sperre zu aktivieren';

  @override
  String get lockReasonOff => 'Bestätigen, um die Sperre zu deaktivieren';

  @override
  String get noteLock => 'Diese Notiz sperren';

  @override
  String get noteUnlock => 'Diese Notiz entsperren';

  @override
  String get noteLocked => 'Gesperrte Notiz';

  @override
  String get lockReasonNote => 'Gesperrte Notiz öffnen';

  @override
  String get noteLockDone => 'Notiz gesperrt';

  @override
  String get noteUnlockDone => 'Notiz entsperrt';

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
  String get tidyRulesSub =>
      'Legt fest, was Aufräumen mit dem Text macht. Ihre Wahl hier gilt nur für das Basis-Aufräumen — die anderen Wege tun genau das, was ihr Name sagt.';

  @override
  String get syncOnTitle => 'Ein';

  @override
  String get syncOffTitle => 'Aus';

  @override
  String get syncSignedOutTitle => 'Anmeldung nötig';
  @override
  String get syncHelpTitleGdrive => 'Google Drive neu verbinden';
  @override
  String get syncHelpStepsGdrive => '1. Tippen Sie unten und wählen Sie Ihr Google-Konto\n2. Erlauben Sie den Zugriff auf Drive\n3. Der Abgleich startet sofort';
  @override
  String get syncHelpNoteGdrive => 'Ihre Notizen liegen weiterhin auf Drive. Nach der Anmeldung sind sie wieder da.';
  @override
  String get syncDiagSignedOutGdrive => 'Dieses Gerät ist bei keinem Google-Konto angemeldet.';
  @override
  String get syncSignInGoogle => 'Mit Google anmelden';
  @override
  String get syncAllowDrive => 'Zugriff auf Drive erlauben';
  @override
  String get syncDiagPreparingGdrive =>
      "Angemeldet. Notizen werden aus Drive geladen. Sie müssen nicht zusehen — wechseln Sie ruhig die App; das Laden pausiert und setzt beim Zurückkehren genau dort fort.";
  @override
  String get syncRecheckStillGdrive => 'Noch nicht alles da. Der erste Abgleich dauert etwas, wenn Sie viele Notizen haben \u2014 er läuft weiter, auch wenn Sie schließen.';

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
  String get quoteTitle => 'Zitate (> Text)';
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
  String get menuTidyPreview => 'Bereinigung ansehen';
  @override
  String get dividerTip => 'Trennlinie';
  @override
  String get syncScroll => 'Gemeinsam scrollen';
  @override
  String get pasteTipTitle => 'Nicht bei jedem Einfügen fragen';
  @override
  String get pasteTipSub => 'Schalte die Rückfrage aus, die das iPhone bei jedem Einfügen zeigt';
  @override
  String get pasteTipBody =>
      'Das iPhone fragt jedes Mal nach, wenn eine App die Zwischenablage liest. Diese App beginnt mit dem Einfügen, deshalb kommt die Frage sehr oft.\n\nEinmal ändern, dann fragt es nie wieder.\n\n1. Tippe unten auf \'Einstellungen öffnen\'\n2. Tippe auf \'Aus anderen Apps einsetzen\'\n3. Wähle \'Erlauben\'\n\nAuch mit Erlaubnis liest diese App die Zwischenablage nur in dem Moment, in dem du auf Einfügen tippst. Sie schaut nie von selbst nach.';
  @override
  String get pasteTipLater => 'Später';
  @override
  String get adClose => 'Werbung schließen';
  @override
  String get noteDuplicate => 'Duplizieren';
  @override
  String get noteDuplicated => 'Dupliziert';
  @override
  String get adSponsored => 'Anzeige';
  @override
  String get sponsorTitle => 'Eine Anzeige finanziert das nächste Update';
  @override
  String get sponsorBody =>
      'Bessere Funktionen und stetige Updates brauchen deine Unterstützung. Sieh dir eine Anzeige bis zum Ende an, und heute zeigt die App keine Werbung mehr.';
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
  String get premiumPlanBase => 'Standard';
  @override
  String get premiumPlanAll => 'Alle Geräte';
  @override
  String get premiumBestValue => 'Bester Wert';
  @override
  String get premiumPerks => 'Keine Werbung · Unbegrenzt aufräumen · Unbegrenzter KI-Assistent';
  @override
  String get premiumScopeBase => 'Gilt für die Geräte des Stores, in dem Sie gekauft haben, plus Web.';
  @override
  String get premiumScopeAll => 'Überall: iPhone, iPad, Mac, Android, Windows und Web.';
  @override
  String get premiumAutoRenew => 'Abos verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf gekündigt werden. Sie können jederzeit in den Kontoeinstellungen kündigen.';
  @override
  String get premiumRestore => 'Käufe wiederherstellen';
  @override
  String get premiumTerms => 'Nutzungsbedingungen';
  @override
  String get premiumPrivacy => 'Datenschutz';
  @override
  String get premiumThanks => 'Danke. Premium ist aktiv.';
  @override
  String get premiumNoStore => 'Auf diesem Gerät ist kein Kauf möglich. Kaufen Sie in der iPhone- oder Android-App; mit demselben Konto gilt es auch hier.';
  @override
  String get premiumUpgradeHere => 'Wechseln Sie zu Alle Geräte, um es auch hier zu nutzen. Die Restlaufzeit rechnet der Store an.';
  @override
  String get premiumHave => 'Ihr Tarif';
  @override
  String get premiumLoading => 'Preise werden vom Store geladen';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Ohne Werbung. Ohne Limits.';
  @override
  String get premiumPitchSub => 'Werbefrei und unbegrenzt · monatlich, jährlich oder lebenslang';
  @override
  String get premiumBody => 'Premium entfernt Werbung und öffnet Aufräumen und KI-Assistent unbegrenzt. Zwei Tarife: Standard für die Geräte des Kaufstores plus Web, und Alle Geräte für alles — iPhone, Android, PC und Web. Ihre Unterstützung baut das nächste Update.';
  @override
  String get premiumLifetime => 'Lebenslang';
  @override
  String get premiumMonthly => 'Monatlich';
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
  String get premiumYearly => 'Jährlich';
  @override
  String get premiumLifetimeNote => 'Einmalzahlung, keine Verlängerung';

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
  String get aiKeyUnknownFormat => 'Der Anbieter konnte nicht ermittelt werden. Alle vier wurden gefragt, keiner hat diesen Schlüssel akzeptiert. Bitte kopieren und fügen Sie den Schlüssel erneut ein.';
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
