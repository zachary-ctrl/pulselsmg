"""Writes scenes/rooms/*.tscn from the room table below.

Run once to regenerate the starting layouts; after that, edit the rooms
directly in the Godot editor (move platforms, markers and blockers there).
"""
import os
ROOT = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'rooms')

ROOMS = {
 'classroom': dict(name='Room 101', sub='Science Wing · Last Period', size=(1920, 540), floor='wood', tint='#ffb37a',
   solids=[(0,470,1920,70,'s'),(250,430,96,10,'o'),(450,430,96,10,'o'),(650,430,96,10,'o'),(1040,430,96,10,'o'),(1230,430,96,10,'o'),(1440,402,180,68,'s'),(1650,330,130,10,'o')],
   doors=[(1818,298,22,172,'door101')], gates=[],
   markers=[('sigil',dict(pos=(1882,392),flag='door101')),('exit',dict(rect=(1898,290,22,180),target_room='hallway',spawn_point=(60,470))),
            ('anchor',dict(pos=(1715,330),id='momText')),('trigger',dict(rect=(780,0,60,540),event='firstProjection'))]),
 'hallway': dict(name='East Hall', sub='Where the lockers whisper', size=(3200, 540), floor='tile', tint='#9ec2ff',
   solids=[(0,470,1480,70,'s'),(1720,470,1480,70,'s'),(1480,540,240,10,'s'),(1556,392,96,12,'o'),(2050,380,160,90,'s'),(600,404,120,10,'o')],
   doors=[], gates=[(2370,230,28,240,'echo_fight'),(3150,230,28,240,'echo_unresolved')],
   markers=[('hazard',dict(rect=(1480,500,240,40))),('exit',dict(rect=(0,290,22,180),target_room='classroom',spawn_point=(1870,470))),
            ('exit',dict(rect=(3178,290,22,180),target_room='cafeteria',spawn_point=(60,1010))),('anchor',dict(pos=(2130,380),id='unknownText')),
            ('trigger',dict(rect=(2520,0,40,540),event='echoArena')),('spawn',dict(pos=(1150,470),enemy='sleeper',id='s1')),
            ('spawn',dict(pos=(1880,470),enemy='sleeper',id='s2')),('spawn',dict(pos=(2280,470),enemy='sleeper',id='s3',patrol_range=70)),
            ('npc',dict(pos=(860,470),id='lana',face=-1,dialog='lana1',dialog_repeat='lana2')),('bench',dict(pos=(300,470))),
            ('portal',dict(pos=(1030,470),target_room='rooftop',spawn_point=(120,470))),('spawn',dict(pos=(2960,470),enemy='underboss',id='devil1')),
            ('loot',dict(pos=(660,404),id='l_lunchbox',item='lunchbox'))]),
 'cafeteria': dict(name='The Cafeteria', sub='412 lunches served · 0 eaten', size=(2400, 1080), floor='lino', tint='#b8ffd8',
   solids=[(0,1010,1300,70,'s'),(1560,1010,840,70,'s'),(1300,1080,260,10,'s'),(180,950,200,12,'o'),(520,950,200,12,'o'),(880,950,200,12,'o'),
           (1700,950,200,12,'o'),(2050,950,200,12,'o'),(1380,935,100,12,'o'),(1100,800,160,14,'o'),(1380,650,140,14,'o'),(1600,520,800,30,'s'),
           (130,905,110,12,'a'),(320,800,110,12,'a'),(130,695,110,12,'a'),(320,590,110,12,'a'),(130,485,110,12,'a'),(300,385,200,12,'a')],
   doors=[], gates=[],
   markers=[('hazard',dict(rect=(1300,1030,260,50))),('exit',dict(rect=(0,870,22,140),target_room='hallway',spawn_point=(3110,470))),
            ('exit',dict(rect=(2378,380,22,140),target_room='lab',spawn_point=(60,470))),('anchor',dict(pos=(400,385),id='levitation',astral=True)),
            ('anchor',dict(pos=(2150,950),id='receipt')),('spawn',dict(pos=(1200,700),enemy='mote',id='m1')),('spawn',dict(pos=(1900,800),enemy='mote',id='m2')),
            ('spawn',dict(pos=(700,640),enemy='mote',id='m3')),('spawn',dict(pos=(1900,1010),enemy='sleeper',id='s4',patrol_range=120)),
            ('npc',dict(pos=(760,1010),id='jason',face=1,dialog='jason1',dialog_repeat='jason2')),('bench',dict(pos=(1760,520))),
            ('spawn',dict(pos=(2100,1010),enemy='imp',id='i1',patrol_range=120)),('loot',dict(pos=(1440,650),id='h_caf',item='heart'))]),
 'lab': dict(name='Sub-Basement Lab', sub='Property of the Dharma Order', size=(1120, 540), floor='metal', tint='#7ff0ff',
   solids=[(0,470,1120,70,'s'),(170,368,170,12,'o'),(790,368,170,12,'o')],
   doors=[], gates=[(4,230,28,240,'ciencia_fight')],
   markers=[('exit',dict(rect=(0,290,20,180),target_room='cafeteria',spawn_point=(2330,520))),('anchor',dict(pos=(110,470),id='dharmaNote')),
            ('trigger',dict(rect=(300,0,40,540),event='cienciaArena')),('spawn',dict(pos=(900,470),enemy='ciencia',id='boss'))]),
 'street': dict(name='Westbrook Avenue', sub='Chapter Two · The Carrier', size=(2800, 540), floor='lino', tint='#ffc890', draw=True,
   solids=[(0,470,2250,70,'s'),(2390,470,410,70,'s'),(2250,540,140,10,'s'),(500,360,160,12,'o'),(900,410,180,12,'o'),(1500,410,180,12,'o'),(1200,420,80,50,'s'),(1900,340,200,12,'o')],
   doors=[], gates=[],
   markers=[('hazard',dict(rect=(2250,500,140,40))),('exit',dict(rect=(2778,290,22,180),target_room='hospital',spawn_point=(60,470))),
            ('bench',dict(pos=(300,470))),('npc',dict(pos=(420,470),id='lana',face=1,dialog='c2_lana2',dialog_repeat='c2_lana2')),
            ('portal',dict(pos=(1350,470),target_room='downtown',spawn_point=(120,470))),('spawn',dict(pos=(2480,470),enemy='underboss',id='devil2')),
            ('anchor',dict(pos=(580,360),id='dadText')),('spawn',dict(pos=(1100,470),enemy='sleeper',id='ta1',patrol_range=90)),
            ('spawn',dict(pos=(1750,470),enemy='sleeper',id='a2')),('spawn',dict(pos=(2050,470),enemy='sleeper',id='ta3',patrol_range=80)),
            ('spawn',dict(pos=(1400,300),enemy='mote',id='m4')),('spawn',dict(pos=(2550,320),enemy='mote',id='m5')),
            ('spawn',dict(pos=(980,410),enemy='imp',id='i2',patrol_range=60)),('spawn',dict(pos=(1980,340),enemy='imp',id='i3',patrol_range=60)),
            ('spawn',dict(pos=(1500,470),enemy='rider',id='elite_r1',patrol_range=260)),
            ('loot',dict(pos=(1240,420),id='h_street',item='heart')),('loot',dict(pos=(2000,340),id='l_jersey',item='jersey'))]),
 'hospital': dict(name='Mercy General', sub='Third floor · Visiting hours are over', size=(2000, 540), floor='tile', tint='#cfe8ff', draw=True,
   solids=[(0,470,2000,70,'s'),(400,420,120,10,'o'),(900,420,120,10,'o'),(1180,400,180,70,'s')],
   doors=[], gates=[(1380,230,28,240,'carrier_fight')],
   markers=[('exit',dict(rect=(0,290,20,180),target_room='street',spawn_point=(2730,470))),('npc',dict(pos=(250,470),id='jason',face=1,dialog='c2_jason',dialog_repeat='c2_jason2')),
            ('anchor',dict(pos=(1270,400),id='chart')),('spawn',dict(pos=(700,470),enemy='sleeper',id='t5',patrol_range=120)),('bench',dict(pos=(1050,470))),
            ('trigger',dict(rect=(1460,0,40,540),event='carrierArena')),('spawn',dict(pos=(1820,470),enemy='carrier',id='carrier')),
            ('spawn',dict(pos=(960,420),enemy='imp',id='i4',patrol_range=40)),('loot',dict(pos=(460,420),id='l_tot',item='tot'))]),
 'waterworks': dict(name='Westbrook Waterworks', sub='Chapter Three · Red Water', size=(2600, 1080), floor='metal', tint='#ff9a9a', draw=True,
   solids=[(0,1010,700,70,'s'),(1000,1010,600,70,'s'),(1900,1010,700,70,'s'),(700,1080,300,10,'s'),(1600,1080,300,10,'s'),
           (600,880,160,12,'o'),(1000,780,200,12,'o'),(1400,880,160,12,'o'),(1640,900,120,12,'o'),(1850,780,180,12,'o'),(2150,650,200,12,'o'),(2200,520,400,30,'s')],
   doors=[], gates=[(2540,380,28,140,'rescue_incomplete')],
   markers=[('hazard',dict(rect=(700,1030,300,50))),('hazard',dict(rect=(1600,1030,300,50))),
            ('exit',dict(rect=(2578,380,22,140),target_room='pumphouse',spawn_point=(60,470))),('npc',dict(pos=(150,1010),id='jason',face=1,dialog='c3_jason2',dialog_repeat='c3_jason2')),
            ('worker',dict(pos=(330,1010),id='w1')),('portal',dict(pos=(560,1010),target_room='underpass',spawn_point=(120,470))),('spawn',dict(pos=(2320,1010),enemy='underboss',id='devil3')),('worker',dict(pos=(1150,1010),id='w2')),('worker',dict(pos=(2470,520),id='w3')),
            ('anchor',dict(pos=(1100,780),id='workOrder')),('bench',dict(pos=(2300,520))),
            ('spawn',dict(pos=(900,720),enemy='mote',id='w1m')),('spawn',dict(pos=(1750,640),enemy='mote',id='w2m')),
            ('spawn',dict(pos=(1400,1010),enemy='sleeper',id='t6',patrol_range=120)),('spawn',dict(pos=(2200,1010),enemy='sleeper',id='t7')),
            ('spawn',dict(pos=(400,1010),enemy='rider',id='r2',patrol_range=200)),('spawn',dict(pos=(2300,1010),enemy='rider',id='elite_r3',patrol_range=200)),
            ('spawn',dict(pos=(1100,780),enemy='imp',id='i5',patrol_range=60)),('spawn',dict(pos=(1930,780),enemy='imp',id='i6',patrol_range=60)),
            ('loot',dict(pos=(2250,650),id='h_water',item='heart')),('loot',dict(pos=(680,880),id='l_bell',item='bell'))]),
 'pumphouse': dict(name='The Pumphouse', sub='Intake 3', size=(1200, 540), floor='metal', tint='#ff9a9a', draw=True,
   solids=[(0,470,1200,70,'s'),(250,360,200,12,'o'),(750,360,200,12,'o'),(500,250,200,12,'o')],
   doors=[], gates=[(4,230,28,240,'tide_fight')],
   markers=[('hazard',dict(rect=(0,478,1200,62),id='tide')),('exit',dict(rect=(0,290,20,180),target_room='waterworks',spawn_point=(2480,520))),
            ('npc',dict(pos=(110,470),id='jason',face=1,dialog='c3_jason2',dialog_repeat='c3_jason2')),
            ('trigger',dict(rect=(240,0,40,540),event='tideArena')),('spawn',dict(pos=(600,470),enemy='tide',id='tide'))]),

 'fairhall': dict(name='Science Fair Night', sub='Chapter Four · #ScienceMatters', size=(3000, 540), floor='tile', tint='#ffd0f0', draw=True,
   solids=[(0,470,1300,70,'s'),(1500,470,1500,70,'s'),(1300,540,200,10,'s'),(380,400,140,12,'o'),(700,360,160,12,'o'),(1340,390,120,12,'o'),
           (1800,400,140,12,'o'),(2100,330,160,12,'o'),(2400,410,120,60,'s')],
   doors=[], gates=[(2700,230,28,240,'elite_alive','elite_r4')],
   markers=[('hazard',dict(rect=(1300,500,200,40))),('exit',dict(rect=(2978,290,22,180),target_room='gym',spawn_point=(60,1010))),
            ('bench',dict(pos=(260,470))),('npc',dict(pos=(520,470),id='lana',face=1,dialog='c4_lana',dialog_repeat='c4_lana2')),
            ('portal',dict(pos=(1600,470),target_room='neon',spawn_point=(120,470))),('spawn',dict(pos=(2800,470),enemy='underboss',id='devil4')),
            ('anchor',dict(pos=(780,360),id='flyer')),('spawn',dict(pos=(1000,470),enemy='sleeper',id='f1',patrol_range=120)),
            ('spawn',dict(pos=(1700,470),enemy='imp',id='f2',patrol_range=80)),('spawn',dict(pos=(1880,400),enemy='imp',id='f3',patrol_range=40)),
            ('spawn',dict(pos=(2250,470),enemy='sleeper',id='tf4',patrol_range=100)),('spawn',dict(pos=(2550,470),enemy='rider',id='elite_r4',patrol_range=120)),
            ('trigger',dict(rect=(2420,0,40,540),event='eliteIntro')),
            ('loot',dict(pos=(2180,330),id='h_fair',item='heart')),('loot',dict(pos=(1400,390),id='l_badge',item='badge'))]),
 'gym': dict(name='The Gymnasium', sub='Collective Cognition · All exhibits synchronized', size=(2400, 1080), floor='wood', tint='#ffb0e0', draw=True,
   solids=[(0,1010,2400,70,'s'),(200,900,180,12,'o'),(520,800,180,12,'o'),(860,700,200,12,'o'),(1200,800,180,12,'o'),(1500,690,200,12,'o'),
           (1820,800,180,12,'o'),(2050,620,350,30,'s'),(1000,560,160,12,'o'),(640,520,160,12,'o')],
   doors=[], gates=[(2340,470,28,150,'exhibits_incomplete')],
   markers=[('exit',dict(rect=(0,870,22,140),target_room='fairhall',spawn_point=(2930,470))),('exit',dict(rect=(2378,470,22,150),target_room='stage',spawn_point=(60,470))),
            ('npc',dict(pos=(140,1010),id='jason',face=1,dialog='c4_jason',dialog_repeat='c4_jason2')),('bench',dict(pos=(2200,620))),
            ('spawn',dict(pos=(600,1010),enemy='exhibit',id='x1')),('spawn',dict(pos=(1080,560),enemy='exhibit',id='x2')),('spawn',dict(pos=(1900,1010),enemy='exhibit',id='x3')),
            ('spawn',dict(pos=(900,1010),enemy='sleeper',id='tg1',patrol_range=140)),('spawn',dict(pos=(1500,1010),enemy='rider',id='g2',patrol_range=220)),
            ('spawn',dict(pos=(1300,700),enemy='mote',id='g3')),('spawn',dict(pos=(1600,690),enemy='imp',id='g4',patrol_range=60)),('spawn',dict(pos=(700,520),enemy='imp',id='g5',patrol_range=40)),
            ('trigger',dict(rect=(200,0,40,1080),event='gymIntro')),('loot',dict(pos=(700,520),id='l_phone',item='phone'))]),
 'stage': dict(name='The Main Stage', sub='Judging begins', size=(1120, 540), floor='wood', tint='#ff9ad8', draw=True,
   solids=[(0,470,1120,70,'s'),(170,368,170,12,'o'),(790,368,170,12,'o')],
   doors=[], gates=[(4,230,28,240,'collective_fight')],
   markers=[('exit',dict(rect=(0,290,20,180),target_room='gym',spawn_point=(2320,620))),('trigger',dict(rect=(300,0,40,540),event='collectiveArena')),
            ('spawn',dict(pos=(900,470),enemy='collective',id='boss4'))]),
 'rooftop': dict(name='School Rooftop', sub='Side area · The Hall Monitor', size=(2400, 540), floor='metal', tint='#9ec2ff', draw=True,
   solids=[(0,470,700,70,'s'),(860,470,560,70,'s'),(1580,470,820,70,'s'),(700,540,160,10,'s'),(1420,540,160,10,'s'),(300,390,140,12,'o'),(720,370,120,12,'o'),
           (1100,360,160,12,'o'),(1440,380,120,12,'o'),(1250,300,100,170,'s')],
   doors=[], gates=[],
   markers=[('portal',dict(pos=(90,470),target_room='hallway',spawn_point=(1030,470))),('trigger',dict(rect=(200,0,40,540),event='dlg_rooftopIntro')),
            ('spawn',dict(pos=(560,330),enemy='mote',id='rt_m1')),('spawn',dict(pos=(1000,470),enemy='imp',id='rt_i1',patrol_range=80)),('spawn',dict(pos=(1300,250),enemy='mote',id='rt_m2')),
            ('anchor',dict(pos=(760,370),id='rooftopNote')),('loot',dict(pos=(1300,300),id='h_roof',item='heart')),
            ('spawn',dict(pos=(2050,470),enemy='underboss',id='monitor'))]),
 'downtown': dict(name='Downtown at Dusk', sub='Side area · The Brood Mother', size=(2800, 540), floor='lino', tint='#ffb0a0', draw=True,
   solids=[(0,470,900,70,'s'),(1050,470,700,70,'s'),(1900,470,900,70,'s'),(900,540,150,10,'s'),(1750,540,150,10,'s'),(400,380,160,12,'o'),(940,380,120,12,'o'),
           (1300,350,180,12,'o'),(1780,380,120,12,'o'),(1500,420,90,50,'s')],
   doors=[], gates=[],
   markers=[('portal',dict(pos=(90,470),target_room='street',spawn_point=(1350,470))),('trigger',dict(rect=(220,0,40,540),event='dlg_downtownIntro')),
            ('spawn',dict(pos=(700,470),enemy='rider',id='dt_r1',patrol_range=160)),('spawn',dict(pos=(1320,350),enemy='imp',id='dt_i1',patrol_range=40)),
            ('spawn',dict(pos=(1600,470),enemy='imp',id='dt_i2',patrol_range=80)),('anchor',dict(pos=(470,380),id='busAd')),
            ('loot',dict(pos=(1390,350),id='l_dt',item='charger')),('spawn',dict(pos=(2400,470),enemy='underboss',id='brood'))]),
 'underpass': dict(name='Flooded Underpass', sub='Side area · The Pipe Warden', size=(2600, 540), floor='metal', tint='#9fe2ff', draw=True,
   solids=[(0,470,600,70,'s'),(760,470,500,70,'s'),(1420,470,1180,70,'s'),(600,540,160,10,'s'),(1260,540,160,10,'s'),(620,390,120,12,'o'),(1290,390,110,12,'o'),
           (900,360,160,12,'o'),(300,380,140,12,'o')],
   doors=[], gates=[],
   markers=[('portal',dict(pos=(90,470),target_room='waterworks',spawn_point=(560,1010))),('trigger',dict(rect=(220,0,40,540),event='dlg_underpassIntro')),
            ('hazard',dict(rect=(600,500,160,40))),('hazard',dict(rect=(1260,500,160,40))),
            ('spawn',dict(pos=(1000,470),enemy='sleeper',id='up_t1',patrol_range=120)),('spawn',dict(pos=(950,300),enemy='mote',id='up_m1')),('spawn',dict(pos=(1600,470),enemy='rider',id='up_r1',patrol_range=150)),
            ('anchor',dict(pos=(960,360),id='floodLog')),('loot',dict(pos=(340,380),id='h_under',item='heart')),
            ('spawn',dict(pos=(2150,470),enemy='underboss',id='warden'))]),
 'neon': dict(name='Neon Billboards', sub='Side area · The Third Judge', size=(2400, 540), floor='metal', tint='#ff9ad8', draw=True,
   solids=[(0,470,2400,70,'s'),(380,390,140,12,'o'),(700,330,140,12,'o'),(1000,390,140,12,'o'),(1300,320,140,12,'o'),(1700,380,160,12,'o'),(2050,380,160,12,'o')],
   doors=[], gates=[],
   markers=[('portal',dict(pos=(90,470),target_room='fairhall',spawn_point=(1600,470))),('trigger',dict(rect=(220,0,40,540),event='dlg_neonIntro')),
            ('spawn',dict(pos=(800,470),enemy='imp',id='ne_i1',patrol_range=80)),('spawn',dict(pos=(1300,250),enemy='mote',id='ne_m1')),('spawn',dict(pos=(1150,470),enemy='rider',id='ne_r1',patrol_range=120)),
            ('anchor',dict(pos=(760,330),id='neonBill')),('loot',dict(pos=(1360,320),id='h_neon',item='heart')),
            ('spawn',dict(pos=(1950,400),enemy='underboss',id='judge'))]),
 'nightcity': dict(name='Westbrook After Dark', sub='Chapter Five · The Teacher Who Was Fired', size=(3000, 540), floor='lino', tint='#a8ffcf', draw=True,
   solids=[(0,470,1200,70,'s'),(1380,470,1620,70,'s'),(1200,540,180,10,'s'),(450,380,160,12,'o'),(900,350,160,12,'o'),(1230,400,120,12,'o'),(1700,380,160,12,'o'),(2200,340,180,12,'o'),(2500,420,120,50,'s')],
   doors=[], gates=[(2750,230,28,240,'elite_alive','elite_r5')],
   markers=[('hazard',dict(rect=(1200,500,180,40))),('bench',dict(pos=(260,470))),('npc',dict(pos=(520,470),id='lana',face=1,dialog='c5_lana',dialog_repeat='c5_lana')),
            ('exit',dict(rect=(2978,290,22,180),target_room='skyline',spawn_point=(60,470))),
            ('spawn',dict(pos=(800,470),enemy='sleeper',id='nc_t1',patrol_range=120)),('spawn',dict(pos=(950,350),enemy='imp',id='nc_i1',patrol_range=40)),
            ('spawn',dict(pos=(1600,470),enemy='rider',id='nc_r1',patrol_range=160)),('spawn',dict(pos=(2250,340),enemy='imp',id='nc_i2',patrol_range=40)),
            ('spawn',dict(pos=(2550,470),enemy='rider',id='elite_r5',patrol_range=120)),('loot',dict(pos=(950,350),id='h_night',item='heart'))]),
 'skyline': dict(name='The Smog Line', sub='Rooftops above the bank', size=(2800, 540), floor='metal', tint='#ffb0d8', draw=True,
   solids=[(0,470,500,70,'s'),(640,430,300,110,'s'),(1080,390,260,150,'s'),(1480,440,320,100,'s'),(1940,400,300,140,'s'),(2380,470,420,70,'s'),
           (540,360,80,12,'o'),(980,320,80,12,'o'),(1390,330,70,12,'o'),(1830,340,80,12,'o'),(2270,350,80,12,'o')],
   doors=[], gates=[],
   markers=[('trigger',dict(rect=(160,0,40,540),event='dlg_skylineIntro')),('exit',dict(rect=(2778,290,22,180),target_room='archive',spawn_point=(60,470))),
            ('spawn',dict(pos=(800,430),enemy='imp',id='sk_i1',patrol_range=60)),('spawn',dict(pos=(1200,250),enemy='mote',id='sk_m1')),('spawn',dict(pos=(1620,440),enemy='imp',id='sk_i2',patrol_range=60)),
            ('spawn',dict(pos=(2080,280),enemy='mote',id='sk_m2')),('bench',dict(pos=(2500,470))),('anchor',dict(pos=(2600,470),id='cienciaFile')),('spawn',dict(pos=(2690,470),enemy='underboss',id='devil5'))]),
 'archive': dict(name='Dharma Records Office', sub='Office of Continuity', size=(1120, 540), floor='metal', tint='#ffe08a', draw=True,
   solids=[(0,470,1120,70,'s'),(170,368,170,12,'o'),(790,368,170,12,'o')],
   doors=[], gates=[(4,230,28,240,'elite_alive','auditor')],
   markers=[('trigger',dict(rect=(300,0,40,540),event='auditorArena')),('anchor',dict(pos=(560,470),id='subject7')),
            ('spawn',dict(pos=(900,400),enemy='underboss',id='auditor'))]),
}
LAYER = {'s': 1, 'o': 2, 'a': 4}

