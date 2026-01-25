extends Node2D

@export var slice_map_layer : TileMapLayer
@export var main_map_gen_node : Node2D

var width : int
var height : int
var altitude = {}
var biome_id: Dictionary = {}
var open_slice_noise := FastNoiseLite.new()
var source_id := 0

var border_ta: Vector2i = Vector2i(10,0)
var border_darker_ta: Vector2i = Vector2i(10,1)
var border_2_ta: Vector2i = Vector2i(11,0)
var border_3_ta: Vector2i = Vector2i(11,1)

enum BiomeID {
	A,
	B,
	C
}

func _ready() -> void:
	width = main_map_gen_node.get_width()
	height = main_map_gen_node.get_height()
	altitude = generate_map(200, 4)
	set_tile()
	merge_small_clusters(1000)
	paint_slice_biome_outlines(1)
	clear_non_darker_borders()


func generate_map(per: float, oct: int) -> Dictionary:
	open_slice_noise.seed = randi()
	open_slice_noise.frequency = 1.0 / per
	open_slice_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	open_slice_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	open_slice_noise.fractal_octaves = oct

	var grid_a := {}
	for x in range(width):
		for y in range(height):
			var n: float = absf(open_slice_noise.get_noise_2d(x, y)) * 2.0
			grid_a[Vector2i(x, y)] = n
	return grid_a


func set_tile() -> void:
	for x in range(width):
		for y in range(height):
			var pos := Vector2i(x, y)
			var alt : float = altitude[pos]

			if alt < 0.38:
				slice_map_layer.set_cell(pos, source_id, border_2_ta)
				biome_id[pos] = BiomeID.A
			elif alt < 0.9:
				slice_map_layer.set_cell(pos, source_id, border_3_ta)
				biome_id[pos] = BiomeID.B
			else:
				slice_map_layer.set_cell(pos, source_id, border_ta)
				biome_id[pos] = BiomeID.C

func merge_small_clusters(threshold: int = 1000) -> void:
	var clusters := detect_biome_clusters()

	for cluster in clusters:
		if cluster.size() >= threshold:
			continue

		var neighbor_counts := {}
		var directions = [
			Vector2i(1,0), Vector2i(-1,0),
			Vector2i(0,1), Vector2i(0,-1)
		]

		# count adjacent biome types
		for p in cluster:
			for d in directions:
				var n = p + d
				if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
					continue
				var neigh_biome = biome_id.get(n, null)
				if neigh_biome == null:
					continue
				if neigh_biome == biome_id[p]:
					continue
				neighbor_counts[neigh_biome] = neighbor_counts.get(neigh_biome, 0) + 1

		if neighbor_counts.size() == 0:
			continue

		# pick majority neighbor biome
		var best_biome = null
		var best_count = -1
		for biome_key in neighbor_counts.keys():
			if neighbor_counts[biome_key] > best_count:
				best_count = neighbor_counts[biome_key]
				best_biome = biome_key

		if best_biome == null:
			continue

		# apply biome change to cluster
		for p in cluster:
			biome_id[p] = best_biome
			match best_biome:
				BiomeID.A:
					slice_map_layer.set_cell(p, source_id, border_2_ta)
				BiomeID.B:
					slice_map_layer.set_cell(p, source_id, border_3_ta)
				BiomeID.C:
					slice_map_layer.set_cell(p, source_id, border_ta)

func detect_biome_clusters() -> Array:
	var clusters: Array = []
	var visited := {}
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			if visited.has(pos):
				continue
			var b = biome_id.get(pos, -1)
			if b == -1:
				continue
			var cluster = flood_biome(pos, b, visited)
			clusters.append(cluster)
	return clusters


func flood_biome(start: Vector2i, biome_type: int, visited: Dictionary) -> Array:
	var q: Array = [start]
	var cluster: Array = []
	while q.size() > 0:
		var pos: Vector2i = q.pop_front()
		if visited.has(pos):
			continue
		visited[pos] = true
		cluster.append(pos)

		var neighbors = [
			pos + Vector2i(1,0),
			pos + Vector2i(-1,0),
			pos + Vector2i(0,1),
			pos + Vector2i(0,-1)
		]
		for n in neighbors:
			if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
				continue
			if biome_id.get(n, -1) == biome_type and not visited.has(n):
				q.append(n)
	return cluster


func paint_slice_biome_outlines(threshold: int = 1) -> void:
	var clusters: Array = detect_biome_clusters()

	for cluster in clusters:
		if cluster.size() < threshold:
			continue

		var cluster_set := {}
		for p in cluster:
			cluster_set[p] = true

		for p in cluster:
			var is_edge: bool = false
			var neighbors = [
				p + Vector2i(1, 0),
				p + Vector2i(-1, 0),
				p + Vector2i(0, 1),
				p + Vector2i(0, -1)
			]
			for n in neighbors:
				if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
					is_edge = true
					break
				if not cluster_set.has(n):
					is_edge = true
					break

			if is_edge:
				slice_map_layer.set_cell(p, source_id, border_darker_ta)


func clear_non_darker_borders() -> void:
	for x in range(width):
		for y in range(height):
			var pos := Vector2i(x, y)
			var cell := slice_map_layer.get_cell_atlas_coords(pos)

			if cell != border_darker_ta:
				slice_map_layer.set_cell(pos,0, border_ta)
				#slice_map_layer.erase_cell(pos)
