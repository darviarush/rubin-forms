class AbstractMap extends CWidget
	constructor: (@id, x, y, zoom) ->
		if x? then @createMap(x, y, zoom)

class Map extends AbstractMap
	constructor: ->
		coord = [XGoogle, YGoogle]
		zoom = 10
		if myPrevMap
			coord = myPrevMap.getCenter()
			zoom = myPrevMap.getZoom()
		
		@map = @createMap(coord[0], coord[1], zoom)
		@houseMarker = @createMarker NewX, NewY, "Перетащите эту метку", "images/house-marker.png", 3, ->
			self.dragEnd.apply(self, arguments)
		
		@houseMarkerGray = @createMarker(XGoogle, YGoogle, "Старое положение метки", "images/house-marker-gray.png", 2)
		@addressMarker = @createMarker(XMark, YMark, xy_address, "images/address-marker.png", 1)
		#@searchMarker = @createMarker(XGoogle, YGoogle, "", "images/search-marker.png", 0)
		if !(YMark == YGoogle and XMark == XGoogle) and !myPrevMap then	@setBoundsEx()

	onSearch: (coord, title) ->
		@setMarkerXY(@houseMarker, coord)
		#@setMarkerTitle(@searchMarker, title)
		@dragEnd(@houseMarker)
		@setBoundsEx()

	onSearchError: ->
		alert('По запросу ничего не найдено!')

	toXY: ->	# сменилась карта - перейти к её координатам
		@map.setCenter(myPrevMap.getCenter(), myPrevMap.getZoom())
		@map.setMarkerXY(@map.houseMarker, [NewX, NewY])
		#@map.setMarkerXY(@map.searchMarker, myPrevMap.getMarkerXY(myPrevMap.searchMarker))

	setBoundsEx: ->
		@setBounds()
		minZoom = 16
		zoom = @getZoom()
		if(zoom > minZoom) @setZoom(minZoom)
		else @setZoom(zoom - 1)

		
	

class YandexMap extends AbstractMap
	createMap: (x, y, zoom) ->
		# создаём карту
		@map = new ymaps.Map "YandexMap",
			center: [x, y],
			zoom: zoom,
			behaviors: ['default', 'scrollZoom'],
			type: 'yandex#map', # publicMap
			adjustZoomOnTypeChange: true,
			noPlacemark: true,
			yandexMapAutoSwitch: true
		
		
		@map.controls
			.add searchControl, left: 120, top: 5
			.add 'zoomControl'
			.add 'typeSelector'
			.add 'mapTools'		

	addSearchControl: (width, left, top) ->
		searchControl = new ymaps.control.SearchControl width: width, noPlacemark: true, noCentering: true
		searchControl.events.add ['resultselect'], (event) ->
			console.log 'resultselect'
			result = searchControl.getResultsArray()[searchControl.getSelectedIndex()]
			coord = result.geometry.getCoordinates()
			self.onSearch coord, result.properties.get("text")
			
			@map.controls.add searchControl, unless left? then left: 120, top: 5 else left: left, top: top

		setTimeout ->
			map = document.getElementById('YandexMap')
			input = getElementsByClass "ymaps-b-form-input__input", map
			input[0].value = Address
			hint = getElementsByClass "ymaps-b-form-input__hint", map
			hint[0].style.display = 'none'
		, 500
		
	createMarker: (x, y, title, icon, zIndex, dragEnd) ->
		zIndex += 1500
		myPlacemark = new ymaps.Placemark([x, y], {
			hintContent: escapeHTML(title)
		}, {
			iconImageHref: icon,
			iconImageSize: [37, 43],
			iconImageOffset: [-9, -40],
			draggable: !!dragEnd,
			zIndex: zIndex,
			zIndexDrag: zIndex,
			zIndexHover: zIndex,
			zIndexActive: zIndex
		})
		@map.geoObjects.add(myPlacemark)
		
		if dragEnd # устанавливаем обработчик события окончания перетаскивания
			myPlacemark.events.add ['dragend'], dragEnd
		
		myPlacemark

	dragEnd: ->
		coord = @houseMarker.geometry.getCoordinates()
		dragEnd(coord[0], coord[1], ymaps.formatter.distance(
			ymaps.coordSystem.geo.getDistance coord, @houseMarkerGray.geometry.getCoordinates()
		))

	setBounds: ->
		@map.setBounds(@map.geoObjects.getBounds())

	getZoom: ->
		return @map.getZoom()

	setZoom: (zoom) ->
		return @map.setZoom(zoom)

	getMarkerXY: (marker) ->
		return marker.geometry.getCoordinates()

	setMarkerXY: (marker, coord) ->
		marker.geometry.setCoordinates(coord)

	setMarkerTitle: (marker, title) -> marker.properties.set('hintContent', title)
	setCenter: (coord, zoom) -> @map.setCenter(coord); if zoom? then @map.setZoom(zoom)
	getCenter: -> @map.getCenter()


