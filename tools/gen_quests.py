"""Generator berkas FTB Quests (SNBT) untuk Zombie Apocalypse.

Menulis data.snbt + 7 chapter ke pack/overrides/config/ftbquests/quests/.
ID 16-hex dibuat deterministik supaya diff stabil:
  0A<cc><nn> -> chapter, 0B -> quest, 0C -> task, 0D -> reward.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QDIR = ROOT / 'pack' / 'overrides' / 'config' / 'ftbquests' / 'quests'


class Byte(int):
    pass


def hexid(prefix, chapter, n):
    return '%02X%02X%012X' % (prefix, chapter, n)


def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def emit(v, depth):
    pad = '\t' * depth
    if isinstance(v, dict):
        if not v:
            return '{ }'
        inner = []
        for k, val in v.items():
            inner.append('\t' * (depth + 1) + k + ': ' + emit(val, depth + 1))
        return '{\n' + '\n'.join(inner) + '\n' + pad + '}'
    if isinstance(v, list):
        if not v:
            return '[ ]'
        inner = ['\t' * (depth + 1) + emit(x, depth + 1) for x in v]
        return '[\n' + '\n'.join(inner) + '\n' + pad + ']'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, Byte):
        return '%db' % int(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return repr(v)
    return q(str(v))


DATA = {
    'version': 13,
    'default_reward_team': False,
    'default_consume_items': False,
    'default_autoclaim_rewards': 'disabled',
    'default_quest_shape': 'circle',
    'default_quest_disable_jei': False,
    'emergency_items': [],
    'emergency_items_cooldown': 300,
    'drop_loot_crates': False,
    'disable_gui': False,
    'grid_scale': 0.5,
    'pause_game': False,
    'lock_message': '',
    'progression_mode': 'flexible',
    'detection_delay': 20,
    'drop_book_on_death': False,
    'show_lock_icons': True,
    'hide_excluded_quests': False,
}


def ammo(n):
    return {'item': {'id': 'tacz:ammo', 'Count': Byte(1), 'tag': {'AmmoId': 'tacz:9mm'}}, 'count': n}


def water(n):
    return {'item': {'id': 'minecraft:potion', 'Count': Byte(1), 'tag': {'Potion': 'minecraft:water'}}, 'count': n}


def item(name, n=1):
    return {'item': name, 'count': n}


CHAPTER_SPECS = [
    {
        'stem': 'hari_pertama',
        'title': 'Hari Pertama',
        'icon': 'minecraft:leather_chestplate',
        'subtitle': ['Kenali kit dan bertahan sampai fajar'],
        'quests': [
            {
                'title': 'Selamat Datang di Dunia Beku',
                'icon': 'minecraft:leather_chestplate',
                'desc': [
                    'Dunia ini dingin, sunyi, dan penuh zombie.',
                    'Kit awal: armor kulit, pistol, 64 peluru, 8 steak, 4 botol air, 8 obor.',
                    'Klik tanda centang setelah kamu memeriksa isi tas.',
                ],
                'tasks': [{'kind': 'checkmark'}],
                'rewards': [item('minecraft:torch', 8)],
            },
            {
                'title': 'Bangun Tempat Berlindung',
                'icon': 'minecraft:oak_door',
                'desc': [
                    'Gali ruang kecil di lereng atau tutup celah dengan blok.',
                    'Pastikan ada pintu dan tidak ada jalan masuk untuk zombie.',
                ],
                'tasks': [{'kind': 'checkmark'}],
                'rewards': [item('minecraft:cobblestone', 16)],
            },
            {
                'title': 'Meja Kerajinan dan Furnace',
                'icon': 'minecraft:crafting_table',
                'desc': [
                    'Buat meja kerajinan dan furnace di dalam shelter.',
                    'Kamu akan membutuhkannya untuk amunisi, air, dan armor wool.',
                ],
                'tasks': [{'kind': 'checkmark'}],
                'rewards': [item('minecraft:cooked_beef', 4), water(2)],
            },
            {
                'title': 'Tunggu Fajar Pertama',
                'icon': 'minecraft:torch',
                'desc': [
                    'Malam pertama hanya sedikit zombie, tetapi suhu turun drastis.',
                    'Nyalakan obor dan jangan keluar sampai matahari terbit.',
                ],
                'tasks': [{'kind': 'checkmark'}],
                'rewards': [ammo(16)],
            },
        ],
    },
    {
        'stem': 'dingin',
        'title': 'Dingin',
        'icon': 'minecraft:white_wool',
        'subtitle': ['Wool menyelamatkan nyawa'],
        'quests': [
            {
                'title': 'Kumpulkan Wool',
                'icon': 'minecraft:white_wool',
                'desc': [
                    'Cari domba di dataran bersalju.',
                    'Wool adalah bahan utama insulasi armor.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:white_wool', 'count': 4}],
                'rewards': [item('minecraft:leather', 4)],
            },
            {
                'title': 'Jahit Armor Insulated',
                'icon': 'kubejs:insulated_leather_chestplate',
                'desc': [
                    'Resep: armor kulit + 2 wool (shapeless) untuk tiap bagian.',
                    'Setiap bagian insulated menambah insulasi dingin 15%.',
                    'Buat chestplate insulated terlebih dahulu.',
                ],
                'tasks': [{'kind': 'item', 'item': 'kubejs:insulated_leather_chestplate', 'count': 1}],
                'rewards': [ammo(8)],
            },
            {
                'title': 'Lengkapi Set Insulated',
                'icon': 'kubejs:insulated_leather_leggings',
                'desc': [
                    'Lengkapi helmet, leggings, dan boots insulated.',
                    'Perhatikan meter suhu tubuhmu saat memakainya.',
                ],
                'tasks': [{'kind': 'item', 'item': 'kubejs:insulated_leather_leggings', 'count': 1}],
                'rewards': [item('cold_sweat:thermometer', 1)],
            },
            {
                'title': 'Nyalakan Api Unggun',
                'icon': 'minecraft:campfire',
                'desc': [
                    'Api unggun menghangatkan tubuh dan menerangi sekitar shelter.',
                    'Letakkan di dalam ruang tertutup agar panasnya terasa.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:campfire', 'count': 1}],
                'rewards': [item('minecraft:torch', 16)],
            },
            {
                'title': 'Persediaan Arang',
                'icon': 'minecraft:charcoal',
                'desc': [
                    'Bakar kayu di furnace untuk arang.',
                    'Arang menjadi bahan bakar obor dan api unggun cadangan.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:charcoal', 'count': 8}],
                'rewards': [item('minecraft:cooked_beef', 4)],
            },
        ],
    },
    {
        'stem': 'haus',
        'title': 'Haus',
        'icon': 'minecraft:potion',
        'subtitle': ['Air adalah nyawa kedua'],
        'quests': [
            {
                'title': 'Kumpulkan Salju',
                'icon': 'minecraft:snowball',
                'desc': [
                    'Salju bisa dicairkan menjadi air minum.',
                    'Kumpulkan lebih banyak dari perkiraanmu.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:snowball', 'count': 16}],
                'rewards': [item('minecraft:glass_bottle', 4)],
            },
            {
                'title': 'Cairkan Air',
                'icon': 'minecraft:glass_bottle',
                'desc': [
                    'Resep: 4 snowball + 1 botol kaca menjadi 1 botol air.',
                    'Simpan botol air untuk perjalanan jauh.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:glass_bottle', 'count': 4}],
                'rewards': [water(4)],
            },
            {
                'title': 'Buat Mangkuk Air Bersih',
                'icon': 'thirst:terracotta_water_bowl',
                'desc': [
                    'Mangkuk tanah liat bisa diisi air dari sumber mana pun.',
                    'Panggang mangkuk berisi air di campfire atau furnace agar bersih.',
                ],
                'tasks': [{'kind': 'item', 'item': 'thirst:terracotta_water_bowl', 'count': 2}],
                'rewards': [item('thirst:terracotta_bowl', 4)],
            },
            {
                'title': 'Isi Waterskin',
                'icon': 'cold_sweat:waterskin',
                'desc': [
                    'Waterskin dibawa di badan dan tidak memakan slot hotbar.',
                    'Isi penuh sebelum meninggalkan shelter.',
                ],
                'tasks': [{'kind': 'item', 'item': 'cold_sweat:waterskin', 'count': 1}],
                'rewards': [water(4)],
            },
        ],
    },
    {
        'stem': 'senjata',
        'title': 'Senjata',
        'icon': 'tacz:modern_kinetic_gun',
        'subtitle': ['Reruntuhan menyimpan senjata dan peluru'],
        'quests': [
            {
                'title': 'Temukan Senjata di Reruntuhan',
                'icon': 'tacz:modern_kinetic_gun',
                'desc': [
                    'Cari reruntuhan, kapal karam, atau dungeon.',
                    'Peti berisi senjata sering dijaga zombie.',
                ],
                'tasks': [{'kind': 'item', 'item': 'tacz:modern_kinetic_gun', 'count': 1}],
                'rewards': [ammo(16)],
            },
            {
                'title': 'Kumpulkan Bahan Peluru',
                'icon': 'minecraft:gunpowder',
                'desc': [
                    'Resep gunpowder: arang + flint + pasir.',
                    'Bahan ini dipakai untuk membuat amunisi 9mm.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:gunpowder', 'count': 2}],
                'rewards': [ammo(8)],
            },
            {
                'title': 'Buat 32 Peluru',
                'icon': 'tacz:ammo',
                'desc': [
                    'Resep: 1 gunpowder + 1 iron nugget + 1 paper menjadi 8 peluru.',
                    'Simpan amunisi di backpack agar tidak hilang saat mati.',
                ],
                'tasks': [{'kind': 'item', 'item': 'tacz:ammo', 'count': 32}],
                'rewards': [item('minecraft:cooked_beef', 4)],
            },
            {
                'title': 'Bersihkan Jalan',
                'icon': 'minecraft:iron_sword',
                'desc': [
                    'Zombie mulai memakai armor sejak hari ke-3.',
                    'Aim ke kepala dan jaga jarak.',
                ],
                'tasks': [{'kind': 'kill', 'entity': 'minecraft:zombie', 'value': 5}],
                'rewards': [ammo(16)],
            },
        ],
    },
    {
        'stem': 'malam_ke_10',
        'title': 'Malam ke-10',
        'icon': 'minecraft:zombie_head',
        'subtitle': ['Horde pertama datang'],
        'quests': [
            {
                'title': 'Siapkan Persediaan',
                'icon': 'minecraft:cooked_beef',
                'desc': [
                    'Horde bisa berlangsung lama. Siapkan makanan dan air.',
                    'Jangan habiskan semua amunisi sebelum horde tiba.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:cooked_beef', 'count': 8}],
                'rewards': [water(4)],
            },
            {
                'title': 'Kumpulkan Obor',
                'icon': 'minecraft:torch',
                'desc': [
                    'Terangi jalur keluar-masuk shelter.',
                    'Zombie tetap datang, tetapi kamu bisa melihat mereka.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:torch', 'count': 16}],
                'rewards': [ammo(8)],
            },
            {
                'title': 'Perkuat Pintu',
                'icon': 'minecraft:iron_ingot',
                'desc': [
                    'Kumpulkan besi untuk pintu, jeruji, atau pelat.',
                    'Pintu kayu tidak bertahan lama melawan horde.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:iron_ingot', 'count': 4}],
                'rewards': [item('minecraft:stone_bricks', 16)],
            },
            {
                'title': 'Bertahan dari Horde Hari ke-10',
                'icon': 'minecraft:zombie_head',
                'desc': [
                    'Horde menyerang saat malam hari ke-10. Tidur dikunci.',
                    'Bunuh 25 zombie sampai fajar.',
                ],
                'tasks': [{'kind': 'kill', 'entity': 'minecraft:zombie', 'value': 25}],
                'rewards': [ammo(32), item('minecraft:iron_ingot', 4)],
            },
        ],
    },
    {
        'stem': 'benteng',
        'title': 'Benteng',
        'icon': 'minecraft:stone_bricks',
        'subtitle': ['Bangun pertahanan permanen'],
        'quests': [
            {
                'title': 'Bangun Dinding Pertahanan',
                'icon': 'minecraft:stone_bricks',
                'desc': [
                    'Kelilingi shelter dengan dinding batu setinggi 3 blok.',
                    'Sisakan satu pintu yang bisa kamu tutup.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:stone_bricks', 'count': 32}],
                'rewards': [item('minecraft:cobblestone', 16)],
            },
            {
                'title': 'Pasang Jebakan',
                'icon': 'minecraft:oak_trapdoor',
                'desc': [
                    'Trapdoor dan parit memperlambat zombie masuk.',
                    'Kombinasikan dengan celah tembak di dinding.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:oak_trapdoor', 'count': 8}],
                'rewards': [item('minecraft:iron_ingot', 2)],
            },
            {
                'title': 'Rakit Backpack',
                'icon': 'sophisticatedbackpacks:backpack',
                'desc': [
                    'Resep backpack: 5 leather + 2 wool + 2 string.',
                    'Backpack menambah ruang loot saat eksplorasi.',
                ],
                'tasks': [{'kind': 'item', 'item': 'sophisticatedbackpacks:backpack', 'count': 1}],
                'rewards': [item('minecraft:leather', 8)],
            },
            {
                'title': 'Horde Kedua',
                'icon': 'minecraft:shield',
                'desc': [
                    'Horde hari ke-20 lebih besar dan zombie membawa kapak.',
                    'Bunuh 40 zombie tanpa meninggalkan benteng.',
                ],
                'tasks': [{'kind': 'kill', 'entity': 'minecraft:zombie', 'value': 40}],
                'rewards': [ammo(32), item('minecraft:cooked_beef', 8)],
            },
        ],
    },
    {
        'stem': 'mutasi',
        'title': 'Mutasi',
        'icon': 'minecraft:ender_pearl',
        'subtitle': ['Mutan muncul sejak hari ke-30'],
        'quests': [
            {
                'title': 'Zombie Pembawa Ender Pearl',
                'icon': 'minecraft:ender_pearl',
                'desc': [
                    'Sebagian zombie membawa ender pearl dan berteleportasi.',
                    'Bunuh mereka untuk mendapatkan pearl.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:ender_pearl', 'count': 1}],
                'rewards': [ammo(16)],
            },
            {
                'title': 'Bunuh 20 Zombie di Overworld',
                'icon': 'minecraft:iron_axe',
                'desc': [
                    'Mutan berukuran besar dan memukul jauh lebih keras.',
                    'Tetap di Overworld; Nether dan End terkunci.',
                ],
                'tasks': [
                    {'kind': 'dimension', 'dimension': 'minecraft:overworld'},
                    {'kind': 'kill', 'entity': 'minecraft:zombie', 'value': 20},
                ],
                'rewards': [item('minecraft:cooked_beef', 4)],
            },
            {
                'title': 'Kumpulkan 4 Ender Pearl',
                'icon': 'minecraft:ender_eye',
                'desc': [
                    'Pearl dipakai untuk membuat ender eye dan waystone.',
                    'Simpan di backpack, jangan di hotbar.',
                ],
                'tasks': [{'kind': 'item', 'item': 'minecraft:ender_pearl', 'count': 4}],
                'rewards': [item('minecraft:diamond', 1)],
            },
            {
                'title': 'Horde Hari ke-30',
                'icon': 'minecraft:nether_star',
                'desc': [
                    'Horde pertama dengan mutant. Peluang mutant naik setiap hari.',
                    'Bunuh 60 zombie dan bertahan sampai fajar.',
                ],
                'tasks': [{'kind': 'kill', 'entity': 'minecraft:zombie', 'value': 60}],
                'rewards': [ammo(64), item('minecraft:gold_ingot', 4)],
            },
        ],
    },
]


def build():
    files = {}

    files[QDIR / 'data.snbt'] = emit(DATA, 0) + '\n'

    prev_last = None
    for ci, spec in enumerate(CHAPTER_SPECS):
        chapter_no = ci + 1
        ch_id = hexid(0x0A, chapter_no, 1)
        quests = []
        last_id = None
        for qi, qspec in enumerate(spec['quests']):
            quest_no = qi + 1
            qid = hexid(0x0B, chapter_no, quest_no)
            deps = []
            if last_id is not None:
                deps.append(last_id)
            elif prev_last is not None:
                deps.append(prev_last)

            tasks = []
            for ti, ts in enumerate(qspec['tasks']):
                task = {'id': hexid(0x0C, chapter_no, len(quests) * 10 + ti + 1)}
                if ts['kind'] == 'checkmark':
                    task['type'] = 'checkmark'
                elif ts['kind'] == 'item':
                    task['type'] = 'item'
                    task['item'] = ts['item']
                    task['count'] = ts['count']
                elif ts['kind'] == 'kill':
                    task['type'] = 'kill'
                    task['entity'] = ts['entity']
                    task['value'] = ts['value']
                elif ts['kind'] == 'dimension':
                    task['type'] = 'dimension'
                    task['dimension'] = ts['dimension']
                tasks.append(task)

            rewards = []
            for ri, rs in enumerate(qspec['rewards']):
                reward = {'id': hexid(0x0D, chapter_no, len(quests) * 10 + ri + 1)}
                if 'xp' in rs:
                    reward['type'] = 'xp'
                    reward['xp'] = rs['xp']
                else:
                    reward['type'] = 'item'
                    reward['item'] = rs['item']
                    reward['count'] = rs['count']
                rewards.append(reward)

            quest = {
                'id': qid,
                'x': qi * 1.5,
                'y': 0.0,
                'title': qspec['title'],
                'icon': qspec['icon'],
                'description': qspec['desc'],
            }
            if deps:
                quest['dependencies'] = deps
            quest['tasks'] = tasks
            quest['rewards'] = rewards
            quests.append(quest)
            last_id = qid

        chapter = {
            'id': ch_id,
            'group': '',
            'order_index': ci,
            'filename': spec['stem'],
            'title': spec['title'],
            'icon': spec['icon'],
            'default_quest_shape': 'circle',
            'quests': quests,
            'quest_links': [],
        }
        if spec.get('subtitle'):
            chapter['subtitle'] = spec['subtitle']
        files[QDIR / 'chapters' / (spec['stem'] + '.snbt')] = emit(chapter, 0) + '\n'
        prev_last = last_id

    return files


def main():
    files = build()
    stale = set()
    for path, text in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')
        stale.add(path.resolve())
    chap_dir = QDIR / 'chapters'
    for path in chap_dir.glob('*.snbt'):
        if path.resolve() not in stale:
            path.unlink()
    total = sum(len(s['quests']) for s in CHAPTER_SPECS)
    print('quests: %d files, %d chapters, %d quests' % (len(files), len(CHAPTER_SPECS), total))


if __name__ == '__main__':
    main()
