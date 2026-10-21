class_name ChapterFiveOptics
extends RefCounted
## Finite planar ray/segment and ray/circle intersections. Positions are quantized
## to integer milli-pixels only when recorded, not when deciding intersections.
const CENTERS := [Vector2(160,64),Vector2(64,64),Vector2(64,128)]
const SOURCE := Vector2(160,16)
const BOX_CENTER := Vector2(128,128)
const EPS := 0.00001
static func point(v: Vector2) -> Array: return [int(round(v.x*1000)),int(round(v.y*1000))]
static func tangent(angle: int) -> Vector2:
	return Vector2(cos(deg_to_rad(angle)),sin(deg_to_rad(angle)))
static func reflection(direction: Vector2, angle: int) -> Vector2:
	var t := tangent(angle)
	return (2.0*direction.dot(t)*t-direction).normalized()
static func segment_hit(origin: Vector2, direction: Vector2, a: Vector2, b: Vector2) -> float:
	var edge := b-a; var cross := direction.cross(edge)
	if absf(cross)<EPS: return INF
	var offset := a-origin
	var distance := offset.cross(edge)/cross; var fraction := offset.cross(direction)/cross
	return distance if distance>EPS and fraction>=-EPS and fraction<=1.0+EPS else INF
static func circle_hit(origin: Vector2, direction: Vector2) -> float:
	var offset := origin-BOX_CENTER
	var half_b := offset.dot(direction); var discriminant := half_b*half_b-offset.length_squared()+256.0
	if discriminant<0: return INF
	var root := sqrt(discriminant)
	var near := -half_b-root; var far := -half_b+root
	if near>EPS: return near
	return far if far>EPS else INF
static func trace(mounted: Array, angles: Array, ring: int) -> Dictionary:
	var origin := SOURCE; var direction := Vector2.DOWN
	var segments: Array = []; var mirrors: Array = []; var holes: Array = []
	var axis := tangent(ring*45)
	var hole_centers := [BOX_CENTER-axis*16,BOX_CENTER+axis*16]
	var outcome := "escaped"; var projected := false; var glyphs: Array = []
	for bounce in range(12):
		var nearest := INF; var object_id := ""; var mirror_index := -1
		for i in range(3):
			if not mounted[i]: continue
			var t := tangent(angles[i])*sqrt(128.0)
			var distance := segment_hit(origin,direction,CENTERS[i]-t,CENTERS[i]+t)
			if distance<nearest: nearest=distance; object_id="mirror"; mirror_index=i
		var circle := circle_hit(origin,direction)
		if circle<nearest: nearest=circle; object_id="box"
		var screen := segment_hit(origin,direction,Vector2(224,0),Vector2(224,180))
		if screen<nearest: nearest=screen; object_id="screen"
		var boundaries := [[Vector2(0,0),Vector2(320,0)],[Vector2(320,0),Vector2(320,180)],[Vector2(320,180),Vector2(0,180)],[Vector2(0,180),Vector2(0,0)]]
		for edge in boundaries:
			var distance := segment_hit(origin,direction,edge[0],edge[1])
			if distance<nearest: nearest=distance; object_id="boundary"
		if not is_finite(nearest): outcome="no_intersection"; break
		var hit := origin+direction*nearest
		segments.append({"from":point(origin),"to":point(hit),"hit":object_id,"mirror":mirror_index})
		if object_id=="mirror":
			mirrors.append(mirror_index)
			direction=reflection(direction,angles[mirror_index])
		elif object_id=="box":
			var aperture := -1
			for i in range(2):
				if hit.distance_to(hole_centers[i])<0.001: aperture=i
			if aperture<0: outcome="opaque_box_wall"; break
			holes.append(aperture)
		elif object_id=="screen":
			# The ring transforms both aperture coordinates and glyph orientation.
			for i in range(4): glyphs.append({"glyph":["紫","府","元","宗"][i],"position":point(hit+axis*float(-18+12*i)),"up":point(Vector2(axis.y,-axis.x))})
			var upright := axis.dot(Vector2.RIGHT)>0.999999
			projected=hit.distance_to(Vector2(224,128))<0.001 and direction.dot(Vector2.RIGHT)>0.999999 and upright and holes==[0,1] and mirrors==[0,1,2]
			outcome="upright_projection" if projected else "misaligned_projection"
			break
		else: outcome="escaped"; break
		origin=hit+direction*0.001
		if bounce==11: outcome="bounce_limit"
	return {"segments":segments,"mirrors":mirrors,"holes":holes,"glyphs":glyphs,"outcome":outcome,"projected":projected}
