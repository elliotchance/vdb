// eval.v executes expressions (such as you would find in a WHERE condition).

module vsql

import regex

// A ExprOperation executes expressions for each row.
struct ExprOperation {
mut:
	conn    &Connection
	params  map[string]Value
	exprs   []DerivedColumn
	columns []Column
}

fn new_expr_operation(mut conn Connection, params map[string]Value, select_list SelectList, tables map[string]Table) !ExprOperation {
	mut exprs := []DerivedColumn{}
	mut columns := []Column{}

	match select_list {
		AsteriskExpr {
			for _, table in tables {
				columns << table.columns
				for column in table.columns {
					exprs << DerivedColumn{column.name, Identifier{
						sub_entity_name: column.name.sub_entity_name
					}}
				}
			}
		}
		QualifiedAsteriskExpr {
			mut table_name := conn.resolve_table_identifier(select_list.table_name, true)!
			table := tables[table_name.id()] or { return sqlstate_42p01('table', table_name.str()) }
			columns = table.columns
			for column in table.columns {
				exprs << DerivedColumn{column.name, Identifier{
					sub_entity_name: column.name.sub_entity_name
				}}
			}
		}
		[]DerivedColumn {
			empty_row := new_empty_table_row(tables)
			for i, column in select_list {
				mut column_name := 'COL${i + 1}'
				if column.as_clause.sub_entity_name != '' {
					column_name = column.as_clause.sub_entity_name
				} else if column.expr is Identifier {
					column_name = column.expr.sub_entity_name
				}

				expr := resolve_identifiers(conn, column.expr, tables)!
				col := Identifier{
					sub_entity_name: column_name
				}

				columns << Column{col, eval_as_type(conn, empty_row, expr, params)!, false}

				exprs << DerivedColumn{expr, col}
			}
		}
	}

	return ExprOperation{conn, params, exprs, columns}
}

fn (o ExprOperation) str() string {
	return 'EXPR (${o.columns()})'
}

fn (o ExprOperation) columns() Columns {
	return o.columns
}

fn (mut o ExprOperation) execute(rows []Row) ![]Row {
	mut new_rows := []Row{}

	for row in rows {
		mut data := map[string]Value{}
		for expr in o.exprs {
			data[expr.as_clause.id()] = eval_as_value(mut o.conn, row, expr.expr, o.params)!
		}
		new_rows << new_row(data)
	}

	return new_rows
}

fn eval_row(mut conn Connection, data Row, exprs []Expr, params map[string]Value) !Row {
	mut col_number := 1
	mut row := map[string]Value{}
	for expr in exprs {
		row['COL${col_number}'] = eval_as_value(mut conn, data, expr, params)!
		col_number++
	}

	return Row{
		data: row
	}
}

fn eval_as_type(conn &Connection, data Row, e Expr, params map[string]Value) !Type {
	match e {
		CallExpr {
			mut arg_types := []Type{}
			for arg in e.args {
				arg_types << eval_as_type(conn, data, arg, params)!
			}

			func := conn.find_function(e.function_name, arg_types)!

			return func.return_type
		}
		CountAllExpr, NextValueExpr {
			return new_type('INTEGER', 0, 0)
		}
		BetweenExpr, NullExpr, TruthExpr, LikeExpr, SimilarExpr {
			return new_type('BOOLEAN', 0, 0)
		}
		Parameter {
			p := params[e.name] or { return sqlstate_42p02(e.name) }

			return eval_as_type(conn, data, p, params)
		}
		Value {
			return e.typ
		}
		CastExpr {
			return e.target
		}
		CoalesceExpr {
			return eval_as_type(conn, data, e.exprs[0], params)
		}
		NullIfExpr {
			return eval_as_type(conn, data, e.a, params)
		}
		UnaryExpr {
			return eval_as_type(conn, data, e.expr, params)
		}
		BinaryExpr {
			left := eval_as_type(conn, data, e.left, params)!
			right := eval_as_type(conn, data, e.right, params)!

			l, _ := coerce_numeric_binary(new_empty_value(left), e.op, new_empty_value(right))?

			return l.typ
		}
		Identifier {
			col := data.data[e.id()] or { return sqlstate_42601('unknown column: ${e}') }

			return col.typ
		}
		NoExpr, QualifiedAsteriskExpr, QueryExpression, RowExpr {
			return sqlstate_42601('invalid expression provided: ${e.str()}')
		}
		CurrentDateExpr {
			return new_type('DATE', 0, 0)
		}
		CurrentTimeExpr {
			return new_type('TIME WITH TIME ZONE', 0, 0)
		}
		CurrentTimestampExpr {
			return new_type('TIMESTAMP WITH TIME ZONE', 0, 0)
		}
		LocalTimeExpr {
			return new_type('TIME WITHOUT TIME ZONE', 0, 0)
		}
		LocalTimestampExpr {
			return new_type('TIMESTAMP WITHOUT TIME ZONE', 0, 0)
		}
		SubstringExpr, TrimExpr, CurrentCatalogExpr, CurrentSchemaExpr {
			return new_type('CHARACTER VARYING', 0, 0)
		}
		UntypedNullExpr {
			return error('cannot determine type of untyped NULL')
		}
	}
}

