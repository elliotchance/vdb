#!/usr/bin/env -S v

// This script generates the V client library documentation from the "vsql/" module
// in reStructuredText format.
//
// Run from the repo root: $ ./scripts/generate-v-client-library-docs.vsh

import v.doc

fn get_sym_name(dn doc.DocNode) string {
	sym_name := if dn.parent_name.len > 0 && dn.parent_name != 'void' {
		'(${dn.parent_name}) ${dn.name}'
	} else {
		dn.name
	}
	return sym_name
}

fn main() {
	root_dir := 'vsql'

	// pub_only = true, with_comments = true
	d := doc.generate(root_dir, true, true, doc.Platform.cross)!

	module_title := 'V Module: ${d.head.name}'
	println(module_title)
	println('-'.repeat(module_title.len))
	print('\n')

	dcs_contents := d.contents.arr()

	for node in dcs_contents {
		section_title := if node.kind == .const_group {
			get_sym_name(node)
		} else {
			'${node.kind} ${get_sym_name(node)}'
		}
		println(section_title)
		println('-'.repeat(section_title.len))
		print('\n')
		if node.kind == .const_group {
			for ch in node.children {
				print('\n')
				println('.. code-block:: v\n')
				println('  ${ch.content}')
				print('\n')
				println(ch.merge_comments())
			}
		} else {
			print('\n')
			if node.content.len > 0 {
				println('.. code-block:: v\n')
				println(node.content.split_into_lines().map('   ${it}').join('\n'))
				print('\n')
			}
			println(node.merge_comments())
		}
		print('\n')
	}
}
