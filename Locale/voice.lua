-- Narrator — voice manifest (auto-managed).
-- Produced by tools/generate-voice.mjs (esES:40, esMX:40, enUS:40).
-- Safe to delete; the addon then falls back to text + game sounds.

Narrator = Narrator or {}
Narrator.VOICE = Narrator.VOICE or {}
Narrator.VOICE["esES"] = {
  death = {
    "esES/death_d08168941a.wav",
    "esES/death_58d5dbf856.wav",
    "esES/death_c2edc6edb1.wav",
  },
  pvpdeath = {
    "esES/pvpdeath_96a3833f84.wav",
    "esES/pvpdeath_e472087337.wav",
    "esES/pvpdeath_1df3a02695.wav",
  },
  milestone = {
    "esES/milestone_443c5dd0f4.wav",
    "esES/milestone_f992fc25e5.wav",
    "esES/milestone_6d17fa0aeb.wav",
  },
  fall = {
    "esES/fall_e2bccd59c2.wav",
    "esES/fall_b7e89914a0.wav",
    "esES/fall_b50bb0596f.wav",
  },
  fire = {
    "esES/fire_8f7c1ca35d.wav",
    "esES/fire_ab32ee9095.wav",
    "esES/fire_aeaceb254b.wav",
  },
  drown = {
    "esES/drown_21c8db3ae7.wav",
    "esES/drown_703febc9ed.wav",
    "esES/drown_fffa31bfd3.wav",
  },
  fatigue = {
    "esES/fatigue_4c1a71fc12.wav",
    "esES/fatigue_6608d1eb43.wav",
  },
  unknown = {
    "esES/unknown_e0e3333296.wav",
    "esES/unknown_99d18dbe40.wav",
  },
  crit = {
    "esES/crit_f8ba834268.wav",
    "esES/crit_3f66dd3c77.wav",
    "esES/crit_26c971781f.wav",
  },
  levelup = {
    "esES/levelup_cdca301ca9.wav",
    "esES/levelup_cd38f694ce.wav",
    "esES/levelup_53ee3fc809.wav",
  },
  loot = {
    "esES/loot_24365d78e0.wav",
    "esES/loot_de56200b2f.wav",
    "esES/loot_a0df433d97.wav",
  },
  legendary = {
    "esES/legendary_6915e193ff.wav",
    "esES/legendary_d23ad5499e.wav",
    "esES/legendary_f976361162.wav",
  },
  pvpkill = {
    "esES/pvpkill_060f7f3fb3.wav",
    "esES/pvpkill_a16f42b57e.wav",
    "esES/pvpkill_9cfac7b8c7.wav",
  },
  login = {
    "esES/login_ef868fafe8.wav",
    "esES/login_3d5068a61a.wav",
    "esES/login_9822cd730d.wav",
  },
}
Narrator.VOICE["esMX"] = {
  death = {
    "esMX/death_7b76fa517c.wav",
    "esMX/death_4f34fd7d3f.wav",
    "esMX/death_058786c7e3.wav",
  },
  pvpdeath = {
    "esMX/pvpdeath_367d4b6f73.wav",
    "esMX/pvpdeath_2b51af8f7c.wav",
    "esMX/pvpdeath_ffa43e17aa.wav",
  },
  milestone = {
    "esMX/milestone_04537efa1f.wav",
    "esMX/milestone_1ac9cf0e34.wav",
    "esMX/milestone_29875b48a0.wav",
  },
  fall = {
    "esMX/fall_b1410d9626.wav",
    "esMX/fall_2da8af1fa8.wav",
    "esMX/fall_ed36961a9a.wav",
  },
  fire = {
    "esMX/fire_cba17ebcf0.wav",
    "esMX/fire_1a7ebee2b8.wav",
    "esMX/fire_566317c52b.wav",
  },
  drown = {
    "esMX/drown_d760cfdca7.wav",
    "esMX/drown_17cfd4be24.wav",
    "esMX/drown_1e491f7eac.wav",
  },
  fatigue = {
    "esMX/fatigue_7d9548dc7b.wav",
    "esMX/fatigue_6203656d2a.wav",
  },
  unknown = {
    "esMX/unknown_60ecc52def.wav",
    "esMX/unknown_cc7e5719e6.wav",
  },
  crit = {
    "esMX/crit_961a66dd36.wav",
    "esMX/crit_2535bebb99.wav",
    "esMX/crit_2a61df8120.wav",
  },
  levelup = {
    "esMX/levelup_dc7a0e9123.wav",
    "esMX/levelup_8b9a9565b3.wav",
    "esMX/levelup_7b58767132.wav",
  },
  loot = {
    "esMX/loot_4b2fcf234f.wav",
    "esMX/loot_c6df0b1ace.wav",
    "esMX/loot_9f82fb3486.wav",
  },
  legendary = {
    "esMX/legendary_32ee2b8760.wav",
    "esMX/legendary_276719f45b.wav",
    "esMX/legendary_7ae7d43bde.wav",
  },
  pvpkill = {
    "esMX/pvpkill_6026452fab.wav",
    "esMX/pvpkill_8296910fdf.wav",
    "esMX/pvpkill_9714cb4c31.wav",
  },
  login = {
    "esMX/login_0d957541d2.wav",
    "esMX/login_1aa10f5e2d.wav",
    "esMX/login_36252ad35a.wav",
  },
}
Narrator.VOICE["enUS"] = {
  death = {
    "enUS/death_621b8695df.wav",
    "enUS/death_7a6f9ed827.wav",
    "enUS/death_f3b2d261ff.wav",
  },
  pvpdeath = {
    "enUS/pvpdeath_61db89f77d.wav",
    "enUS/pvpdeath_0f2dd8a3c8.wav",
    "enUS/pvpdeath_acfbc48abb.wav",
  },
  milestone = {
    "enUS/milestone_08cfd7080d.wav",
    "enUS/milestone_28a3d9116f.wav",
    "enUS/milestone_b851a37a7c.wav",
  },
  fall = {
    "enUS/fall_53e594579d.wav",
    "enUS/fall_acef8d3dac.wav",
    "enUS/fall_3163721069.wav",
  },
  fire = {
    "enUS/fire_e396f08c37.wav",
    "enUS/fire_ad3228461d.wav",
    "enUS/fire_01b180ca85.wav",
  },
  drown = {
    "enUS/drown_c8755ecbfb.wav",
    "enUS/drown_b4f94edd3e.wav",
    "enUS/drown_a0fd744dcf.wav",
  },
  fatigue = {
    "enUS/fatigue_7e7e3e7438.wav",
    "enUS/fatigue_41c3caf872.wav",
  },
  unknown = {
    "enUS/unknown_c8befc7ded.wav",
    "enUS/unknown_5486510f11.wav",
  },
  crit = {
    "enUS/crit_06b6042b1a.wav",
    "enUS/crit_19ae6c32e1.wav",
    "enUS/crit_916ad6cdcc.wav",
  },
  levelup = {
    "enUS/levelup_7076a2f46a.wav",
    "enUS/levelup_a00d71d5c2.wav",
    "enUS/levelup_550ecff836.wav",
  },
  loot = {
    "enUS/loot_5fc443cbf8.wav",
    "enUS/loot_bb4da2116e.wav",
    "enUS/loot_8b58377e08.wav",
  },
  legendary = {
    "enUS/legendary_6814c4e944.wav",
    "enUS/legendary_d2cfbe5c2c.wav",
    "enUS/legendary_3b2bf530d5.wav",
  },
  pvpkill = {
    "enUS/pvpkill_cf81a59103.wav",
    "enUS/pvpkill_58367269ed.wav",
    "enUS/pvpkill_59cf228bc3.wav",
  },
  login = {
    "enUS/login_aa7e33871e.wav",
    "enUS/login_656762049a.wav",
    "enUS/login_a185f184de.wav",
  },
}
