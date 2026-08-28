import 'l10n.dart';

/// Français
class L10nFr extends L10n {
  const L10nFr();

  @override
  String get localeTag => 'fr';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => 'Version';

  @override
  String get homeTitle => 'Notes';
  @override
  String get settingsTooltip => 'Règles de nettoyage';
  @override
  String get searchHint => 'Rechercher';
  @override
  String get emptyList => 'Aucune note.\nCommencez avec « Coller et nettoyer ».';
  @override
  String get pinnedLabel => 'Épinglées';
  @override
  String get notesLabel => 'Notes';
  @override
  String get newNoteTooltip => 'Nouvelle note';
  @override
  String get pasteAndTidy => 'Nouvelle note depuis le presse-papiers';
  @override
  String get clipboardEmpty => 'Le presse-papiers est vide. Copiez d\'abord une réponse d\'IA.';
  @override
  String get yesterday => 'Hier';
  @override
  String get untitled => 'Sans titre';
  @override
  String get deleteConfirmTitle => 'Supprimer cette note ?';
  @override
  String get cancel => 'Annuler';
  @override
  String get delete => 'Supprimer';

  @override
  String dateShort(int y, int m, int d) => '$d/$m/$y';

  @override
  String get seedTitle => 'Bienvenue dans Skyblue Note';
  @override
  String get seedTag => 'Mode d\'emploi';
  @override
  String get shareAppTitle => "Partager l'app";
  @override
  String get rateAppTitle => 'Évaluez-nous';
  @override
  String get shareAppMsg =>
      'Skyblue Note — une app de notes légère et rapide, synchronisée sur tous vos appareils.';
  @override
  String get seedBody => [
        'Bonjour ! 😊 Voici le résumé que vous avez demandé[1][2].',
        '',
        '# Skyblue Note',
        '',
        'Le tableau est décalé. Touchez la **baguette** en bas à gauche. 🎉',
        '',
        '| Société | Symbole | Rendement | Poids',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '|Nvidia|NVDA|+48.9%|22%|',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '|Tesla|TSLA|-8.3%|8%|',
        '',
        '> Une fois rangé, les colonnes s’alignent. Le menu « Tableau » le colle tel quel dans un tableur.',
        '',
        '## Ce qui disparaît',
        '',
        '- [ ] Formules de politesse et émojis 🙂',
        '- [ ] Notes collées en fin de phrase[3][4]',
        '- [ ] Une paire d’astérisques oubliée en fin de ligne**',
        '- [x] Le tableau cassé est reconstruit',
        '',
        '## Ce qui reste',
        '',
        'Les titres, le **gras** et les citations restent. À l’écran on voit le sens ; collés dans Notes ou sur un forum, les marques disparaissent.',
        '',
        '---',
        '',
        '\t•\tPuces enveloppées de tabulations — c’est ainsi que Grok et ChatGPT collent',
        '\t•\tEspaces   et tabulations en double',
        '\t•\tCes lignes éparses retrouvent leur place aussi',
        '',
        '> Pas convaincu ? [Restaurer l’original](https://ezlong.com/skybluenote) le remet.',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get bodyFontSizeTitle => 'Taille du texte';

  @override
  String get bodyLineHeightTitle => 'Interligne du corps';

  @override
  String get bodyFontSizeSample =>
      'Découvrez un espace de travail Smart qui met de l’ordre dans vos nombreuses idées avec une vraie Simplicity. Collez, appuyez sur Nettoyer, tout devient Clean.';

  @override
  String get wizardNothingToDo => 'Rien à modifier';

  @override
  String wizardAppliedToast(int count) => '$count instruction(s) appliquée(s)';

  @override
  String get skipPreviewCheck => 'Ignorer l’aperçu à l’avenir';

  @override
  String get previewTitle2 => 'Aperçu avant application';

  @override
  String get previewSub2 => 'Affiche le résultat puis demande avant d’appliquer';
  @override
  String get metaTooltip => 'Titre et tags';
  @override
  String get pinTooltip => 'Épingler en haut';
  @override
  String get unpinTooltip => 'Désépingler';

  @override
  String get unpinConfirmTitle => 'Détacher cette note ?';

  @override
  String get unpinConfirmBody =>
      'Appuyez longuement sur une note dans la liste pour la réépingler.';
  @override
  String get deleteTooltip => 'Supprimer';
  @override
  String get titleHint => 'Titre (automatique)';
  @override
  String get titleTapHint => 'Ajouter un titre';
  @override
  String get sourceNone => 'Aucune source';
  @override
  String get sourceOther => 'Autre';
  @override
  String get tagsHint => 'Tags (séparés par des virgules)';
  @override
  String get tagAiButton => 'Tags par IA';
  @override
  String get tagAiWorking => 'Recherche de tags…';
  @override
  String get tagAiNone => 'Aucun mot-clé trouvé';
  @override
  String get tagAiLocalNote => 'Pas de clé IA : sélection locale';
  @override
  String get tagsBoxHint => 'Saisissez un tag, puis une virgule';
  @override
  String get tagRemoveTip => 'Supprimer le tag';
  @override
  String get bodyHint => 'Collez ou saisissez ici';
  @override
  String get noteNotFound => 'Note introuvable';
  @override
  String get revertedToast => 'Retour à l\'original. Le texte précédent est dans l\'historique.';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => 'Revenir à l\'original';

  @override
  String get revertConfirmTitle => 'Revenir à l\'original ?';

  @override
  String get revertConfirmBody =>
      'La note revient au texte que vous avez collé au départ. Tout le nettoyage et toutes les modifications faites ensuite seront perdus.\n\nVous pourrez toujours revenir à vos modifications précédentes — le menu → Historique des versions conserve le texte actuel en première position.';

  @override
  String get revertConfirmOk => 'Revenir';

  @override
  String get okAction =>
      'OK';

  @override
  String get revertDoneTitle =>
      'Retour à l\'original effectué';

  @override
  String get revertDoneBody =>
      'Le texte sur lequel vous travailliez n\'est pas perdu.\n\nOuvrez le menu → Historique des versions : la première entrée est le texte juste avant le retour. Touchez-la pour le récupérer à tout moment.';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => 'Liste à puces';

  @override
  String get listDashAction => 'Liste à tirets';

  @override
  String get listNumberAction => 'Liste numérotée';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => 'Source';

  @override
  String sourceSaved(String name) => 'Source enregistrée : $name';

  @override
  String sourceDetected(String name) => 'Source détectée : $name';

  @override
  String get sourceCleared => 'Source effacée';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'Dossier';

  @override
  String get folderNone => 'Aucun dossier';

  @override
  String get folderNew => 'Nouveau dossier';

  @override
  String get folderNameHint => 'Nom du dossier';

  @override
  String get folderCleared => 'Retiré du dossier';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => 'Gérer les dossiers';

  @override
  String get folderRename => 'Renommer';

  @override
  String get folderDelete => 'Supprimer le dossier';

  @override
  String get folderReorderHint => 'Faites glisser pour réordonner';

  @override
  String get folderManageEmpty => 'Aucun dossier pour le moment';

  @override
  String get folderDupName => 'Un dossier portant ce nom existe déjà';

  @override
  String get folderDeleted => 'Dossier supprimé';

  @override
  String get folderRenamed => 'Renommé';

  @override
  String folderDeleteBody(String name, int count) =>
      'Les $count notes de « $name » restent dans Toutes. Les notes ne sont pas supprimées.';

  @override
  String folderNoteCount(int count) => '$count notes';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => 'Vérification de son fonctionnement réel…';

  @override
  String get aiPingOk => 'L’édition fonctionne. Vous pouvez y aller.';

  @override
  String aiPingFailed(String err) => 'La liste est arrivée, mais l’appel d’édition a été refusé — $err';

  @override
  String get aiAdvancedNote => 'En général, inutile d’y toucher. La clé suffit.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => 'Papier';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWalnut => 'Noyer';

  @override
  String get paperNight => 'Nuit';

  @override
  String get paperSky => 'Ciel';

  @override
  String get themeSystemNote =>
      'En suivant l’appareil, l’app passe en sombre quand l’appareil le fait.';

  @override
  String folderMoved(String name) => 'Déplacé vers $name';
  @override
  String appliedDone(String summary) => 'Appliqué — $summary';

  @override
  String get undoTip => 'Annuler';
  @override
  String get redoTip => 'Rétablir';
  @override
  String get moveLeftTip => 'Vers la gauche';
  @override
  String get moveRightTip => 'Vers la droite';
  @override
  String get lineStartTip => 'Début de ligne';
  @override
  String get lineEndTip => 'Fin de ligne';
  @override
  String get indentTip => 'Indenter';

  @override
  String get todoAction => 'Tâche';
  @override
  String get hideKeyboardTip => 'Masquer le clavier';

  @override
  String get tidyAction => 'Nettoyer';
  @override
  String get wizardAction => 'IA';
  @override
  String get tableAction => 'Tableau';
  @override
  String get replaceAction => 'Remplacer';
  @override
  String get copyAction => 'Copier';
  @override
  String get undoAction => 'Annuler';

  @override
  String get noTablesFound => 'Aucun tableau trouvé dans cette note';
  @override
  String tableInfo(int n, int cols, int rows) => 'Tableau $n — $cols col × $rows lignes';
  @override
  String get forSpreadsheet => 'Pour tableur';
  @override
  String get copiedSpreadsheet => 'Copié — collez dans une cellule de Google Sheets ou Excel';
  @override
  String get copiedCsv => 'Copié en CSV';
  @override
  String get copiedMarkdown => 'Copié en tableau Markdown';

  @override
  String get wizardTitle => 'Édition par IA';
  @override
  String get wizardHint =>
      'Donnez vos consignes en langage naturel. Ex. :\nMets 2 lignes vides avant les sous-titres et 1 après\nRemplace MS par Microsoft';
  @override
  String get favSaveButton => 'Enregistrer en favori';
  @override
  String get favListTitle => 'Instructions favorites';
  @override
  String get favUse => 'Utiliser';
  @override
  String get favEmpty => 'Aucune instruction enregistrée';
  @override
  String get favRemove => 'Retirer';
  @override
  String get favSavedToast => 'Enregistré';
  @override
  String appliedPrefix(String what) => 'Appliqué · $what';
  @override
  String unknownPrefix(String what) => 'L\'IA s\'en charge · $what';
  @override
  String get aiKeyPromo =>
      'Ajoutez une clé d\'API d\'IA dans les réglages pour traiter aussi ces éditions libres.';
  @override
  String get aiBusyLabel => 'L\'IA édite…';
  @override
  String get aiWorking => 'L\'IA modifie le texte selon vos instructions. Cela peut prendre un moment…';
  @override
  String get aiEmptyResponse => 'Réponse vide';
  @override
  String aiCallFailed(String error) => 'Échec de l\'appel IA : $error';
  @override
  String get aiAppliedToast => 'Édition IA appliquée — récupérable avec Annuler';
  @override
  String get close => 'Fermer';
  @override
  String get interpretApply => 'Interpréter et appliquer';

  @override
  String get replaceTitle => 'Remplacer';
  @override
  String get findLabel => 'Rechercher';
  @override
  String get replaceWithLabel => 'Remplacer par (\\n = saut de ligne)';
  @override
  String get regexLabel => 'Expression régulière';
  @override
  String get saveAsRule => 'Enregistrer comme règle de remplacement auto';
  @override
  String get saveAsRuleSub => 'Toujours appliquée à chaque « Nettoyer » futur';
  @override
  String get ruleScopeAll => 'Appliquer à toutes les notes';
  @override
  String get ruleScopeNote => 'Appliquer à cette note uniquement';
  @override
  String get noteRules => 'Règles de cette note';
  @override
  String get invalidRegex => 'Expression régulière invalide';
  @override
  String get noMatches => 'Aucune correspondance';
  @override
  String replacedCount(int count) => 'Remplacé à $count endroits';
  @override
  String get savedRuleSuffix => ' · enregistré comme règle de remplacement auto';
  @override
  String get replaceAllAction => 'Tout remplacer';

  @override
  String get copyAll => 'Tout copier';

  @override
  String get copyPlainSub =>
      'Texte brut — sans les marques markdown';

  @override
  String get copyRaw => 'Copier en markdown';

  @override
  String get copyRawSub =>
      'Pour Notion, Slack, GitHub et autres apps qui lisent le markdown';
  @override
  String get copiedAll => 'Texte entier copié';
  @override
  String get tidyCopy => 'Nettoyer et copier';
  @override
  String get tidyCopySub => 'La note reste intacte ; seul le résultat nettoyé est copié';
  @override
  String tidyCopied(String summary) => 'Nettoyé et copié — $summary';
  @override
  String get copyTableSpreadsheet => 'Copier les tableaux pour tableur';
  @override
  String get copiedTableSpreadsheet => 'Tableaux copiés pour tableur';

  @override
  String previewTitle(String preset) => '$preset — Aperçu';
  @override
  String warningPrefix(String warning) => 'Attention : $warning';
  @override
  String get tidyResultLabel => 'Résultat';
  @override
  String get originalLabel => 'Original';
  @override
  String get apply => 'Appliquer le nettoyage';

  @override
  String get presetAiName =>
      'Nettoyage standard';
  @override
  String get presetAiDesc =>
      'Rend lisible une réponse d IA collée. Cela suffit la plupart du temps';
  @override
  String get presetStripName =>
      'Tout enlever';
  @override
  String get presetStripDesc =>
      'Pour le chat et les SMS. Toutes les marques et émojis partent, le tableau s’aligne';
  @override
  String get presetMinimalName =>
      'Peluches seulement';
  @override
  String get presetMinimalDesc =>
      'Garde la structure, enlève seulement l invisible';
  @override
  String get presetTablesName =>
      'Tableaux seulement';
  @override
  String get presetTablesDesc =>
      'Pour coller directement dans Excel ou Google Sheets';
  @override
  String get presetBlogName =>
      'Pour les blogs';
  @override
  String get presetBlogDesc =>
      'Garde les adresses des liens, enlève les signes';

  @override
  String get tidySample => [
        '## Résumé du jour 😊',
        '',
        'Les **points clés** sont au nombre de trois[1][2].',
        '',
        '- Premier point',
        '- Deuxième point',
        '',
        '> Une ligne citée',
        '',
        'Plus sur le [blog](https://ezlong.com)',
        '',
        '| Poste | Valeur |',
        '|---|---|',
        '|Ventes|120|',
      ].join('\n');

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get menuAppSettings => "Réglages de l'app";

  @override
  String get menuAiKey => 'Clé API IA';

  @override
  String get syncTitle => 'Synchronisation';
  @override
  String get syncAppleOnly => 'Apple uniquement';

  @override
  String get syncScopeTitle =>
      'Portée de la synchronisation';

  @override
  String get syncScopeShared =>
      'Synchronisé entre vos appareils : notes, règles de nettoyage, règles de remplacement ajoutées, dossiers, instructions IA enregistrées';

  @override
  String get syncStateOffGdrive => 'Reconnectez-vous à votre compte Google';
  @override
  String get syncStateExpiredGdrive => 'Votre compte est toujours connecté, mais l’autorisation d’accès à Drive a expiré. Touchez une fois pour la renouveler.';

  @override
  String get syncScopePlatformGdrive =>
      'Le stockage Google Drive est partagé par tous les appareils équipés de cette app. Installez-la et connectez-vous avec le même compte Google';

  @override
  String get syncScopeDevice =>
      'Par appareil : taille du texte, interligne, papier, apparence, tri';

  @override
  String get syncScopePlatform =>
      "Pour l'instant, la synchronisation automatique ne fonctionne qu'entre appareils Apple (iPhone, iPad, Mac). Ailleurs, utilisez Exporter la sauvegarde et Importer depuis le menu";

  @override
  String get typographyTitle => 'Texte et interligne';

  @override
  String get syncScopeNever =>
      'La clé d’API IA n’est envoyée vers aucun cloud, saisissez-la donc sur chaque appareil';
  @override
  String get syncWhereTitle =>
      'Où le garder';
  @override
  String get syncBackendNone =>
      'Ne pas synchroniser';
  @override
  String get syncBackendNoneSub =>
      'Uniquement sur cet appareil';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      'Entre iPhone, iPad et Mac';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      'Les autres appareils et le web aussi';
  @override
  String get syncSoon =>
      'Bientôt';

  @override
  String get driveSignInFailed => 'Impossible de connecter votre compte Google';

  @override
  String get driveNeedsSignIn => 'Connectez d\'abord un compte Google';

  @override
  String get driveSignedInAs => 'Connecté';
  @override
  String get syncSectionState =>
      'État actuel';
  @override
  String get syncNowAction =>
      'Synchroniser maintenant';
  @override
  String get syncNowBusy => 'Synchronisation…';

  @override
  String get syncLastNever =>
      'Jamais synchronisé';
  @override
  String get headingTip => 'Titre';
  @override
  String get quoteTip => 'Citation';
  @override
  String get boldTip => 'Gras';
  @override
  String get codeTip => 'Code';
  @override
  String get linkTip => 'Lien';
  @override
  String get outdentTip => 'Diminuer le retrait';
  @override
  String get cursorLeftTip => 'Gauche';
  @override
  String get cursorRightTip => 'Droite';
  @override
  String get clearFormatTip => 'Effacer la mise en forme';

  @override
  String get blockFormatTip => 'Format de paragraphe';
  @override
  String get blockBody => 'Corps';
  @override
  String get blockH1 => 'Titre 1';
  @override
  String get blockH2 => 'Titre 2';
  @override
  String get blockH3 => 'Titre 3';
  @override
  String get blockQuote => 'Citation';
  @override
  String get blockCode => 'Code';
  @override
  String get bodyFontTitle => 'Police du corps';
  @override
  String get bodyFontSystem => 'Système';
  @override
  String get bodyFontNoto => 'Noto';
  @override
  String get bodyFontMono => 'Monospace';
  @override
  String get moreTools => 'Plus';
  @override
  String get findTitle => 'Rechercher';
  @override
  String get findAction => 'Rechercher';
  @override
  String get showReplaceLabel => 'Remplacer';
  @override
  String get replaceOneAction => 'Remplacer';
  @override
  String get findNone => 'Aucun résultat';
  @override
  String get syncFirstTitle => 'Synchronisation…';
  @override
  String get syncFirstSub => 'Récupération des notes de vos autres appareils. Cela peut prendre un moment si vous en avez beaucoup.';
  @override
  String get syncLogTitle => 'Historique de synchronisation';
  @override
  String get syncLogNote => 'Uniquement ce qui a circulé et quand. Le contenu des notes n\'est pas conservé ici.';
  @override
  String get syncLogEmpty => 'Rien n\'a encore circulé';
  @override
  String get syncLogNever => 'Pas encore';
  @override
  String get syncLogUp => 'Envoyé';
  @override
  String get syncLogDown => 'Reçu';
  @override
  String get syncLogFailed => 'Échec';
  @override
  String syncUpdatedAt(String when) => 'Mis à jour ' + when;
  @override
  String findHits(int n) => n.toString() + ' trouvé(s)';
  @override
  String syncLogLastUp(String when) => 'Dernier envoi · ' + when;
  @override
  String syncLogLastDown(String when) => 'Dernière réception · ' + when;
  @override
  String get syncTroubleTitle =>
      'En cas de problème';
  @override
  String get syncTroubleNote =>
      'Synchroniser n’est pas sauvegarder. Supprimé ici, supprimé partout. Exportez de temps en temps un fichier de ce qui compte.';
  @override
  String syncLastAt(String when) => 'Dernière synchro : $when';

  @override
  String syncStateOn(String where) => 'Conservé dans $where : les mêmes notes sur chaque appareil avec cette app';

  @override
  String get syncStateOff => 'Activez iCloud Drive dans les réglages de l\'appareil';

  @override
  String syncStateSyncing(String where) => 'Synchronisation avec $where… cela prend de quelques secondes à une minute';

  @override
  String get aiKeyNotSynced => 'Vos notes sont synchronisées sur tous vos appareils via le stockage choisi. Pas votre clé API — saisissez-la sur chaque appareil.';
  @override
  String get aiKeySyncTitle => 'Synchroniser aussi la clé API';
  @override
  String get aiKeySyncSubApple => 'Elle passe par le trousseau iCloud, une voie différente de celle de vos notes. Seuls vos appareils détiennent la clé : même Apple ne peut pas la lire.';
  @override
  String get aiKeySyncSubGdrive => 'Une fois sur Google Drive, la sécurité de la clé API relève de chacun.';

  @override
  String get autoTagTitle => 'Étiqueter automatiquement';

  @override
  String get autoTagSub =>
      'Après une pause, l’IA réextrait les étiquettes. Les notes dont vous avez modifié les étiquettes restent intactes';

  @override
  String get syncStateSignedOut => 'Touchez pour voir comment';

  @override
  String get syncHelpTitle => 'Comment activer iCloud';

  @override
  String get syncHelpSteps =>
      '1. Réglages › votre nom en haut › iCloud\n2. Vérifiez qu\'iCloud Drive est activé — s\'il est désactivé, aucune app ne se synchronise\n3. Verrouillez puis déverrouillez l\'iPhone, revenez ici et touchez Revérifier\n\nVérifiez dans l\'app Fichiers, pas dans Réglages. Si vous voyez un dossier Skyblue Note dans Fichiers › iCloud Drive, tout est prêt.';

  @override
  String get syncOpenSettings => 'Ouvrir Réglages';

  @override
  String get syncRecheck => 'Vérifier à nouveau';

  @override
  String get syncHelpNote =>
      'Juste après l installation, la préparation peut prendre une ou deux minutes. Touchez alors Vérifier à nouveau.';

  @override
  String get sortFilterTooltip => 'Trier et filtrer';

  @override
  String get sortFilterTitle => 'Trier et filtrer';

  @override
  String get sortLabel => 'Tri';

  @override
  String get sortUpdated => 'Modifié récemment';

  @override
  String get sortCreated => 'Date de création';

  @override
  String get sortByTitle => 'Titre';

  @override
  String get filterSourceLabel => 'Source';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get selectWord => 'Sélectionner';

  @override
  String get tagAiNeedKey => 'Saisissez une clé API dans les Réglages pour utiliser le marquage automatique par IA.';

  @override
  String get toggleListTooltip => 'Masquer ou afficher la liste';

  @override
  String get aiDetecting => 'Recherche du fournisseur auquel appartient cette clé…';

  @override
  String get aiErrNoCredits => 'La clé est valide, mais le compte n\'a plus de solde. Ajoutez un moyen de paiement ou des crédits chez le fournisseur. Pour ne rien payer, essayez une clé Google Gemini (commence par AIza…) — elle a un palier gratuit.';

  @override
  String get aiErrBadKey => 'La clé a été refusée. Vérifiez les espaces ou guillemets en trop, puis générez une nouvelle clé si besoin.';

  @override
  String get aiErrRateLimit => 'Le fournisseur est saturé pour le moment. Ce n\'est pas l\'application : réessayez dans un instant.';

  @override
  String get aiErrNoModel => 'Ce modèle n\'est pas disponible sur ce compte. Choisissez-en un autre dans \'Avancé — choisir un modèle\'.';

  @override
  String get aiErrNetwork => 'Impossible d\'accéder à internet. Vérifiez la connexion et réessayez.';

  @override
  String get multiSelectStart => 'Supprimer plusieurs notes';

  @override
  String get selectAllTooltip => 'Tout sélectionner / désélectionner';

  @override
  String get deleteSelected => 'Supprimer la sélection';

  @override
  String get deleteSelectedDone => 'Terminé';

  @override
  String get deleteSelectedConfirm => 'Supprimer les notes sélectionnées ?';

  @override
  String deleteSelectedBody(int n) => n == 1
          ? '1 note ira à la corbeille. Vous pourrez la restaurer sous 30 jours.'
          : '$n notes iront à la corbeille. Vous pourrez les restaurer sous 30 jours.';

  @override
  String get trashTitle => 'Corbeille';

  @override
  String get trashSubtitle => 'Les notes supprimées sont conservées 30 jours';

  @override
  String get trashEmpty => 'La corbeille est vide';

  @override
  String get trashRestore => 'Restaurer';

  @override
  String get trashDeleteNow => 'Supprimer maintenant';

  @override
  String get trashEmptyAll => 'Vider';

  @override
  String get trashEmptyConfirm => 'Vider la corbeille est irréversible. Continuer ?';

  @override
  String get trashRestored => 'Restaurée';

  @override
  String trashDaysLeftLabel(int days) => 'Suppression définitive dans $days jours';

  @override
  String get exportSectionTitle =>
      'Importer et exporter';

  @override
  String get exportSubtitle =>
      'Vos notes peuvent partir à tout moment. Le Markdown s ouvre dans Notes d Apple, Obsidian, Notion et les autres.';

  @override
  String get exportNote =>
      'Exporter cette note';

  @override
  String get exportAllMd =>
      'Exporter toutes les notes';

  @override
  String get exportAllMdSub =>
      'Toutes les notes en Markdown, dans un zip';

  @override
  String get exportBackup =>
      'Enregistrer une sauvegarde';

  @override
  String get exportBackupSub =>
      'Un fichier qui restaure tout ici (sans votre clé API)';

  @override
  String get exportFailed =>
      'Échec de l export';

  @override
  String get printAction =>
      'Imprimer';

  @override
  String get exportPdf =>
      'Exporter en PDF';

  @override
  String get pdfFailed =>
      'Impossible de créer le PDF';

  @override
  String get exportEmpty =>
      'Aucune note à exporter';

  @override
  String get choosePreset => 'Choisir le type de nettoyage';

  @override
  String get importFiles =>
      'Importer depuis des fichiers';

  @override
  String get importFilesSub =>
      'Les fichiers Markdown et texte deviennent des notes. Les sauvegardes se restaurent ici aussi';

  @override
  String get importAppend =>
      'Charger un fichier et l\'ajouter au texte';

  @override
  String get importNone =>
      'Rien n a été importé';

  @override
  String importDone(int n) => '$n notes importées';

  @override
  String get sourceGuessSuffix => '(estimation)';

  @override
  String get splitEmpty => 'Choisissez une note à gauche';

  @override
  String get historyTitle =>
      'Historique des versions';

  @override
  String get historySub =>
      'Revenez au texte avant un nettoyage ou un remplacement';

  @override
  String get historyEmpty =>
      'Rien à restaurer pour l instant';

  @override
  String get historyRestore =>
      'Restaurer';

  @override
  String get historyOriginal =>
      'Tel que collé';

  @override
  String get historyWhyTidy => 'Avant le nettoyage';

  @override
  String get historyWhyAi => 'Avant la modification par IA';

  @override
  String get historyWhyReplace => 'Avant le remplacement';

  @override
  String get historyWhyRevert => 'Avant le retour à l\'original';

  @override
  String get historyWhyRestore => 'Avant la restauration';

  @override
  String get widgetEmpty => 'Pas encore de notes';

  @override
  String get widgetAllLocked => 'Les notes verrouillées n\'apparaissent pas dans le widget';

  @override
  String get attachTitle => 'Pièces jointes';

  @override
  String get attachAdd => 'Joindre un fichier';

  @override
  String get attachRemove => 'Retirer la pièce jointe';

  @override
  String get attachRemoveBody => 'Le fichier sera supprimé de cet appareil. C\'est irréversible.';

  @override
  String get attachFailed => 'Impossible de joindre le fichier';

  @override
  String get attachNotHere => 'Ce fichier se trouve sur un autre appareil';

  @override
  String attachAndMore(int n) => 'et ${n} de plus';

  @override
  String attachOther(String device, String what) => 'Pièce jointe : ${what} est joint à la note sur votre ${device} (consultable sur cet appareil uniquement)';

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
        return 'téléphone Android';
      case 'windows':
        return 'PC Windows';
      case 'web':
        return 'web';
      default:
        return 'autre appareil';
    }
  }

  @override
  String historyUnknownTime(int n) => 'Version précédente $n';

  @override
  String get selUnitSentence => 'Phrase';

  @override
  String get selUnitLine => 'Ligne';

  @override
  String get selUnitPara => 'Paragraphe';

  @override
  String get selUnitAll => 'Tout';

  @override
  String get selStartLeft => 'Début gauche';

  @override
  String get selStartRight => 'Début droite';

  @override
  String get selEndLeft => 'Fin gauche';

  @override
  String get selEndRight => 'Fin droite';

  @override
  String get selClear => 'Effacer la sélection';

  @override
  String get paperTitle => 'Fond de l\'éditeur';

  @override
  String get paperSub => 'Fond et lignes en un ensemble. L\'interligne suit la taille du texte.';

  @override
  String get paperNone => 'Uni';

  @override
  String get paperMoleskine => 'Moleskine';

  @override
  String get paperSepia => 'Sépia';

  @override
  String get paperManuscript => 'Manuscrit';

  @override
  String get paperFrost => 'Givre';

  @override
  String get lockSectionTitle => 'Verrouillage';

  @override
  String get lockTitle => 'Verrouillage de l\'app';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? 'Ouvrez l’app avec votre empreinte, votre visage ou le verrouillage de l’écran.'
      : vendor == 'windows'
          ? 'Ouvrez l’app avec Windows Hello ou le code PIN de l’appareil.'
          : 'Ouvrez l’app avec Face ID, Touch ID ou le code de l’appareil.';

  @override
  String get lockNote => 'Ce verrouillage empêche quelqu\'un qui prend votre appareil d\'ouvrir l\'app. Il ne chiffre pas les fichiers stockés sur l\'appareil.';

  @override
  String get lockDelayTitle => 'Verrouiller après';

  @override
  String get lockDelayNow => 'Immédiatement';

  @override
  String get lockDelay1m => 'Après 1 minute';

  @override
  String get lockDelay5m => 'Après 5 minutes';

  @override
  String get lockUnlock => 'Déverrouiller';

  @override
  String get lockLocked => 'Verrouillé';

  @override
  String lockUnavailable(String vendor) => vendor == 'android'
      ? 'L’empreinte, la reconnaissance faciale et le verrouillage de l’écran ne sont pas disponibles ici.'
      : vendor == 'windows'
          ? 'Windows Hello et le code PIN de l’appareil ne sont pas disponibles ici.'
          : 'Face ID, Touch ID et le code de l’appareil ne sont pas disponibles ici.';

  @override
  String get lockReasonOpen => 'Vérifiez pour ouvrir vos notes';

  @override
  String get lockReasonOn => 'Vérifiez pour activer le verrouillage';

  @override
  String get lockReasonOff => 'Vérifiez pour désactiver le verrouillage';

  @override
  String get noteLock => 'Verrouiller cette note';

  @override
  String get noteUnlock => 'Déverrouiller cette note';

  @override
  String get noteLocked => 'Note verrouillée';

  @override
  String get lockReasonNote => 'Ouvrir la note verrouillée';

  @override
  String get noteLockDone => 'Note verrouillée';

  @override
  String get noteUnlockDone => 'Note déverrouillée';

  @override
  String get syncDiagSignedOut => 'Cet appareil n\'est pas connecté à iCloud. Connectez-vous d\'abord.';

  @override
  String get syncDiagNoContainer => 'Vous êtes connecté, mais cette app n\'a pas encore son espace iCloud. Activez-le avec les étapes ci-dessous.';

  @override
  String get syncDiagPreparing => 'L\'espace est là. En attente de sa préparation.';

  @override
  String get syncRecheckWhat => 'Redemande à l\'appareil l\'état d\'iCloud, depuis le début.';

  @override
  String get syncRecheckOk => 'iCloud est activé';

  @override
  String get syncRecheckStill => 'Pas encore activé. Activez-le dans Réglages puis touchez à nouveau. Si vous venez de l\'activer, réessayez dans une ou deux minutes.';

  @override
  String get syncOpenFailed => 'Impossible d\'ouvrir Réglages. Ouvrez-le depuis l\'écran d\'accueil.';

  @override
  String get syncOpenManual => 'Ouvrez Réglages vous-même : écran d\'accueil › Réglages › votre nom en haut › iCloud.';

  @override
  String get menuFile => 'Fichier';

  @override
  String get menuClose => 'Fermer';

  @override
  String get menuPrefs => 'Réglages…';

  @override
  String get appliedTitle => 'Tout est bien rangé';

  @override
  String get tidyRulesTitle => 'Règles de nettoyage';

  @override
  String get tidyRulesSub =>
      'Définit ce que Ranger fait à votre texte. Votre choix ici ne vaut que pour le rangement de base ; les autres façons font exactement ce que leur nom dit.';

  @override
  String get syncOnTitle => 'Activé';

  @override
  String get syncOffTitle => 'Désactivé';

  @override
  String get syncSignedOutTitle => 'Connexion requise';
  @override
  String get syncHelpTitleGdrive => 'Reconnecter Google Drive';
  @override
  String get syncHelpStepsGdrive => '1. Touchez le bouton ci-dessous et choisissez votre compte Google\n2. Autorisez Drive\n3. La synchronisation démarre aussitôt';
  @override
  String get syncHelpNoteGdrive => 'Vos notes sont toujours sur Drive. Elles reviennent dès la connexion.';
  @override
  String get syncDiagSignedOutGdrive => 'Aucun compte Google sur cet appareil.';
  @override
  String get syncSignInGoogle => 'Se connecter avec Google';
  @override
  String get syncAllowDrive => 'Autoriser Drive';
  @override
  String get syncDiagPreparingGdrive =>
      "Connecté. Récupération de vos notes depuis Drive. Inutile de rester devant l’écran — passez à une autre app ; la récupération se met en pause et reprend à votre retour.";
  @override
  String get syncRecheckStillGdrive => 'Tout n\u2019est pas encore arrivé. La première synchronisation prend un moment si vous avez beaucoup de notes \u2014 elle continue après la fermeture.';

  @override
  String pastedFrom(String src, String date) =>
      'de $src le $date';

  @override
  String pastedOn(String date) => 'collé le $date';

  @override
  String staleWarn(int days) =>
      'Cette réponse a $days jours. Le modèle a pu changer depuis.';
  @override
  String get settingsSecView => 'Affichage';
  @override
  String get settingsSecTidy => 'Règles de nettoyage';
  @override
  String get settingsSecWhen => 'Lors du nettoyage';
  @override
  String get settingsSecInfo => 'À propos';
  @override
  String get emphTitle => 'Emphase en gras (**texte**)';
  @override
  String get emphSub => 'Pour les phrases entières de plus de 40 caractères, seules les marques sont retirées';
  @override
  String get emphQuoteSingle => "Guillemets simples 'emphase'";
  @override
  String get emphQuoteDouble => 'Guillemets doubles "emphase"';
  @override
  String get removeLabel => 'Retirer';
  @override
  String get keepLabel => 'Conserver';
  @override
  String get hrTitle => 'Séparateurs (---)';
  @override
  String get headingTitle => 'Titres (#, ##)';

  @override
  String get quoteTitle => 'Citations (> texte)';
  @override
  String get headingStrip => 'Garder le texte seul';
  @override
  String get headingKeep => 'Laisser tel quel';
  @override
  String get headingPrefix => 'Préfixer par ■';
  @override
  String get headingBracket => '[Crochets]';
  @override
  String get bulletTitle => 'Puces (-, *)';
  @override
  String get bulletHyphen => 'Trait d\'union -';
  @override
  String get bulletMiddot => 'Point médian ·';
  @override
  String get bulletDot => 'Puce •';
  @override
  String get bulletWhite => 'Puce blanche ◦';
  @override
  String get bulletKeep => 'Garder le symbole d\'origine';
  @override
  String get bulletIndentTitle => 'Retrait des puces';
  @override
  String get indent2 => '2 espaces';
  @override
  String get indent4 => '4 espaces';
  @override
  String get indentNone => 'Aucun';
  @override
  String get headingPadTitle => 'Espacement des sous-titres';
  @override
  String get headingPadSub =>
      '2 lignes avant, 1 après — un caractère invisible (ㅤ) préserve l\'espacement dans les messageries et blogs';
  @override
  String get citationsTitle => 'Retirer les liens de citation';
  @override
  String get citationsSub => 'Supprime les numéros de note dans le texte et la liste des sources à la fin';
  @override
  String get monoEditorTitle => 'Tableaux à chasse fixe';
  @override
  String get monoEditorSub => 'Aligne exactement les colonnes des tableaux et du code. Le texte garde la police de l’appareil';
  @override
  String get dashListTitle => 'Transformer les suites de tirets en listes';
  @override
  String get dashListSub => 'Découpe les suites sur une ligne comme « – a – b – c » en liste';
  @override
  String get fillerHeadingTitle => 'Nettoyer les sous-titres à caractère invisible';
  @override
  String get fillerHeadingSub => 'Applique les règles d\'espacement et de titre aux pseudo-titres entourés de ㅤ';
  @override
  String get aiSectionTitle => 'Connexion Édition IA';
  @override
  String get aiSectionDesc =>
      'Avec une clé API, l IA suit des consignes libres comme "fais plus court". Le nettoyage utilise des règles locales et ne demande pas de clé — seule l édition IA en a besoin.';
  @override
  String get aiKeyHint => 'Clé API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get menuTidyPreview => 'Aperçu du nettoyage';
  @override
  String get dividerTip => 'Séparateur';
  @override
  String get syncScroll => 'Défilement synchronisé';
  @override
  String get pasteTipTitle => 'Ne plus demander à chaque collage';
  @override
  String get pasteTipSub => 'Supprimez d\'un coup l\'alerte que l\'iPhone affiche à chaque collage';
  @override
  String get pasteTipBody =>
      'L\'iPhone demande la permission chaque fois qu\'une app lit le presse-papiers. Cette app commence par un collage, donc cette alerte revient souvent.\n\nChangez-le une fois et il ne demandera plus.\n\n1. Touchez \'Ouvrir Réglages\' ci-dessous\n2. Touchez ‘Coller depuis d’autres apps’\n3. Choisissez \'Autoriser\'\n\nMême autorisée, cette app ne lit le presse-papiers qu\'au moment où vous touchez Coller. Elle ne regarde jamais d\'elle-même.';
  @override
  String get pasteTipLater => 'Plus tard';
  @override
  String get adClose => 'Fermer les pubs';
  @override
  String get noteDuplicate => 'Dupliquer';
  @override
  String get noteDuplicated => 'Dupliquée';
  @override
  String get adSponsored => 'Sponsorisé';
  @override
  String get sponsorTitle => 'Une publicité finance la prochaine mise à jour';
  @override
  String get sponsorBody =>
      'De meilleures fonctions et des mises à jour régulières ont besoin de votre soutien. Regardez une publicité jusqu\'au bout et l\'app n\'affichera plus de publicité aujourd\'hui.';
  @override
  String get sponsorWatch => 'Regarder une pub pour soutenir';
  @override
  String get sponsorSkip => 'Passer';
  @override
  String get sponsorLoading => 'Chargement de la publicité…';
  @override
  String get sponsorFailed => 'Impossible de charger la publicité. Réessayez dans un instant.';
  @override
  String get moreTooltip => 'Plus';
  @override
  String get sponsorGoPremium => 'Passer à Premium, sans pubs';
  @override
  String get premiumPlanBase => 'Standard';
  @override
  String get premiumPlanAll => 'Tous les appareils';
  @override
  String get premiumBestValue => 'Meilleur prix';
  @override
  String get premiumPerks => 'Sans publicité · Nettoyage illimité · Assistant IA illimité';
  @override
  String get premiumScopeBase => 'Fonctionne sur les appareils de la boutique d’achat, et sur le web.';
  @override
  String get premiumScopeAll => 'Sur tous les appareils que vous utilisez.';
  @override
  String get premiumAutoRenew => 'L’abonnement se renouvelle automatiquement s’il n’est pas annulé au moins 24 heures avant la fin de la période. Vous pouvez l’annuler à tout moment dans les réglages du compte.';
  @override
  String get premiumRestore => 'Restaurer les achats';
  @override
  String get premiumTerms => 'Conditions d’utilisation';
  @override
  String get premiumPrivacy => 'Confidentialité';
  @override
  String get premiumThanks => 'Merci. Premium est activé.';
  @override
  String get premiumNoStore => 'Achat impossible sur cet appareil. Une fois l’achat effectué, cela s’applique ici dès la connexion avec le même compte.';
  @override
  String get premiumUpgradeHere => 'Passez à Tous les appareils pour l’utiliser ici. La boutique déduit le temps restant.';
  @override
  String get premiumHave => 'Votre formule';
  @override
  String get premiumLoading => 'Récupération des prix';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Sans pub. Sans limites.';
  @override
  String get premiumPitchSub => 'Sans pub et illimité · mensuel, annuel ou à vie';
  @override
  String get premiumBody => 'Premium supprime la publicité et débloque le nettoyage et l’assistant IA sans limite. Deux formules : Standard, pour les appareils de la boutique d’achat et le web ; et Tous les appareils, pour tous les appareils que vous utilisez. Votre soutien construit la prochaine version.';
  @override
  String get premiumLifetime => 'À vie';
  @override
  String get premiumMonthly => 'Mensuel';
  @override
  String get premiumComingSoon => "Les achats seront activés dans la version App Store. C'est pour bientôt.";
  @override
  String get limitTitle => "Vous avez épuisé les usages gratuits du jour";
  @override
  String limitTidyBody(int n) => "L'offre gratuite comprend $n nettoyages par jour. Réinitialisation demain ; Premium supprime la limite.";
  @override
  String limitWizardBody(int n) =>
      'La version gratuite comprend $n éditions IA par jour. Cela repart demain — Premium supprime la limite.';
  @override
  String get limitSeePremium => 'Voir Premium';
  @override
  String get premiumYearly => 'Annuel';
  @override
  String get premiumLifetimeNote => 'Paiement unique, sans renouvellement';

  @override
  String trialBadge(int days) => 'Essai illimité · $days jours restants';

  @override
  String get trialEndedTitle => "Votre essai illimité est terminé";

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      'Pendant l essai, vous avez lancé $tidy nettoyages et $wiz éditions IA. Désormais, la version gratuite offre $tidyLimit nettoyages et $wizLimit éditions IA par jour. Premium supprime la limite.';
  @override
  String get themeTitle => 'Apparence';
  @override
  String get themeSystem => 'Suivre l\'appareil';
  @override
  String get themeLight => 'Clair';
  @override
  String get themeDark => 'Sombre';
  @override
  String get aiKeyVerify => 'Vérifier la clé';
  @override
  String get aiKeyChecking => 'Vérification…';
  @override
  String get aiKeyUnknownFormat => 'Impossible d\'identifier le fournisseur. Les quatre ont été interrogés et aucun n\'a accepté cette clé. Copiez-collez la clé à nouveau.';
  @override
  String get aiAdvancedLabel => 'Avancé — choisir le modèle soi-même';
  @override
  String get aiManualModelHint => 'Saisir le nom du modèle (ex. : gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => 'Automatique : $provider · $model';
  @override
  String aiModelsFound(int n) => '$n modèles disponibles confirmés.';
  @override
  String aiListFailed(String error) => 'Impossible de récupérer la liste des modèles ($error). La liste de secours intégrée sera utilisée.';
  @override
  String aiModelSwitched(String model) => "L'ancien modèle ne répondait plus – passage à $model.";
  @override
  String get rulesSectionTitle => 'Règles de remplacement automatique';
  @override
  String get rulesSectionDesc =>
      'Appliquées de haut en bas. \\n dans le remplacement crée un saut de ligne. Les blocs de code ne sont pas modifiés.';
  @override
  String get addRule => 'Ajouter une règle';
  @override
  String get settingsFooter =>
      'Les réglages prennent effet immédiatement et s\'appliquent dès le prochain « Nettoyer ». Les notes déjà nettoyées ne changent pas rétroactivement.';
}
