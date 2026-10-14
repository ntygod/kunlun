class_name ChapterSevenFormation
extends RefCounted
## Finite teaching board. Coordinates use screen north (negative y).
const UNITS := ["char_liang_xiao","npc_tutuha","npc_nang_gudai","npc_li_ting","npc_yang_que","npc_wang_ke"]
const VECTORS := {"N":[0,-1],"E":[1,0],"S":[0,1],"W":[-1,0]}
const TEMPLATES := {"R":[[0,0],[2,-1],[-2,-1],[2,1],[-2,1],[0,-2]],"S":[[-1,-1],[1,-1],[-1,0],[1,0],[-1,1],[1,1]]}
const PARK := [[-5,-5],[-3,-5],[-1,-5],[1,-5],[3,-5],[5,-5]]
static func valid(p:Array) -> bool:
	if p.size()!=6:return false
	var seen:Array=[]
	for cell in p:
		if not cell is Array or cell.size()!=2:return false
		for n in cell:
			if not (n is int or n is float) or not is_finite(float(n)) or n!=floor(n) or abs(n)>5:return false
		if cell in seen:return false
		seen.append(cell)
	return true
static func targets(shape:String,orientation:String,center:Array) -> Array:
	var out:Array=[]
	for original in TEMPLATES[shape]:
		var p:Array=original.duplicate()
		for i in range(["N","E","S","W"].find(orientation)):p=[-p[1],p[0]]
		out.append([p[0]+center[0],p[1]+center[1]])
	return out
static func fit(p:Array,shape:String) -> Dictionary:
	if not valid(p):return {}
	for direction in ["N","E","S","W"]:
		var t:=targets(shape,direction,[0,0]);var center:Array=[p[0][0]-t[0][0],p[0][1]-t[0][1]]
		if targets(shape,direction,center)==p:return {"orientation":direction,"center":center}
	return {}
static func path(p:Array,unit:int,target:Array) -> Array:
	if not valid(p) or unit<0 or unit>=6 or target.size()!=2 or abs(target[0])>5 or abs(target[1])>5:return []
	if target==p[unit] or target in p:return []
	var queue:Array=[p[unit]];var parents:Dictionary={str(p[unit]):[]};var cursor:=0
	while cursor<queue.size():
		var here:Array=queue[cursor];cursor+=1
		for d in ["N","E","S","W"]:
			var v:Array=VECTORS[d];var next:Array=[here[0]+v[0],here[1]+v[1]]
			if abs(next[0])>5 or abs(next[1])>5 or next in p or parents.has(str(next)):continue
			parents[str(next)]=here
			if next==target:
				var result:Array=[next];var previous:Array=here
				while previous!=p[unit]:result.push_front(previous);previous=parents[str(previous)]
				return result
			queue.append(next)
	return []
static func directions(p:Array,enemy:String,gap:String) -> Array:
	var v:Array=VECTORS[enemy];var maximum:=-999;var out:Array=[]
	for cell in p:maximum=maxi(maximum,cell[0]*v[0]+cell[1]*v[1])
	for cell in p:out.append(enemy if cell[0]*v[0]+cell[1]*v[1]==maximum else gap)
	return out
static func wave(scope:String,index:int) -> Dictionary:
	var drill:=scope=="ch07_qincha_drill"
	return {"shape":"S" if index==1 else "R","orientation":("N" if index==1 else "E") if drill else ("E" if index==1 else "N"),"enemy":("S" if index==1 else "W") if drill else ("W" if index==1 else "S"),"gap":("N" if index==1 else "E") if drill else ("E" if index==1 else "N")}
static func plan(p:Array,target:Array) -> Array:
	# Park on six spaced boundary cells first. A boundary slot cannot enclose
	# another unit; choose reachable units before trapped ones. Occupied slots
	# are cleared through a free temporary cell, never by teleportation.
	if not valid(p) or not valid(target):return []
	var current:Array=p.duplicate(true);var result:Array=[]
	for phase in [PARK,target]:
		var guard:=0
		while current!=phase and guard<100:
			guard+=1;var moved:=false
			for i in range(6):
				if current[i]==phase[i]:continue
				var route:=path(current,i,phase[i])
				if route.is_empty():continue
				result.append({"unit":i,"target":phase[i].duplicate(),"path":route});current[i]=phase[i].duplicate();moved=true;break
			if moved:continue
			# A target occupied by the wrong token, or a surrounded token: move
			# one reachable blocker to a non-target free cell, then reconsider.
			for i in range(6):
				if current[i]==phase[i]:continue
				for y in range(5,-6,-1):
					for x in range(-5,6):
						var cell:Array=[x,y]
						if cell in current or cell in phase:continue
						var route:=path(current,i,cell)
						if route.is_empty():continue
						result.append({"unit":i,"target":cell,"path":route});current[i]=cell;moved=true;break
					if moved:break
				if moved:break
			if not moved:return []
		if current!=phase:return []
	return result
