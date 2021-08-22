// select.v contains the implementation for the SELECT statement.

module vsql

fn (mut c Connection) query_select(stmt SelectStmt) ?Result {
	// Find all rows first.
	mut all_rows := []Row{}
	mut exprs := stmt.exprs

	if stmt.from == '' {
		all_rows = [Row{}]
	} else {
		table_name := identifier_name(stmt.from)

		if table_name !in c.storage.tables {
			return sqlstate_42p01(table_name)
		}
		table := c.storage.tables[table_name]

		if exprs is AsteriskExpr {
			mut new_exprs := []DerivedColumn{}
			for column_name in table.column_names() {
				new_exprs << DerivedColumn{Identifier{'"$column_name"'}, Identifier{'"$column_name"'}}
			}

			exprs = new_exprs
		}

		all_rows = c.storage.read_rows(table.index, stmt.offset) ?
		if stmt.where is NoExpr {
			if stmt.fetch >= 0 && all_rows.len > stmt.fetch {
				all_rows = all_rows[..stmt.fetch]
			}
		} else {
			all_rows = where(c, all_rows, false, stmt.where, stmt.fetch) ?
		}
	}

	// Transform into expressions.
	mut returned_rows := []Row{cap: all_rows.len}
	mut col_num := 1
	mut column_names := []string{cap: (exprs as []DerivedColumn).len}
	mut first_row := true
	for row in all_rows {
		col_num = 1
		mut data := map[string]Value{}
		for expr in exprs as []DerivedColumn {
			mut column_name := 'COL$col_num'
			if expr.as_clause.name != '' {
				column_name = identifier_name(expr.as_clause.name)
			}
			if expr.expr is Identifier {
				column_name = identifier_name(expr.expr.name)
			}

			if first_row {
				column_names << column_name
			}

			data[column_name] = eval_as_value(c, row, expr.expr) ?
			col_num++
		}

		first_row = false
		returned_rows << Row{
			data: data
		}
	}

	return new_result(column_names, returned_rows)
}