# карта 2gis
#function initDGmap() { @map = @mapsSave["2GisMap"] = new DoubleGisMap() }
#class DoubleGisMap() { @init() }
class DoubleGisMap extends AbstractMap
	createMap: (x, y, zoom) ->
		map_element = document.getElementById('2gis-map')
		map = new DG.Map(map_element)
		map.enablePlugin('ruler')
		geo = new DG.GeoPoint(y, x)
		map.setCenter(geo, zoom)
		map.controls.add(new DG.Controls.Zoom())
		
		search = document.getElementById("2gis-input")
		search.value = Address
		return map

	createMarker: (x, y, title, icon, zIndex, dragEnd) ->
		# создаём перетаскиваемый маркер
		icon_size = new DG.Size(37, 43)
		icon_offset = -> new DG.Point -9, -40
		image = new DG.Icon icon, icon_size, icon_offset
		marker = new DG.Markers.Common({
			geoPoint: new DG.GeoPoint(y, x),
			draggable: !!dragEnd,
			icon: image,
			hint: escapeHTML(title),
			dragStopCallback: dragEnd
		})
		@map.markers.add(marker)
		document.getElementById(marker.getContainerId()).parentNode.style.zIndex = 501 + zIndex
		return marker

	dragEnd: (marker) ->	# устанавливаем обработчик события окончания перетаскивания
		pos = marker.getPosition()
		distance = DG.Utils.getDistance(pos, @houseMarkerGray.getPosition())
		if(distance < 1000) distance = Math.round(distance) + " м"
		else distance = Math.round(distance / 10) / 100 + " км"
		dragEnd(pos.lat, pos.lon, distance)

	setBounds: ->
		@map.setBounds(@map.markers.getBounds())

	getZoom: ->
		return @map.getZoom()

	setZoom: (zoom) ->
		@map.setZoom(zoom)

	getMarkerXY: (marker) ->
		pos = marker.getPosition()
		return [pos.lat, pos.lon]

	setMarkerXY: (marker, coord) ->
		marker.setPosition(new DG.GeoPoint(coord[1], coord[0]))

	setMarkerTitle: (marker, title) -> marker.setHintContent title
	setCenter: (coord, zoom) -> @map.setCenter(new DG.GeoPoint(coord[1], coord[0]), zoom)
	getCenter: -> pos = @map.getCenter(); [pos.lat, pos.lon]

###
function findDGmap() {
	console.log("findDGmap")
	try {
	search = document.getElementById("2gis-input")
	@map.map.geocoder.get(search.value, {
		types: ['city', 'settlement', 'district', 'street', 'living_area', 'place', 'house'],
		limit: 1,
		success: (geocoderObjects) ->
			search.style.backgroundColor = "white"
			setfindDGmap(geocoderObjects[0])

		failure: (errNo, errMsg) ->
			search.style.backgroundColor = "MistyRose"
			@map.onSearchError()
			console.log("@map.geocoder.failure "+errNo+" -> "+errMsg)

	})
	} catch(e) { console.log(e) }
	return false
}

function setfindDGmap(geo) {
	console.log("setfindDGmap")
	pos = geo.getCenterGeoPoint()
	@map.onSearch([pos.lat, pos.lon], geo.getName())
	
	search = document.getElementById("2gis-input")
	search.value = geo.getName()
	autocomplete = document.getElementById("2gis-autocomplete")
	autocomplete.innerHTML = ""
}

function clickfindDGmap() {
	console.log("clickfindDGmap")
	setfindDGmap(@geocoderObject)
	return false
}

function keyfindDGmap(event) {
	search = document.getElementById("2gis-input").value
	console.log("keyfindDGmap " + search)
	if event.which == 13 then findDGmap() return; }
	if(search.length <= 2) return
	@map.map.geocoder.get(search, { types: ['city', 'settlement', 'district', 'street', 'living_area', 'place', 'house'],
		limit: 6,
		success: (geocoderObjects) ->
			autocomplete = document.getElementById("2gis-autocomplete")
			autocomplete.innerHTML = ""
			if(!(geocoderObjects and geocoderObjects.length)) return
			for(i=0, n=geocoderObjects.length; i<n; i++) {
				geo = geocoderObjects[i]
				name = geo.getName()
				a = document.createElement('a')
				a.className = 'autoitem'
				a.href = "/"
				a.geocoderObject = geo
				a.onclick = clickfindDGmap
				if(typeof(a.innerText)!='undefined') a.innerText = name; else a.textContent = name
				autocomplete.appendChild(a)

		failure: (errNo, errMsg) ->
			console.log("geocoder.failure "+errNo+" -> "+errMsg)

	})
}
###


