#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""다음 판을 심사에 낼 준비를 한 번에 한다 — 그리고 낼 때만 낸다.

2026-08-28 새벽 신설. 소유자 지시: "현재 심사신청 버전 완료되면 즉시 이어서
심사신청할 수 있게 준비해줘."

애플은 **앞 판이 심사 줄에 서 있는 동안 새 판을 못 만든다.** 그래서 미리
만들어 둘 수가 없다. 대신 앞 판이 나가는 순간 한 줄로 끝나도록 여기 모아
둔다. 사람이 다섯 화면을 돌아다니며 열한 개 언어의 '새로운 기능'을 붙여
넣는 일이 이 파일 하나로 줄어든다.

  python3 tool/submit_next.py               # 지금 어떤 상태인지만 본다
  python3 tool/submit_next.py --prepare     # 판을 만들고 글과 빌드를 붙인다
  python3 tool/submit_next.py --submit      # 준비된 판을 심사에 낸다

**--submit 은 소유자가 말했을 때만 친다.** 준비(--prepare)는 되돌릴 수
있지만 제출은 사람의 결정이다.

버전 이름은 스토어에 보이는 것(1.3 → 1.4)이고, 앱 안의 버전(3.8.0)과 다르다.
빌드는 App Store Connect 에 올라온 것 중 가장 큰 번호를 쓴다
(올리는 일은 tool/appstore_ios.sh).
"""
import argparse
import json
import os
import sys

# 열쇠 꾸러미는 ziririt 홈에 있다. 맥 자동 실행꾼이 다른 계정으로 돌 때도
# 찾아야 해서 후보를 차례로 본다(2026-09-07). 값은 여기 없고, 자리만 있다.
for _cand in (os.environ.get('SKY_SECRETS_HOME'), os.path.expanduser('~'),
              '/Users/ziririt'):
    if _cand and os.path.isdir(os.path.join(_cand, '.appstoreconnect')):
        sys.path.insert(0, os.path.join(_cand, '.appstoreconnect'))
        break
try:
    from asc import api
except Exception as e:  # noqa: BLE001
    print('열쇠 꾸러미를 못 읽었다(.appstoreconnect): %s' % e)
    raise SystemExit(2)

BUNDLE = 'com.ziririt.simpletext'

_raw_api = api


def api(method, path, body=None, tries=4):
    """애플 API 는 이따금 응답 없이 연결을 끊는다(2026-08-28 실측).

    한 번 끊겼다고 판 만들기를 중간에 멈추면, 열한 언어 중 둘만 고쳐진
    어정쩡한 상태가 남는다. 끊기면 잠깐 쉬고 다시 건다.
    """
    import time
    last = None
    for i in range(tries):
        try:
            return _raw_api(method, path, body)
        except Exception as e:  # noqa: BLE001
            last = e
            if i == tries - 1:
                break
            time.sleep(2 * (i + 1))
    raise last
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(HERE, 'store', 'ios')


def die(msg):
    print(msg)
    raise SystemExit(1)


def ok(st, r, what):
    if st >= 300:
        die('%s 실패(%s): %s' % (what, st, json.dumps(r)[:500]))
    return r


def app_id():
    st, r = api('GET', '/v1/apps?filter[bundleId]=%s' % BUNDLE)
    ok(st, r, '앱 찾기')
    if not r.get('data'):
        die('앱을 못 찾았다: %s' % BUNDLE)
    return r['data'][0]['id']


def versions(aid):
    st, r = api('GET', '/v1/apps/%s/appStoreVersions?limit=5' % aid)
    ok(st, r, '판 목록')
    return r['data']


def newest_build(aid):
    st, r = api('GET', '/v1/builds?filter[app]=%s&limit=10' % aid)
    ok(st, r, '빌드 목록')
    live = [b for b in r['data']
            if b['attributes'].get('processingState') == 'VALID'
            and not b['attributes'].get('expired')]
    if not live:
        die('쓸 수 있는 빌드가 없다. 먼저 tool/appstore_ios.sh 를 돌려라.')
    live.sort(key=lambda b: int(b['attributes']['version']), reverse=True)
    return live[0]


def next_name(vs):
    """스토어에 보이는 버전 이름의 다음 값. 1.3 → 1.4, 1.9 → 1.10 이 아니라 2.0."""
    nums = []
    for v in vs:
        s = v['attributes'].get('versionString', '')
        try:
            nums.append(tuple(int(x) for x in s.split('.')))
        except ValueError:
            continue
    if not nums:
        return '1.0'
    hi = max(nums)
    major, minor = (list(hi) + [0, 0])[:2]
    return '%d.0' % (major + 1) if minor >= 9 else '%d.%d' % (major, minor + 1)


def notes():
    out = {}
    for loc in sorted(os.listdir(STORE)):
        p = os.path.join(STORE, loc, 'release_notes.txt')
        if os.path.isfile(p):
            with open(p, encoding='utf-8') as f:
                t = f.read().strip()
            if t:
                out[loc] = t
    return out


def show():
    aid = app_id()
    vs = versions(aid)
    print('앱 %s' % aid)
    for v in vs:
        a = v['attributes']
        print('  %-6s %-26s %s' % (a.get('versionString'), a.get('appStoreState'), v['id']))
    b = newest_build(aid)
    print('가장 새 빌드: %s (%s)' % (b['attributes']['version'], b['attributes']['processingState']))
    n = notes()
    print('새로운 기능 글: %d개 로케일 — %s' % (len(n), ', '.join(sorted(n))))
    live = [v for v in vs if v['attributes'].get('appStoreState') in
            ('PREPARE_FOR_SUBMISSION', 'WAITING_FOR_REVIEW', 'IN_REVIEW',
             'PENDING_DEVELOPER_RELEASE', 'REJECTED', 'METADATA_REJECTED')]
    if live:
        a = live[0]['attributes']
        print('\n지금 손에 잡히는 판: %s (%s)' % (a['versionString'], a['appStoreState']))
        if a['appStoreState'] in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
            print('→ 이 판이 나갈 때까지 새 판을 못 만든다. 기다렸다가 --prepare.')
        elif a['appStoreState'] == 'PREPARE_FOR_SUBMISSION':
            print('→ 준비된 판이 있다. --prepare 로 글·빌드를 맞추고 --submit 으로 낸다.')
    else:
        print('\n손에 잡히는 판이 없다 → --prepare 로 새 판을 만든다.')
    print('다음 판 이름이 될 값: %s' % next_name(vs))


# 아직 심사 줄에 서지 않은 판의 상태들.
#
# READY_FOR_REVIEW 는 '냈다'가 아니라 **'낼 준비가 끝났다'**이다.
# 2026-09-02에 인앱 상품 넣기가 중간에 실패해 제출함만 만들어진 채
# 멈췄더니, 판이 이 상태로 남고 --submit 이 '낼 판이 없다'고 했다.
# 그때 사람이 할 수 있는 일이 없어진다 — 낼 판은 분명히 있는데.
_OPEN_STATES = (
    'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED',
    'DEVELOPER_REJECTED', 'READY_FOR_REVIEW',
)


def editable(aid, states=None):
    """지금 손댈 수 있는 판. 없으면 None."""
    want = states or _OPEN_STATES
    for v in versions(aid):
        if v['attributes'].get('appStoreState') in want:
            return v
    return None


def prepare():
    aid = app_id()
    vs = versions(aid)
    # 준비 단계는 글을 고치는 일이라 READY_FOR_REVIEW 는 대상이 아니다.
    v = editable(aid, states=(
        'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED',
        'DEVELOPER_REJECTED'))
    if v is None:
        name = next_name(vs)
        body = {'data': {'type': 'appStoreVersions',
                         'attributes': {'platform': 'IOS',
                                        'versionString': name,
                                        'releaseType': 'AFTER_APPROVAL'},
                         'relationships': {'app': {'data': {'type': 'apps', 'id': aid}}}}}
        st, r = api('POST', '/v1/appStoreVersions', body)
        if st >= 300:
            die('판을 못 만들었다(%s). 앞 판이 아직 심사 중이면 이렇게 나온다.\n%s'
                % (st, json.dumps(r)[:400]))
        v = r['data']
        print('판 %s 를 만들었다' % name)
    vid = v['id']
    print('고치는 판: %s (%s)' % (v['attributes']['versionString'], vid))

    # 1) 열한 언어의 '새로운 기능'
    # 필드를 locale 하나로 줄인다. 설명 글까지 다 받으면 응답이 커서
    # 애플 쪽에서 읽다가 끊긴다(2026-08-28 socket.timeout).
    st, r = api('GET', '/v1/appStoreVersions/%s/appStoreVersionLocalizations'
                       '?limit=50&fields[appStoreVersionLocalizations]=locale' % vid)
    ok(st, r, '로케일 목록')
    have = {x['attributes']['locale']: x['id'] for x in r['data']}
    for loc, txt in sorted(notes().items()):
        if loc in have:
            st, rr = api('PATCH', '/v1/appStoreVersionLocalizations/%s' % have[loc],
                         {'data': {'type': 'appStoreVersionLocalizations',
                                   'id': have[loc],
                                   'attributes': {'whatsNew': txt}}})
        else:
            st, rr = api('POST', '/v1/appStoreVersionLocalizations',
                         {'data': {'type': 'appStoreVersionLocalizations',
                                   'attributes': {'locale': loc, 'whatsNew': txt},
                                   'relationships': {'appStoreVersion': {
                                       'data': {'type': 'appStoreVersions', 'id': vid}}}}})
        print('  %-8s %s' % (loc, '됐다' if st < 300 else '실패 %s %s' % (st, json.dumps(rr)[:200])))

    # 2) 빌드 붙이기
    b = newest_build(aid)
    st, r = api('PATCH', '/v1/appStoreVersions/%s/relationships/build' % vid,
                {'data': {'type': 'builds', 'id': b['id']}})
    print('빌드 %s 붙이기: %s' % (b['attributes']['version'],
                              '됐다' if st < 300 else '실패 %s %s' % (st, json.dumps(r)[:300])))
    print('\n준비 끝. 낼 때는 tool/submit_next.py --submit')


def cancel(force=False):
    """심사 줄에 서 있는 판을 뺀다 — 새 빌드를 붙이려면 먼저 이걸 한다.

    2026-09-07 소유자 지시. 1.5 가 줄 서 있는 동안 급한 고침이 나왔다.
    애플은 심사에 들어간 판에 새 빌드를 못 붙인다. 제출함을 취소해 판을
    PREPARE_FOR_SUBMISSION 으로 되돌린 뒤 빌드를 갈아 끼운다.

    **줄 자리를 잃는다.** 다시 처음부터 기다린다 — 알고 하는 일이다.

    ── 그보다 훨씬 비싼 대가가 하나 더 있다 (2026-09-07에 치렀다) ──────
    제출함을 취소하면 그 안에 담긴 **모든 항목이 함께 취소된다.** 판만이
    아니다. 인앱 상품·구독까지 '개발자가 취소함'으로 떨어진다.

    그리고 되돌릴 때, 판은 API 로 다시 넣을 수 있지만 **상품은 못 넣는다.**
    reviewSubmissionItems 는 상품을 아예 받지 않고
      'inAppPurchaseV2' is not a relationship on the resource
      'reviewSubmissionItems'
    상품 전용 창구(inAppPurchaseSubmissions)도 거절한다
      'has no pending version for submission'
    애플 규칙이 '첫 구독 그룹은 새 앱 버전과 **한 제출함에** 담겨야 한다'
    이기 때문이다. 그 조립은 App Store Connect 웹 화면에서만 된다
    (상품 화면 → '심사에 추가' → 판이 담긴 초안 고르기).

    그날 원래 제출은 7개 항목이었다: 판 1 + 구독 그룹 1 + 구독 4 + 평생 1.
    API 로 다시 낸 것은 1개 항목(판만)이었고, 그대로 심사에 들어갔으면
    심사원 화면에는 값이 안 뜨는 결제 화면이 보였을 것이다.

    **그러니 상품이 걸린 판을 취소하기 전에 각오할 것:** 되돌리는 마지막
    조립은 사람이 웹 화면에서 해야 한다. 판만 있는 앱이면 상관없다.

    ── IN_REVIEW 는 값이 다르다 (2026-09-10 에 배웠다) ──────────────────

    WAITING_FOR_REVIEW 는 줄만 서 있는 것이다. 빼도 잃는 것은 줄 뒤로
    가는 몇 시간뿐이다. 그러나 IN_REVIEW 는 **심사원이 이미 열어 본 것**
    이다. 몇 시간을 기다려 얻은 자리이고, 결과가 곧 날 수도 있다.

    2026-09-10, 소유자의 "바로 해줘"만 믿고 IN_REVIEW 를 뺐다. 소유자는
    그것이 줄 서 있는 상태인 줄 알고 말한 것이었고, 직후에 "이미 리뷰
    중이면 기다리자"고 했다. 되돌릴 수 없었다.

    **IN_REVIEW 를 빼려면 --force 를 함께 친다.** 그 한 글자가 '소유자에게
    이 상태를 알리고 답을 받았다'는 뜻이다. 손이 미끄러져 쳐지지 않도록.
    """
    aid = app_id()
    st, r = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    ok(st, r, '제출함 목록')
    # 초안(READY_FOR_REVIEW)은 건드리지 않는다. 조립 중인 제출함을 여기서
    # 지워 버리면 방금 넣은 상품이 통째로 날아간다.
    live = [d for d in r['data'] if d['attributes'].get('state') in
            ('WAITING_FOR_REVIEW', 'IN_REVIEW', 'UNRESOLVED_ISSUES')]
    if not live:
        die('심사 줄에 서 있는 제출함이 없다. 뺄 것이 없다.')
    watched = [d for d in live if d['attributes'].get('state') == 'IN_REVIEW']
    if watched and not force:
        die('심사원이 이미 열어 본 판이다(IN_REVIEW). 줄만 서 있는 것과\n'
            '값이 다르다 — 빼면 그 자리가 사라지고, 결과가 곧 날 수도 있다.\n'
            '소유자에게 이 상태를 알리고 답을 받았으면 --cancel --force 로 친다.')
    for d in live:
        sid = d['id']
        was = d['attributes'].get('state')
        st, rr = api('PATCH', '/v1/reviewSubmissions/%s' % sid,
                     {'data': {'type': 'reviewSubmissions', 'id': sid,
                               'attributes': {'canceled': True}}})
        if st >= 300:
            die('제출함 %s(%s) 빼기 실패(%s): %s'
                % (sid, was, st, json.dumps(rr)[:400]))
        print('제출함 %s (%s) 를 뺐다' % (sid, was))
    print('이제 --prepare 로 글과 빌드를 갈아 끼운다.')


def tidy():
    """항목이 하나도 없는 초안만 치운다.

    2026-09-07. 제출이 중간에 죽을 때마다 빈 제출함이 하나씩 남는다.
    ASC 화면에 '제출 초안(N개)'로 뜨는데 안은 비어 있어, 다음에 조립할 때
    어느 것이 진짜인지 헷갈린다. **항목이 있는 것은 절대 건드리지 않는다.**
    """
    aid = app_id()
    st, r = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    ok(st, r, '제출함 목록')
    n = 0
    for d in r['data']:
        if d['attributes'].get('state') != 'READY_FOR_REVIEW':
            continue
        st2, it = api('GET', '/v1/reviewSubmissions/%s/items?limit=10' % d['id'])
        cnt = len(it.get('data', [])) if st2 < 300 else -1
        if cnt != 0:
            print('  %s 항목 %d개 — 그대로 둔다' % (d['id'], cnt))
            continue
        st3, rr = api('PATCH', '/v1/reviewSubmissions/%s' % d['id'],
                      {'data': {'type': 'reviewSubmissions', 'id': d['id'],
                                'attributes': {'canceled': True}}})
        print('  %s 빈 초안 %s' % (d['id'],
                                '치웠다' if st3 < 300 else '실패 %s' % st3))
        n += 1
    print('빈 초안 %d개 처리.' % n)


def iaps_report():
    """인앱 상품과 제출함의 지금 상태를 그대로 찍는다 — 짐작하지 않기 위해.

    2026-09-07. 1.5 를 뺐다가 다시 내는 길에 상품 제출이 409 로 막혔다
    ('has no pending version for submission'). 상태를 눈으로 봐야 다음
    수를 정할 수 있어 진단 창구를 둔다.
    """
    aid = app_id()
    print('== 일회성 상품 ==')
    st, r = api('GET', '/v1/apps/%s/inAppPurchasesV2?limit=200' % aid)
    ok(st, r, '상품 목록')
    for d in r.get('data', []):
        a2 = d['attributes']
        print('  %-46s %-18s %s' % (a2.get('productId'), a2.get('state'), d['id']))
    print('== 구독 ==')
    st, g = api('GET', '/v1/apps/%s/subscriptionGroups?limit=50' % aid)
    ok(st, g, '구독 묶음')
    for grp in g.get('data', []):
        st2, s2 = api('GET',
                      '/v1/subscriptionGroups/%s/subscriptions?limit=50' % grp['id'])
        if st2 >= 300:
            continue
        for x in s2.get('data', []):
            a3 = x['attributes']
            print('  %-46s %-18s %s' % (a3.get('productId'), a3.get('state'), x['id']))
    print('== 제출함 ==')
    st, rs = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    ok(st, rs, '제출함')
    for d in rs.get('data', []):
        print('  %-22s %s' % (d['attributes'].get('state'), d['id']))


def iap_probe():
    """상품을 어느 창구로 내야 하는지 실제로 찔러 보고 응답을 그대로 찍는다.

    2026-09-07. inAppPurchaseSubmissions 가 409
    'has no pending version for submission' 로 막혔다. 문서만 보고
    고치면 또 헛손질이라, 후보 창구를 하나씩 시험해 응답을 남긴다.
    아무것도 바꾸지 않는 시험은 없다 — 성공하면 실제로 제출된다.
    """
    aid = app_id()
    st, rs = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    ok(st, rs, '제출함')
    sub = None
    for d in rs['data']:
        if d['attributes'].get('state') == 'READY_FOR_REVIEW':
            sub = d['id']
    print('쓸 제출함: %s' % sub)

    st, r = api('GET', '/v1/apps/%s/inAppPurchasesV2?limit=200' % aid)
    ok(st, r, '상품')
    iap = r['data'][0]
    iid = iap['id']
    print('시험 상품: %s (%s)' % (iap['attributes'].get('productId'), iid))

    print('\n[A] 상품의 하위 자원 살펴보기')
    for sp in ('inAppPurchaseLocalizations', 'iapPriceSchedule',
               'appStoreReviewScreenshot', 'promotedPurchase'):
        st2, r2 = api('GET', '/v2/inAppPurchases/%s/%s' % (iid, sp))
        d2 = r2.get('data')
        n = len(d2) if isinstance(d2, list) else (1 if d2 else 0)
        print('  %-28s %s (%s개)' % (sp, st2, n))

    if sub:
        print('\n[B] reviewSubmissionItems 에 inAppPurchaseV2 로 넣어 보기')
        st3, r3 = api('POST', '/v1/reviewSubmissionItems',
                      {'data': {'type': 'reviewSubmissionItems',
                                'relationships': {
                                    'reviewSubmission': {'data': {
                                        'type': 'reviewSubmissions', 'id': sub}},
                                    'inAppPurchaseV2': {'data': {
                                        'type': 'inAppPurchases', 'id': iid}}}}})
        print('  %s %s' % (st3, json.dumps(r3, ensure_ascii=False)[:600]))


def why():
    """판이 왜 심사에 못 들어가는지 애플 응답을 잘리지 않게 통째로 찍는다.

    2026-09-07. 항목 넣기가 409 STATE_ERROR 로 막혔고, 진짜 이유는
    meta.associatedErrors 안에 있었는데 300자에서 잘려 안 보였다.
    잘린 로그로 고치려 들면 헛손질만 는다.
    """
    aid = app_id()
    v = editable(aid)
    if v is None:
        die('손에 잡히는 판이 없다.')
    vid = v['id']
    print('판 %s (%s) %s' % (v['attributes']['versionString'],
                            v['attributes']['appStoreState'], vid))

    # 빈 제출함을 치운다 — 항목 없는 제출함이 쌓이면 다음 제출이 헷갈린다.
    st, rs = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    ok(st, rs, '제출함')
    for d in rs['data']:
        if d['attributes'].get('state') != 'READY_FOR_REVIEW':
            continue
        st2, it = api('GET', '/v1/reviewSubmissions/%s/items?limit=10' % d['id'])
        n = len(it.get('data', [])) if st2 < 300 else -1
        print('  제출함 %s 항목 %s개' % (d['id'], n))
        if n == 0:
            api('PATCH', '/v1/reviewSubmissions/%s' % d['id'],
                {'data': {'type': 'reviewSubmissions', 'id': d['id'],
                          'attributes': {'canceled': True}}})
            print('    → 비어 있어 치웠다')

    print('\n새 제출함을 만들고 판을 넣어 본다 (응답 전체):')
    st, r = api('POST', '/v1/reviewSubmissions',
                {'data': {'type': 'reviewSubmissions',
                          'attributes': {'platform': 'IOS'},
                          'relationships': {'app': {'data': {
                              'type': 'apps', 'id': aid}}}}})
    if st >= 300:
        print(json.dumps(r, ensure_ascii=False, indent=2)[:3000]); return
    sub = r['data']['id']
    st, r = api('POST', '/v1/reviewSubmissionItems',
                {'data': {'type': 'reviewSubmissionItems',
                          'relationships': {
                              'reviewSubmission': {'data': {
                                  'type': 'reviewSubmissions', 'id': sub}},
                              'appStoreVersion': {'data': {
                                  'type': 'appStoreVersions', 'id': vid}}}}})
    print('상태 %s' % st)
    print(json.dumps(r, ensure_ascii=False, indent=2)[:4000])


def pending_iaps(aid):
    """아직 한 번도 심사를 안 거친 인앱 상품.

    2026-09-02 신설. 프리미엄을 켜면서 상품 다섯을 처음 내보내는데,
    **판만 내고 상품을 안 내면** 심사원 손에 값이 안 뜨는 앱이 간다.
    그건 2.1(되지 않는 기능)로 반려되는 지름길이다.

    이미 승인된 상품은 다시 넣지 않는다 — 넣으면 제출함이 거부한다.
    그래서 READY_TO_SUBMIT 인 것만 고른다.

    돌려주는 것: (제출 창구, 관계 이름, 타입, id, 상품 이름) 목록.

    **인앱 상품은 판과 같은 제출함(reviewSubmissionItems)에 못 넣는다.**
    2026-09-02에 넣어 봤다가 409 로 거절당했다 —
      'inAppPurchaseV2' is not a relationship on the resource
      'reviewSubmissionItems'
    애플은 상품마다 따로 창구를 둔다: 일회성은 inAppPurchaseSubmissions,
    구독은 subscriptionSubmissions. 판 제출과 나란히 부르면 된다.
    """
    out = []
    st, r = api('GET', '/v1/apps/%s/inAppPurchasesV2?limit=200' % aid)
    if st < 300:
        for d in r.get('data', []):
            if d['attributes'].get('state') == 'READY_TO_SUBMIT':
                out.append(('inAppPurchaseSubmissions', 'inAppPurchaseV2',
                            'inAppPurchases', d['id'],
                            d['attributes'].get('productId')))
    st, g = api('GET', '/v1/apps/%s/subscriptionGroups?limit=50' % aid)
    if st < 300:
        for grp in g.get('data', []):
            st2, s2 = api('GET',
                          '/v1/subscriptionGroups/%s/subscriptions?limit=50' % grp['id'])
            if st2 >= 300:
                continue
            for x in s2.get('data', []):
                if x['attributes'].get('state') == 'READY_TO_SUBMIT':
                    out.append(('subscriptionSubmissions', 'subscription',
                                'subscriptions', x['id'],
                                x['attributes'].get('productId')))
    return out


def submit():
    aid = app_id()
    v = editable(aid)
    if v is None:
        die('낼 판이 없다. 먼저 --prepare.')
    vid = v['id']
    name = v['attributes']['versionString']
    # 열려 있는 제출함을 먼저 찾는다 — **새로 만들기보다 이것이 먼저다.**
    #
    # 2026-09-07 사고. 제출이 인앱 상품 단계에서 죽으면 제출함은 이미
    # 만들어져 있고 판도 그 안에 담겨 있다. 그 상태에서 다시 --submit 하면
    # 새 제출함을 만들고 판을 또 넣으려 들어 409 로 막힌다
    # (ITEM_PART_OF_ANOTHER_SUBMISSION). 애플이 옳다 — 판은 한 제출함에만
    # 담긴다. 그러니 있는 것을 쓰고, 없을 때만 만든다.
    #
    # 고르는 순서가 중요하다. 빈 제출함을 집으면 판을 새로 넣어야 하는데,
    # 판이 이미 다른(항목 있는) 제출함에 담겨 있으면 또 409 다. 그래서
    # **항목이 있는 제출함을 먼저** 고르고, 남은 빈 것은 치운다.
    sub, has_item = None, False
    st, rs = api('GET', '/v1/apps/%s/reviewSubmissions?limit=20' % aid)
    opens = []
    if st < 300:
        for d in rs.get('data', []):
            if d['attributes'].get('state') != 'READY_FOR_REVIEW':
                continue
            st2, it = api('GET', '/v1/reviewSubmissions/%s/items?limit=10' % d['id'])
            opens.append((d['id'], len(it.get('data', [])) if st2 < 300 else 0))
    filled = [x for x in opens if x[1] > 0]
    if filled:
        sub, n = filled[0]
        has_item = True
        print('열려 있던 제출함을 쓴다: %s (항목 %d개)' % (sub, n))
    elif opens:
        sub, n = opens[0]
        print('비어 있던 제출함을 쓴다: %s' % sub)
    for sid, n in opens:
        if sid != sub and n == 0:
            api('PATCH', '/v1/reviewSubmissions/%s' % sid,
                {'data': {'type': 'reviewSubmissions', 'id': sid,
                          'attributes': {'canceled': True}}})
            print('빈 제출함 %s 치웠다' % sid)
    if sub is None:
        st, r = api('POST', '/v1/reviewSubmissions',
                    {'data': {'type': 'reviewSubmissions',
                              'attributes': {'platform': 'IOS'},
                              'relationships': {'app': {'data': {
                                  'type': 'apps', 'id': aid}}}}})
        if st >= 300:
            die('제출함을 못 만들었다(%s): %s' % (st, json.dumps(r)[:400]))
        sub = r['data']['id']
        print('제출함을 만들었다: %s' % sub)
    if not has_item:
        st, r = api('POST', '/v1/reviewSubmissionItems',
                    {'data': {'type': 'reviewSubmissionItems',
                              'relationships': {
                                  'reviewSubmission': {'data': {
                                      'type': 'reviewSubmissions', 'id': sub}},
                                  'appStoreVersion': {'data': {
                                      'type': 'appStoreVersions', 'id': vid}}}}})
        if st >= 300:
            die('판을 제출함에 못 넣었다(%s): %s'
                % (st, json.dumps(r, ensure_ascii=False)[:1200]))
        print('판을 제출함에 넣었다')

    # 인앱 상품도 같은 제출함에 넣는다. 판만 내면 심사원 손에는 값이 안
    # 뜨는 앱이 간다 — 그 상태로 '결제가 안 된다'고 반려된다.
    iaps = pending_iaps(aid)
    if iaps:
        print('처음 내는 인앱 상품 %d개를 각자 창구로 낸다:' % len(iaps))
        skipped = []
        for endpoint, rel, typ, iid, pid in iaps:
            st, r = api('POST', '/v1/%s' % endpoint,
                        {'data': {'type': endpoint,
                                  'relationships': {
                                      rel: {'data': {'type': typ, 'id': iid}}}}})
            if st >= 300:
                blob = json.dumps(r, ensure_ascii=False)
                # 애플이 '이 상품은 따로 낼 대기 버전이 없다'고 답하는 경우.
                #
                # 2026-09-07: 다섯 상품이 모두 READY_TO_SUBMIT 이고 설명·가격·
                # 심사용 그림까지 다 채워져 있는데도 이 답이 왔다. 확인해 보니
                # 5일 전 1.5 가 심사 줄에 섰을 때도 상품은 같은 상태였다 —
                # 즉 이건 오늘 생긴 일이 아니라 원래 그대로다.
                #
                # 그래서 여기서 판 제출을 막지 않는다. 막으면 급한 고침이
                # 스토어로 못 간다. 대신 건너뛴 것을 끝에 크게 남겨서,
                # 사람이 ASC 화면에서 상품 상태를 반드시 눈으로 보게 한다.
                if 'no pending version for submission' in blob:
                    print('  %s 건너뜀 — 애플: 따로 낼 대기 버전이 없다' % pid)
                    skipped.append(pid)
                    continue
                # 그 밖의 실패는 그대로 멈춘다. 돈이 걸린 자리에서
                # '경고 찍고 계속'은 대개 제일 나쁜 선택이다.
                die('  %s 내기 실패(%s): %s' % (pid, st, blob[:400]))
            print('  %s 냈다' % pid)
        if skipped:
            print('\n※ 상품 %d개를 못 냈다: %s' % (len(skipped), ', '.join(skipped)))
            print('  판은 그대로 낸다. ASC 화면에서 상품 심사 상태를 꼭 확인할 것.')

    st, r = api('PATCH', '/v1/reviewSubmissions/%s' % sub,
                {'data': {'type': 'reviewSubmissions', 'id': sub,
                          'attributes': {'submitted': True}}})
    if st >= 300:
        die('제출 실패(%s): %s' % (st, json.dumps(r)[:500]))
    print('%s 를 심사에 냈다. 확인: python3 tool/review_status.py skyblue' % name)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--iaps', action='store_true')
    ap.add_argument('--iapprobe', action='store_true')
    ap.add_argument('--why', action='store_true')
    ap.add_argument('--tidy', action='store_true')
    ap.add_argument('--cancel', action='store_true')
    ap.add_argument('--force', action='store_true',
                    help='IN_REVIEW(심사원이 보고 있는) 판까지 뺀다 — '
                         '소유자에게 물어보고 답을 받았을 때만')
    ap.add_argument('--prepare', action='store_true')
    ap.add_argument('--submit', action='store_true')
    a = ap.parse_args()
    if a.iaps:
        iaps_report()
    elif a.iapprobe:
        iap_probe()
    elif a.why:
        why()
    elif a.tidy:
        tidy()
    elif a.cancel:
        cancel(force=a.force)
    elif a.prepare:
        prepare()
    elif a.submit:
        submit()
    else:
        show()
