class_name Tester
extends RefCounted
## Petit cadre d'assertions pour les tests headless.

var total := 0
var failed := 0
var _section := ""
var messages: Array = []

func section(n: String) -> void:
	_section = n

func _fail(msg: String) -> void:
	failed += 1
	messages.append("  ✗ [%s] %s" % [_section, msg])

func ok(cond: bool, msg: String) -> void:
	total += 1
	if not cond:
		_fail(msg)

func bad(cond: bool, msg: String) -> void:
	ok(not cond, msg)

func eq(a, b, msg: String) -> void:
	total += 1
	if a != b:
		_fail("%s (attendu %s, obtenu %s)" % [msg, str(b), str(a)])

func ne(a, b, msg: String) -> void:
	total += 1
	if a == b:
		_fail("%s (les deux valent %s)" % [msg, str(a)])

func approx(a: float, b: float, eps: float, msg: String) -> void:
	total += 1
	if absf(a - b) > eps:
		_fail("%s (attendu ~%s, obtenu %s)" % [msg, str(b), str(a)])

func gt(a, b, msg: String) -> void:
	total += 1
	if not (a > b):
		_fail("%s (%s n'est pas > %s)" % [msg, str(a), str(b)])

func ge(a, b, msg: String) -> void:
	total += 1
	if not (a >= b):
		_fail("%s (%s n'est pas >= %s)" % [msg, str(a), str(b)])

func lt(a, b, msg: String) -> void:
	total += 1
	if not (a < b):
		_fail("%s (%s n'est pas < %s)" % [msg, str(a), str(b)])

func passed() -> int:
	return total - failed