# Google Map
#function initGmap() { @map = @mapsSave["GoogleMap"] = new GoogleMap() }
#function GoogleMap() { @init() }
class GoogleMap extends AbstractMap
	createMap: (x, y, zoom) ->
		@map = new google.maps.Map(document.getElementById('google-map'), {
			zoom: zoom,
			center: new google.maps.LatLng(x, y),
			mapTypeId: google.maps.MapTypeId.ROADMAP
		})
		@searchBox = @byId("google-input")
		@searchBox.value = Address
		autocomplete = new google.maps.places.Autocomplete(searchBox)
		google.maps.event.addListener autocomplete, 'place_changed', ->
			console.log('place_changed')
			place = autocomplete.getPlace()
			if !place.geometry
				searchBox.style.backgroundColor = "MistyRose"
				self.onSearchError()
				return

			searchBox.style.backgroundColor = "white"
			
			address = ''
			if place.address_components
				address = [
					(place.address_components[0] and place.address_components[0].short_name or ''),
					(place.address_components[1] and place.address_components[1].short_name or ''),
					(place.address_components[2] and place.address_components[2].short_name or '')
				].join(', ')

			
			pos = place.geometry.location
			self.onSearch([pos.lat(), pos.lng()], place.name + ', ' + address)
		return map

	createMarker: (x, y, title, icon, zIndex, dragEnd) ->
		icon_size = new google.maps.Size(37, 43)
		icon_origin = new google.maps.Point(0, 0)
		icon_base = new google.maps.Point(9, 40)
		image2 = new google.maps.MarkerImage(icon, icon_size, icon_origin, icon_base)
		myPlacemark = new google.maps.Marker({
			map: @map,
			position: new google.maps.LatLng(x, y),
			title: title,
			icon: image2,
			draggable: !!dragEnd,
			zIndex: zIndex
		})
		if dragEnd then google.maps.event.addListener(myPlacemark, 'dragend', dragEnd)
		return myPlacemark

	dragEnd: ->	# устанавливаем обработчик события окончания перетаскивания
		pos = @houseMarker.getPosition()
		distance = google.maps.geometry.spherical.computeDistanceBetween(pos, @houseMarkerGray.getPosition(), 6371)
		if(distance < 1) distance = Math.round(distance * 1000) + " м"
		else distance = Math.round(distance*100) / 100 + " км"
		dragEnd(pos.lat(), pos.lng(), distance)

	setBounds: ->
		bounds = new google.maps.LatLngBounds()
		bounds.extend(@houseMarker.getPosition())
		bounds.extend(@houseMarkerGray.getPosition())
		bounds.extend(@addressMarker.getPosition())
		#bounds.extend(@searchMarker.getPosition())
		@map.fitBounds(bounds)

	getZoom: ->
		return @map.getZoom()

	setZoom: (zoom) ->
		@map.setZoom(zoom)

	getMarkerXY: (marker) ->
		pos = marker.getPosition()
		return [pos.lat(), pos.lng()]

	setMarkerXY: (marker, coord) ->
		marker.setPosition(new google.maps.LatLng(coord[0], coord[1]))

	setMarkerTitle: (marker, title) -> marker.setTitle(title)
	setCenter: (coord, zoom) -> @map.setCenter(new google.maps.LatLng(coord[0], coord[1])); if zoom? then @map.setZoom(zoom)
	getCenter: -> pos = @map.getCenter(); [pos.lat(), pos.lng()]


###
function initial(src, fn) {
	console.log("initial src="+src+' fn='+fn)
	
	#div.innerHTML = "Загружается карта..."

	script = document.createElement('script')
	script.charset="utf-8"
	script.src=src
	script.type="text/javascript"
	script.onload = fn
	script.onerror = ->
		container.innerHTML = "Произошёл сбой. Выбранная Вами карта в данное время не работает. Выберите другую."
	}
	script.onreadystatechange = ->
		if(@readyState == "complete") @load()
	}
	(document.getElementsByTagName('head')[0] or document.getElementsByTagName('body')[0]).appendChild(script)
}

function switchOn(who, typeYmap) {
	if(container) container.style.display = 'none'
	container = document.getElementById(who + "Map")
	container.style.display = 'block'
	
	myPrevMap = @map
	@map = @mapsSave[who + "Map"]
	console.log(myPrevMap)
	console.log(@map)
	if(@map and myPrevMap) @map.toXY()
	
	if who == "2Gis" then
		if(!window.DG) initial("http:#maps.api.2gis.ru/1.0?loadByRequire=1", -> DG.load(initDGmap) })
	} else if who == "Yandex" then
		if(!window.ymaps) initial("#api-maps.yandex.ru/2.0/?load=package.standard,package.geoObjects&lang=ru-RU&onload=initYmap", ->})
		else {
			@map.map.setType("yandex#"+(typeYmap or 'map'))

	} else if who == "Google" then
		if(!window.google) initial("https:#maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&libraries=geometry,places&callback=initGmap&language=ru", ->})
	} else {
		throw "Ошика! Затребована карта " + who + ". Но такой карты нет"

	return false
}


# утилиты, используются выше, для установки адреса в поисковый инпут яндекс-карты. не удалять!
getElementsByClass = if document.getElementsByClassName? then (classList, node) -> (node || document).getElementsByClassName(classList)
else (classList, node) ->			
	node ||= document
	list = node.getElementsByTagName('*')
	length = list.length
	classArray = classList.split(/\s+/)
	classes = classArray.length
	result = [], i, j
	for i in [0...length]
		for j in [0...classes]
			if list[i].className.search('\\b' + classArray[j] + '\\b') != -1 then
				result.push(list[i])
				break

	return result


# если ie - то карта гугла
map_name = '\v'!='v'? "Yandex": "Google"
#map_name = "2Gis"
switchOn(map_name)
###