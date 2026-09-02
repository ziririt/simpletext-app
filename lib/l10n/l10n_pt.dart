import 'l10n.dart';

/// Português (기준: 브라질 pt-BR — pt-PT 분리가 필요해지면 파일을 나눈다)
class L10nPt extends L10n {
  const L10nPt();

  @override
  String get localeTag => 'pt';

  @override
  String get appTitle => 'Skyblue Note';

  @override
  String get versionLabel => 'Versão';

  @override
  String get homeTitle => 'Notas';
  @override
  String get settingsTooltip => 'Regras de organização';
  @override
  String get searchHint => 'Buscar';
  @override
  String get emptyList => 'Nenhuma nota.\nComece com "Colar e organizar".';
  @override
  String get pinnedLabel => 'Fixadas';
  @override
  String get notesLabel => 'Notas';
  @override
  String get newNoteTooltip => 'Nova nota';
  @override
  String get pasteAndTidy => 'Nova nota a partir da área de transferência';
  @override
  String get clipboardEmpty => 'A área de transferência está vazia. Copie uma resposta de IA primeiro.';
  @override
  String get yesterday => 'Ontem';
  @override
  String get untitled => 'Sem título';
  @override
  String get deleteConfirmTitle => 'Excluir esta nota?';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Excluir';

  @override
  String dateShort(int y, int m, int d) => '$d/$m/$y';

