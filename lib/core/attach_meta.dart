/// 첨부 파일 — 화면과 저장소를 모르는 판정만.
///
/// 2026-08-19 소유자 확정(HANDOVER 8-2절). 이 기능의 규칙 하나가 다른
/// 무엇보다 중요하다.
///
/// **알맹이는 기기 밖으로 안 나간다.** 파일 자체는 붙인 그 기기 안에만 있고,
/// 아이클라우드에도 구글 드라이브에도 올라가지 않는다. 오가는 것은 이름·크기·
/// 붙인 시각·어느 기기였는가 넷뿐이다. 다른 기기에서는 그 넷으로 "여기 뭐가
/// 붙어 있다"고 알려만 준다.
///
/// 까닭은 그릇이다. 아이클라우드 Documents도 구글 드라이브 appDataFolder도
/// 용량이 사용자 계정에서 나간다. 메모 한 통은 몇 KB지만 첨부는 한 장에 수
/// MB다 — 무료 15GB를 말없이 갉아먹는 앱이 되면 그 순간 지워진다.
///
/// 막는 것이 아니라 **미루는 것**이다. 이 넷만 있으면 나중에 유료 층에서
/// '첨부도 동기화'를 켤 때 저장 형식을 바꾸지 않고 알맹이만 실어 보내면 된다.
library;

/// 첨부 하나. 여기 담기는 것은 전부 **동기화되는** 값이다.
/// 파일이 실제로 어디 있는지(경로)는 담지 않는다 — 기기마다 다르고,
/// 다른 기기로 건너가면 뜻이 없는 값이기 때문이다.
class Attach {
  const Attach({
    required this.id,
    required this.name,
    required this.size,
    required this.addedAt,
    required this.device,
  });

  /// 기기 안에서 파일을 찾는 열쇠. 파일 이름으로도 쓴다.
  final String id;

  /// 사람이 보는 원래 이름. '결산표.pdf'
  final String name;

  /// 바이트.
  final int size;

  final int addedAt;

