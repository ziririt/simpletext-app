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
  String get seedBody => [
        'Claro! 🙂 Aqui está tudo o que você pediu, organizado abaixo.',
        '',
        '---',
        '',
        '## Como usar o Skyblue Note',
        '',
        '**1. Colar e organizar** — copie uma resposta do ChatGPT ou do Claude e toque em "Colar e organizar".',
        '* Os asteriscos (**), as cerquilhas (##), os emojis 🎉 e as introduções somem **de uma vez**.',
        '* As tabelas quebradas são reparadas ao mesmo tempo.',
        '',
        '### 2. Trabalhando com tabelas',
        '',
        '> Em notas com tabelas, o botão "Tabela" copia para planilhas (TSV).',
        '',
        '**3. Desfazer** — toda organização pode ser [revertida](https://example.com/undo) com um único Desfazer. ✅',
        '',
        '---',
        '',
        'Abaixo há uma tabela quebrada de propósito. Toque em "Organizar" para ver o reparo.',
        '',
        '| Ação | Ticker | Retorno | Peso',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5% | 18% |',
        '| NVIDIA | NVDA | +48.9% | 22% |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get bodyFontSizeTitle => 'Tamanho do texto';

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
  String get metaTooltip => 'Fonte e tags';
  @override
  String get pinTooltip => 'Fixar no topo';
  @override
  String get unpinTooltip => 'Desafixar';
  @override
  String get deleteTooltip => 'Excluir';
  @override
  String get titleHint => 'Título (automático)';
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
      'A nota volta ao texto que colou no início. Todas as organizações e todas as edições feitas depois vão desaparecer.\n\nO texto atual fica no histórico, por isso pode trazê-lo de volta.';

  @override
  String get revertConfirmOk => 'Voltar';

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
  String unknownPrefix(String what) => 'Não reconhecido como regra · $what';
  @override
  String get aiKeyPromo => 'Adicione uma chave de API de IA nos Ajustes para processar também edições livres assim.';
  @override
  String get aiRunUnknown => 'Executar comandos não reconhecidos com IA';
  @override
  String get aiBusyLabel => 'IA editando…';
  @override
  String get aiEmptyResponse => 'Resposta vazia';
  @override
  String aiCallFailed(String error) => 'Falha na chamada de IA: $error';
  @override
  String get aiApplyResult => 'Aplicar resultado da IA';
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
      'Para lugares sem formatação, como chats e SMS';
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
  String get settingsTitle => 'Ajustes';

  @override
  String get menuAppSettings => 'Ajustes do app';

  @override
  String get menuAiKey => 'Chave de API de IA';

  @override
  String get syncTitle => 'iCloud';

  @override
  String get syncStateOn => 'As mesmas notas no iPhone, iPad e Mac';

  @override
  String get syncStateOff => 'Ative o iCloud Drive nos ajustes do dispositivo';

  @override
  String get syncStateSyncing => 'Conectando ao iCloud… leva de alguns segundos a um minuto';

  @override
  String get aiKeyNotSynced => 'Suas notas sincronizam entre todos os seus dispositivos pelo iCloud. Sua chave de API não: informe-a em cada dispositivo.';

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
  String get paperGrid => 'Quadriculado';

  @override
  String get lockSectionTitle => 'Bloqueio';

  @override
  String get lockTitle => 'Bloqueio do app';

  @override
  String get lockSub => 'Abra o app com Face ID, Touch ID ou a senha do dispositivo.';

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
  String get lockUnavailable => 'Face ID, Touch ID e a senha do dispositivo não estão disponíveis neste aparelho.';

  @override
  String get lockReasonOpen => 'Verifique para abrir suas notas';

  @override
  String get lockReasonOn => 'Verifique para ativar o bloqueio';

  @override
  String get lockReasonOff => 'Verifique para desativar o bloqueio';

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
  String get tidyRulesSub => 'Define como o texto muda ao tocar em Organizar.';

  @override
  String get syncOnTitle => 'Ativado';

  @override
  String get syncOffTitle => 'Desativado';

  @override
  String get syncSignedOutTitle => 'Falta iniciar sessão';

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
  String get premiumTitle => 'Premium';
  @override
  String get premiumPitch => 'Sem anúncios, em todos os seus aparelhos';
  @override
  String get premiumPitchSub => 'US\$29.99 uma vez ou US\$1.99/mês · iPhone, iPad e Mac juntos';
  @override
  String get premiumBody => 'O Premium remove todos os anúncios e libera o Skyblue Note no iPhone, iPad e Mac. Uma compra vale pelos três. Seu apoio constrói a próxima atualização.';
  @override
  String get premiumLifetime => 'Vitalício · US\$29.99';
  @override
  String get premiumMonthly => 'Mensal · US\$2.99/mês';
  @override
  String get premiumComingSoon => 'As compras serão ativadas na versão da App Store. Falta pouco.';
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
  String get premiumYearly => 'Anual · US\$14.99/ano';
  @override
  String get premiumLifetimeNote => 'Preço de lançamento · normal US\$39.99';

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
  String get rulesSectionTitle => 'Regras de substituição automática';
  @override
  String get rulesSectionDesc =>
      'Aplicadas de cima para baixo. Use \\n na substituição para quebra de linha. Blocos de código não são alterados.';
  @override
  String get addRule => 'Adicionar regra';
  @override
  String get settingsFooter =>
      'Os ajustes valem imediatamente e passam a ser aplicados no próximo "Organizar". Notas já organizadas não mudam retroativamente.';
}
