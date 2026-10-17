class_name SelectionProfiles
extends RefCounted

const ROOT := "res://assets/ui/character_selection/"
# Supplied filenames are swapped. Map the inspected artwork, not the filename.
const DATA: Array[Dictionary] = [
	{"id": "calaca", "display_name": "Calaca Bonifacia", "subtitle": "La pirata del cielo", "short_role": "Caos y teatralidad",
	"description": "Una capitana pirata-esqueleto tan intensa como divertida. Le encanta intimidar, presumir y atacar a sus rivales, aunque en el fondo disfruta el caos más que la victoria.",
	"tags": ["TEATRAL", "TRAVIESA", "COMPETITIVA"], "art_texture": ROOT + "char_timo_select.png"},
	{"id": "timo", "display_name": "Timo Chispa", "subtitle": "El piloto novato", "short_role": "Energía y entusiasmo",
	"description": "Un joven aviador lleno de energía que sueña con ser el más rápido del cielo. Optimista, impulsivo y un poco torpe, siempre se lanza a la aventura con una gran sonrisa.",
	"tags": ["OPTIMISTA", "IMPULSIVO", "COMPETITIVO"], "art_texture": ROOT + "char_lord_pomposo_select.png"},
	{"id": "greta", "display_name": "Greta Tuerca", "subtitle": "La inventora del caos", "short_role": "Ingenio y riesgo",
	"description": "Una brillante e ingeniosa inventora que convierte cualquier problema en un experimento divertido. Vive para crear, ajustar y explotar cosas, y rara vez juega sobre seguro.",
	"tags": ["INGENIOSA", "CAÓTICA", "INTENSA"], "art_texture": ROOT + "char_calaca_select.png"},
	{"id": "pomposo", "display_name": "Lord Pomposo IV", "subtitle": "El aristócrata del aire", "short_role": "Clase y arrogancia",
	"description": "Un noble corredor que compite como si cada carrera fuera un evento de gala. Arrogante, dramático y elegantemente exigente, convierte los cielos en su escenario personal.",
	"tags": ["ARROGANTE", "ELEGANTE", "DRAMÁTICO"], "art_texture": ROOT + "char_greta_select.png"}
]