  /// 어느 갈래의 기기에서 붙였나. 'iphone' 'ipad' 'mac' 'android'
  /// 'windows' 'web'.
  ///
  /// 진짜 기기 이름('성동의 아이폰')을 안 쓴다. 애플이 그걸 개인정보로 보고
  /// 막아 뒀고, 막지 않았더라도 그 이름은 동기화 파일에 실려 클라우드로
  /// 나간다. 갈래만 있으면 "어느 기기로 가면 되는지"는 충분히 알 수 있다.
  final String device;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'at': addedAt,
        'dev': device,
      };

  static Attach? fromJson(Object? o) {
    if (o is! Map) return null;
    final id = (o['id'] ?? '') as String;
    if (id.isEmpty) return null;
    return Attach(
      id: id,
      name: (o['name'] ?? '') as String,
      size: (o['size'] is int) ? o['size'] as int : 0,
      addedAt: (o['at'] is int) ? o['at'] as int : 0,
      device: (o['dev'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Attach &&
      other.id == id &&
      other.name == name &&
      other.size == size &&
      other.addedAt == addedAt &&
      other.device == device;

  @override
  int get hashCode => Object.hash(id, name, size, addedAt, device);

  @override
  String toString() => 'Attach($id, $name, $size, $device)';
}

/// 파일 하나가 몇 갈래인가. 아이콘과 미리보기 방식을 여기서 가른다.
const String kAttachImage = 'image';
const String kAttachPdf = 'pdf';
const String kAttachDoc = 'doc';
const String kAttachSheet = 'sheet';
const String kAttachSlide = 'slide';
const String kAttachAudio = 'audio';
const String kAttachVideo = 'video';
const String kAttachArchive = 'zip';
const String kAttachText = 'text';
const String kAttachFile = 'file';

const Map<String, String> _byExt = {
  'jpg': kAttachImage, 'jpeg': kAttachImage, 'png': kAttachImage,
  'gif': kAttachImage, 'webp': kAttachImage, 'heic': kAttachImage,
  'heif': kAttachImage, 'bmp': kAttachImage, 'tif': kAttachImage,
  'tiff': kAttachImage,
  'pdf': kAttachPdf,
  'doc': kAttachDoc, 'docx': kAttachDoc, 'hwp': kAttachDoc,
  'hwpx': kAttachDoc, 'rtf': kAttachDoc, 'odt': kAttachDoc,
  'pages': kAttachDoc,
  'xls': kAttachSheet, 'xlsx': kAttachSheet, 'csv': kAttachSheet,
  'numbers': kAttachSheet, 'ods': kAttachSheet,
  'ppt': kAttachSlide, 'pptx': kAttachSlide, 'key': kAttachSlide,
  'odp': kAttachSlide,
  'mp3': kAttachAudio, 'm4a': kAttachAudio, 'wav': kAttachAudio,
  'aac': kAttachAudio, 'flac': kAttachAudio, 'ogg': kAttachAudio,
  'mp4': kAttachVideo, 'mov': kAttachVideo, 'm4v': kAttachVideo,
  'avi': kAttachVideo, 'mkv': kAttachVideo, 'webm': kAttachVideo,
  'zip': kAttachArchive, 'rar': kAttachArchive, '7z': kAttachArchive,
  'gz': kAttachArchive, 'tar': kAttachArchive,
  'txt': kAttachText, 'md': kAttachText, 'json': kAttachText,
  'log': kAttachText,
};

/// 이름에서 갈래를 읽는다. 확장자를 못 알아보면 [kAttachFile].
///
/// 파일 속을 안 열어 본다. 첨부 목록을 그릴 때마다 수십 개의 파일을 열어
/// 첫 바이트를 읽는 것은 값이 안 맞는다 — 아이콘 하나 고르자고 디스크를
/// 훑을 이유가 없다.
String attachKind(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return kAttachFile;
  final ext = name.substring(dot + 1).toLowerCase();
  return _byExt[ext] ?? kAttachFile;
}

/// 이 갈래를 화면에 그림으로 펼쳐 볼 수 있는가.
bool attachShowsThumb(String name) => attachKind(name) == kAttachImage;

/// 사람이 읽는 크기. '820B' '1.2MB' '3.4GB'
///
/// 1024로 나눈다(KiB). 파일 탐색기가 그렇게 세고, 사용자는 그 숫자에 익숙하다.
/// 소수 첫째 자리까지만 — 둘째 자리는 아무도 안 본다.
String humanSize(int bytes) {
  if (bytes < 0) return '0B';
  if (bytes < 1024) return '${bytes}B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = bytes / 1024;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  // 10 넘으면 소수점을 뗀다. '12.3MB'보다 '12MB'가 읽기 쉽고, 그 자리에서
  // 소수점 한 자리는 뜻이 없다.
  final s = v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
  return '$s${units[i]}';
}

/// 파일 이름을 칸에 맞게 줄인다. **뒤를 남긴다.**
///
/// 앞을 남기고 뒤를 자르면 확장자가 사라져서 '2026년_3분기_결산_최종…' 이
/// 무엇인지 알 수 없다. 가운데를 접으면 이름의 앞뒤가 다 남는다.
String shortName(String name, {int max = 22}) {
  if (name.length <= max) return name;
  final dot = name.lastIndexOf('.');
  final ext = (dot > 0 && name.length - dot <= 6) ? name.substring(dot) : '';
  final head = max - ext.length - 1;
  if (head < 4) return '${name.substring(0, max - 1)}…';
  return '${name.substring(0, head)}…$ext';
}

/// 이 기기에서 붙인 것인가.
bool isMine(Attach a, String myDevice) => a.device == myDevice;

/// 다른 기기에서 붙인 것들을 기기별로 묶는다.
///
/// 안내 줄을 기기 하나에 한 줄씩 내기 위해서다. 파일마다 한 줄이면 다섯
/// 개를 붙인 사람의 화면은 안내문 다섯 줄로 덮인다.
Map<String, List<Attach>> groupOthers(List<Attach> all, String myDevice) {
  final out = <String, List<Attach>>{};
  for (final a in all) {
    if (a.device == myDevice) continue;
    (out[a.device] ??= []).add(a);
  }
  return out;
}

/// 안내 줄에 들어갈 파일 나열. '결산표.pdf(1.2MB) 외 2개'
String othersSummary(List<Attach> list, String andMore) {
  if (list.isEmpty) return '';
  final first = '${list.first.name}(${humanSize(list.first.size)})';
  if (list.length == 1) return first;
  return '$first $andMore';
}
