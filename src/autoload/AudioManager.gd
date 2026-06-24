extends Node
## Sons et ambiances générés par synthèse (aucun fichier audio externe, donc aucune licence).
## Effets courts (clic, coups, soins…) + nappes d'ambiance en boucle.

const MIX := 22050

var _sfx: Dictionary = {}      # nom -> AudioStreamWAV
var _music: Dictionary = {}    # nom -> AudioStreamWAV (bouclé)
var _players: Array = []       # pool d'AudioStreamPlayer pour les SFX
var _music_player: AudioStreamPlayer
var _current_music := ""

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -16.0
	add_child(_music_player)
	_build_sfx()
	_build_music()

# ---------------------------------------------------------------- synthèse
func _encode(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		if v < 0:
			v += 65536
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return bytes

func _stream(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX
	s.stereo = false
	s.data = _encode(samples)
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s

## Génère une tonalité. type: "sine","square","saw","noise","tri".
func _tone(freq: float, dur: float, type: String, vol: float,
		sweep: float = 1.0, decay: float = 4.0) -> PackedFloat32Array:
	var n := int(dur * MIX)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX
		var f := freq * lerpf(1.0, sweep, t / maxf(dur, 0.0001))
		phase += TAU * f / MIX
		var w := 0.0
		match type:
			"sine": w = sin(phase)
			"square": w = 1.0 if sin(phase) >= 0.0 else -1.0
			"saw": w = fposmod(phase, TAU) / PI - 1.0
			"tri": w = asin(sin(phase)) * (2.0 / PI)
			"noise": w = randf() * 2.0 - 1.0
		var env := exp(-decay * t / maxf(dur, 0.0001))
		out[i] = w * env * vol
	return out

func _concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out

func _mix2(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a[i] if i < a.size() else 0.0
		var vb := b[i] if i < b.size() else 0.0
		out[i] = clampf(va + vb, -1.0, 1.0)
	return out

func _build_sfx() -> void:
	_sfx["click"] = _stream(_tone(660, 0.08, "square", 0.25, 1.0, 12.0))
	_sfx["hover"] = _stream(_tone(880, 0.05, "sine", 0.15, 1.0, 16.0))
	_sfx["attack"] = _stream(_mix2(_tone(180, 0.18, "saw", 0.35, 0.5, 9.0), _tone(90, 0.12, "noise", 0.2, 1.0, 14.0)))
	_sfx["hit"] = _stream(_tone(120, 0.15, "noise", 0.4, 0.4, 12.0))
	_sfx["crit"] = _stream(_concat([_tone(140, 0.06, "noise", 0.45, 1.0, 10.0), _tone(520, 0.16, "saw", 0.35, 0.6, 7.0)]))
	_sfx["heal"] = _stream(_concat([_tone(523, 0.1, "sine", 0.3, 1.05, 5.0), _tone(784, 0.18, "sine", 0.28, 1.05, 4.0)]))
	_sfx["buff"] = _stream(_tone(440, 0.22, "tri", 0.3, 1.6, 4.0))
	_sfx["debuff"] = _stream(_tone(330, 0.22, "tri", 0.3, 0.55, 4.0))
	_sfx["death"] = _stream(_tone(200, 0.3, "saw", 0.35, 0.35, 6.0))
	_sfx["summon"] = _stream(_concat([
		_tone(392, 0.12, "sine", 0.3, 1.02, 3.0), _tone(523, 0.12, "sine", 0.3, 1.02, 3.0),
		_tone(659, 0.12, "sine", 0.3, 1.02, 3.0), _tone(784, 0.3, "sine", 0.34, 1.02, 2.5)]))
	_sfx["reveal_rare"] = _stream(_concat([
		_tone(523, 0.1, "square", 0.3, 1.0, 6.0), _tone(659, 0.1, "square", 0.3, 1.0, 6.0),
		_tone(880, 0.35, "sine", 0.4, 1.0, 3.0)]))
	_sfx["victory"] = _stream(_concat([
		_tone(523, 0.14, "tri", 0.32, 1.0, 3.0), _tone(659, 0.14, "tri", 0.32, 1.0, 3.0),
		_tone(784, 0.14, "tri", 0.32, 1.0, 3.0), _tone(1047, 0.4, "tri", 0.36, 1.0, 2.2)]))
	_sfx["defeat"] = _stream(_concat([
		_tone(440, 0.18, "tri", 0.3, 1.0, 4.0), _tone(349, 0.18, "tri", 0.3, 1.0, 4.0),
		_tone(262, 0.45, "tri", 0.32, 0.9, 3.0)]))

func _pad(freqs: Array, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * MIX)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / MIX
		var s := 0.0
		for f in freqs:
			s += sin(TAU * f * t)
		# fondu doux aux extrémités pour une boucle propre
		var fade := minf(1.0, minf(t / 0.4, (dur - t) / 0.4))
		out[i] = (s / float(freqs.size())) * vol * fade
	return out

func _build_music() -> void:
	_music["menu"] = _stream(_pad([196.0, 246.94, 293.66], 4.0, 0.5), true)
	_music["battle"] = _stream(_pad([220.0, 261.63, 329.63], 4.0, 0.5), true)
	_music["boss"] = _stream(_pad([146.83, 174.61, 220.0], 4.0, 0.55), true)

# ---------------------------------------------------------------- API
func play_sfx(name: String) -> void:
	if not GameState.settings.get("sfx", true):
		return
	if not _sfx.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sfx[name]
			p.play()
			return
	_players[0].stream = _sfx[name]
	_players[0].play()

func play_music(name: String) -> void:
	if _current_music == name:
		return
	_current_music = name
	if not GameState.settings.get("music", true) or not _music.has(name):
		_music_player.stop()
		return
	_music_player.stream = _music[name]
	_music_player.play()

func stop_music() -> void:
	_current_music = ""
	_music_player.stop()

func refresh_music_setting() -> void:
	if GameState.settings.get("music", true):
		if _current_music != "" and _music.has(_current_music):
			if not _music_player.playing:
				_music_player.stream = _music[_current_music]
				_music_player.play()
	else:
		_music_player.stop()