fn eval_as_value(mut conn Connection, data Row, e Expr, params map[string]Value) !Value {
	match e {
		BetweenExpr {
			return eval_between(mut conn, data, e, params)
		}
		BinaryExpr {
			return eval_binary(mut conn, data, e, params)
		}
		CallExpr {
			return eval_call(mut conn, data, e, params)
		}
		CastExpr {
			return eval_cast(mut conn, data, e, params)
		}
		CoalesceExpr {
			return eval_coalesce(mut conn, data, e, params)
		}
		CountAllExpr {
			return eval_identifier(data, new_column_identifier('"COUNT(*)"')!)
		}
		Identifier {
			return eval_identifier(data, e)
		}
		LikeExpr {
			return eval_like(mut conn, data, e, params)
		}
		NextValueExpr {
			return eval_next_value(mut conn, data, e, params)
		}
		NullExpr {
			return eval_null(mut conn, data, e, params)
		}
		NullIfExpr {
			return eval_nullif(mut conn, data, e, params)
		}
		Parameter {
			return params[e.name] or { return sqlstate_42p02(e.name) }
		}
		SimilarExpr {
			return eval_similar(mut conn, data, e, params)
		}
		SubstringExpr {
			return eval_substring(mut conn, data, e, params)
		}
		UnaryExpr {
			return eval_unary(mut conn, data, e, params)
		}
		Value {
			return e
		}
		NoExpr, QualifiedAsteriskExpr, QueryExpression, RowExpr {
			// RowExpr should never make it to eval because it will be
			// reformatted into a ValuesOperation.
			//
			// QueryExpression will have already been resolved to a
			// ValuesOperation.
			return sqlstate_42601('missing or invalid expression provided')
		}
		CurrentCatalogExpr {
			return new_varchar_value(conn.current_catalog, 0)
		}
		CurrentDateExpr {
			now, _ := conn.now()

			return new_date_value(now.strftime('%Y-%m-%d'))
		}
		CurrentSchemaExpr {
			return new_varchar_value(conn.current_schema, 0)
		}
		CurrentTimeExpr {
			if e.prec > 6 {
				return sqlstate_42601('${e}: cannot have precision greater than 6')
			}

			return new_time_value(time_value(conn, e.prec, true))
		}
		CurrentTimestampExpr {
			if e.prec > 6 {
				return sqlstate_42601('${e}: cannot have precision greater than 6')
			}

			now, _ := conn.now()

			return new_timestamp_value(now.strftime('%Y-%m-%d ') + time_value(conn, e.prec, true))
		}
		LocalTimeExpr {
			if e.prec > 6 {
				return sqlstate_42601('${e}: cannot have precision greater than 6')
			}

			return new_time_value(time_value(conn, e.prec, false))
		}
		LocalTimestampExpr {
			if e.prec > 6 {
				return sqlstate_42601('${e}: cannot have precision greater than 6')
			}

			now, _ := conn.now()

			return new_timestamp_value(now.strftime('%Y-%m-%d ') + time_value(conn, e.prec, false))
		}
		TrimExpr {
			return eval_trim(mut conn, data, e, params)
		}
		TruthExpr {
			return eval_truth(mut conn, data, e, params)
		}
		UntypedNullExpr {
			return error('cannot determine value of untyped NULL')
		}
	}
}

fn time_value(conn &Connection, prec int, include_offset bool) string {
	now, _ := conn.now()

	mut s := now.strftime('%H:%M:%S')

	if prec > 0 {
		microseconds := left_pad(now.microsecond.str(), '0', 6)
		s += '.' + microseconds.substr(0, prec)
	}

	if include_offset {
		s += time_zone_value(conn)
	}

	return s
}

fn left_pad(s string, c string, len int) string {
	mut new_s := s
	for new_s.len < len {
		new_s = c + new_s
	}

	return new_s
}

fn eval_as_bool(mut conn Connection, data Row, e Expr, params map[string]Value) !bool {
	v := eval_as_value(mut conn, data, e, params)!

	if v.typ.typ == .is_boolean {
		return v.bool_value() == .is_true
	}

	return sqlstate_42804('in expression', 'BOOLEAN', v.typ.str())
}

