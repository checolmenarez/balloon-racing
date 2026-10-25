extends RefCounted
## Deterministic input targets for testing only. Never loaded by gameplay.
static func height(x: float, upper: bool, technical: bool = true) -> float:
	if x < 2050: return 320.0
	if x < 3100: return 370.0
	if x < 4000: return 180.0 if technical else 465.0
	if x < 4500: return 195.0 if technical else 525.0
	if x < 5150: return 420.0
	if x < 6000: return 270.0
	if x < 6750: return 350.0
	if x < 8900 and not technical: return 550.0
	if x < 7600: return 130.0
	if x < 8050: return 325.0
	if x < 8800: return 140.0
	if x < 10050: return 335.0
	if x < 10900: return 170.0 if upper else 535.0
	if x < 11500: return 195.0 if upper else 535.0
	if x < 13000: return 178.0 if upper else 535.0
	if x < 13700: return 200.0
	if x < 16050 and not technical: return 550.0
	if x < 14700: return 130.0
	if x < 15150: return 325.0
	if x < 16000: return 140.0
	if x < 16600: return 335.0
	if x < 17150: return 400.0
	if x < 17500: return 320.0
	return 230.0
