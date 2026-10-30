"""Validasi struktural berkas quest FTB Quests (SNBT) untuk pack ini.

Bukan generator: skrip ini membaca apa yang ada di disk dan gagal bila
skema/konten tidak sesuai kontrak Task 11.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QDIR = ROOT / 'pack' / 'overrides' / 'config' / 'ftbquests' / 'quests'

CHAPTERS = [
    ('hari_pertama', 'Hari Pertama'),
    ('dingin', 'Dingin'),
    ('haus', 'Haus'),
    ('senjata', 'Senjata'),
    ('malam_ke_10', 'Malam ke-10'),
    ('benteng', 'Benteng'),
    ('mutasi', 'Mutasi'),
]

ID_RE = re.compile(r'^[0-9A-F]{16}$')
TASK_TYPES = {'item', 'kill', 'dimension', 'checkmark'}
REWARD_TYPES = {'item', 'xp'}
FOOD = {'minecraft:cooked_beef', 'minecraft:bread', 'minecraft:cooked_porkchop',
        'minecraft:cooked_mutton', 'minecraft:baked_potato'}


class SnbtError(ValueError):
    pass


def tokenize(text):
    tokens = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in ' \t\r\n,':
            i += 1
        elif c in '{}[]:':
            tokens.append(c)
            i += 1
        elif c == '"':
            i += 1
            buf = []
            while True:
                if i >= n:
                    raise SnbtError('unterminated string')
                ch = text[i]
                if ch == '\\':
                    nxt = text[i + 1] if i + 1 < n else ''
                    buf.append({'n': '\n', 't': '\t', 'r': '\r'}.get(nxt, nxt))
                    i += 2
                    continue
                if ch == '"':
                    i += 1
                    break
                buf.append(ch)
                i += 1
            tokens.append(('str', ''.join(buf)))
        else:
            j = i
            while j < n and text[j] not in ' \t\r\n,{}[]:"':
                j += 1
            if j == i:
                raise SnbtError('unexpected character %r' % c)
            tokens.append(('atom', text[i:j]))
            i = j
    return tokens


def parse_atom(text):
    low = text.lower()
    if low == 'true':
        return True
    if low == 'false':
        return False
    if low == 'null':
        return None
    if re.fullmatch(r'-?\d+', text):
        return int(text)
    if re.fullmatch(r'-?\d+[bBsSlL]', text):
        return int(text[:-1])
    if re.fullmatch(r'-?(\d+\.\d*|\.\d+|\d+)([eE][+-]?\d+)?[fFdD]?', text):
        return float(re.sub(r'[fFdD]$', '', text))
    raise SnbtError('bad atom %r' % text)


class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.i = 0

    def peek(self):
        return self.tokens[self.i] if self.i < len(self.tokens) else None

    def take(self):
        if self.i >= len(self.tokens):
            raise SnbtError('unexpected end of input')
        self.i += 1
        return self.tokens[self.i - 1]

    def value(self):
        tok = self.peek()
        if tok == '{':
            return self.compound()
        if tok == '[':
            return self.list()
        tok = self.take()
        if isinstance(tok, tuple) and tok[0] == 'str':
            return tok[1]
        if isinstance(tok, tuple) and tok[0] == 'atom':
            return parse_atom(tok[1])
        raise SnbtError('unexpected token %r' % (tok,))

    def key(self):
        tok = self.take()
        if isinstance(tok, tuple) and tok[0] in ('str', 'atom'):
            return tok[1]
        raise SnbtError('expected key, got %r' % (tok,))

    def compound(self):
        self.take()
        out = {}
        while self.peek() != '}':
            k = self.key()
            if self.take() != ':':
                raise SnbtError('expected ":" after key %r' % k)
            if k in out:
                raise SnbtError('duplicate key %r' % k)
            out[k] = self.value()
        self.take()
        return out

    def list(self):
        self.take()
        out = []
        while self.peek() != ']':
            out.append(self.value())
        self.take()
        return out

    def parse(self):
        v = self.value()
        if self.i != len(self.tokens):
            raise SnbtError('trailing tokens')
        return v


def load(path):
    return Parser(tokenize(path.read_text(encoding='utf-8'))).parse()


def main():
    errors = []
    seen_ids = {}
    quest_total = 0
    type_counts = {t: 0 for t in TASK_TYPES}
    reward_items = []
    quests_by_id = {}

    data_file = QDIR / 'data.snbt'
    if not data_file.exists():
        errors.append('data.snbt tidak ada')
    else:
        data = load(data_file)
        if data.get('version') != 13:
            errors.append('data.snbt: version harus 13, dapat %r' % data.get('version'))
        if data.get('progression_mode') not in ('linear', 'flexible'):
            errors.append('data.snbt: progression_mode tidak valid')

    chap_dir = QDIR / 'chapters'
    files = sorted(chap_dir.glob('*.snbt')) if chap_dir.exists() else []
    if len(files) != len(CHAPTERS):
        errors.append('jumlah chapter %d, harus %d' % (len(files), len(CHAPTERS)))

    for order, (stem, title) in enumerate(CHAPTERS):
        path = chap_dir / (stem + '.snbt')
        if not path.exists():
            errors.append('chapter hilang: %s' % path.name)
            continue
        try:
            ch = load(path)
        except SnbtError as exc:
            errors.append('%s: SNBT tidak valid: %s' % (path.name, exc))
            continue

        if ch.get('title') != title:
            errors.append('%s: title %r, harus %r' % (path.name, ch.get('title'), title))
        if ch.get('filename') != stem:
            errors.append('%s: filename %r, harus %r' % (path.name, ch.get('filename'), stem))
        if ch.get('order_index') != order:
            errors.append('%s: order_index %r, harus %d' % (path.name, ch.get('order_index'), order))
        if ch.get('group') != '':
            errors.append('%s: group harus ""' % path.name)
        if not isinstance(ch.get('icon'), str) or ':' not in ch.get('icon', ''):
            errors.append('%s: icon tidak valid' % path.name)
        if ch.get('quest_links') != []:
            errors.append('%s: quest_links harus []' % path.name)

        ch_id = ch.get('id', '')
        if not ID_RE.match(str(ch_id)):
            errors.append('%s: id chapter bukan 16 hex: %r' % (path.name, ch_id))
        elif ch_id in seen_ids:
            errors.append('id duplikat %s' % ch_id)
        else:
            seen_ids[ch_id] = path.name

        quests = ch.get('quests')
        if not isinstance(quests, list):
            errors.append('%s: quests bukan list' % path.name)
            continue
        if not 3 <= len(quests) <= 5:
            errors.append('%s: %d quest, harus 3-5' % (path.name, len(quests)))

        for q in quests:
            quest_total += 1
            qid = str(q.get('id', ''))
            if not ID_RE.match(qid):
                errors.append('%s: id quest bukan 16 hex: %r' % (path.name, qid))
            elif qid in seen_ids:
                errors.append('id duplikat %s' % qid)
            else:
                seen_ids[qid] = path.name
            quests_by_id[qid] = (path.name, q)

            if not isinstance(q.get('title'), str) or not q['title'].strip():
                errors.append('%s/%s: title kosong' % (path.name, qid))
            if not isinstance(q.get('icon'), str) or ':' not in q.get('icon', ''):
                errors.append('%s/%s: icon tidak valid' % (path.name, qid))
            if not isinstance(q.get('x'), (int, float)) or not isinstance(q.get('y'), (int, float)):
                errors.append('%s/%s: x/y bukan angka' % (path.name, qid))
            desc = q.get('description')
            if not isinstance(desc, list) or not desc or not all(isinstance(s, str) and s.strip() for s in desc):
                errors.append('%s/%s: description kosong' % (path.name, qid))

            tasks = q.get('tasks')
            if not isinstance(tasks, list) or not tasks:
                errors.append('%s/%s: tasks kosong' % (path.name, qid))
                tasks = []
            for t in tasks:
                tid = str(t.get('id', ''))
                if not ID_RE.match(tid):
                    errors.append('%s: id task bukan 16 hex: %r' % (path.name, tid))
                elif tid in seen_ids:
                    errors.append('id duplikat %s' % tid)
                else:
                    seen_ids[tid] = path.name
                ttype = t.get('type')
                if ttype not in TASK_TYPES:
                    errors.append('%s/%s: tipe task %r tidak dikenal' % (path.name, qid, ttype))
                    continue
                type_counts[ttype] += 1
                if ttype == 'item':
                    item = t.get('item')
                    item_id = item if isinstance(item, str) else (item or {}).get('id')
                    if not isinstance(item_id, str) or ':' not in item_id:
                        errors.append('%s/%s: item task tanpa id' % (path.name, qid))
                    if not isinstance(t.get('count'), int) or t['count'] < 1:
                        errors.append('%s/%s: item task count tidak valid' % (path.name, qid))
                elif ttype == 'kill':
                    if not isinstance(t.get('entity'), str) or ':' not in t.get('entity', ''):
                        errors.append('%s/%s: kill task tanpa entity' % (path.name, qid))
                    if not isinstance(t.get('value'), int) or t['value'] < 1:
                        errors.append('%s/%s: kill task value tidak valid' % (path.name, qid))
                elif ttype == 'dimension':
                    if t.get('dimension') != 'minecraft:overworld':
                        errors.append('%s/%s: dimension task harus minecraft:overworld (Nether/End dikunci)'
                                      % (path.name, qid))

                if stem == 'hari_pertama' and ttype != 'checkmark':
                    errors.append('%s/%s: chapter Hari Pertama harus memakai checkmark' % (path.name, qid))

            rewards = q.get('rewards')
            if not isinstance(rewards, list) or not rewards:
                errors.append('%s/%s: rewards kosong' % (path.name, qid))
                rewards = []
            for r in rewards:
                rid = str(r.get('id', ''))
                if not ID_RE.match(rid):
                    errors.append('%s: id reward bukan 16 hex: %r' % (path.name, rid))
                elif rid in seen_ids:
                    errors.append('id duplikat %s' % rid)
                else:
                    seen_ids[rid] = path.name
                rtype = r.get('type')
                if rtype not in REWARD_TYPES:
                    errors.append('%s/%s: tipe reward %r tidak dikenal' % (path.name, qid, rtype))
                    continue
                if rtype == 'item':
                    item = r.get('item')
                    item_id = item if isinstance(item, str) else (item or {}).get('id')
                    if not isinstance(item_id, str) or ':' not in item_id:
                        errors.append('%s/%s: reward item tanpa id' % (path.name, qid))
                        continue
                    if not isinstance(r.get('count'), int) or r['count'] < 1:
                        errors.append('%s/%s: reward count tidak valid' % (path.name, qid))
                    reward_items.append((item_id, item))
                elif rtype == 'xp':
                    if not isinstance(r.get('xp'), int) or r['xp'] < 1:
                        errors.append('%s/%s: reward xp tidak valid' % (path.name, qid))

    for qid, (chap, q) in quests_by_id.items():
        deps = q.get('dependencies', [])
        if deps is None:
            deps = []
        if not isinstance(deps, list):
            errors.append('%s/%s: dependencies bukan list' % (chap, qid))
            continue
        for dep in deps:
            if dep not in quests_by_id:
                errors.append('%s/%s: dependency %r tidak ada' % (chap, qid, dep))
            elif dep == qid:
                errors.append('%s/%s: dependency ke diri sendiri' % (chap, qid))

    if type_counts['kill'] < 1:
        errors.append('tidak ada task kill')
    if type_counts['dimension'] < 1:
        errors.append('tidak ada task dimension')
    if type_counts['item'] < 8:
        errors.append('task item terlalu sedikit: %d' % type_counts['item'])
    if type_counts['checkmark'] < 3:
        errors.append('task checkmark terlalu sedikit: %d' % type_counts['checkmark'])

    ids = [i for i, _ in reward_items]
    if not any(i == 'tacz:ammo' for i in ids):
        errors.append('reward tanpa amunisi TaCZ')
    if not any(i in FOOD for i in ids):
        errors.append('reward tanpa makanan')
    if not any(i == 'minecraft:potion' and isinstance(o, dict)
               and (o.get('tag') or {}).get('Potion') == 'minecraft:water'
               or i.startswith('thirst:') for i, o in reward_items):
        errors.append('reward tanpa air minum')
    if not any(i in ('minecraft:iron_ingot', 'minecraft:leather', 'minecraft:white_wool',
                     'minecraft:cobblestone', 'minecraft:stone_bricks') for i in ids):
        errors.append('reward tanpa material')

    if errors:
        for e in errors[:40]:
            print('FAIL', e)
        print('FAIL: %d masalah' % len(errors))
        return 1

    print('quests: %d chapters, %d quests, %d tasks, %d rewards'
          % (len(CHAPTERS), quest_total, sum(type_counts.values()), len(reward_items)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
