
# функции из mootools для animate
extend CMath,
	easeIn: (transition, pos, args...) -> transition(pos, args...)
	easeOut: (transition, pos, args...) -> 1 - transition 1 - pos, args...
	easeInOut: (transition, pos, args...) -> (if pos <= 0.5 then transition 2 * pos, args... else 2 - transition 2 * (1 - pos), args...) / 2

	linear: (x) -> x
	quad: (x) -> x*x
	cubic: (x) -> Math.pow x, 3
	quart: (x) -> x*x*x*x
	quint: (x) -> Math.pow x, 5
	expo: (x) -> Math.pow 2, 8 * (x - 1)
	circ: (x) -> 1 - Math.sin Math.acos x
	sine: (x) -> 1 - Math.cos x * Math.PI / 2
	back: (x, p=1.618) -> Math.pow(x, 2) * ((p + 1) * x - p)
	bounce: (x) ->
		a = 0; b = 1
		loop
			a += b; b /= 2
			if x >= (7 - 4 * a) / 11
				value = b * b - Math.pow (11 - 6 * a - 11 * x) / 4, 2
				break
		value
	elastic: (x, p=1) -> Math.pow(2, 10 * --x) * Math.cos 20 * x * Math.PI * p / 3