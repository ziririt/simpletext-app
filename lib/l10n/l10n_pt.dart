import 'l10n.dart';

/// Português (기준: 브라질 pt-BR — pt-PT 분리가 필요해지면 파일을 나눈다)
class L10nPt extends L10n {
  const L10nPt();

  @override
  String get localeTag => 'pt';

  @override
  String get appTitle => 'SimpleText';

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
  String get seedTitle => 'Bem-vindo ao SimpleText';
  @override
  String get seedTag => 'Como usar';
  @override
  String get seedBody => [
        'Como usar o SimpleText',
        '',
        '1. Copie uma resposta do ChatGPT ou do Claude e toque em "Colar e organizar".',
        '2. Compare o original e o resultado na prévia e toque em "Aplicar". Pronto.',
        '3. Em notas com tabelas, o botão "Tabela" copia para planilhas (TSV).',
        '4. Toda organização pode ser revertida com um único Desfazer.',
        '',
        'Abaixo há uma tabela quebrada de propósito. Toque em "Organizar" para ver o reparo.',
        '',
        '| Ação | Ticker | Retorno | Peso',
        '|------|------|--------|',
        '| Apple | AAPL | +14.2% | 12% |',
        '| Microsoft | MSFT | +21.5%',
        '| Nvidia | NVDA | +48.9% | 22% | célula extra |',
        '|Tesla|TSLA|-8.3%|8%|',
      ].join('\n');

  @override
  String get done => 'OK';

  @override
  String get autoTidy => 'Limpeza automática';

  @override
  String get bodyFontSizeTitle => 'Tamanho do texto';

  @override
  String get bodyFontSizeSample =>
      'Conheça um espaço de trabalho Smart que organiza as muitas ideias da sua cabeça com pura Simplicity. Cole o texto, toque em Limpar e tudo fica Clean.';

  @override
  String get wizardNothingToDo => 'Nada para alterar';

  @override
  String wizardAppliedToast(int count) => '\$count instrução(ões) aplicada(s)';

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
  String get revertedToast => 'Versão anterior restaurada';
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
  String get wizardAction => 'Assistente';
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
  String get wizardTitle => 'Assistente';
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
  String get apply => 'Aplicar';

  @override
  String get presetAiName => 'Organizar resposta de IA';
  @override
  String get presetAiDesc => 'Remove marcas de markdown, emojis e preâmbulos de IA; repara tabelas';
  @override
  String get presetStripName => 'Remover todo o Markdown';
  @override
  String get presetStripDesc => 'Remove ao máximo a sintaxe markdown; tabelas viram TSV';
  @override
  String get presetMinimalName => 'Organização mínima';
  @override
  String get presetMinimalDesc => 'Mantém a estrutura; remove só ruído (espaços, caracteres de largura zero)';
  @override
  String get presetTablesName => 'Somente tabelas';
  @override
  String get presetTablesDesc => 'Extrai as tabelas do documento como TSV';
  @override
  String get presetBlogName => 'Colar em blog';
  @override
  String get presetBlogDesc => 'Remove marcas, mantém as URLs dos links, repara tabelas';

  @override
  String get settingsTitle => 'Regras de organização';
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
  String get aiSectionTitle => 'Conexão do Assistente de IA (edição livre)';
  @override
  String get aiSectionDesc =>
      'Com uma chave de API, o Assistente processa comandos livres como "deixe mais conciso". A chave fica salva só neste dispositivo.';
  @override
  String get aiKeyHint => 'Chave de API (Gemini · Claude · ChatGPT · Grok)';
  @override
  String get adClose => 'Fechar anúncios';
  @override
  String get sponsorTitle => 'Um anúncio financia a próxima atualização';
  @override
  String get sponsorBody => 'O Skyblue Note funciona só no seu aparelho, sem servidores. Ainda assim, desenvolvimento e manutenção custam dinheiro de verdade. Assista a um anúncio de tela cheia por dia e o pequeno banner no topo some pelo resto do dia.';
  @override
  String get sponsorWatch => 'Assistir a um anúncio para apoiar';
  @override
  String get sponsorSkip => 'Pular';
  @override
  String get sponsorLoading => 'Carregando anúncio…';
  @override
  String get sponsorFailed => 'Não foi possível carregar o anúncio. Tente novamente em instantes.';
  @override
  String get aiKeyVerify => 'Verificar chave';
  @override
  String get aiKeyChecking => 'Verificando…';
  @override
  String get aiKeyUnknownFormat => 'Formato de chave não reconhecido. Defina o modelo em Avançado.';
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
