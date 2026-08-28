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

sys.path.insert(0, os.path.expanduser('~/.appstoreconnect'))
try:
    from asc import api
except Exception as e:  # noqa: BLE001
    print('열쇠 꾸러미를 못 읽었다(~/.appstoreconnect): %s' % e)
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


def editable(aid):
    """지금 고칠 수 있는 판. 없으면 None."""
    for v in versions(aid):
        if v['attributes'].get('appStoreState') in (
                'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED',
                'DEVELOPER_REJECTED'):
            return v
    return None


def prepare():
    aid = app_id()
    vs = versions(aid)
    v = editable(aid)
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


def submit():
    aid = app_id()
    v = editable(aid)
    if v is None:
        die('낼 판이 없다. 먼저 --prepare.')
    vid = v['id']
    name = v['attributes']['versionString']
    st, r = api('POST', '/v1/reviewSubmissions',
                {'data': {'type': 'reviewSubmissions',
                          'attributes': {'platform': 'IOS'},
                          'relationships': {'app': {'data': {'type': 'apps', 'id': aid}}}}})
    if st >= 300:
        # 이미 열려 있는 제출함이 있으면 그것을 쓴다.
        st2, r2 = api('GET', '/v1/apps/%s/reviewSubmissions?filter[state]=READY_FOR_REVIEW,'
                             'WAITING_FOR_REVIEW,IN_REVIEW&limit=1' % aid)
        if st2 < 300 and r2.get('data'):
            r = {'data': r2['data'][0]}
            print('열려 있던 제출함을 쓴다')
        else:
            die('제출함을 못 만들었다(%s): %s' % (st, json.dumps(r)[:400]))
    sub = r['data']['id']
    st, r = api('POST', '/v1/reviewSubmissionItems',
                {'data': {'type': 'reviewSubmissionItems',
                          'relationships': {
                              'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': sub}},
                              'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}}}})
    if st >= 300:
        print('항목 넣기 경고(%s): %s' % (st, json.dumps(r)[:300]))
    st, r = api('PATCH', '/v1/reviewSubmissions/%s' % sub,
                {'data': {'type': 'reviewSubmissions', 'id': sub,
                          'attributes': {'submitted': True}}})
    if st >= 300:
        die('제출 실패(%s): %s' % (st, json.dumps(r)[:500]))
    print('%s 를 심사에 냈다. 확인: python3 tool/review_status.py skyblue' % name)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--prepare', action='store_true')
    ap.add_argument('--submit', action='store_true')
    a = ap.parse_args()
    if a.prepare:
        prepare()
    elif a.submit:
        submit()
    else:
        show()
