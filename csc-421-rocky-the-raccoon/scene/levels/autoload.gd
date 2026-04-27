extends Node

signal dialogue_show_mouse
signal dialogue_hide_mouse
signal level1_ended
signal level2_ended
signal level3_ended

const CASES := {
	1: {
		"title": "Carla's Email Case",
		"answer_labels": ["Suspicious clue", "Warning signs", "Safety advice"],
		"expected_feedback": [
			"Expected Email 1 / Rajah.",
			"Expected phishing signs like urgency, a strange sender address, money or bank requests, or unsafe links.",
			"Expected advice like verifying the sender, not sharing bank information, and avoiding suspicious links.",
		],
		"answer_checks": [
			["email 1", "rajah"],
			["phishing", "urgent", "address", "link", "bank", "https"],
			["verify", "trust", "share", "bank", "click", "link", "https"],
		],
	},
	2: {
		"title": "Patty's PictoSnap Case",
		"answer_labels": ["Suspicious clue", "Impersonation signs", "Safety advice"],
		"expected_feedback": [
			"Expected Message 1 / Clue 1 from Rodney.",
			"Expected impersonation signs like fake profile details, odd wording, AI image clues, or requests for login information.",
			"Expected advice like verifying with the real friend, never sharing login details, changing the password, or contacting support.",
		],
		"answer_checks": [
			["message 1", "clue 1", "rodney", "impersonator"],
			["fake", "ai", "login", "password", "six", "6", "formal", "wording"],
			["verify", "support", "password", "share", "login", "account"],
		],
	},
	3: {
		"title": "Peter's Malware Case",
		"answer_labels": ["Suspicious clue", "Malware signs", "Safety advice"],
		"expected_feedback": [
			"Expected the Movie Webpage / Clue 3.",
			"Expected unsafe-site signs like pop-up ads, suspicious downloads, random free sites, or missing trust signals.",
			"Expected advice like using trusted sites, avoiding unknown downloads, and checking links before clicking.",
		],
		"answer_checks": [
			["movie", "webpage", "clue 3"],
			["ads", "download", "pop-up", "popup", "unsafe", "https", "random"],
			["trusted", "download", "ads", "pop-up", "popup", "verify", "https"],
		],
	},
}

var _case_results := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_case_grades()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _show_mouse():
	dialogue_show_mouse.emit()

func _hide_mouse():
	dialogue_hide_mouse.emit()

func _level1_ended():
	_record_case_solved(1)
	level1_ended.emit()

func _level2_ended():
	_record_case_solved(2)
	level2_ended.emit()

func _level3_ended():
	_record_case_solved(3)
	level3_ended.emit()


func reset_case_grades() -> void:
	_case_results.clear()
	for case_id in CASES.keys():
		_case_results[case_id] = {
			"title": CASES[case_id].get("title", "Case"),
			"mistakes": 0,
			"solved": false,
			"choice_score": 50,
			"journal_score": 0,
			"total_score": 0,
			"grade": "Incomplete",
			"journal_feedback": "No journal answers were graded.",
			"solve_feedback": [],
		}


func _record_case_mistake(case_id: int, reason: String = "") -> void:
	if not _case_results.has(case_id):
		reset_case_grades()
	var result: Dictionary = _case_results[case_id]
	result["mistakes"] = int(result.get("mistakes", 0)) + 1
	if not reason.strip_edges().is_empty():
		var solve_feedback: Array = result.get("solve_feedback", [])
		solve_feedback.append(reason.strip_edges())
		result["solve_feedback"] = solve_feedback
	_update_case_total(case_id)


func _record_case_solved(case_id: int) -> void:
	if not _case_results.has(case_id):
		reset_case_grades()
	var result: Dictionary = _case_results[case_id]
	result["solved"] = true
	_update_case_total(case_id)


func grade_case_journal(case_id: int, answers: Array[String]) -> void:
	if not _case_results.has(case_id):
		reset_case_grades()
	if not CASES.has(case_id):
		return

	var checks: Array = CASES[case_id].get("answer_checks", [])
	var labels: Array = CASES[case_id].get("answer_labels", [])
	var expected_feedback: Array = CASES[case_id].get("expected_feedback", [])
	var earned := 0
	var max_points := checks.size() * 10
	var matched_count := 0
	var missed_feedback: Array[String] = []
	for index in range(checks.size()):
		var answer := ""
		if index < answers.size():
			answer = answers[index].to_lower()
		if _answer_matches_keywords(answer, checks[index]):
			earned += 10
			matched_count += 1
		else:
			var label := "Prompt %d" % [index + 1]
			if index < labels.size():
				label = str(labels[index])
			var expected := "The answer did not include the expected case evidence."
			if index < expected_feedback.size():
				expected = str(expected_feedback[index])
			missed_feedback.append("%s: %s" % [label, expected])

	var journal_score := int(round((float(earned) / float(max_points)) * 50.0)) if max_points > 0 else 0
	var result: Dictionary = _case_results[case_id]
	result["journal_score"] = journal_score
	if missed_feedback.is_empty():
		result["journal_feedback"] = "All journal answers matched the key evidence."
	else:
		var missed_feedback_text := PackedStringArray()
		for feedback in missed_feedback:
			missed_feedback_text.append(feedback)
		result["journal_feedback"] = "%d of %d journal prompts matched. Review: %s" % [
			matched_count,
			checks.size(),
			" ".join(missed_feedback_text),
		]
	_update_case_total(case_id)


func get_case_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var ids := _case_results.keys()
	ids.sort()
	for case_id in ids:
		results.append((_case_results[case_id] as Dictionary).duplicate(true))
	return results


func get_overall_score() -> int:
	var results := get_case_results()
	if results.is_empty():
		return 0

	var total := 0
	for result in results:
		total += int(result.get("total_score", 0))
	return int(round(float(total) / float(results.size())))


func get_letter_grade(score: int) -> String:
	if score >= 90:
		return "A"
	if score >= 80:
		return "B"
	if score >= 70:
		return "C"
	if score >= 60:
		return "D"
	return "F"


func _update_case_total(case_id: int) -> void:
	var result: Dictionary = _case_results[case_id]
	result["choice_score"] = max(0, 50 - (int(result.get("mistakes", 0)) * 10)) if result.get("solved", false) else 0
	result["total_score"] = clamp(int(result.get("choice_score", 0)) + int(result.get("journal_score", 0)), 0, 100)
	result["grade"] = get_letter_grade(int(result.get("total_score", 0))) if result.get("solved", false) else "Incomplete"


func _answer_matches_keywords(answer: String, keywords: Array) -> bool:
	for keyword in keywords:
		if answer.find(str(keyword).to_lower()) != -1:
			return true
	return false
