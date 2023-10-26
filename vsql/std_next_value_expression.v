// ISO/IEC 9075-2:2016(E), 6.14, <next value expression>

module vsql

// Format
//~
//~ <next value expression> /* NextValueExpression */ ::=
//~     NEXT VALUE FOR <sequence generator name>   -> next_value_expression

// NextValueExpression for "NEXT VALUE FOR <sequence generator name>"
struct NextValueExpression {
	name Identifier
}

fn (e NextValueExpression) pstr(params map[string]Value) string {
	return 'NEXT VALUE FOR ${e.name}'
}

fn (e NextValueExpression) eval(mut conn Connection, data Row, params map[string]Value) !Value {
	mut catalog := conn.catalog()
	next := catalog.storage.sequence_next_value(e.name)!

	return new_bigint_value(next)
}

fn (e NextValueExpression) eval_type(conn &Connection, data Row, params map[string]Value) !Type {
	return new_type('INTEGER', 0, 0)
}

fn (e NextValueExpression) is_agg(conn &Connection, row Row, params map[string]Value) !bool {
	return false
}

fn (e NextValueExpression) resolve_identifiers(conn &Connection, tables map[string]Table) !NextValueExpression {
	return NextValueExpression{conn.resolve_identifier(e.name)}
}

fn parse_next_value_expression(name Identifier) !NextValueExpression {
	return NextValueExpression{
		name: name
	}
}
