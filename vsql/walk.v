// walk.v contains the iterator that is able to walk through ranges of the
// B-tree.

module vsql

struct PageIterator {
	btree Btree
	// min and max are inclusive.
	min []byte
	max []byte
mut:
	// objects is just for performance so we dont need to parse the objects in
	// the page several times while we iterate that page.
	objects []PageObject
	// path describes the depth. At each depth is an iterator for that page.
	path           []int
	depth_iterator []int
}

fn (mut iter PageIterator) next() ?PageObject {
	// Special case for no data.
	if iter.btree.pager.total_pages() == 0 {
		return error('')
	}

	// On the first iteration we fast-forward to the starting page.
	if iter.path.len == 0 {
		iter.path, iter.depth_iterator = iter.btree.search_page(iter.min) ?

		// search_page does not include the last depth_iterator becuase that
		// belongs to the leaf not which is does not search.
		iter.depth_iterator << 0

		// Load all the objects for this leaf. Making sure to skip over any keys
		// that are out of bounds.
		iter.objects = (iter.btree.pager.fetch_page(iter.path[iter.path.len - 1]) ?).objects()
		for object in iter.objects {
			// TODO(elliotchance): It would be more efficient to do a binary
			//  search here since the page is already sorted.
			if compare_bytes(object.key, iter.min) < 0 {
				iter.depth_iterator[iter.depth_iterator.len - 1]++
			}
		}
	}

	// If this page is done, roll up to the parent and continue to traverse
	// down.
	if iter.depth_iterator[iter.depth_iterator.len - 1] >= iter.objects.len {
		for {
			if iter.path.len == 1 {
				return error('')
			}

			iter.path = iter.path[..iter.path.len - 1]
			iter.depth_iterator = iter.depth_iterator[..iter.depth_iterator.len - 1]
			iter.depth_iterator[iter.depth_iterator.len - 1]++

			if iter.depth_iterator[iter.depth_iterator.len - 1] < (iter.btree.pager.fetch_page(iter.path[iter.path.len - 1]) ?).objects().len {
				break
			}
		}

		for (iter.btree.pager.fetch_page(iter.path[iter.path.len - 1]) ?).kind == kind_not_leaf {
			objects := (iter.btree.pager.fetch_page(iter.path[iter.path.len - 1]) ?).objects()

			iter.path << bytes_to_int(objects[iter.depth_iterator[iter.depth_iterator.len - 1]].value)
			iter.depth_iterator << 0
		}

		iter.objects = (iter.btree.pager.fetch_page(iter.path[iter.path.len - 1]) ?).objects()
	}

	o := iter.objects[iter.depth_iterator[iter.depth_iterator.len - 1]]
	iter.depth_iterator[iter.depth_iterator.len - 1]++

	// We also need to bail out if we encounter a value greater the upper bound.
	if compare_bytes(o.key, iter.max) > 0 {
		return error('')
	}

	return o
}