fn eval_identifier(data Row, e Identifier) !Value {
	value := data.data[e.id()] or { return sqlstate_42601('unknown column: ${e}') }

	return value
}

fn eval_call(mut conn Connection, data Row, e CallExpr, params map[string]Value) !Value {
	func_name := e.function_name

	mut arg_types := []Type{}
	for arg in e.args {
		arg_types << eval_as_type(conn, data, arg, params)!
	}

	func := conn.find_function(func_name, arg_types)!

	if func.is_agg {
		return eval_identifier(data, Identifier{ custom_id: e.pstr(params) })
	}

	if e.args.len != func.arg_types.len {
		return sqlstate_42883('${func_name} has ${e.args.len} ${pluralize(e.args.len,
			'argument')} but needs ${func.arg_types.len} ${pluralize(func.arg_types.len,
			'argument')}')
	}

	mut args := []Value{}
	mut i := 0
	for typ in func.arg_types {
		arg := eval_as_value(mut conn, data, e.args[i], params)!
		args << cast(conn, 'argument ${i + 1} in ${func_name}', arg, typ)!
		i++
	}

	return func.func(args)
}

fn eval_next_value(mut conn Connection, data Row, e NextValueExpr, params map[string]Value) !Value {
	mut catalog := conn.catalog()
	next := catalog.storage.sequence_next_value(e.name)!

	return new_bigint_value(next)
}

fn eval_null(mut conn Connection, data Row, e NullExpr, params map[string]Value) !Value {
	value := eval_as_value(mut conn, data, e.expr, params)!

	if e.not {
		return new_boolean_value(!value.is_null)
	}

	return new_boolean_value(value.is_null)
}

fn eval_nullif(mut conn Connection, data Row, e NullIfExpr, params map[string]Value) !Value {
	a := eval_as_value(mut conn, data, e.a, params)!
	b := eval_as_value(mut conn, data, e.b, params)!

	if a.typ.typ != b.typ.typ {
		return sqlstate_42804('in NULLIF', a.typ.str(), b.typ.str())
	}

	cmp, _ := a.cmp(b)!
	if cmp == 0 {
		return new_null_value(a.typ.typ)
	}

	return a
}

fn eval_coalesce(mut conn Connection, data Row, e CoalesceExpr, params map[string]Value) !Value {
	// TODO(elliotchance): This is horribly inefficient.

	mut typ := SQLType.is_varchar
	mut first := true
	for i, expr in e.exprs {
		typ2 := eval_as_type(conn, data, expr, params)!

		if first {
			typ = typ2.typ
			first = false
		} else if typ != typ2.typ {
			return sqlstate_42804('in argument ${i + 1} of COALESCE', typ.str(), typ2.typ.str())
		}
	}

	mut value := Value{}
	for expr in e.exprs {
		value = eval_as_value(mut conn, data, expr, params)!

		if !value.is_null {
			return value
		}
	}

	return new_null_value(value.typ.typ)
}

fn eval_cast(mut conn Connection, data Row, e CastExpr, params map[string]Value) !Value {
	value := eval_as_value(mut conn, data, e.expr, params)!

	return cast(conn, 'for CAST', value, e.target)
}

fn eval_truth(mut conn Connection, data Row, e TruthExpr, params map[string]Value) !Value {
	value := eval_as_value(mut conn, data, e.expr, params)!
	result := match value.bool_value() {
		.is_true {
			match e.value.bool_value() {
				.is_true { new_boolean_value(true) }
				.is_false, .is_unknown { new_boolean_value(false) }
			}
		}
		.is_false {
			match e.value.bool_value() {
				.is_true, .is_unknown { new_boolean_value(false) }
				.is_false { new_boolean_value(true) }
			}
		}
		.is_unknown {
			match e.value.bool_value() {
				.is_true, .is_false { new_boolean_value(false) }
				.is_unknown { new_boolean_value(true) }
			}
		}
	}

	if e.not {
		return unary_not_boolean(conn, result)
	}

	return result
}

fn eval_trim(mut conn Connection, data Row, e TrimExpr, params map[string]Value) !Value {
	source := eval_as_value(mut conn, data, e.source, params)!
	character := eval_as_value(mut conn, data, e.character, params)!

	if e.specification == 'LEADING' {
		return new_varchar_value(source.string_value().trim_left(character.string_value()),
			0)
	}

	if e.specification == 'TRAILING' {
		return new_varchar_value(source.string_value().trim_right(character.string_value()),
			0)
	}

	return new_varchar_value(source.string_value().trim(character.string_value()), 0)
}

