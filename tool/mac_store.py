#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""맥 앱스토어 판 — 만들고, 글을 붙이고, 빌드를 붙이고, 낸다.

2026-09-13 신설. 소유자 신고 "맥 앱스토어에 맥용 앱이 없더라"에서 시작했다.
아이폰 쪽(tool/submit_next.py)과 같은 생김새다. 다른 것은 platform 이
MAC_OS 라는 것, 그리고 **같은 앱 기록에 macOS 판을 처음 만든다**는 것이다 —
같은 기록이어야 아이폰에서 산 사람이 맥에서 공짜로 받는다(유니버설 구매).

  python3 tool/mac_store.py                 # 지금 어떤 상태인지만 본다
  python3 tool/mac_store.py --prepare       # 판을 만들고 글·그림·빌드를 붙인다
  python3 tool/mac_store.py --submit        # 준비된 판을 심사에 낸다

**--submit 은 소유자가 말했을 때만 친다.**

글의 출처:
  · 소개말·키워드·홍보 문구 — store/mac/<locale>/ 에 있으면 그것, 없으면 store/ios/<locale>/
  · 새로운 기능 — store/mac/<locale>/release_notes.txt (맥은 따로 쓴다)
  · 지원 주소·마케팅 주소·저작권·심사 연락처 — 지금 팔리고 있는 아이폰 판에서 베낀다
  · 스크린샷 — store/screenshots/mac/<locale>/*.png (없는 언어는 애플이 기본 언어 것을 보여 준다)

빌드는 tool/appstore_mac.sh 가 올린다. 여기서는 올라온 것 중 가장 큰 번호를 붙인다.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.request

for _cand in (os.environ.get('SKY_SECRETS_HOME'), os.path.expanduser('~'),
              '/Users/ziririt'):
    if _cand and os.path.isdir(os.path.join(_cand, '.appstoreconnect')):
        sys.path.insert(0, os.path.join(_cand, '.appstoreconnect'))
        break
try:
    from asc import api as _raw_api
except Exception as e:  # noqa: BLE001
    print('열쇠 꾸러미를 못 읽었다(.appstoreconnect): %s' % e)
    raise SystemExit(2)

BUNDLE = 'com.ziririt.simpletext'
PLATFORM = 'MAC_OS'
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IOS = os.path.join(HERE, 'store', 'ios')
MAC = os.path.join(HERE, 'store', 'mac')
SHOTS = os.path.join(HERE, 'store', 'screenshots', 'mac')
FIELDS = {'description': 'description.txt', 'keywords': 'keywords.txt',
          'promotionalText': 'promotional_text.txt'}


def api(method, path, body=None, tries=4):
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


def die(msg):
    print(msg)
    raise SystemExit(1)


def ok(st, r, what):
    if st >= 300:
        die('%s 실패(%s): %s' % (what, st, json.dumps(r, ensure_ascii=False)[:600]))
    return r


def repo_version():
    with open(os.path.join(HERE, 'lib', 'version.dart'), encoding='utf-8') as f:
        m = re.search(r"appVersion\s*=\s*'([^']+)'", f.read())
    return m.group(1) if m else die('lib/version.dart 에서 appVersion 을 못 읽었다')


def app_id():
    st, r = api('GET', '/v1/apps?filter[bundleId]=%s' % BUNDLE)
    ok(st, r, '앱 찾기')
    if not r.get('data'):
        die('앱을 못 찾았다: %s' % BUNDLE)
    return r['data'][0]['id']


def versions(aid, platform):
    st, r = api('GET', '/v1/apps/%s/appStoreVersions?filter[platform]=%s&limit=10'
                % (aid, platform))
    ok(st, r, '판 목록')
    return r.get('data', [])


def mac_builds(aid):
    st, r = api('GET', '/v1/builds?filter[app]=%s&filter[preReleaseVersion.platform]=%s'
                       '&sort=-uploadedDate&limit=10' % (aid, PLATFORM))
    ok(st, r, '맥 빌드 목록')
    return r.get('data', [])


def read(loc, fname):
    for base in (MAC, IOS):
        p = os.path.join(base, loc, fname)
        if os.path.isfile(p):
            with open(p, encoding='utf-8') as f:
                t = f.read().strip()
            if t:
                return t
    return None


def locales():
    return sorted(d for d in os.listdir(IOS) if os.path.isdir(os.path.join(IOS, d)))


# ---------------------------------------------------------------- 보기
def show():
    aid = app_id()
    vs = versions(aid, PLATFORM)
    print('맥 판:')
    if not vs:
        print('  (없다 — 아직 macOS 판을 만든 적이 없다)')
    for v in vs:
        a = v['attributes']
        print('  %-8s %s' % (a['versionString'], a.get('appStoreState')))
    bs = mac_builds(aid)
    print('맥 빌드:')
    if not bs:
        print('  (없다 — tool/appstore_mac.sh 로 올린다)')
    for b in bs[:5]:
        a = b['attributes']
        print('  %-6s %s  %s' % (a['version'], a.get('processingState'),
                                (a.get('uploadedDate') or '')[:16]))


# ---------------------------------------------------------------- 준비
def live_ios(aid):
    """지금 팔리는 아이폰 판 — 베낄 것들의 출처."""
    for v in versions(aid, 'IOS'):
        if v['attributes'].get('appStoreState') == 'READY_FOR_SALE':
            return v
    return versions(aid, 'IOS')[0] if versions(aid, 'IOS') else None


def ios_localizations(vid):
    st, r = api('GET', '/v1/appStoreVersions/%s/appStoreVersionLocalizations?limit=50'
                       '&fields[appStoreVersionLocalizations]=locale,supportUrl,marketingUrl' % vid)
    ok(st, r, '아이폰 로케일')
    return {x['attributes']['locale']: x['attributes'] for x in r['data']}


def ensure_version(aid):
    name = repo_version()
    for v in versions(aid, PLATFORM):
        if v['attributes'].get('appStoreState') in (
                'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED',
                'DEVELOPER_REJECTED', 'READY_FOR_REVIEW', 'WAITING_FOR_REVIEW'):
            print('있는 맥 판을 쓴다: %s (%s)' % (v['attributes']['versionString'],
                                            v['attributes']['appStoreState']))
            return v
    ios = live_ios(aid)
    attrs = {'platform': PLATFORM, 'versionString': name, 'releaseType': 'AFTER_APPROVAL'}
    if ios and ios['attributes'].get('copyright'):
        attrs['copyright'] = ios['attributes']['copyright']
    st, r = api('POST', '/v1/appStoreVersions',
                {'data': {'type': 'appStoreVersions', 'attributes': attrs,
                          'relationships': {'app': {'data': {'type': 'apps', 'id': aid}}}}})
    ok(st, r, '맥 판 만들기')
    print('맥 판 %s 를 만들었다 — 이 앱 기록에 macOS 가 처음 붙었다' % name)
    return r['data']


def fill_texts(vid, ios_locs):
    st, r = api('GET', '/v1/appStoreVersions/%s/appStoreVersionLocalizations'
                       '?limit=50&fields[appStoreVersionLocalizations]=locale' % vid)
    ok(st, r, '맥 로케일 목록')
    have = {x['attributes']['locale']: x['id'] for x in r['data']}
    out = {}
    for loc in locales():
        attrs = {}
        for k, fname in FIELDS.items():
            t = read(loc, fname)
            if t:
                attrs[k] = t
        wn = None
        p = os.path.join(MAC, loc, 'release_notes.txt')
        if os.path.isfile(p):
            with open(p, encoding='utf-8') as f:
                wn = f.read().strip()
        if wn:
            attrs['whatsNew'] = wn
        src = ios_locs.get(loc) or ios_locs.get('en-US') or {}
        for k in ('supportUrl', 'marketingUrl'):
            if src.get(k):
                attrs[k] = src[k]
        def send(attrs):
            if loc in have:
                st, rr = api('PATCH', '/v1/appStoreVersionLocalizations/%s' % have[loc],
                             {'data': {'type': 'appStoreVersionLocalizations',
                                       'id': have[loc], 'attributes': attrs}})
                return st, rr, have[loc]
            st, rr = api('POST', '/v1/appStoreVersionLocalizations',
                         {'data': {'type': 'appStoreVersionLocalizations',
                                   'attributes': dict(attrs, locale=loc),
                                   'relationships': {'appStoreVersion': {
                                       'data': {'type': 'appStoreVersions', 'id': vid}}}}})
            return st, rr, (rr.get('data', {}).get('id') if st < 300 else None)

        st, rr, lid = send(attrs)
        # 어느 플랫폼이든 **첫 판에는 '새로운 기능'이 없다** — 애플이 409 로 막는다
        # (2026-09-13 실측: "Attribute 'whatsNew' cannot be edited at this time").
        # 그때는 그 칸만 빼고 다시 보낸다. 두 번째 맥 판부터는 들어간다.
        if st == 409 and 'whatsNew' in json.dumps(rr) and 'whatsNew' in attrs:
            attrs.pop('whatsNew')
            st, rr, lid = send(attrs)
            note = ' (첫 판이라 새로운 기능은 뺐다)'
        else:
            note = ''
        print('  글 %-8s %s%s' % (loc, '됐다' if st < 300 else '실패 %s %s'
                                 % (st, json.dumps(rr, ensure_ascii=False)[:300]), note))
        if lid:
            out[loc] = lid
    return out


def copy_review_detail(vid, ios_vid):
    st, r = api('GET', '/v1/appStoreVersions/%s/appStoreReviewDetail' % ios_vid)
    if st >= 300 or not r.get('data'):
        print('  심사 연락처: 아이폰 판에 없다 — 건너뛴다')
        return
    a = r['data']['attributes']
    keep = {k: v for k, v in a.items() if v not in (None, '')}
    st, r2 = api('GET', '/v1/appStoreVersions/%s/appStoreReviewDetail' % vid)
    if st < 300 and r2.get('data'):
        st, r3 = api('PATCH', '/v1/appStoreReviewDetails/%s' % r2['data']['id'],
                     {'data': {'type': 'appStoreReviewDetails', 'id': r2['data']['id'],
                               'attributes': keep}})
    else:
        st, r3 = api('POST', '/v1/appStoreReviewDetails',
                     {'data': {'type': 'appStoreReviewDetails', 'attributes': keep,
                               'relationships': {'appStoreVersion': {
                                   'data': {'type': 'appStoreVersions', 'id': vid}}}}})
    print('  심사 연락처: %s' % ('아이폰 판에서 베꼈다' if st < 300 else
                            '실패 %s %s' % (st, json.dumps(r3, ensure_ascii=False)[:300])))


def attach_build(aid, vid):
    bs = [b for b in mac_builds(aid) if b['attributes'].get('processingState') == 'VALID']
    if not bs:
        print('  빌드: 붙일 것이 없다(아직 처리 중이거나 안 올렸다)')
        return
    b = max(bs, key=lambda x: int(x['attributes']['version']))
    st, r = api('PATCH', '/v1/appStoreVersions/%s/relationships/build' % vid,
                {'data': {'type': 'builds', 'id': b['id']}})
    print('  빌드 %s 붙이기: %s' % (b['attributes']['version'], '됐다' if st < 300 else
                                 '실패 %s %s' % (st, json.dumps(r, ensure_ascii=False)[:300])))


# ---------------------------------------------------------------- 그림
def _put(url, data, headers):
    req = urllib.request.Request(url, data=data, method='PUT')
    for h in headers or []:
        req.add_header(h['name'], h['value'])
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.status


def upload_shots(loc_ids):
    if not os.path.isdir(SHOTS):
        print('  그림: store/screenshots/mac 이 없다 — 건너뛴다')
        return
    for loc, lid in sorted(loc_ids.items()):
        d = os.path.join(SHOTS, loc)
        files = sorted(f for f in os.listdir(d)) if os.path.isdir(d) else []
        files = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        if not files:
            continue
        st, r = api('GET', '/v1/appStoreVersionLocalizations/%s/appScreenshotSets'
                           '?include=appScreenshots' % lid)
        ok(st, r, '그림 묶음')
        sid = None
        for s in r.get('data', []):
            if s['attributes'].get('screenshotDisplayType') == 'APP_DESKTOP':
                sid = s['id']
                n = len((s.get('relationships', {}).get('appScreenshots', {}) or {}).get('data', []))
                if n:
                    print('  그림 %-8s 이미 %d장 있다 — 건너뛴다' % (loc, n))
                    sid = 'skip'
                break
        if sid == 'skip':
            continue
        if sid is None:
            st, r = api('POST', '/v1/appScreenshotSets',
                        {'data': {'type': 'appScreenshotSets',
                                  'attributes': {'screenshotDisplayType': 'APP_DESKTOP'},
                                  'relationships': {'appStoreVersionLocalization': {
                                      'data': {'type': 'appStoreVersionLocalizations', 'id': lid}}}}})
            ok(st, r, '그림 묶음 만들기')
            sid = r['data']['id']
        for f in files:
            p = os.path.join(d, f)
            with open(p, 'rb') as fh:
                blob = fh.read()
            st, r = api('POST', '/v1/appScreenshots',
                        {'data': {'type': 'appScreenshots',
                                  'attributes': {'fileName': f, 'fileSize': len(blob)},
                                  'relationships': {'appScreenshotSet': {
                                      'data': {'type': 'appScreenshotSets', 'id': sid}}}}})
            ok(st, r, '그림 자리 잡기')
            shot = r['data']
            for op in shot['attributes'].get('uploadOperations') or []:
                off, ln = op['offset'], op['length']
                _put(op['url'], blob[off:off + ln], op.get('requestHeaders'))
            st, r = api('PATCH', '/v1/appScreenshots/%s' % shot['id'],
                        {'data': {'type': 'appScreenshots', 'id': shot['id'],
                                  'attributes': {'uploaded': True,
                                                 'sourceFileChecksum': hashlib.md5(blob).hexdigest()}}})
            print('  그림 %-8s %s %s' % (loc, f, '올렸다' if st < 300 else '실패 %s' % st))


def prepare():
    aid = app_id()
    v = ensure_version(aid)
    vid = v['id']
    ios = live_ios(aid)
    ios_locs = ios_localizations(ios['id']) if ios else {}
    loc_ids = fill_texts(vid, ios_locs)
    if ios:
        copy_review_detail(vid, ios['id'])
    upload_shots(loc_ids)
    attach_build(aid, vid)
    print('\n준비 끝. 낼 때는 tool/mac_store.py --submit')


# ---------------------------------------------------------------- 제출
def submit():
    aid = app_id()
    v = None
    for x in versions(aid, PLATFORM):
        if x['attributes'].get('appStoreState') in (
                'PREPARE_FOR_SUBMISSION', 'REJECTED', 'METADATA_REJECTED', 'DEVELOPER_REJECTED'):
            v = x
            break
    if v is None:
        die('낼 맥 판이 없다. 먼저 --prepare.')
    vid, name = v['id'], v['attributes']['versionString']
    st, r = api('POST', '/v1/reviewSubmissions',
                {'data': {'type': 'reviewSubmissions', 'attributes': {'platform': PLATFORM},
                          'relationships': {'app': {'data': {'type': 'apps', 'id': aid}}}}})
    ok(st, r, '제출함 만들기')
    sub = r['data']['id']
    st, r = api('POST', '/v1/reviewSubmissionItems',
                {'data': {'type': 'reviewSubmissionItems',
                          'relationships': {
                              'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': sub}},
                              'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}}}})
    ok(st, r, '판을 제출함에 넣기')
    st, r = api('PATCH', '/v1/reviewSubmissions/%s' % sub,
                {'data': {'type': 'reviewSubmissions', 'id': sub, 'attributes': {'submitted': True}}})
    ok(st, r, '제출')
    print('맥 %s 를 심사에 냈다.' % name)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--prepare', action='store_true')
    ap.add_argument('--submit', action='store_true')
    a = ap.parse_args()
    if a.submit:
        submit()
    elif a.prepare:
        prepare()
    else:
        show()