  @override
  String get seedTitle => 'Bem-vindo ao Skyblue Note';
  @override
  String get seedTag => 'Como usar';
  @override
  String get shareAppTitle => 'Compartilhar o app';
  @override
  String get rateAppTitle => 'Avalie-nos';
  @override
  String get shareAppMsg =>
      'Skyblue Note — um app de notas leve e rápido que sincroniza em todos os seus dispositivos.';
  @override
  String get seedBody => [
        'Olá! 😊 Segue o resumo que você pediu[1][2].',
        '',
        '# Skyblue Note',
        '',
        'A tabela está desalinhada. Toque na **varinha** no canto inferior esquerdo. 🎉',
        '',
        '| Empresa | Código | Retorno | Peso',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '|Nvidia|NVDA|+48.9%|22%|',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '|Tesla|TSLA|-8.3%|8%|',
        '',
        '> Ao organizar, as colunas se alinham. O menu «Tabela» cola direto numa planilha.',
        '',
        '## O que sai',
        '',
        '- [ ] Saudações de enfeite e emojis 🙂',
        '- [ ] Notas de rodapé coladas na frase[3][4]',
        '- [ ] Um asterisco solto no fim da linha**',
        '- [x] A tabela quebrada é remontada',
        '',
        '## O que fica',
        '',
        'Títulos, **negrito** e citações ficam. Na tela aparecem como formatação; ao colar no Notas ou num fórum, as marcas somem.',
        '',
        '---',
        '',
        '\t•\tMarcadores embrulhados em tabulações — é assim que Grok e ChatGPT colam',
        '\t•\tEspaços   e tabulações repetidos',
        '\t•\tEstas linhas soltas também acham o lugar',
        '',
        '> Não gostou? [Restaurar original](https://ezlong.com/skybluenote) traz de volta.',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get bodyFontSizeTitle => 'Tamanho do texto';

  @override
  String get bodyLineHeightTitle => 'Espaçamento entre linhas';

  @override
  String get bodyFontSizeSample =>
      'Conheça um espaço de trabalho Smart que organiza as muitas ideias da sua cabeça com pura Simplicity. Cole o texto, toque em Limpar e tudo fica Clean.';

  @override
  String get wizardNothingToDo => 'Nada para alterar';

  @override
  String wizardAppliedToast(int count) => '$count instrução(ões) aplicada(s)';

  @override
  String get skipPreviewCheck => 'Ignorar a pré-visualização a partir de agora';

  @override
  String get previewTitle2 => 'Pré-visualizar antes de aplicar';

  @override
  String get previewSub2 => 'Mostra o resultado e pergunta antes de aplicar';
  @override
  String get metaTooltip => 'Título e tags';
  @override
  String get pinTooltip => 'Fixar no topo';
  @override
  String get unpinTooltip => 'Desafixar';

  @override
  String get unpinConfirmTitle => 'Desafixar esta nota?';

  @override
  String get unpinConfirmBody =>
      'Toque e segure uma nota na lista para fixá-la novamente.';
  @override
  String get deleteTooltip => 'Excluir';
  @override
  String get titleHint => 'Título (automático)';
  @override
  String get titleTapHint => 'Adicionar título';
  @override
  String get sourceNone => 'Sem fonte';
  @override
  String get sourceOther => 'Outro';
  @override
  String get tagsHint => 'Tags (separadas por vírgula)';
  @override
  String get tagAiButton => 'Etiquetas com IA';
  @override
  String get tagAiWorking => 'A procurar etiquetas…';
  @override
  String get tagAiNone => 'Nenhuma palavra-chave encontrada';
  @override
  String get tagAiLocalNote => 'Sem chave de IA: escolhidas no dispositivo';
  @override
  String get tagsBoxHint => 'Escreva uma etiqueta e uma vírgula';
  @override
  String get tagRemoveTip => 'Remover etiqueta';
  @override
  String get bodyHint => 'Cole ou digite aqui';
  @override
  String get noteNotFound => 'Nota não encontrada';
  @override
  String get revertedToast => 'De volta ao original. O texto anterior está no histórico.';

  // 원본복귀 (2026-08-17)
  @override
  String get revertAction => 'Voltar ao original';

  @override
  String get revertConfirmTitle => 'Voltar ao original?';

  @override
  String get revertConfirmBody =>
      'A nota volta ao texto que você colou no início. Toda a organização e as edições feitas depois serão perdidas.\n\nVocê ainda pode voltar às edições anteriores — o menu → Histórico de versões guarda o texto atual como primeiro item.';

  @override
  String get revertConfirmOk => 'Voltar';

  @override
  String get okAction =>
      'OK';

  @override
  String get revertDoneTitle =>
      'Voltou ao original';

  @override
  String get revertDoneBody =>
      'O texto em que você estava trabalhando não se perdeu.\n\nAbra o menu → Histórico de versões: o primeiro item é o texto de antes da reversão. Toque nele para trazê-lo de volta quando quiser.';

  // 자판 위 막대의 목록 셋 (2026-08-17)
  @override
  String get listBulletAction => 'Lista com marcadores';

  @override
  String get listDashAction => 'Lista com travessões';

  @override
  String get listNumberAction => 'Lista numerada';

  // 출처 칸 (2026-08-17)
  @override
  String get sourceFieldLabel => 'Fonte';

  @override
  String sourceSaved(String name) => 'Fonte salva: $name';

  @override
  String sourceDetected(String name) => 'Fonte detectada: $name';

  @override
  String get sourceCleared => 'Fonte apagada';

  // 폴더 (2026-08-17)
  @override
  String get folderTitle => 'Pasta';

  @override
  String get folderNone => 'Sem pasta';

  @override
  String get folderNew => 'Nova pasta';

  @override
  String get folderNameHint => 'Nome da pasta';

  @override
  String get folderCleared => 'Removido da pasta';

  // 폴더 관리 (2026-08-18)
  @override
  String get folderManage => 'Gerir pastas';

  @override
  String get folderRename => 'Renomear';

  @override
  String get folderDelete => 'Excluir pasta';

  @override
  String get folderReorderHint => 'Arraste para reordenar';

  @override
  String get folderManageEmpty => 'Ainda não há pastas';

  @override
  String get folderDupName => 'Já existe uma pasta com esse nome';

  @override
  String get folderDeleted => 'Pasta excluída';

  @override
  String get folderRenamed => 'Renomeado';

  @override
  String folderDeleteBody(String name, int count) =>
      'As $count notas em «$name» continuarão em Todas. As notas não são excluídas.';

  @override
  String folderNoteCount(int count) => '$count notas';

  // '키 확인'이 진짜로 한 번 불러 볼 때 (2026-08-17)
  @override
  String get aiPinging => 'Verificando se dá mesmo para usar…';

  @override
  String get aiPingOk => 'A edição funciona. Pode começar.';

  @override
  String aiPingFailed(String err) => 'A lista chegou, mas a chamada de edição foi recusada — $err';

  @override
  String get aiAdvancedNote => 'Normalmente não precisa mexer aqui. A chave já basta.';

  // 종이 다섯 벌 추가 (2026-08-17)
  @override
  String get paperPlain => 'Papel';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWalnut => 'Nogueira';

  @override
  String get paperNight => 'Noite';

  @override
  String get paperSky => 'Céu';

  @override
  String get themeSystemNote =>
      'Seguindo o aparelho, o app escurece quando o aparelho escurece.';

  @override
  String folderMoved(String name) => 'Movido para $name';
  @override
  String appliedDone(String summary) => 'Aplicado — $summary';

  @override
  String get undoTip => 'Desfazer';
  @override
  String get redoTip => 'Refazer';
  @override
  String get moveLeftTip => 'Mover para a esquerda';
  @override
  String get moveRightTip => 'Mover para a direita';
  @override
  String get lineStartTip => 'Início da linha';
  @override
  String get lineEndTip => 'Fim da linha';
  @override
  String get indentTip => 'Recuo';

  @override
  String get todoAction => 'Tarefa';
  @override
  String get hideKeyboardTip => 'Ocultar teclado';

  @override
  String get tidyAction => 'Organizar';
  @override
  String get wizardAction => 'IA';
  @override
  String get tableAction => 'Tabela';
  @override
  String get replaceAction => 'Substituir';
  @override
  String get copyAction => 'Copiar';
  @override
  String get undoAction => 'Desfazer';

  @override
  String get noTablesFound => 'Nenhuma tabela encontrada nesta nota';
  @override
  String tableInfo(int n, int cols, int rows) => 'Tabela $n — $cols col × $rows linhas';
  @override
  String get forSpreadsheet => 'Para planilhas';
  @override
  String get copiedSpreadsheet => 'Copiado — cole em uma célula do Google Sheets ou Excel';
  @override
  String get copiedCsv => 'Copiado como CSV';
  @override
  String get copiedMarkdown => 'Copiado como tabela Markdown';

  @override
  String get wizardTitle => 'Edição com IA';
  @override
  String get wizardHint =>
      'Dê instruções no seu idioma. Ex.:\nDeixe 2 linhas antes dos subtítulos e 1 depois\nSubstitua MS por Microsoft';
  @override
  String get favSaveButton => 'Guardar como favorito';
  @override
  String get favListTitle => 'Instruções favoritas';
  @override
  String get favUse => 'Usar';
  @override
  String get favEmpty => 'Ainda não há instruções guardadas';
  @override
  String get favRemove => 'Remover';
  @override
  String get favSavedToast => 'Guardado';
  @override
  String appliedPrefix(String what) => 'Aplicado · $what';
  @override
  String unknownPrefix(String what) => 'A IA cuida disto · $what';
  @override
  String get aiKeyPromo => 'Adicione uma chave de API de IA nos Ajustes para processar também edições livres assim.';
  @override
  String get aiBusyLabel => 'IA editando…';
  @override
  String get aiKeyInviteTitle => 'Com a sua própria chave de IA fica bem mais forte';
  @override
  String get aiKeyInviteBody => 'Agora só entendemos regras fixas. Com a sua própria chave de IA, instruções livres como "deixe mais conciso" ou "reescreva de forma formal" também funcionam, e as tags são extraídas pela IA.';
  @override
  String get aiKeyCta => 'Adicionar chave de IA';
  @override
  String get aiKeyPasteBtn => 'Colar';
  @override
  String get aiKeyCost => 'O app chama diretamente o serviço de IA que você já usa. Coloque a chave do que você tiver: Gemini, ChatGPT, Claude ou Grok.';
  @override
  String get aiKeySafe => 'A chave fica só neste aparelho. Nunca é enviada para os servidores deste app.';
  @override
  String get aiKeyWhere => 'Onde obter uma chave';
  @override
  String get aiKeyStart => 'Começar';
  @override
  String get recentPromptsTitle => 'Usados recentemente';
  @override
  String get recentEmpty => 'Nada ainda. O que você executar aparece aqui';
  @override
  String get favAdd => 'Salvar como favorito';
  @override
  String get tableFixTitle => 'Organizar tabelas';
  @override
  String get tableFixSub => 'Reconstrói tabelas quebradas e alinha as colunas';
  @override
  String get wideTableTitle => 'Tabelas largas';
  @override
  String get wideTableAuto => 'Automático';
  @override
  String get wideTableAligned => 'Alinhar colunas';
  @override
  String get wideTableRecords => 'Escrever como texto';
  @override
  String get headingBigTitle => 'Subtítulos como Título 2';
  @override
  String get headingBigSub => 'Deixa os subtítulos detectados grandes e em negrito (Título 2)';
  @override
  String get aiWorking => 'A IA está editando conforme suas instruções. Pode demorar um pouco…';
  @override
  String get aiEmptyResponse => 'Resposta vazia';
  @override
  String aiCallFailed(String error) => 'Falha na chamada de IA: $error';
  @override
  String get aiAppliedToast => 'Edição de IA aplicada — recuperável com Desfazer';
  @override
  String get close => 'Fechar';
  @override
  String get interpretApply => 'Interpretar e aplicar';

  @override
  String get replaceTitle => 'Substituir';
  @override
  String get findLabel => 'Localizar';
  @override
  String get replaceWithLabel => 'Substituir por (\\n = quebra de linha)';
  @override
  String get regexLabel => 'Expressão regular';
  @override
  String get saveAsRule => 'Salvar como regra de substituição automática';
  @override
  String get saveAsRuleSub => 'Sempre aplicada em cada "Organizar" futuro';
  @override
  String get ruleScopeAll => 'Aplicar a todas as notas';
  @override
  String get ruleScopeNote => 'Aplicar somente a esta nota';
  @override
  String get noteRules => 'Regras desta nota';
  @override
  String get invalidRegex => 'Expressão regular inválida';
  @override
  String get noMatches => 'Nenhuma correspondência encontrada';
  @override
  String replacedCount(int count) => 'Substituído em $count lugares';
  @override
  String get savedRuleSuffix => ' · salvo como regra de substituição automática';
  @override
  String get replaceAllAction => 'Substituir tudo';

  @override
  String get copyAll => 'Copiar tudo';

  @override
  String get copyPlainSub =>
      'Texto puro — sem marcas de markdown';

  @override
  String get copyRaw => 'Copiar como markdown';

  @override
  String get copyRawSub =>
      'Para Notion, Slack, GitHub e outros apps que leem markdown';
  @override
  String get copiedAll => 'Texto completo copiado';
  @override
  String get tidyCopy => 'Organizar e copiar';
  @override
  String get tidyCopySub => 'A nota fica como está; só o resultado organizado é copiado';
  @override
  String tidyCopied(String summary) => 'Organizado e copiado — $summary';
  @override
  String get copyTableSpreadsheet => 'Copiar tabelas para planilhas';
  @override
  String get copiedTableSpreadsheet => 'Tabelas copiadas para planilhas';

  @override
  String previewTitle(String preset) => '$preset — Prévia';
  @override
  String warningPrefix(String warning) => 'Atenção: $warning';
  @override
  String get tidyResultLabel => 'Resultado';
  @override
  String get originalLabel => 'Original';
  @override
  String get apply => 'Aplicar a organização';

  @override
  String get presetAiName =>
      'Organização padrão';
  @override
  String get presetAiDesc =>
      'Deixa legível uma resposta de IA colada. Quase sempre basta';
  @override
  String get presetStripName =>
      'Remover todos os símbolos';
  @override
  String get presetStripDesc =>
      'Para chat e SMS. Some tudo — marcas e emojis; a tabela fica alinhada';
  @override
  String get presetMinimalName =>
      'Só a sujeira';
  @override
  String get presetMinimalDesc =>
      'Mantém a estrutura, tira só o invisível';
  @override
  String get presetTablesName =>
      'Só tabelas';
  @override
  String get presetTablesDesc =>
      'Para colar direto no Excel ou Google Planilhas';
  @override
  String get presetBlogName =>
      'Para blogs';
  @override
  String get presetBlogDesc =>
      'Mantém os endereços dos links, tira os símbolos';

  @override
  String get tidySample => [
        '## Resumo de hoje 😊',
        '',
        'Os **pontos** principais são três[1][2].',
        '',
        '- Primeiro item',
        '- Segundo item',
        '',
        '> Uma linha citada',
        '',
        'Mais no [blog](https://ezlong.com)',
        '',
        '| Item | Valor |',
        '|---|---|',
        '|Vendas|120|',
      ].join('\n');

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get menuAppSettings => 'Ajustes do app';

  @override
  String get menuAiKey => 'Chave de API de IA';

  @override
  String get syncTitle => 'Sincronização';
  @override
  String get syncAppleOnly => 'Só Apple';

  @override
  String get syncScopeTitle =>
      'Escopo da sincronização';

  @override
  String get syncScopeShared =>
      'Sincronizado entre seus aparelhos: notas, regras de organização, regras de substituição adicionadas, pastas, instruções de IA salvas';

  @override
  String get syncStateOffGdrive => 'Entre novamente na sua conta do Google';
  @override
  String get syncStateExpiredGdrive => 'Sua conta continua conectada, mas a permissão para usar o Drive expirou. Toque uma vez para renovar.';

  @override
  String get syncScopePlatformGdrive =>
      'O armazém do Google Drive é compartilhado por todos os aparelhos com este app. Instale-o e entre com a mesma conta do Google';

  @override
  String get syncScopeDevice =>
      'Por dispositivo: tamanho do texto, espaçamento, papel, aparência, ordenação';

  @override
  String get syncScopePlatform =>
      'Por enquanto, a sincronização automática funciona apenas entre dispositivos Apple (iPhone, iPad, Mac). Nos demais, use Exportar backup e Importar no menu';

  @override
  String get typographyTitle => 'Texto e espaçamento';

  @override
  String get syncScopeNever =>
      'A chave de API de IA não é enviada a nenhuma nuvem, portanto digite-a em cada dispositivo';
  @override
  String get syncWhereTitle =>
      'Onde guardar';
  @override
  String get syncBackendNone =>
      'Não sincronizar';
  @override
  String get syncBackendNoneSub =>
      'Só neste aparelho';
  @override
  String get syncBackendIcloud =>
      'iCloud';
  @override
  String get syncBackendIcloudSub =>
      'Entre iPhone, iPad e Mac';
  @override
  String get syncBackendGdrive =>
      'Google Drive';
  @override
  String get syncBackendGdriveSub =>
      'Outros aparelhos e a web também';
  @override
  String get syncSoon =>
      'Em breve';

  @override
  String get driveSignInFailed => 'Não foi possível conectar sua conta do Google';

  @override
  String get driveNeedsSignIn => 'Conecte uma conta do Google primeiro';

  @override
  String get driveSignedInAs => 'Conectada';
  @override
  String get syncSectionState =>
      'Estado atual';
  @override
  String get syncNowAction =>
      'Sincronizar agora';
  @override
  String get syncNowBusy => 'Sincronizando…';

  @override
  String get syncLastNever =>
      'Ainda não sincronizou';
  @override
  String get headingTip => 'Título';
  @override
  String get quoteTip => 'Citação';
  @override
  String get boldTip => 'Negrito';
  @override
  String get codeTip => 'Código';
  @override
  String get linkTip => 'Ligação';
  @override
  String get outdentTip => 'Diminuir avanço';
  @override
  String get cursorLeftTip => 'Esquerda';
  @override
  String get cursorRightTip => 'Direita';
  @override
  String get clearFormatTip => 'Limpar formatação';

  @override
  String get blockFormatTip => 'Formato de parágrafo';

  @override
  String get syncStalledTitle => 'A sincronização está parada';

  @override
  String get wipeAction => 'Antes e depois';

  @override
  String get travelAction => 'Viagem no tempo';

  @override
  String get skyAction => 'Constelação';

  @override
  String get timePasted => 'Colado';

  @override
  String get exportShort => 'Exportar';
  @override
  String get exportPdfShort => 'PDF';
  @override
  String get printShort => 'Imprimir';
  @override
  String timeEdited(String when) => 'editado $when';
  @override
  String get skyTitle => 'Constelação';
  @override
  String skyCounts(int stars, int links) => '$stars estrelas · $links fios';
  @override
  String skyEmpty(int more) => 'Com mais $more notas sua constelação aparece aqui. Notas parecidas são ligadas por fios.';
  @override
  String get travelTitle => 'Viagem no tempo';
  @override
  String get travelNow => 'Agora';
  @override
  String get travelOlder => 'Anterior';
  @override
  String get travelRestore => 'Restaurar';
  @override
  String travelShrank(int n) => '$n caracteres a menos';
  @override
  String travelGrew(int n) => '$n caracteres a mais';
  @override
  String get wipeTitle => 'Antes · Depois';
  @override
  String get wipeBefore => 'Antes';
  @override
  String get wipeAfter => 'Depois';
  @override
  String wipeCounts(int before, int after) => '$before → $after caracteres';
  @override
  String get syncStalledSub => 'O acesso do Google expirou. Suas notas estão seguras neste aparelho.';
  @override
  String get syncStalledFix => 'Reconectar';
  @override
  String get blockBody => 'Corpo';
  @override
  String get blockH1 => 'Título 1';
  @override
  String get blockH2 => 'Título 2';
  @override
  String get blockH3 => 'Título 3';
  @override
  String get blockQuote => 'Citação';
  @override
  String get blockCode => 'Código';
  @override
  String get bodyFontTitle => 'Fonte do corpo';
  @override
  String get bodyFontSystem => 'Sistema';
  @override
  String get bodyFontNoto => 'Noto';
  @override
  String get bodyFontMono => 'Monoespaçada';
  @override
  String get moreTools => 'Mais';
  @override
  String get findTitle => 'Localizar';
  @override
  String get findAction => 'Localizar';
  @override
  String get showReplaceLabel => 'Substituir';
  @override
  String get replaceOneAction => 'Substituir';
  @override
  String get findNone => 'Sem correspondências';
  @override
  String get syncFirstTitle => 'A sincronizar…';
  @override
  String get syncFirstSub => 'A obter as notas dos seus outros dispositivos. Pode demorar um pouco se tiver muitas.';
  @override
  String get syncLogTitle => 'Histórico de sincronização';
  @override
  String get syncLogNote => 'Apenas o que foi movido e quando. O conteúdo das notas não fica guardado aqui.';
  @override
  String get syncLogEmpty => 'Ainda não houve movimento';
  @override
  String get syncLogNever => 'Ainda não';
  @override
  String get syncLogUp => 'Enviado';
  @override
  String get syncLogDown => 'Recebido';
  @override
  String get syncLogFailed => 'Falha';
  @override
  String syncUpdatedAt(String when) => 'Atualizado ' + when;
  @override
  String findHits(int n) => n.toString() + ' encontrados';
  @override
  String syncLogLastUp(String when) => 'Último envio · ' + when;
  @override
  String syncLogLastDown(String when) => 'Última receção · ' + when;
  @override
  String get syncTroubleTitle =>
      'Se algo der errado';
  @override
  String get syncTroubleNote =>
      'Sincronizar não é backup. Apagou num aparelho, some em todos. Exporte um arquivo de vez em quando com o que importa.';
  @override
  String syncLastAt(String when) => 'Última sincronização: $when';

  @override
  String syncStateOn(String where) => 'Guardado no $where: as mesmas notas em todos os aparelhos com este app';

  @override
  String get syncStateOff => 'Ative o iCloud Drive nos ajustes do dispositivo';

  @override
  String syncStateSyncing(String where) => 'Sincronizando com o $where… leva de alguns segundos a um minuto';

  @override
  String get aiKeyNotSynced => 'Suas notas sincronizam entre todos os seus aparelhos pelo armazém escolhido. Sua chave de API não: informe-a em cada aparelho.';
  @override
  String get aiKeySyncTitle => 'Sincronizar também a chave de API';
  @override
  String get aiKeySyncSubApple => 'Viaja pelo Chaveiro do iCloud, um caminho diferente do das suas notas. Só os seus aparelhos têm a chave, então nem a Apple consegue lê-la.';
  @override
  String get aiKeySyncSubGdrive => 'Uma vez no Google Drive, a segurança da chave de API é responsabilidade de cada um.';

  @override
  String get autoTagTitle => 'Marcar automaticamente';

  @override
  String get autoTagSub =>
      'Ao pausar depois de editar, a IA extrai as etiquetas de novo. Notas cujas etiquetas você editou ficam intactas';

  @override
  String get syncStateSignedOut => 'Toque para ver como';

  @override
  String get syncHelpTitle => 'Como ativar o iCloud';

  @override
  String get syncHelpSteps =>
      '1. Ajustes › seu nome no topo › iCloud\n2. Verifique se o iCloud Drive está ligado — se estiver desligado, nenhum app sincroniza\n3. Bloqueie e desbloqueie o iPhone, volte aqui e toque em Verificar novamente\n\nVerifique no app Arquivos, não nos Ajustes. Se vir uma pasta Skyblue Note em Arquivos › iCloud Drive, está pronto.';

  @override
  String get syncOpenSettings => 'Abrir Ajustes';

  @override
  String get syncRecheck => 'Verificar novamente';

  @override
  String get syncHelpNote =>
      'Se você acabou de instalar o app, pode levar um ou dois minutos até ficar pronto. Toque em Verificar novamente.';

  @override
  String get sortFilterTooltip => 'Ordenar e filtrar';

  @override
  String get sortFilterTitle => 'Ordenar e filtrar';

  @override
  String get sortLabel => 'Ordem';

  @override
  String get sortUpdated => 'Editado recentemente';

  @override
  String get sortCreated => 'Data de criação';

  @override
  String get sortByTitle => 'Título';

  @override
  String get filterSourceLabel => 'Origem';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterAll => 'Tudo';

  @override
  String get filterReset => 'Redefinir';

  @override
  String get selectWord => 'Selecionar';

  @override
  String get tagAiNeedKey => 'Insira uma chave de API nas Configurações para usar a marcação automática por IA.';

  @override
  String get toggleListTooltip => 'Ocultar ou mostrar a lista';

  @override
  String get aiDetecting => 'Verificando a qual provedor esta chave pertence…';

  @override
  String get aiErrNoCredits => 'A chave está correta, mas a conta não tem saldo. Adicione um meio de pagamento ou créditos no site do provedor. Para não pagar, experimente uma chave do Google Gemini (começa com AIza…) — ela tem camada gratuita.';

  @override
  String get aiErrBadKey => 'A chave foi recusada. Verifique espaços ou aspas sobrando e, se continuar, gere uma nova chave.';

  @override
  String get aiErrRateLimit => 'O provedor está sobrecarregado agora. Não é falha do app: tente de novo em instantes.';

  @override
  String get aiErrNoModel => 'Esse modelo não está disponível nesta conta. Escolha outro em \'Avançado — escolher modelo\'.';

  @override
  String get aiErrNetwork => 'Não foi possível acessar a internet. Verifique a conexão e tente de novo.';

  @override
  String get multiSelectStart => 'Excluir várias notas';

  @override
  String get selectAllTooltip => 'Selecionar tudo / nada';

  @override
  String get deleteSelected => 'Excluir selecionadas';

  @override
  String get deleteSelectedDone => 'Concluído';

  @override
  String get deleteSelectedConfirm => 'Excluir as notas selecionadas?';

  @override
  String deleteSelectedBody(int n) => n == 1
          ? '1 nota irá para a lixeira. Você pode restaurá-la em 30 dias.'
          : '$n notas irão para a lixeira. Você pode restaurá-las em 30 dias.';

  @override
  String get trashTitle => 'Lixeira';

  @override
  String get trashSubtitle => 'Notas excluídas ficam guardadas por 30 dias';

  @override
  String get trashEmpty => 'A lixeira está vazia';

  @override
  String get trashRestore => 'Recuperar';

  @override
  String get trashDeleteNow => 'Excluir agora';

  @override
  String get trashEmptyAll => 'Esvaziar';

  @override
  String get trashEmptyConfirm => 'Esvaziar a lixeira não pode ser desfeito. Continuar?';

  @override
  String get trashRestored => 'Recuperada';

  @override
  String trashDaysLeftLabel(int days) => 'Será excluída definitivamente em $days dias';

  @override
  String get exportSectionTitle =>
      'Importar e exportar';

  @override
  String get exportSubtitle =>
      'Suas notas podem sair quando quiser. Markdown abre no Notas da Apple, Obsidian, Notion e outros.';

  @override
  String get exportNote =>
      'Exportar esta nota';

  @override
  String get exportAllMd =>
      'Exportar todas as notas';

  @override
  String get exportAllMdSub =>
      'Todas as notas em Markdown, em um zip';

  @override
  String get exportBackup =>
      'Salvar backup';

  @override
  String get exportBackupSub =>
      'Um arquivo que restaura tudo aqui (sem sua chave de API)';

  @override
  String get exportFailed =>
      'Falha ao exportar';

  @override
  String get printAction =>
      'Imprimir';

  @override
  String get exportPdf =>
      'Exportar como PDF';

  @override
  String get pdfFailed =>
      'Não foi possível criar o PDF';

  @override
  String get exportEmpty =>
      'Não há notas para exportar';

  @override
  String get choosePreset => 'Escolher como organizar';

  @override
  String get importFiles =>
      'Importar de arquivos';

  @override
  String get importFilesSub =>
      'Arquivos Markdown e de texto viram notas. Backups também são restaurados aqui';

  @override
  String get importAppend =>
      'Carregar um arquivo e anexar ao texto';

  @override
  String get importNone =>
      'Nada foi importado';

  @override
  String importDone(int n) => '$n notas importadas';

  @override
  String get sourceGuessSuffix => '(estimado)';

  @override
  String get splitEmpty => 'Escolha uma nota à esquerda';

  @override
  String get historyTitle =>
      'Histórico de versões';

  @override
  String get historySub =>
      'Volte ao texto anterior a uma organização ou substituição';

  @override
  String get historyEmpty =>
      'Ainda não há nada para restaurar';

  @override
  String get historyRestore =>
      'Restaurar';

  @override
  String get historyOriginal =>
      'Como foi colado';

  @override
  String get historyWhyTidy => 'Antes de organizar';

  @override
  String get historyWhyAi => 'Antes da edição por IA';

  @override
  String get historyWhyReplace => 'Antes de substituir';

  @override
  String get historyWhyRevert => 'Antes de voltar ao original';

  @override
  String get historyWhyRestore => 'Antes de restaurar';

  @override
  String get widgetEmpty => 'Ainda não há notas';

  @override
  String get widgetAllLocked => 'Notas bloqueadas não aparecem no widget';

  @override
  String get attachTitle => 'Anexos';

  @override
  String get attachAdd => 'Anexar arquivo';

  @override
  String get attachRemove => 'Remover anexo';

  @override
  String get attachRemoveBody => 'O arquivo será apagado deste dispositivo. Não é possível desfazer.';

  @override
  String get attachFailed => 'Não foi possível anexar o arquivo';

  @override
  String get attachNotHere => 'Este arquivo está em outro dispositivo';

  @override
  String attachAndMore(int n) => 'e mais ${n}';

  @override
  String attachOther(String device, String what) => 'Anexo: ${what} está anexado no seu ${device} (visível apenas nesse dispositivo)';

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
        return 'celular Android';
      case 'windows':
        return 'PC com Windows';
      case 'web':
        return 'web';
      default:
        return 'outro dispositivo';
    }
  }

  @override
  String historyUnknownTime(int n) => 'Versão anterior $n';

  @override
  String get selUnitSentence => 'Frase';

  @override
  String get selUnitLine => 'Linha';

  @override
  String get selUnitPara => 'Parágrafo';

  @override
  String get selUnitAll => 'Tudo';

  @override
  String get selStartLeft => 'Início esq.';

  @override
  String get selStartRight => 'Início dir.';

  @override
  String get selEndLeft => 'Fim esq.';

  @override
  String get selEndRight => 'Fim dir.';

  @override
  String get selClear => 'Limpar seleção';

  @override
  String get paperTitle => 'Fundo do editor';

  @override
  String get paperSub => 'Fundo e pauta em conjunto. O entrelinhas acompanha o tamanho da letra.';

  @override
  String get paperNone => 'Liso';

  @override
  String get paperMoleskine => 'Moleskine';

  @override
  String get paperSepia => 'Sépia';

  @override
  String get paperManuscript => 'Manuscrito';

  @override
  String get paperFrost => 'Geada';

  @override
  String get lockSectionTitle => 'Bloqueio';

  @override
  String get lockTitle => 'Bloqueio do app';

  @override
  String lockSub(String vendor) => vendor == 'android'
      ? 'Abra o app com sua digital, seu rosto ou o bloqueio de tela.'
      : vendor == 'windows'
          ? 'Abra o app com Windows Hello ou o PIN do dispositivo.'
          : 'Abra o app com Face ID, Touch ID ou a senha do dispositivo.';

  @override
  String get lockNote => 'Este bloqueio impede que alguém que pegue o seu dispositivo abra o app. Ele não criptografa os arquivos guardados no dispositivo.';

  @override
  String get lockDelayTitle => 'Bloquear após';

  @override
  String get lockDelayNow => 'Imediatamente';

  @override
  String get lockDelay1m => 'Após 1 minuto';

  @override
  String get lockDelay5m => 'Após 5 minutos';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockLocked => 'Bloqueado';

  @override
  String lockUnavailable(String vendor) => vendor == 'android'
      ? 'Digital, reconhecimento facial e bloqueio de tela não estão disponíveis neste aparelho.'
      : vendor == 'windows'
          ? 'Windows Hello e o PIN do dispositivo não estão disponíveis neste aparelho.'
          : 'Face ID, Touch ID e a senha do dispositivo não estão disponíveis neste aparelho.';

  @override
  String get lockReasonOpen => 'Verifique para abrir suas notas';

  @override
  String get lockReasonOn => 'Verifique para ativar o bloqueio';

  @override
  String get lockReasonOff => 'Verifique para desativar o bloqueio';

  @override
  String get noteLock => 'Bloquear esta nota';

  @override
  String get noteUnlock => 'Desbloquear esta nota';

  @override
  String get noteLocked => 'Nota bloqueada';

  @override
  String get lockReasonNote => 'Abrir a nota bloqueada';

  @override
  String get noteLockDone => 'Nota bloqueada';

  @override
  String get noteUnlockDone => 'Nota desbloqueada';

  @override
  String get syncDiagSignedOut => 'Este dispositivo não está conectado ao iCloud. Entre primeiro.';

  @override
  String get syncDiagNoContainer => 'Você está conectado, mas o app ainda não tem seu espaço no iCloud. Ative com os passos abaixo.';

  @override
  String get syncDiagPreparing => 'O espaço já existe. Aguardando terminar de ficar pronto.';

  @override
  String get syncRecheckWhat => 'Pergunta de novo ao dispositivo sobre o iCloud, do zero.';

  @override
  String get syncRecheckOk => 'O iCloud está ativado';

  @override
  String get syncRecheckStill => 'Ainda não está ativado. Ative nos Ajustes e toque de novo. Se acabou de ativar, tente outra vez em um ou dois minutos.';

  @override
  String get syncOpenFailed => 'Não foi possível abrir os Ajustes. Abra pela Tela de Início.';

  @override
  String get syncOpenManual => 'Abra os Ajustes você mesmo: Tela de Início › Ajustes › seu nome no topo › iCloud.';

  @override
  String get menuFile => 'Arquivo';

  @override
  String get menuClose => 'Fechar';

  @override
  String get menuPrefs => 'Ajustes…';

  @override
  String get appliedTitle => 'Tudo bem organizado';

  @override
  String get tidyRulesTitle => 'Regras de organização';

  @override
  String get tidyRulesSub =>
      'Define o que Organizar faz com o texto. O que você escolher aqui vale só para a organização básica; as outras formas fazem o que o nome diz.';

  @override
  String get syncOnTitle => 'Ativado';

  @override
  String get syncOffTitle => 'Desativado';

  @override
  String get syncSignedOutTitle => 'Falta iniciar sessão';
  @override
  String get syncHelpTitleGdrive => 'Reconectar o Google Drive';
  @override
  String get syncHelpStepsGdrive => '1. Toque no botão abaixo e escolha sua conta Google\n2. Permita o acesso ao Drive\n3. A sincronização começa em seguida';
  @override
  String get syncHelpNoteGdrive => 'Suas notas continuam no Drive. Elas voltam assim que você entrar.';
  @override
  String get syncDiagSignedOutGdrive => 'Este aparelho não está conectado a uma conta Google.';
  @override
  String get syncSignInGoogle => 'Entrar com o Google';
  @override
  String get syncAllowDrive => 'Permitir acesso ao Drive';
  @override
  String get syncDiagPreparingGdrive =>
      "Sessão iniciada. Recebendo suas notas do Drive. Não precisa ficar olhando — pode ir a outro app; a receção pausa e continua de onde parou quando você voltar.";
  @override
  String get syncRecheckStillGdrive => 'Ainda não chegou tudo. A primeira sincronização demora um pouco quando há muitas notas \u2014 ela continua depois que você fechar.';

  @override
  String pastedFrom(String src, String date) =>
      'de $src em $date';

  @override
  String pastedOn(String date) => 'colado em $date';

  @override
  String staleWarn(int days) =>
      'Esta resposta tem $days dias. O modelo pode ter mudado desde então.';
  @override
  String get settingsSecView => 'Visualização';
  @override
  String get settingsSecTidy => 'Regras de limpeza';
  @override
  String get settingsSecWhen => 'Ao limpar';
  @override
  String get settingsSecInfo => 'Informação';
  @override
  String get emphTitle => 'Ênfase em negrito (**texto**)';
  @override
  String get emphSub => 'Em frases inteiras com mais de 40 caracteres, só as marcas são removidas';
  @override
  String get emphQuoteSingle => "Aspas simples 'ênfase'";
  @override
  String get emphQuoteDouble => 'Aspas duplas "ênfase"';
  @override
  String get removeLabel => 'Remover';
  @override
  String get keepLabel => 'Manter';
  @override
  String get hrTitle => 'Divisores (---)';
  @override
  String get headingTitle => 'Títulos (#, ##)';

  @override
  String get quoteTitle => 'Citações (> texto)';
  @override
  String get headingStrip => 'Deixar só o texto';
  @override
  String get headingKeep => 'Manter como está';
  @override
  String get headingPrefix => 'Prefixar com ■';
  @override
  String get headingBracket => '[Colchetes]';
  @override
  String get bulletTitle => 'Marcadores (-, *)';
  @override
  String get bulletHyphen => 'Hífen -';
  @override
  String get bulletMiddot => 'Ponto médio ·';
  @override
  String get bulletDot => 'Marcador •';
  @override
  String get bulletWhite => 'Marcador branco ◦';
  @override
  String get bulletKeep => 'Manter o símbolo original';
  @override
  String get bulletIndentTitle => 'Recuo dos marcadores';
  @override
  String get indent2 => '2 espaços';
  @override
  String get indent4 => '4 espaços';
  @override
  String get indentNone => 'Nenhum';
  @override
  String get headingPadTitle => 'Espaçamento de subtítulos';
  @override
  String get headingPadSub =>
      '2 linhas acima e 1 abaixo — usa um caractere invisível (ㅤ) que se mantém em apps de mensagem e blogs';
  @override
  String get citationsTitle => 'Remover links de citação';
  @override
  String get citationsSub => 'Remove os números de nota no texto e a lista de fontes no fim';
  @override
  String get monoEditorTitle => 'Tabelas em monoespaçado';
  @override
  String get monoEditorSub => 'Alinha com precisão as colunas de tabelas e código. O texto mantém o tipo de letra do dispositivo';
  @override
  String get dashListTitle => 'Converter sequências com travessão em listas';
  @override
  String get dashListSub => 'Divide sequências de uma linha como "– a – b – c" em lista por linhas';
  @override
  String get fillerHeadingTitle => 'Organizar subtítulos com caractere invisível';
  @override
  String get fillerHeadingSub => 'Aplica as regras de espaçamento e títulos a pseudotítulos envoltos em ㅤ';
  @override
  String get aiSectionTitle => 'Conexão da edição IA';
  @override
  String get aiSectionDesc =>
      'Com uma chave de API, a IA atende instruções livres como "deixe mais curto". A organização usa regras do dispositivo e não precisa de chave; só a edição IA precisa.';
  @override
  String get aiKeyHint => 'Chave de API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get menuTidyPreview => 'Prévia da organização';
  @override
  String get dividerTip => 'Separador';
  @override
  String get syncScroll => 'Rolar junto';
  @override
  String get pasteTipTitle => 'Que não pergunte ao colar';
  @override
  String get pasteTipSub => 'Tire de uma vez o aviso que o iPhone mostra a cada colagem';
  @override
  String get pasteTipBody =>
      'O iPhone pede permissão sempre que um app lê a área de transferência. Este app começa por colar, então esse aviso aparece muito.\n\nMude uma vez e ele não pergunta mais.\n\n1. Toque em \'Abrir Ajustes\' abaixo\n2. Toque em \'Colar de Outros Apps\'\n3. Escolha \'Permitir\'\n\nMesmo permitido, este app lê a área de transferência apenas no momento em que você toca em Colar. Nunca olha por conta própria.';
  @override
  String get pasteTipLater => 'Mais tarde';
  @override
  String get adClose => 'Fechar anúncios';
  @override
  String get noteDuplicate => 'Duplicar';
  @override
  String get noteDuplicated => 'Duplicada';
  @override
  String get adSponsored => 'Patrocinado';
  @override
  String get sponsorTitle => 'Um anúncio financia a próxima atualização';
  @override
  String get sponsorBody =>
      'Recursos melhores e atualizações constantes precisam do seu apoio. Assista a um anúncio até o fim e hoje o app não mostrará mais anúncios.';
  @override
  String get sponsorWatch => 'Assistir a um anúncio para apoiar';
  @override
  String get sponsorSkip => 'Pular';
  @override
  String get sponsorLoading => 'Carregando anúncio…';
  @override
  String get sponsorFailed => 'Não foi possível carregar o anúncio. Tente novamente em instantes.';
  @override
  String get moreTooltip => 'Mais';
  @override
  String get sponsorGoPremium => 'Seja Premium, sem anúncios';
  @override
  String get premiumPlanBase => 'Padrão';
  @override
  String get premiumPlanAll => 'Todos os aparelhos';
  @override
  String get premiumBestValue => 'Melhor valor';
  @override
  String get premiumPerks => 'Sem anúncios · Organização ilimitada · Edição com IA ilimitada';
  @override
  String get premiumScopeBase => 'Comprado na Apple, abre no iPhone, iPad e Mac. Comprado na Google Play, nos seus aparelhos Android. Nos dois casos o app web está incluído.';
  @override
  String get premiumScopeAll => 'Uma compra abre tudo, mesmo usando iPhone e Android ao mesmo tempo. Aparelhos adicionados depois também entram.';
  @override
  String get premiumAutoRenew => 'A assinatura é renovada automaticamente se não for cancelada até 24 horas antes do fim do período. Você pode cancelar quando quiser nos ajustes da conta.';
  @override
  String get premiumRestore => 'Restaurar compras';
  @override
  String get premiumTerms => 'Termos de uso';
  @override
  String get premiumPrivacy => 'Política de privacidade';
  @override
  String get premiumThanks => 'Obrigado. O Premium está ativo.';
  @override
  String get premiumNoStore => 'Não é possível comprar neste aparelho. Após a compra, valerá aqui ao entrar com a mesma conta.';
  @override
  String get premiumUpgradeHere => 'Mude para Todos os aparelhos para usar aqui. A loja credita o tempo restante.';
  @override
  String get premiumHave => 'Seu plano';
  @override
  String get premiumLoading => 'Buscando preços na loja';

  @override
  String get premiumPerkNoAds => 'Sem anúncios — nem o banner de cima, nem o aviso ao fechar';

  @override
  String get premiumGroupPerks => 'Vantagens do Premium';

  @override
  String get premiumHeadline => 'Sem limite. Sem anúncios.';

  @override
  String get onbTitle1 => 'Cole, e já fica limpo';

  @override
  String get onbBody1 => 'Cole a resposta da IA como ela veio. Asteriscos, cerquilhas e saudações de enfeite saem de uma vez.';

  @override
  String get onbTitle2 => 'Tabelas quebradas voltam a ficar de pé';

  @override
  String get onbBody2 => 'Tabelas desalinhadas são refeitas, e um toque cola tudo direto no Excel ou no Google Sheets.';

  @override
  String get onbTitle3 => 'As mesmas notas em todo lugar';

  @override
  String get onbBody3 => 'O que você escreve no iPhone está também no Mac e no navegador. Isso não é cobrado.';

  @override
  String get onbTitle4 => 'Tudo está aberto';

  @override
  String onbBody4(int days) => 'Use sem limites por $days dias. Decida depois, se valer a pena. Agora não há nada a pagar.';

  @override
  String get onbNext => 'Próximo';

  @override
  String get onbStart => 'Começar';

  @override
  String get onbSkip => 'Pular';

  @override
  String get onbSeePremium => 'Ver Premium';

  @override
  String get premiumSubhead => 'Para quem lida com respostas de IA todo dia. Aperte organizar quantas vezes quiser — ninguém está contando.';

  @override
  String get premiumPerkNew => 'Novidades primeiro — assim que ficam prontas';

  @override
  String get premiumTrustTitle => 'Continua sendo construído';

  @override
  String get premiumCancelAnytime => 'Cancele quando quiser';

  @override
  String get premiumPerMonth => 'mês';

  @override
  String get premiumPerYear => 'ano';

  @override
  String get premiumPerLifetime => 'Vitalício';

  @override
  String get premiumUnlockApple => 'Desbloqueie no iPhone, iPad e Mac';

  @override
  String get premiumUnlockGoogle => 'Desbloqueie nos seus aparelhos Android';

  @override
  String get premiumUnlockAll => 'Desbloqueie em todos os seus aparelhos';

  @override
  String premiumCta(String period, String price) => 'Assinar por $price / $period';

  @override
  String premiumChargeNote(String period, String price) => 'Será cobrado $price por $period.';

  @override
  String premiumTrialThen(int days) => '$days dias grátis, depois';

  @override
  String premiumSave(int pct) => 'Economize $pct%';

  @override
  String premiumTrustBody(String version) => 'Você está na $version. Os pedidos costumam sair na mesma semana, e o que mudou dá para ver dentro do app.';




  @override
  String get premiumPerkWeb => 'O app web também — sem anúncios no navegador';






  @override
  String premiumPerkTidy(int n) => 'Organização ilimitada — sem o limite de $n por dia';

  @override
  String premiumPerkWizard(int n) => 'Edição com IA ilimitada — sem o limite de $n por dia';



  @override
  String get sponsorPremiumNote => 'Compre uma vez e nem o banner nem este aviso voltam.';
  @override
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Sem anúncios. Sem limites.';
  @override
  String get premiumLifetime => 'Vitalício';
  @override
  String get premiumMonthly => 'Mensal';
  @override
  String get limitTitle => 'Você usou todos os usos gratuitos de hoje';
  @override
  String limitTidyBody(int n) => 'O plano gratuito inclui $n limpezas por dia. Renova amanhã; o Premium tira o limite.';
  @override
  String limitWizardBody(int n) =>
      'O plano gratuito inclui $n edições IA por dia. Reinicia amanhã; o Premium remove o limite.';
  @override
  String get limitSeePremium => 'Ver Premium';

  @override
  String limitLeftTidy(int n) => 'Resta $n organização grátis hoje.';

  @override
  String limitLeftWizard(int n) => 'Resta $n edição com IA grátis hoje.';
  @override
  String get premiumYearly => 'Anual';
  @override
  String get premiumLifetimeNote => 'Um pagamento, sem renovação';

  @override
  String trialBadge(int days) => 'Teste ilimitado · faltam $days dias';

  @override
  String get trialEndedTitle => 'Seu teste ilimitado terminou';

  @override
  String trialEndedBody(int tidy, int wiz, int tidyLimit, int wizLimit) =>
      'Durante o teste você fez $tidy organizações e $wiz edições IA. A partir de agora o plano gratuito inclui $tidyLimit organizações e $wizLimit edições IA por dia. O Premium remove o limite.';
  @override
  String get themeTitle => 'Aparência';
  @override
  String get themeSystem => 'Seguir o aparelho';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Escuro';
  @override
  String get aiKeyVerify => 'Verificar chave';
  @override
  String get aiKeyChecking => 'Verificando…';
  @override
  String get aiKeyUnknownFormat => 'Não foi possível identificar o provedor. Os quatro foram consultados e nenhum aceitou esta chave. Copie e cole a chave novamente.';
  @override
  String get aiAdvancedLabel => 'Avançado — escolher modelo manualmente';
  @override
  String get aiManualModelHint => 'Digite o nome do modelo (ex.: gemini-2.5-flash-lite)';
  @override
  String aiAutoLabel(String provider, String model) => 'Automático: $provider · $model';
  @override
  String aiModelsFound(int n) => '$n modelos disponíveis confirmados.';
  @override
  String aiListFailed(String error) => 'Não foi possível obter a lista de modelos ($error). Será usada a lista de reserva integrada.';
  @override
  String aiModelSwitched(String model) => 'O modelo anterior parou de responder; mudou para $model.';
  @override
  String get rulesSectionTitle => 'Minhas regras de substituição automática';
  @override
  String get rulesSectionDesc =>
      'Aplicadas de cima para baixo. Use \\n na substituição para quebra de linha. Blocos de código não são alterados.';
  @override
  String get addRule => 'Adicionar regra';
  @override
  String get settingsFooter =>
      'Os ajustes valem imediatamente e passam a ser aplicados no próximo "Organizar". Notas já organizadas não mudam retroativamente.';
}