fn eval_like(mut conn Connection, data Row, e LikeExpr, params map[string]Value) !Value {
	left := eval_as_value(mut conn, data, e.left, params)!
	right := eval_as_value(mut conn, data, e.right, params)!

	// Make sure we escape any regexp characters.
	escaped_regex := right.string_value().replace('+', '\\+').replace('?', '\\?').replace('*',
		'\\*').replace('|', '\\|').replace('.', '\\.').replace('(', '\\(').replace(')',
		'\\)').replace('[', '\\[').replace('{', '\\{').replace('_', '.').replace('%',
		'.*')

	mut re := regex.regex_opt('^${escaped_regex}$') or {
		return error('cannot compile regexp: ^${escaped_regex}$: ${err}')
	}
	result := re.matches_string(left.string_value())

	if e.not {
		return new_boolean_value(!result)
	}

	return new_boolean_value(result)
}

fn eval_substring(mut conn Connection, data Row, e SubstringExpr, params map[string]Value) !Value {
	value := eval_as_value(mut conn, data, e.value, params)!
	from := int((eval_as_value(mut conn, data, e.from, params)!).as_int() - 1)

	if e.using == 'CHARACTERS' {
		characters := value.string_value().runes()

		if from >= characters.len || from < 0 {
			return new_varchar_value('', 0)
		}

		mut @for := characters.len - from
		if e.@for !is NoExpr {
			@for = int((eval_as_value(mut conn, data, e.@for, params)!).as_int())
		}

		return new_varchar_value(characters[from..from + @for].string(), 0)
	}

	if from >= value.string_value().len || from < 0 {
		return new_varchar_value('', 0)
	}

	mut @for := value.string_value().len - from
	if e.@for !is NoExpr {
		@for = int((eval_as_value(mut conn, data, e.@for, params)!).as_int())
	}

	return new_varchar_value(value.string_value().substr(from, from + @for), 0)
}

fn eval_binary(mut conn Connection, data Row, e BinaryExpr, params map[string]Value) !Value {
	left := eval_as_value(mut conn, data, e.left, params)!
	right := eval_as_value(mut conn, data, e.right, params)!

	key := '${left.typ.typ} ${e.op} ${right.typ.typ}'
	if fnc := conn.binary_operators[key] {
		op_fn := fnc as BinaryOperatorFunc
		return op_fn(conn, left, right)
	}

	return sqlstate_42883('operator does not exist: ${left.typ} ${e.op} ${right.typ}')
}

fn eval_unary(mut conn Connection, data Row, e UnaryExpr, params map[string]Value) !Value {
	value := eval_as_value(mut conn, data, e.expr, params)!

	key := '${e.op} ${value.typ.typ}'
	if fnc := conn.unary_operators[key] {
		unary_fn := fnc as UnaryOperatorFunc
		return unary_fn(conn, value)!
	}

	return sqlstate_42883('operator does not exist: ${key}')
}

fn eval_between(mut conn Connection, data Row, e BetweenExpr, params map[string]Value) !Value {
	expr := eval_as_value(mut conn, data, e.expr, params)!
	mut left := eval_as_value(mut conn, data, e.left, params)!
	mut right := eval_as_value(mut conn, data, e.right, params)!

	// SYMMETRIC operands might need to be swapped.
	cmp, is_null := left.cmp(right)!
	if e.symmetric && !is_null && cmp > 0 {
		left, right = right, left
	}

	lower, lower_is_null := expr.cmp(left)!
	upper, upper_is_null := expr.cmp(right)!

	if lower_is_null || upper_is_null {
		return new_null_value(.is_boolean)
	}

	mut result := lower >= 0 && upper <= 0

	if e.not {
		result = !result
	}

	return new_boolean_value(result)
}

fn eval_similar(mut conn Connection, data Row, e SimilarExpr, params map[string]Value) !Value {
	left := eval_as_value(mut conn, data, e.left, params)!
	right := eval_as_value(mut conn, data, e.right, params)!

	regexp := '^${right.string_value().replace('.', '\\.').replace('_', '.').replace('%',
		'.*')}$'
	mut re := regex.regex_opt(regexp) or {
		return error('cannot compile regexp: ${regexp}: ${err}')
	}
	result := re.matches_string(left.string_value())

	if e.not {
		return new_boolean_value(!result)
	}

	return new_boolean_value(result)
}

// eval_as_nullable_value is a broader version of eval_as_value that also takes
// the known destination type as so allows for untyped NULLs.
//
// TODO(elliotchance): Is this even needed? Can eval_as_value be refactored to
//  work the same way and avoid this extra layer?
fn eval_as_nullable_value(mut conn Connection, typ SQLType, data Row, e Expr, params map[string]Value) !Value {
	if e is UntypedNullExpr {
		return new_null_value(typ)
	}

	return eval_as_value(mut conn, data, e, params)
}
