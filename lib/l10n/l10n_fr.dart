import 'l10n.dart';

/// Français
class L10nFr extends L10n {
  const L10nFr();

  @override
  String get localeTag => 'fr';

  @override
  String get appTitle => 'SimpleText';

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
  String get seedTitle => 'Bienvenue dans SimpleText';
  @override
  String get seedTag => 'Mode d\'emploi';
  @override
  String get seedBody => [
        'Comment utiliser SimpleText',
        '',
        '1. Copiez une réponse de ChatGPT ou Claude, puis touchez « Coller et nettoyer ».',
        '2. Comparez l\'original et le résultat dans l\'aperçu, touchez « Appliquer » — terminé.',
        '3. Pour les notes avec tableaux, le bouton « Tableau » les copie pour les tableurs (TSV).',
        '4. Chaque nettoyage peut être annulé d\'un seul geste.',
        '',
        'Ci-dessous, un tableau volontairement cassé. Touchez « Nettoyer » pour voir la réparation.',
        '',
        '| Action | Ticker | Rendement | Poids',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5%',
        '| Nvidia | NVDA | +48.9% | 22% | cellule en trop |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get autoTidy => 'Nettoyage auto';

  @override
  String get bodyFontSizeTitle => 'Taille du texte';

  @override
  String get bodyFontSizeSample =>
      'Découvrez un espace de travail Smart qui met de l’ordre dans vos nombreuses idées avec une vraie Simplicity. Collez, appuyez sur Nettoyer, tout devient Clean.';

  @override
  String get wizardNothingToDo => 'Rien à modifier';

  @override
  String wizardAppliedToast(int count) => '\$count instruction(s) appliquée(s)';

  @override
  String get skipPreviewCheck => 'Ignorer l’aperçu à l’avenir';

  @override
  String get previewTitle2 => 'Aperçu avant application';

  @override
  String get previewSub2 => 'Affiche le résultat puis demande avant d’appliquer';
  @override
  String get metaTooltip => 'Source et tags';
  @override
  String get pinTooltip => 'Épingler en haut';
  @override
  String get unpinTooltip => 'Désépingler';
  @override
  String get deleteTooltip => 'Supprimer';
  @override
  String get titleHint => 'Titre (automatique)';
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
  String get revertedToast => 'Version précédente restaurée';
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
  String get hideKeyboardTip => 'Masquer le clavier';

  @override
  String get tidyAction => 'Nettoyer';
  @override
  String get wizardAction => 'Assistant';
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
  String get wizardTitle => 'Assistant';
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
  String unknownPrefix(String what) => 'Non reconnu comme règle · $what';
  @override
  String get aiKeyPromo =>
      'Ajoutez une clé d\'API d\'IA dans les réglages pour traiter aussi ces éditions libres.';
  @override
  String get aiRunUnknown => 'Exécuter les commandes non reconnues avec l\'IA';
  @override
  String get aiBusyLabel => 'L\'IA édite…';
  @override
  String get aiEmptyResponse => 'Réponse vide';
  @override
  String aiCallFailed(String error) => 'Échec de l\'appel IA : $error';
  @override
  String get aiApplyResult => 'Appliquer le résultat de l\'IA';
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
  String get apply => 'Appliquer';

  @override
  String get presetAiName => 'Nettoyer une réponse d\'IA';
  @override
  String get presetAiDesc => 'Retire les marques markdown, emojis, préambules d\'IA ; répare les tableaux';
  @override
  String get presetStripName => 'Retirer tout le Markdown';
  @override
  String get presetStripDesc => 'Retire au maximum la syntaxe markdown ; les tableaux passent en TSV';
  @override
  String get presetMinimalName => 'Nettoyage minimal';
  @override
  String get presetMinimalDesc => 'Préserve la structure ; ne retire que le bruit (espaces, caractères de largeur nulle)';
  @override
  String get presetTablesName => 'Tableaux seulement';
  @override
  String get presetTablesDesc => 'Extrait les tableaux du document en TSV';
  @override
  String get presetBlogName => 'Coller sur un blog';
  @override
  String get presetBlogDesc => 'Retire les marques, garde les URL des liens, répare les tableaux';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get menuAppSettings => "Réglages de l'app";

  @override
  String get menuAiKey => 'Clé API IA';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'Activé — les mêmes notes sur iPhone, iPad et Mac';

  @override
  String get syncStateOff => 'Désactivé — activez iCloud Drive dans les réglages de l ap';

  @override
  String get syncStateSyncing => 'Synchronisation…';

  @override
  String get aiKeyNotSynced => 'Vos notes sont synchronisées sur tous vos appareils via iCloud. Pas votre clé API — saisissez-la sur chaque appareil.';
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
  String get aiSectionTitle => 'Connexion de l\'Assistant IA (édition libre)';
  @override
  String get aiSectionDesc =>
      'Avec une clé d\'API, l\'Assistant traite des commandes libres comme « rends ça plus concis ». La clé n\'est stockée que sur cet appareil.';
  @override
  String get aiKeyHint => 'Clé API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get adClose => 'Fermer les pubs';
  @override
  String get sponsorTitle => 'Une publicité finance la prochaine mise à jour';
  @override
  String get sponsorBody => "Votre soutien fait vivre les mises à jour. Regardez une publicité plein écran par jour pour utiliser l'app sans bannière ce jour-là — ou passez à Premium et les publicités disparaissent pour de bon.";
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
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Sans publicité, sur tous vos appareils';
  @override
  String get premiumPitchSub => 'US\$29.99 une fois ou US\$1.99/mois · iPhone, iPad et Mac ensemble';
  @override
  String get premiumBody => 'Premium supprime toutes les publicités et débloque Skyblue Note sur iPhone, iPad et Mac. Un seul achat couvre les trois. Votre soutien construit la prochaine mise à jour.';
  @override
  String get premiumLifetime => 'À vie · US\$29.99';
  @override
  String get premiumMonthly => 'Mensuel · US\$2.99/mois';
  @override
  String get premiumComingSoon => "Les achats seront activés dans la version App Store. C'est pour bientôt.";
  @override
  String get limitTitle => "Vous avez épuisé les usages gratuits du jour";
  @override
  String limitTidyBody(int n) => "L'offre gratuite comprend \$n nettoyages par jour. Réinitialisation demain ; Premium supprime la limite.";
  @override
  String limitWizardBody(int n) => "L'offre gratuite comprend \$n utilisations de l'assistant par jour. Réinitialisation demain ; Premium supprime la limite.";
  @override
  String get limitSeePremium => 'Voir Premium';
  @override
  String get premiumYearly => 'Annuel · US\$14.99/an';
  @override
  String get premiumLifetimeNote => 'Prix de lancement · normalement US\$39.99';

  @override
  String trialBadge(int days) => 'Essai illimité · $days jours restants';

  @override
  String get trialEndedTitle => "Votre essai illimité est terminé";

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      "Pendant l'essai, vous avez lancé $tidy nettoyages et $wiz sessions de l'assistant. Désormais, la version gratuite offre $tidyLimit nettoyages et $wizLimit utilisations de l'assistant par jour. Premium supprime la limite.";
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
  String get aiKeyUnknownFormat => 'Format de clé non reconnu. Définissez le modèle dans Avancé.';
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
