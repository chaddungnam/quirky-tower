extends RefCounted

const LANGUAGE_CODES := ["ko", "en", "de", "ja", "fr", "es", "it", "zh_CN", "zh_TW", "ar"]
const LANGUAGE_NAMES := {
	"ko": "한국어",
	"en": "English",
	"de": "Deutsch",
	"ja": "日本語",
	"fr": "Français",
	"es": "Español",
	"it": "Italiano",
	"zh_CN": "简体中文",
	"zh_TW": "繁體中文",
	"ar": "العربية",
}
const STRINGS := {
	"en": {
		"tagline": "STOP. SPOT. DODGE.",
		"prototype": "15-FLOOR PROTOTYPE",
		"play": "PLAY",
		"settings": "SETTINGS",
		"settings_hint": "Adjust the prototype before entering the tower.",
		"bgm": "BGM",
		"sfx": "SOUND EFFECTS",
		"vibration": "VIBRATION",
		"language": "LANGUAGE",
		"back": "BACK TO HOME",
		"on": "ON",
		"off": "OFF",
		"choose_language": "CHOOSE LANGUAGE",
		"choose_one": "Choose a language.",
		"cancel": "CANCEL",
	},
	"ko": {
		"tagline": "멈추고, 찾고, 피한다!", "prototype": "15층 프로토타입", "play": "게임 시작",
		"settings": "설정", "settings_hint": "타워에 들어가기 전 프로토타입 설정을 조정하세요.",
		"bgm": "배경음", "sfx": "효과음", "vibration": "진동", "language": "언어",
		"back": "홈으로", "on": "켜짐", "off": "꺼짐", "choose_language": "언어 선택",
		"choose_one": "언어를 고르세요.",
		"cancel": "취소",
	},
	"de": {
		"tagline": "STOPPEN. FINDEN. AUSWEICHEN.", "prototype": "PROTOTYP MIT 15 ETAGEN",
		"play": "SPIEL STARTEN", "settings": "EINSTELLUNGEN",
		"settings_hint": "Passe den Prototyp an, bevor du den verrückten Turm betrittst.",
		"bgm": "HINTERGRUNDMUSIK", "sfx": "SOUNDEFFEKTE", "vibration": "VIBRATION",
		"language": "SPRACHE", "back": "ZURÜCK ZUM STARTBILDSCHIRM", "on": "AN", "off": "AUS",
		"choose_language": "SPRACHE AUSWÄHLEN",
		"choose_one": "Wähle eine Sprache.",
		"cancel": "ABBRECHEN",
	},
	"ja": {
		"tagline": "止めて、見つけて、避けろ！", "prototype": "15階プロトタイプ", "play": "プレイ",
		"settings": "設定", "settings_hint": "タワーに入る前に設定を調整します。", "bgm": "BGM",
		"sfx": "効果音", "vibration": "振動", "language": "言語", "back": "ホームへ戻る",
		"on": "オン", "off": "オフ", "choose_language": "言語を選択",
		"choose_one": "言語を選んでください。",
		"cancel": "キャンセル",
	},
	"fr": {
		"tagline": "STOPPE. REPÈRE. ESQUIVE.", "prototype": "PROTOTYPE DE 15 ÉTAGES",
		"play": "JOUER", "settings": "PARAMÈTRES",
		"settings_hint": "Réglez le prototype avant d'entrer dans la tour.",
		"bgm": "MUSIQUE", "sfx": "EFFETS SONORES", "vibration": "VIBRATION", "language": "LANGUE",
		"back": "RETOUR À L'ACCUEIL", "on": "OUI", "off": "NON", "choose_language": "CHOISIR LA LANGUE",
		"choose_one": "Choisissez une langue.",
		"cancel": "ANNULER",
	},
	"es": {
		"tagline": "PARA. ENCUENTRA. ESQUIVA.", "prototype": "PROTOTIPO DE 15 PISOS", "play": "JUGAR",
		"settings": "AJUSTES", "settings_hint": "Ajusta el prototipo antes de entrar en la torre.",
		"bgm": "MÚSICA", "sfx": "EFECTOS DE SONIDO", "vibration": "VIBRACIÓN", "language": "IDIOMA",
		"back": "VOLVER AL INICIO", "on": "SÍ", "off": "NO", "choose_language": "ELEGIR IDIOMA",
		"choose_one": "Elige un idioma.",
		"cancel": "CANCELAR",
	},
	"it": {
		"tagline": "FERMA. TROVA. SCHIVA.", "prototype": "PROTOTIPO DI 15 PIANI", "play": "GIOCA",
		"settings": "IMPOSTAZIONI", "settings_hint": "Regola il prototipo prima di entrare nella torre.",
		"bgm": "MUSICA", "sfx": "EFFETTI SONORI", "vibration": "VIBRAZIONE", "language": "LINGUA",
		"back": "TORNA ALLA HOME", "on": "SÌ", "off": "NO", "choose_language": "SCEGLI LA LINGUA",
		"choose_one": "Scegli una lingua.",
		"cancel": "ANNULLA",
	},
	"zh_CN": {
		"tagline": "停下、找准、闪避！", "prototype": "15层原型", "play": "开始游戏", "settings": "设置",
		"settings_hint": "进入高塔前调整原型设置。", "bgm": "背景音乐", "sfx": "音效", "vibration": "振动",
		"language": "语言", "back": "返回主页", "on": "开", "off": "关", "choose_language": "选择语言",
		"choose_one": "请选择语言。",
		"cancel": "取消",
	},
	"zh_TW": {
		"tagline": "停下、找準、閃避！", "prototype": "15層原型", "play": "開始遊戲", "settings": "設定",
		"settings_hint": "進入高塔前調整原型設定。", "bgm": "背景音樂", "sfx": "音效", "vibration": "震動",
		"language": "語言", "back": "返回首頁", "on": "開", "off": "關", "choose_language": "選擇語言",
		"choose_one": "請選擇語言。",
		"cancel": "取消",
	},
	"ar": {
		"tagline": "أوقف. اعثر. تفادَ.", "prototype": "نموذج أولي من 15 طابقًا", "play": "ابدأ اللعب",
		"settings": "الإعدادات", "settings_hint": "اضبط النموذج الأولي قبل دخول البرج.",
		"bgm": "موسيقى الخلفية", "sfx": "المؤثرات الصوتية", "vibration": "الاهتزاز", "language": "اللغة",
		"back": "العودة إلى الرئيسية", "on": "تشغيل", "off": "إيقاف", "choose_language": "اختر اللغة",
		"choose_one": "اختر لغة.",
		"cancel": "إلغاء",
	},
}


static func supported_code(locale: String) -> String:
	var normalized := locale.replace("-", "_")
	if normalized in LANGUAGE_CODES:
		return normalized
	var base := normalized.split("_")[0]
	return base if base in LANGUAGE_CODES else "en"


static func text(locale: String, key: String) -> String:
	var code := supported_code(locale)
	return str(STRINGS.get(code, STRINGS.en).get(key, STRINGS.en.get(key, key)))


static func language_name(code: String) -> String:
	return str(LANGUAGE_NAMES.get(code, LANGUAGE_NAMES.en))
