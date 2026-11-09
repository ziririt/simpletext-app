/// 옛 Skyblue Note 에서 옮겨 오는 안내 — 애플 기기(아이폰·아이패드·맥)만.
///
/// 2026-11-09. 아이폰·아이패드·맥 앱이 새 계정의 'Skyblue Note Pro'
/// (com.ezlong.skybluenote) 로 옮겼다. 묶음 아이디가 바뀌면 옛 앱의 기기 안 자료,
/// 아이클라우드 폴더, 키체인(AI 키)을 새 앱이 읽을 수 없다. 그래서 길을 셋 둔다.
///
///   (가) 구글 드라이브 — 같은 구글 클라우드 프로젝트의 클라이언트로 로그인하면
///        appDataFolder 가 같아서 노트가 그대로 내려온다. 가장 쉬운 길
///   (나) 아이클라우드만 쓰던 사람 — 옛 앱에서 드라이브로 바꾸거나 백업 파일로
///   (다) 기기에만 두던 사람 — 백업 파일로
///
/// 파일 앱의 'Skyblue Note' 아이클라우드 폴더에서 꺼내 오는 길은 **실기기에서
/// 보이는지 확인한 뒤에만** 안내한다(작업 지시 3절). 아직 적지 않는다.
///
/// 처음 켤 때 첫 안내 다음에 한 번, 그 뒤로는 설정 → 정보 의 줄에서 다시 연다.
library;

import 'package:flutter/material.dart';

import 'import_service.dart';
import 'l10n/l10n.dart';
import 'main.dart' show SyncSettingsScreen;

Future<void> showMigrateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => _MigrateSheet(outer: context),
  );
}

class _MigrateSheet extends StatelessWidget {
  const _MigrateSheet({required this.outer});

  /// 시트를 연 화면. 시트를 닫은 뒤 그 화면에서 다음 일을 이어 간다.
  final BuildContext outer;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final body = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.45, fontSize: 15);
    final note = body?.copyWith(color: cs.onSurfaceVariant, fontSize: 14);

    Widget way(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 12),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.migrateTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(l.migrateIntro, style: body),
              const SizedBox(height: 16),
              way(Icons.cloud_outlined, l.migrateDrive),
              way(Icons.cloud_sync_outlined, l.migrateIcloud),
              way(Icons.smartphone_outlined, l.migrateLocal),
              const SizedBox(height: 4),
              Text(l.migrateKeys, style: note),
              const SizedBox(height: 8),
              Text(l.migrateReceipt, style: note),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(outer).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SyncSettingsScreen(),
                    ),
                  );
                },
                child: Text(l.migrateBtnDrive),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final n = await ImportService.importFiles();
                  if (!outer.mounted) return;
                  ScaffoldMessenger.maybeOf(outer)?.showSnackBar(
                    SnackBar(
                      content: Text(n > 0 ? l.importDone(n) : l.importNone),
                    ),
                  );
                },
                child: Text(l.importFiles),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
