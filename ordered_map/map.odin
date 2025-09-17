package ordered_map

import "core:fmt"
import "base:builtin"
import "core:mem"
import "core:slice"

Map :: struct($K: typeid, $V: typeid) {
	_map:      map[K]V,
	key_order: [dynamic]K,
}

len :: proc(m: ^$M/Map($K, $V)) -> int {
	return builtin.len(m._map)
}

contains :: proc(m: ^$M/Map($K, $V), key: K) -> bool {
	_, c := m._map[key]
	return c
}

insert :: proc(m: ^$M/Map($K, $V), key: K, val: V) {
	m._map[key] = val
	append(&m.key_order, key)
}

delete_key :: proc(m: ^$M/Map($K, $V), key: K) {
	if key in m._map {
		builtin.delete_key(&m._map, key)
		for v, i in m.key_order {
			if v == key {
				ordered_remove(&m.key_order, i)
				return
			}
		}
	}
}

delete :: proc(m: ^$M/Map($K, $V)) {
	builtin.delete(m._map)
	builtin.delete(m.key_order)
}

sort :: proc(m: ^$M/Map($K, $V)) {
	slice.sort(m.key_order[:])
}

Iterator :: distinct int

iterate :: #force_inline proc(m: ^$M/Map($K, $V)) -> Iterator { return 0 }

iterate_next :: proc(m: ^$M/Map($K, $V), it: ^Iterator) -> (key: K, val: V, more: bool) {
	defer it^ += 1
	if it^ < Iterator(builtin.len(m.key_order)) {
		key = m.key_order[it^]
		return key, m._map[key], true
	}
	return {}, {}, false
}
