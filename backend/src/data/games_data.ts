export interface AfGame {
  name: string;
  displayName: string;
  package: string;
  devKey: string;
  emoji: string;
  events: AfEvent[];
}

export interface AfEvent {
  eventName: string;
  displayName: string;
  eventType: string;
  isPurchase: boolean;
}

export interface SingularGame {
  name: string;
  displayName: string;
  package: string;
  appKey: string;
  emoji: string;
  events: SingularEvent[];
}

export interface SingularEvent {
  eventName: string;
  displayName: string;
  eventType: string;
}

export interface AdjGame {
  name: string;
  displayName: string;
  appToken: string;
  emoji: string;
  events: AdjEvent[];
}

export interface AdjEvent {
  eventName: string;
  eventToken: string;
  displayName: string;
  levelValue: number;
}

export interface DetectedGame {
  found: true;
  platform: 'af' | 'singular' | 'adj';
  game: AfGame | SingularGame | AdjGame;
}

export interface GameNotFound {
  found: false;
}

export type DetectResult = DetectedGame | GameNotFound;

// ==================== AppsFlyer Games ====================
export const AF_GAMES: AfGame[] = [
  {
    name: 'dice_dream', displayName: 'Dice Dreams', package: 'com.superplaystudios.dicedreams',
    devKey: 'Hn5qYjVAaRNJYDcwF4LaWF', emoji: '🎲',
    events: [
      { eventName: 'af_kingdom_1_restored', displayName: 'Kingdom 1', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_2_restored', displayName: 'Kingdom 2', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_3_restored', displayName: 'Kingdom 3', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_4_restored', displayName: 'Kingdom 4', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_5_restored', displayName: 'Kingdom 5', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_6_restored', displayName: 'Kingdom 6', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_7_restored', displayName: 'Kingdom 7', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_8_restored', displayName: 'Kingdom 8', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_9_restored', displayName: 'Kingdom 9', eventType: 'kingdom', isPurchase: false },
      { eventName: 'af_kingdom_10_restored', displayName: 'Kingdom 10', eventType: 'kingdom', isPurchase: false }
    ],
  },
  {
    name: 'domino_dreams', displayName: 'Domino Dreams', package: 'com.screenshake.dominodreams',
    devKey: 'Hn5qYjVAaRNJYDcwF4LaWF', emoji: '🃏',
    events: [
      { eventName: 'af_area_1_completed', displayName: 'Area 1', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_2_completed', displayName: 'Area 2', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_3_completed', displayName: 'Area 3', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_4_completed', displayName: 'Area 4', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_5_completed', displayName: 'Area 5', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_6_completed', displayName: 'Area 6', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_7_completed', displayName: 'Area 7', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_8_completed', displayName: 'Area 8', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_9_completed', displayName: 'Area 9', eventType: 'area', isPurchase: false },
      { eventName: 'af_area_10_completed', displayName: 'Area 10', eventType: 'area', isPurchase: false }
    ],
  },
  {
    name: 'buzzle_chaos', displayName: 'Buzzle Chaos', package: 'com.global.pnck',
    devKey: 'ZnhUvonKa6qF9xhgt7GcBQ', emoji: '🎲',
    events: [
      { eventName: 'af_level_1_completed', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_2_completed', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_3_completed', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_4_completed', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_5_completed', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_6_completed', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_7_completed', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_8_completed', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_9_completed', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_10_completed', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'coin_master', displayName: 'Coin Master', package: 'com.moonactive.coinmaster',
    devKey: 'H3KjoCRVTiVgA5mWSAHtCe', emoji: '🎲',
    events: [
      { eventName: 'village_1_complete', displayName: 'Village 1 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_2_complete', displayName: 'Village 2 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_3_complete', displayName: 'Village 3 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_4_complete', displayName: 'Village 4 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_5_complete', displayName: 'Village 5 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_6_complete', displayName: 'Village 6 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_7_complete', displayName: 'Village 7 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_8_complete', displayName: 'Village 8 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_9_complete', displayName: 'Village 9 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_10_complete', displayName: 'Village 10 Complete', eventType: 'village', isPurchase: false }
    ],
  },
  {
    name: 'royal_match', displayName: 'Royal Match', package: 'com.dreamgames.royalmatch',
    devKey: 'B27HnbGEcbWC2fv79DDhcb', emoji: '👑',
    events: [
      { eventName: 'level_1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'level_2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'level_3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'level_4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'level_5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'level_6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'level_7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'level_8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'level_9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'level_10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'merge_gardens', displayName: 'Merge Gardens', package: 'com.futureplay.mergematch',
    devKey: 'nr8SibwpFjcKGBQNpDdttd', emoji: '🌺',
    events: [
      { eventName: 'Incent_Player_Level_Up_1', displayName: 'Player Level Up 1', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_2', displayName: 'Player Level Up 2', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_3', displayName: 'Player Level Up 3', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_4', displayName: 'Player Level Up 4', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_5', displayName: 'Player Level Up 5', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_6', displayName: 'Player Level Up 6', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_7', displayName: 'Player Level Up 7', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_8', displayName: 'Player Level Up 8', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_9', displayName: 'Player Level Up 9', eventType: 'level', isPurchase: false },
      { eventName: 'Incent_Player_Level_Up_10', displayName: 'Player Level Up 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'highroller_vegas', displayName: 'HIGHROLLER Vegas', package: 'com.lynxgames.hrv',
    devKey: 'sSpBC5SKPKEV8fbZJgw6vM', emoji: '🎲',
    events: [
      { eventName: 'app_level_achieved_1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'app_level_achieved_10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'rock_n_cash', displayName: 'Rock N Cash Casino', package: 'net.flysher.rockncash',
    devKey: 'W5VWPj5fbCGABtk59TsmJQ', emoji: '💰',
    events: [
      { eventName: 'v3_rnc_level_up_1_S2S', displayName: 'Level Up 1', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_2_S2S', displayName: 'Level Up 2', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_3_S2S', displayName: 'Level Up 3', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_4_S2S', displayName: 'Level Up 4', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_5_S2S', displayName: 'Level Up 5', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_6_S2S', displayName: 'Level Up 6', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_7_S2S', displayName: 'Level Up 7', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_8_S2S', displayName: 'Level Up 8', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_9_S2S', displayName: 'Level Up 9', eventType: 'level', isPurchase: false },
      { eventName: 'v3_rnc_level_up_10_S2S', displayName: 'Level Up 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'coinchef', displayName: 'COINCHEF', package: 'com.FortuneMine.CuisineMaster',
    devKey: 'im6mgZbZJsHKGVowkkxkGm', emoji: '🍳',
    events: [
      { eventName: 'level1_completed', displayName: 'Level 1 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level2_completed', displayName: 'Level 2 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level3_completed', displayName: 'Level 3 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level4_completed', displayName: 'Level 4 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level5_completed', displayName: 'Level 5 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level6_completed', displayName: 'Level 6 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level7_completed', displayName: 'Level 7 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level8_completed', displayName: 'Level 8 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level9_completed', displayName: 'Level 9 Completed', eventType: 'level', isPurchase: false },
      { eventName: 'level10_completed', displayName: 'Level 10 Completed', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'blackjack21', displayName: 'Blackjack 21', package: 'com.kamagames.blackjack',
    devKey: 'YbczyDZZmXbxwpYYyJgqTQ', emoji: '🃏',
    events: [
      { eventName: '1level', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: '2level', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: '3level', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: '4level', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: '5level', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: '6level', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: '7level', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: '8level', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: '9level', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: '10level', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'sunshine_island', displayName: 'Sunshine Island', package: 'com.newmoonproduction.sunshineisland',
    devKey: 'FtaT5WH9rMJjJkMd4LfBCT', emoji: '🏝️',
    events: [
      { eventName: 'af_level1_achieved', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level2_achieved', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level3_achieved', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level4_achieved', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level5_achieved', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level6_achieved', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level7_achieved', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level8_achieved', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level9_achieved', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level10_achieved', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'farmville3', displayName: 'Farmville 3', package: 'com.zynga.FarmVille2CountryEscape',
    devKey: '438VCPmX2ZLYvsDPfGLZXb', emoji: '🌾',
    events: [
      { eventName: 'Player_Level1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'Player_Level10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'disney_solitaire', displayName: 'Disney Solitaire', package: 'com.superplaystudios.disneysolitairedreams',
    devKey: 'Hn5qYjVAaRNJYDcwF4LaWF', emoji: '🎲',
    events: [
      { eventName: 'af_level_1_completed', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_2_completed', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_3_completed', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_4_completed', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_5_completed', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_6_completed', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_7_completed', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_8_completed', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_9_completed', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_10_completed', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'matching_story', displayName: 'Matching Story', package: 'com.joycastle.mergematch',
    devKey: 'v2w2tuNCNaBNXvFJgRGPRW', emoji: '🎲',
    events: [
      { eventName: 'af_level_1_completed', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_2_completed', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_3_completed', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_4_completed', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_5_completed', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_6_completed', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_7_completed', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_8_completed', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_9_completed', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_10_completed', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'nations_of_darkness', displayName: 'Nations of Darkness', package: 'com.allstarunion.nod',
    devKey: 'x88hdqNmd8vALRmRMhgY4Q', emoji: '🎲',
    events: [
      { eventName: 'af_level_1_completed', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_2_completed', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_3_completed', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_4_completed', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_5_completed', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_6_completed', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_7_completed', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_8_completed', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_9_completed', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_10_completed', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'hero_wars', displayName: 'Hero Wars', package: 'com.nexters.herowars',
    devKey: 'MGPcVAUzD9XqbwAY6q7KMf', emoji: '🎲',
    events: [
      { eventName: 'levelup1', displayName: 'Level Up 1', eventType: 'level', isPurchase: false },
      { eventName: 'levelup2', displayName: 'Level Up 2', eventType: 'level', isPurchase: false },
      { eventName: 'levelup3', displayName: 'Level Up 3', eventType: 'level', isPurchase: false },
      { eventName: 'levelup4', displayName: 'Level Up 4', eventType: 'level', isPurchase: false },
      { eventName: 'levelup5', displayName: 'Level Up 5', eventType: 'level', isPurchase: false },
      { eventName: 'levelup6', displayName: 'Level Up 6', eventType: 'level', isPurchase: false },
      { eventName: 'levelup7', displayName: 'Level Up 7', eventType: 'level', isPurchase: false },
      { eventName: 'levelup8', displayName: 'Level Up 8', eventType: 'level', isPurchase: false },
      { eventName: 'levelup9', displayName: 'Level Up 9', eventType: 'level', isPurchase: false },
      { eventName: 'levelup10', displayName: 'Level Up 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'zombie_waves', displayName: 'Zombie Waves', package: 'com.ddup.zombiewaves.zw',
    devKey: 'wiQMRPvGaAYTGBCgM5yN9N', emoji: '🧟',
    events: [
      { eventName: 'af_zw_lv1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_zw_lv10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'coin_master_board', displayName: 'Coin Master - Board Adventure', package: 'com.moonactive.cmboard',
    devKey: 'H3KjoCRVTiVgA5mWSAHtCe', emoji: '⚔️',
    events: [
      { eventName: 'village_1_complete', displayName: 'Village 1 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_2_complete', displayName: 'Village 2 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_3_complete', displayName: 'Village 3 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_4_complete', displayName: 'Village 4 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_5_complete', displayName: 'Village 5 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_6_complete', displayName: 'Village 6 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_7_complete', displayName: 'Village 7 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_8_complete', displayName: 'Village 8 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_9_complete', displayName: 'Village 9 Complete', eventType: 'village', isPurchase: false },
      { eventName: 'village_10_complete', displayName: 'Village 10 Complete', eventType: 'village', isPurchase: false }
    ],
  },
  {
    name: 'royal_farm', displayName: 'Royal Farm', package: 'com.ugo.play.free.farm.valley',
    devKey: 'ktoVPgaiGM9AZhM5BFycVB', emoji: '🚜',
    events: [
      { eventName: 'af_level_up_1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'af_level_up_10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'idle_zombie_miner', displayName: 'Idle Zombie Miner', package: 'com.zombie.idleminertycoon',
    devKey: 'Ko6tMi9uqZbPBgJsKCuAUd', emoji: '🧟',
    events: [
      { eventName: 'mine_1_reached', displayName: 'Mine 1', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_2_reached', displayName: 'Mine 2', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_3_reached', displayName: 'Mine 3', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_4_reached', displayName: 'Mine 4', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_5_reached', displayName: 'Mine 5', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_6_reached', displayName: 'Mine 6', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_7_reached', displayName: 'Mine 7', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_8_reached', displayName: 'Mine 8', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_9_reached', displayName: 'Mine 9', eventType: 'mine', isPurchase: false },
      { eventName: 'mine_10_reached', displayName: 'Mine 10', eventType: 'mine', isPurchase: false }
    ],
  },
  {
    name: 'travel_town', displayName: 'Travel Town', package: 'io.randomco.travel',
    devKey: 'wizhvjciCuaDbAaR8KpZLn', emoji: '✈️',
    events: [
      { eventName: 'level_completed_1', displayName: 'Level 1', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_2', displayName: 'Level 2', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_3', displayName: 'Level 3', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_4', displayName: 'Level 4', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_5', displayName: 'Level 5', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_6', displayName: 'Level 6', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_7', displayName: 'Level 7', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_8', displayName: 'Level 8', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_9', displayName: 'Level 9', eventType: 'level', isPurchase: false },
      { eventName: 'level_completed_10', displayName: 'Level 10', eventType: 'level', isPurchase: false }
    ],
  },
  {
    name: 'goodville', displayName: 'Goodville', package: 'com.goodville.goodgame',
    devKey: 'MqrvZSKujKBZ4byRDHm5a4', emoji: '🏡',
    events: [
      { eventName: 'Start_Exp_1', displayName: 'Start Exp 1', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_2', displayName: 'Start Exp 2', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_3', displayName: 'Start Exp 3', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_4', displayName: 'Start Exp 4', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_5', displayName: 'Start Exp 5', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_6', displayName: 'Start Exp 6', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_7', displayName: 'Start Exp 7', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_8', displayName: 'Start Exp 8', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_9', displayName: 'Start Exp 9', eventType: 'exp', isPurchase: false },
      { eventName: 'Start_Exp_10', displayName: 'Start Exp 10', eventType: 'exp', isPurchase: false }
    ],
  },
  {
    name: 'game_of_vampires', displayName: 'Game of Vampires', package: 'com.mechanist.vampire.aos',
    devKey: 'ZCD7jvH8i9zt9ewanppetD', emoji: '🧛',
    events: [
      { eventName: 'power_1w', displayName: 'Power 1w', eventType: 'power', isPurchase: false },
      { eventName: 'power_2w', displayName: 'Power 2w', eventType: 'power', isPurchase: false },
      { eventName: 'power_3w', displayName: 'Power 3w', eventType: 'power', isPurchase: false },
      { eventName: 'power_4w', displayName: 'Power 4w', eventType: 'power', isPurchase: false },
      { eventName: 'power_5w', displayName: 'Power 5w', eventType: 'power', isPurchase: false },
      { eventName: 'power_6w', displayName: 'Power 6w', eventType: 'power', isPurchase: false },
      { eventName: 'power_7w', displayName: 'Power 7w', eventType: 'power', isPurchase: false },
      { eventName: 'power_8w', displayName: 'Power 8w', eventType: 'power', isPurchase: false },
      { eventName: 'power_9w', displayName: 'Power 9w', eventType: 'power', isPurchase: false },
      { eventName: 'power_10w', displayName: 'Power 10w', eventType: 'power', isPurchase: false }
    ],
  },
  {
    name: 'raid', displayName: 'Raid', package: 'com.plarium.raidlegends',
    devKey: 'MGPcVAUzD9XqbwAY6q7KMf', emoji: '⚔️',
    events: [
      { eventName: 'Purchase_Daily_Gem_Pack_(1.99$)', displayName: 'Purchase Daily Gem Pack (1.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(2.99$)', displayName: 'Purchase Daily Gem Pack (2.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(3.99$)', displayName: 'Purchase Daily Gem Pack (3.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(4.99$)', displayName: 'Purchase Daily Gem Pack (4.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(5.99$)', displayName: 'Purchase Daily Gem Pack (5.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(6.99$)', displayName: 'Purchase Daily Gem Pack (6.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(7.99$)', displayName: 'Purchase Daily Gem Pack (7.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(8.99$)', displayName: 'Purchase Daily Gem Pack (8.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(9.99$)', displayName: 'Purchase Daily Gem Pack (9.99$)', eventType: 'purchase', isPurchase: true },
      { eventName: 'Purchase_Daily_Gem_Pack_(10.99$)', displayName: 'Purchase Daily Gem Pack (10.99$)', eventType: 'purchase', isPurchase: true }
    ],
  }
];

// ==================== Singular Games ====================
export const SINGULAR_GAMES: SingularGame[] = [
  {
    name: 'animals_coins', displayName: 'Animals & Coins', package: 'com.innplaylabs.animalkingdomraid',
    appKey: 'innplay_labs_33d87c9b', emoji: '🦁',
    events: [
      { eventName: 'Reach Level 1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'Reach Level 2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'Reach Level 3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'Reach Level 4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'Reach Level 5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'Reach Level 6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'Reach Level 7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'Reach Level 8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'Reach Level 9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'Reach Level 10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'time_master', displayName: 'Time Master', package: 'com.firefog.timemaster',
    appKey: 'myappfree_spa_38e49215', emoji: '⏰',
    events: [
      { eventName: 'mn_location_1', displayName: 'Location 1', eventType: 'level' },
      { eventName: 'mn_location_2', displayName: 'Location 2', eventType: 'level' },
      { eventName: 'mn_location_3', displayName: 'Location 3', eventType: 'level' },
      { eventName: 'mn_location_4', displayName: 'Location 4', eventType: 'level' },
      { eventName: 'mn_location_5', displayName: 'Location 5', eventType: 'level' },
      { eventName: 'mn_location_6', displayName: 'Location 6', eventType: 'level' },
      { eventName: 'mn_location_7', displayName: 'Location 7', eventType: 'level' },
      { eventName: 'mn_location_8', displayName: 'Location 8', eventType: 'level' },
      { eventName: 'mn_location_9', displayName: 'Location 9', eventType: 'level' },
      { eventName: 'mn_location_10', displayName: 'Location 10', eventType: 'level' }
    ],
  },
  {
    name: 'beast_go', displayName: 'Beast Go', package: 'com.ninthart.board.beastgo',
    appKey: 'myappfree_spa_38e49215', emoji: '🐉',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'coin_fantasy', displayName: 'Coin Fantasy', package: 'com.okvision.coinfantasy',
    appKey: 'myappfree_spa_38e49215', emoji: '💰',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'dragon_farm', displayName: 'Dragon Farm', package: 'com.dragon.escape.island.adventure',
    appKey: 'myappfree_spa_38e49215', emoji: '🐉',
    events: [
      { eventName: 'mn_location_1', displayName: 'Location 1', eventType: 'level' },
      { eventName: 'mn_location_2', displayName: 'Location 2', eventType: 'level' },
      { eventName: 'mn_location_3', displayName: 'Location 3', eventType: 'level' },
      { eventName: 'mn_location_4', displayName: 'Location 4', eventType: 'level' },
      { eventName: 'mn_location_5', displayName: 'Location 5', eventType: 'level' },
      { eventName: 'mn_location_6', displayName: 'Location 6', eventType: 'level' },
      { eventName: 'mn_location_7', displayName: 'Location 7', eventType: 'level' },
      { eventName: 'mn_location_8', displayName: 'Location 8', eventType: 'level' },
      { eventName: 'mn_location_9', displayName: 'Location 9', eventType: 'level' },
      { eventName: 'mn_location_10', displayName: 'Location 10', eventType: 'level' }
    ],
  },
  {
    name: 'box_cat_jam', displayName: 'Box Cat Jam', package: 'com.actionfit.blockcat',
    appKey: 'actionfit_adc62229', emoji: '🐱',
    events: [
      { eventName: 'First_attempt_level_1', displayName: 'First attempt level 1', eventType: 'level' },
      { eventName: 'First_attempt_level_2', displayName: 'First attempt level 2', eventType: 'level' },
      { eventName: 'First_attempt_level_3', displayName: 'First attempt level 3', eventType: 'level' },
      { eventName: 'First_attempt_level_4', displayName: 'First attempt level 4', eventType: 'level' },
      { eventName: 'First_attempt_level_5', displayName: 'First attempt level 5', eventType: 'level' },
      { eventName: 'First_attempt_level_6', displayName: 'First attempt level 6', eventType: 'level' },
      { eventName: 'First_attempt_level_7', displayName: 'First attempt level 7', eventType: 'level' },
      { eventName: 'First_attempt_level_8', displayName: 'First attempt level 8', eventType: 'level' },
      { eventName: 'First_attempt_level_9', displayName: 'First attempt level 9', eventType: 'level' },
      { eventName: 'First_attempt_level_10', displayName: 'First attempt level 10', eventType: 'level' }
    ],
  },
  {
    name: 'idle_soap', displayName: 'Idle Soap ASMR', package: 'games.midnite.isa',
    appKey: 'myappfree_spa_38e49215', emoji: '🧼',
    events: [
      { eventName: 'soap_unlocked_1', displayName: 'Soap Unlocked 1', eventType: 'unlock' },
      { eventName: 'soap_unlocked_2', displayName: 'Soap Unlocked 2', eventType: 'unlock' },
      { eventName: 'soap_unlocked_3', displayName: 'Soap Unlocked 3', eventType: 'unlock' },
      { eventName: 'soap_unlocked_4', displayName: 'Soap Unlocked 4', eventType: 'unlock' },
      { eventName: 'soap_unlocked_5', displayName: 'Soap Unlocked 5', eventType: 'unlock' },
      { eventName: 'soap_unlocked_6', displayName: 'Soap Unlocked 6', eventType: 'unlock' },
      { eventName: 'soap_unlocked_7', displayName: 'Soap Unlocked 7', eventType: 'unlock' },
      { eventName: 'soap_unlocked_8', displayName: 'Soap Unlocked 8', eventType: 'unlock' },
      { eventName: 'soap_unlocked_9', displayName: 'Soap Unlocked 9', eventType: 'unlock' },
      { eventName: 'soap_unlocked_10', displayName: 'Soap Unlocked 10', eventType: 'unlock' }
    ],
  },
  {
    name: 'superheroes_idle', displayName: 'Superheroes Idle RPG', package: 'games.midnite.sid',
    appKey: 'myappfree_spa_38e49215', emoji: '🦸',
    events: [
      { eventName: 'mn_cheater_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'mn_cheater_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'mn_cheater_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'mn_cheater_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'mn_cheater_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'mn_cheater_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'mn_cheater_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'mn_cheater_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'mn_cheater_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'mn_cheater_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'survivor_idle', displayName: 'Survivor Idle Run', package: 'games.midnite.sri',
    appKey: 'myappfree_spa_38e49215', emoji: '🏃',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'pop_slots', displayName: 'POP Slots', package: 'com.playstudios.popslots',
    appKey: 'playstudios_3852f898', emoji: '🎰',
    events: [
      { eventName: 'level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'mgm_slots', displayName: 'MGM Slots Live', package: 'com.playstudios.showstar',
    appKey: 'playstudios_3852f898', emoji: '🎰',
    events: [
      { eventName: 'level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'myvegas', displayName: 'myVEGAS Slots', package: 'com.playstudios.myvegas',
    appKey: 'playstudios_3852f898', emoji: '🎰',
    events: [
      { eventName: 'level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'power_spin', displayName: 'Power Spin Quest', package: 'com.braingames.powerquest',
    appKey: 'brain_games_a7dde873', emoji: '💪',
    events: [
      { eventName: 'level_ended_1', displayName: 'Level 1 Ended', eventType: 'level' },
      { eventName: 'level_ended_2', displayName: 'Level 2 Ended', eventType: 'level' },
      { eventName: 'level_ended_3', displayName: 'Level 3 Ended', eventType: 'level' },
      { eventName: 'level_ended_4', displayName: 'Level 4 Ended', eventType: 'level' },
      { eventName: 'level_ended_5', displayName: 'Level 5 Ended', eventType: 'level' },
      { eventName: 'level_ended_6', displayName: 'Level 6 Ended', eventType: 'level' },
      { eventName: 'level_ended_7', displayName: 'Level 7 Ended', eventType: 'level' },
      { eventName: 'level_ended_8', displayName: 'Level 8 Ended', eventType: 'level' },
      { eventName: 'level_ended_9', displayName: 'Level 9 Ended', eventType: 'level' },
      { eventName: 'level_ended_10', displayName: 'Level 10 Ended', eventType: 'level' }
    ],
  },
  {
    name: 'sweet_jam', displayName: 'Sweet Jam!', package: 'puzzle.game.sweetjam',
    appKey: 'myappfree_spa_38e49215', emoji: '🍯',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'matching_go', displayName: 'Matching Go!', package: 'com.matchinggo.puzzlegames',
    appKey: 'xinagyi_f4545a5d', emoji: '🔗',
    events: [
      { eventName: 'user_level_1_complete', displayName: 'Level 1 Complete', eventType: 'level' },
      { eventName: 'user_level_2_complete', displayName: 'Level 2 Complete', eventType: 'level' },
      { eventName: 'user_level_3_complete', displayName: 'Level 3 Complete', eventType: 'level' },
      { eventName: 'user_level_4_complete', displayName: 'Level 4 Complete', eventType: 'level' },
      { eventName: 'user_level_5_complete', displayName: 'Level 5 Complete', eventType: 'level' },
      { eventName: 'user_level_6_complete', displayName: 'Level 6 Complete', eventType: 'level' },
      { eventName: 'user_level_7_complete', displayName: 'Level 7 Complete', eventType: 'level' },
      { eventName: 'user_level_8_complete', displayName: 'Level 8 Complete', eventType: 'level' },
      { eventName: 'user_level_9_complete', displayName: 'Level 9 Complete', eventType: 'level' },
      { eventName: 'user_level_10_complete', displayName: 'Level 10 Complete', eventType: 'level' }
    ],
  },
  {
    name: 'screw_out', displayName: 'Screw Out Factory 3D', package: 'com.ntt.screw.out.factory',
    appKey: 'puzzle_studios_4d38bec9', emoji: '🔧',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'hole_collect', displayName: 'Hole Collect', package: 'com.ntt.hole.collect.objects',
    appKey: 'puzzle_studios_4d38bec9', emoji: '🕳️',
    events: [
      { eventName: 'sng_level_1_achieved', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sng_level_2_achieved', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sng_level_3_achieved', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sng_level_4_achieved', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sng_level_5_achieved', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sng_level_6_achieved', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sng_level_7_achieved', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sng_level_8_achieved', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sng_level_9_achieved', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sng_level_10_achieved', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'tetris_block', displayName: 'Tetris Block Party', package: 'com.playstudios.tetrisblockparty',
    appKey: 'playstudios_3852f898', emoji: '🧩',
    events: [
      { eventName: 'level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'word_madness', displayName: 'Word Madness', package: 'com.word.madness',
    appKey: 'brain_games_a7dde873', emoji: '📖',
    events: [
      { eventName: '1_levels_completed', displayName: '1 Levels Completed', eventType: 'level' },
      { eventName: '2_levels_completed', displayName: '2 Levels Completed', eventType: 'level' },
      { eventName: '3_levels_completed', displayName: '3 Levels Completed', eventType: 'level' },
      { eventName: '4_levels_completed', displayName: '4 Levels Completed', eventType: 'level' },
      { eventName: '5_levels_completed', displayName: '5 Levels Completed', eventType: 'level' },
      { eventName: '6_levels_completed', displayName: '6 Levels Completed', eventType: 'level' },
      { eventName: '7_levels_completed', displayName: '7 Levels Completed', eventType: 'level' },
      { eventName: '8_levels_completed', displayName: '8 Levels Completed', eventType: 'level' },
      { eventName: '9_levels_completed', displayName: '9 Levels Completed', eventType: 'level' },
      { eventName: '10_levels_completed', displayName: '10 Levels Completed', eventType: 'level' }
    ],
  },
  {
    name: 'word_wise', displayName: 'Word Wise', package: 'com.playx.wordwise.crossword',
    appKey: 'myappfree_spa_38e49215', emoji: '📖',
    events: [
      { eventName: 'mn_level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'mn_level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'mn_level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'mn_level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'mn_level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'mn_level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'mn_level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'mn_level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'mn_level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'mn_level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'eatventure', displayName: 'Eatventure', package: 'com.hwqgrhhjfd.idlefastfood',
    appKey: 'lessmore_edff53fc', emoji: '🍔',
    events: [
      { eventName: 'restaurant_1_unlocked', displayName: 'Restaurant 1 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_2_unlocked', displayName: 'Restaurant 2 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_3_unlocked', displayName: 'Restaurant 3 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_4_unlocked', displayName: 'Restaurant 4 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_5_unlocked', displayName: 'Restaurant 5 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_6_unlocked', displayName: 'Restaurant 6 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_7_unlocked', displayName: 'Restaurant 7 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_8_unlocked', displayName: 'Restaurant 8 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_9_unlocked', displayName: 'Restaurant 9 Unlocked', eventType: 'unlock' },
      { eventName: 'restaurant_10_unlocked', displayName: 'Restaurant 10 Unlocked', eventType: 'unlock' }
    ],
  },
  {
    name: 'myappfree', displayName: 'MyAppFree', package: 'myappfreesrl.com.myappfree',
    appKey: 'loyaltydigital_10c54e02', emoji: '📱',
    events: [
      { eventName: '1_cashout_s2s', displayName: '1 Cashouts', eventType: 'cashout' },
      { eventName: '2_cashout_s2s', displayName: '2 Cashouts', eventType: 'cashout' },
      { eventName: '3_cashout_s2s', displayName: '3 Cashouts', eventType: 'cashout' },
      { eventName: '4_cashout_s2s', displayName: '4 Cashouts', eventType: 'cashout' },
      { eventName: '5_cashout_s2s', displayName: '5 Cashouts', eventType: 'cashout' },
      { eventName: '6_cashout_s2s', displayName: '6 Cashouts', eventType: 'cashout' },
      { eventName: '7_cashout_s2s', displayName: '7 Cashouts', eventType: 'cashout' },
      { eventName: '8_cashout_s2s', displayName: '8 Cashouts', eventType: 'cashout' },
      { eventName: '9_cashout_s2s', displayName: '9 Cashouts', eventType: 'cashout' },
      { eventName: '10_cashout_s2s', displayName: '10 Cashouts', eventType: 'cashout' }
    ],
  },
  {
    name: 'supermarketaffairs', displayName: 'Supermarket Affairs', package: 'com.potatoplay.supermarketaffairs',
    appKey: 'potatoplay_52168b49', emoji: '🎮',
    events: [
      { eventName: 'sma_player_level_1', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'sma_player_level_2', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'sma_player_level_3', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'sma_player_level_4', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'sma_player_level_5', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'sma_player_level_6', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'sma_player_level_7', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'sma_player_level_8', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'sma_player_level_9', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'sma_player_level_10', displayName: 'Level 10', eventType: 'level' }
    ],
  },
  {
    name: 'mergerestaurant', displayName: 'Merge Restaurant', package: 'com.potatoplay.mergerestaurant',
    appKey: 'potatoplay_52168b49', emoji: '🍳',
    events: [
      { eventName: 'lv1_playerLevelUp', displayName: 'Level 1', eventType: 'level' },
      { eventName: 'lv2_playerLevelUp', displayName: 'Level 2', eventType: 'level' },
      { eventName: 'lv3_playerLevelUp', displayName: 'Level 3', eventType: 'level' },
      { eventName: 'lv4_playerLevelUp', displayName: 'Level 4', eventType: 'level' },
      { eventName: 'lv5_playerLevelUp', displayName: 'Level 5', eventType: 'level' },
      { eventName: 'lv6_playerLevelUp', displayName: 'Level 6', eventType: 'level' },
      { eventName: 'lv7_playerLevelUp', displayName: 'Level 7', eventType: 'level' },
      { eventName: 'lv8_playerLevelUp', displayName: 'Level 8', eventType: 'level' },
      { eventName: 'lv9_playerLevelUp', displayName: 'Level 9', eventType: 'level' },
      { eventName: 'lv10_playerLevelUp', displayName: 'Level 10', eventType: 'level' }
    ],
  }
];

// ==================== Adjust Games ====================
export const ADJ_GAMES: AdjGame[] = [
  {
    name: 'get_color', displayName: 'Get Color', appToken: '367kicwptj5s', emoji: '🎨',
    events: [
      { eventName: 'level_1', eventToken: 'xaji0y', displayName: 'Level 1', levelValue: 10 },
      { eventName: 'level_2', eventToken: '6dpbhs', displayName: 'Level 2', levelValue: 20 },
      { eventName: 'level_3', eventToken: 'ahxthv', displayName: 'Level 3', levelValue: 30 },
      { eventName: 'level_4', eventToken: '3a3zmf', displayName: 'Level 4', levelValue: 40 },
      { eventName: 'level_5', eventToken: '8mdd4v', displayName: 'Level 5', levelValue: 50 },
      { eventName: 'level_6', eventToken: '30t9nt', displayName: 'Level 6', levelValue: 60 },
      { eventName: 'level_7', eventToken: '3w5uzb', displayName: 'Level 7', levelValue: 70 },
      { eventName: 'level_8', eventToken: 'ikcidk', displayName: 'Level 8', levelValue: 80 },
      { eventName: 'level_9', eventToken: 'wnnhj7', displayName: 'Level 9', levelValue: 90 },
      { eventName: 'level_10', eventToken: 'xvg0fn', displayName: 'Level 10', levelValue: 100 }
    ],
  },
  {
    name: 'merge_blocks', displayName: '2048 X2 Merge Blocks', appToken: '367kicwptj5s', emoji: '🔲',
    events: [
      { eventName: 'event_callback_9xuy41', eventToken: '9xuy41', displayName: 'Step 1', levelValue: 10 },
      { eventName: 'event_callback_ibljh7', eventToken: 'ibljh7', displayName: 'Step 2', levelValue: 20 },
      { eventName: 'event_callback_5lxo6q', eventToken: '5lxo6q', displayName: 'Step 3', levelValue: 30 },
      { eventName: 'event_callback_jiujv6', eventToken: 'jiujv6', displayName: 'Step 4', levelValue: 40 },
      { eventName: 'event_callback_oh9sdb', eventToken: 'oh9sdb', displayName: 'Step 5', levelValue: 50 },
      { eventName: 'event_callback_dw2pcn', eventToken: 'dw2pcn', displayName: 'Step 6', levelValue: 60 },
      { eventName: 'event_callback_9t84az', eventToken: '9t84az', displayName: 'Step 7', levelValue: 70 },
      { eventName: 'event_callback_ytjxep', eventToken: 'ytjxep', displayName: 'Step 8', levelValue: 80 },
      { eventName: 'event_callback_q85jsg', eventToken: 'q85jsg', displayName: 'Step 9', levelValue: 90 },
      { eventName: 'event_callback_65kxvf', eventToken: '65kxvf', displayName: 'Step 10', levelValue: 100 }
    ],
  },
  {
    name: 'bingo_aloha', displayName: 'Bingo Aloha', appToken: '367kicwptj5s', emoji: '🍍',
    events: [
      { eventName: 'event_callback_1t2tal', eventToken: '1t2tal', displayName: 'Level 1', levelValue: 10 },
      { eventName: 'event_callback_a753lc', eventToken: 'a753lc', displayName: 'Level 2', levelValue: 20 },
      { eventName: 'event_callback_58drc1', eventToken: '58drc1', displayName: 'Level 3', levelValue: 30 },
      { eventName: 'event_callback_1ertj5', eventToken: '1ertj5', displayName: 'Level 4', levelValue: 40 },
      { eventName: 'event_callback_pht0hl', eventToken: 'pht0hl', displayName: 'Level 5', levelValue: 50 },
      { eventName: 'event_callback_9xpsei', eventToken: '9xpsei', displayName: 'Level 6', levelValue: 60 },
      { eventName: 'event_callback_mvihcw', eventToken: 'mvihcw', displayName: 'Level 7', levelValue: 70 },
      { eventName: 'event_callback_i64ciy', eventToken: 'i64ciy', displayName: 'Level 8', levelValue: 80 },
      { eventName: 'event_callback_he7ur2', eventToken: 'he7ur2', displayName: 'Level 9', levelValue: 90 },
      { eventName: 'event_callback_3gdppq', eventToken: '3gdppq', displayName: 'Level 10', levelValue: 100 }
    ],
  },
  {
    name: 'battle_night', displayName: 'Battle Night', appToken: '367kicwptj5s', emoji: '⚔️',
    events: [
      { eventName: 'event_callback_0y9dom', eventToken: '0y9dom', displayName: 'Chapter 1', levelValue: 10 },
      { eventName: 'event_callback_5igqpk', eventToken: '5igqpk', displayName: 'Chapter 2', levelValue: 20 },
      { eventName: 'event_callback_i7p5tb', eventToken: 'i7p5tb', displayName: 'Chapter 3', levelValue: 30 },
      { eventName: 'event_callback_94874f', eventToken: '94874f', displayName: 'Chapter 4', levelValue: 40 },
      { eventName: 'event_callback_rhocn9', eventToken: 'rhocn9', displayName: 'Chapter 5', levelValue: 50 },
      { eventName: 'event_callback_j2qp89', eventToken: 'j2qp89', displayName: 'Chapter 6', levelValue: 60 },
      { eventName: 'event_callback_uzfk8u', eventToken: 'uzfk8u', displayName: 'Chapter 7', levelValue: 70 },
      { eventName: 'event_callback_t0cvs4', eventToken: 't0cvs4', displayName: 'Chapter 8', levelValue: 80 },
      { eventName: 'event_callback_f8cgvy', eventToken: 'f8cgvy', displayName: 'Chapter 9', levelValue: 90 },
      { eventName: 'event_callback_ie6ivw', eventToken: 'ie6ivw', displayName: 'Chapter 10', levelValue: 100 }
    ],
  },
  {
    name: 'blast_friends', displayName: 'Blast Friends', appToken: '367kicwptj5s', emoji: '💥',
    events: [
      { eventName: 'event_callback_pvs7hz', eventToken: 'pvs7hz', displayName: 'Level 1', levelValue: 10 },
      { eventName: 'event_callback_ioykl1', eventToken: 'ioykl1', displayName: 'Level 2', levelValue: 20 },
      { eventName: 'event_callback_cq99ch', eventToken: 'cq99ch', displayName: 'Level 3', levelValue: 30 },
      { eventName: 'event_callback_j755nf', eventToken: 'j755nf', displayName: 'Level 4', levelValue: 40 },
      { eventName: 'event_callback_4zw9xa', eventToken: '4zw9xa', displayName: 'Level 5', levelValue: 50 },
      { eventName: 'event_callback_3kx7ee', eventToken: '3kx7ee', displayName: 'Level 6', levelValue: 60 },
      { eventName: 'event_callback_dtjvzh', eventToken: 'dtjvzh', displayName: 'Level 7', levelValue: 70 },
      { eventName: 'event_callback_wjr64d', eventToken: 'wjr64d', displayName: 'Level 8', levelValue: 80 },
      { eventName: 'event_callback_pja1wj', eventToken: 'pja1wj', displayName: 'Level 9', levelValue: 90 },
      { eventName: 'event_callback_0tpac5', eventToken: '0tpac5', displayName: 'Level 10', levelValue: 100 }
    ],
  },
  {
    name: 'block_blitz', displayName: 'Block Blitz', appToken: '367kicwptj5s', emoji: '🧱',
    events: [
      { eventName: 'event_callback_6t4ufe', eventToken: '6t4ufe', displayName: 'Level 1', levelValue: 10 },
      { eventName: 'event_callback_l6246h', eventToken: 'l6246h', displayName: 'Level 2', levelValue: 20 },
      { eventName: 'event_callback_id25ow', eventToken: 'id25ow', displayName: 'Level 3', levelValue: 30 },
      { eventName: 'event_callback_f75935', eventToken: 'f75935', displayName: 'Level 4', levelValue: 40 },
      { eventName: 'event_callback_a0l725', eventToken: 'a0l725', displayName: 'Level 5', levelValue: 50 },
      { eventName: 'event_callback_3j2d54', eventToken: '3j2d54', displayName: 'Level 6', levelValue: 60 },
      { eventName: 'event_callback_i3qk2i', eventToken: 'i3qk2i', displayName: 'Level 7', levelValue: 70 },
      { eventName: 'event_callback_agl58k', eventToken: 'agl58k', displayName: 'Level 8', levelValue: 80 },
      { eventName: 'event_callback_xo9t7e', eventToken: 'xo9t7e', displayName: 'Level 9', levelValue: 90 },
      { eventName: 'event_callback_8g8jdp', eventToken: '8g8jdp', displayName: 'Level 10', levelValue: 100 }
    ],
  }
];

// ==================== Package Lookup Maps ====================
export const AF_BY_PACKAGE = new Map<string, AfGame>(
  AF_GAMES.map((g) => [g.package, g])
);

export const SINGULAR_BY_PACKAGE = new Map<string, SingularGame>(
  SINGULAR_GAMES.map((g) => [g.package, g])
);

export function detectGameByPackage(pkg: string): DetectResult {
  const afGame = AF_BY_PACKAGE.get(pkg);
  if (afGame) return { found: true, platform: 'af', game: afGame };

  const singularGame = SINGULAR_BY_PACKAGE.get(pkg);
  if (singularGame) return { found: true, platform: 'singular', game: singularGame };

  return { found: false };
}