def v2(p): return 'Vector2(%g, %g)' % p
def col(h):
    h = h.lstrip('#'); r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return 'Color(%.4f, %.4f, %.4f, 1)' % (r, g, b)
def gen(rid, r):
    subs, nodes = [], []
    ext = ['[ext_resource type="Script" path="res://scripts/room.gd" id="room"]',
           '[ext_resource type="Script" path="res://scripts/marker.gd" id="marker"]',
           '[ext_resource type="Script" path="res://scripts/blocker.gd" id="blocker"]']
    title = rid.capitalize()
    nodes.append(f'[node name="{title}" type="Node2D"]\nscript = ExtResource("room")\nroom_id = "{rid}"\ndisplay_name = "{r["name"]}"\nsubtitle = "{r["sub"]}"\nroom_size = {v2(r["size"])}\nfloor_sound = "{r["floor"]}"\ntint = {col(r["tint"])}\n' + ('draw_platforms = true\n' if r.get('draw') else ''))
    nodes.append('[node name="Platforms" type="Node2D" parent="."]\n')
    for i, (x, y, w, h, k) in enumerate(r['solids']):
        sid = f'shape_p{i}'; subs.append(f'[sub_resource type="RectangleShape2D" id="{sid}"]\nsize = Vector2({w}, {h})\n')
        nm = {'s': 'Solid', 'o': 'OneWay', 'a': 'Astral'}[k] + str(i)
        nodes.append(f'[node name="{nm}" type="StaticBody2D" parent="Platforms"]\nposition = {v2((x + w / 2, y + h / 2))}\ncollision_layer = {LAYER[k]}\ncollision_mask = 0\n' + ('metadata/astral = true\n' if k == 'a' else ''))
        nodes.append(f'[node name="Shape" type="CollisionShape2D" parent="Platforms/{nm}"]\nshape = SubResource("{sid}")\n' + ('one_way_collision = true\n' if k in 'oa' else ''))
    nodes.append('[node name="Blockers" type="Node2D" parent="."]\n')
    bl = [('door', d) for d in r['doors']] + [('gate', g) for g in r['gates']]
    for i, (kind, g) in enumerate(bl):
        x, y, w, h, c = g[:5]
        gflag = g[5] if len(g) > 5 else ''
        sid = f'shape_b{i}'; subs.append(f'[sub_resource type="RectangleShape2D" id="{sid}"]\nsize = Vector2({w}, {h})\n')
        nm = kind.capitalize() + str(i)
        extra = f'flag = "{c}"\n' if kind == 'door' else f'condition = "{c}"\n' + (f'flag = "{gflag}"\n' if gflag else '')
        nodes.append(f'[node name="{nm}" type="StaticBody2D" parent="Blockers"]\nposition = {v2((x + w / 2, y + h / 2))}\ncollision_layer = {8 if kind == "door" else 16}\ncollision_mask = 0\nscript = ExtResource("blocker")\nkind = "{kind}"\n{extra}size = Vector2({w}, {h})\n')
        nodes.append(f'[node name="Shape" type="CollisionShape2D" parent="Blockers/{nm}"]\nshape = SubResource("{sid}")\n')
    nodes.append('[node name="Markers" type="Node2D" parent="."]\n')
    for i, (kind, d) in enumerate(r['markers']):
        props = [f'kind = "{kind}"']
        if 'rect' in d: x, y, w, h = d['rect']; pos = (x, y); props.append(f'size = Vector2({w}, {h})')
        else: pos = d['pos']
        for k in ('target_room', 'event', 'id', 'flag', 'dialog', 'dialog_repeat', 'enemy', 'item'):
            if k in d: props.append(f'{k} = "{d[k]}"')
        if 'spawn_point' in d: props.append(f'spawn_point = {v2(d["spawn_point"])}')
        if 'face' in d: props.append(f'face = {d["face"]}')
        if 'patrol_range' in d: props.append(f'patrol_range = {d["patrol_range"]}')
        if d.get('astral'): props.append('astral = true')
        label = (d.get('id') or d.get('event') or d.get('target_room') or kind).replace(' ', '')
        nodes.append(f'[node name="{kind.capitalize()}_{label}_{i}" type="Node2D" parent="Markers"]\nposition = {v2(pos)}\nscript = ExtResource("marker")\n' + '\n'.join(props) + '\n')
    head = f'[gd_scene load_steps={len(ext) + len(subs) + 1} format=3]\n'
    return head + '\n' + '\n'.join(ext) + '\n\n' + '\n'.join(subs) + '\n' + '\n'.join(nodes)

if __name__ == '__main__':
    os.makedirs(ROOT, exist_ok=True)
    for rid, r in ROOMS.items():
        open(os.path.join(ROOT, rid + '.tscn'), 'w').write(gen(rid, r))
    print('rooms written')
