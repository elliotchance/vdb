// ISO/IEC 9075-2:2016(E), 14.15, <set clause list>

module vsql

// Format
//~
//~ <set clause list> /* map[string]UpdateSource */ ::=
//~     <set clause>
//~   | <set clause list> <comma> <set clause>   -> set_clause_append
//~
//~ <set clause> /* map[string]UpdateSource */ ::=
//~   <set target> <equals operator> <update source>   -> set_clause
//~
//~ <set target> /* Identifier */ ::=
//~     <update target>
//~
//~ <update target> /* Identifier */ ::=
//~     <object column>
//~
//~ <update source> /* UpdateSource */ ::=
//~     <value expression>                         -> UpdateSource
//~   | <contextually typed value specification>   -> UpdateSource
//~
//~ <object column> /* Identifier */ ::=
//~     <column name>

type UpdateSource = NullSpecification | ValueExpression

fn (e UpdateSource) pstr(params map[string]Value) string {
	return match e {
		ValueExpression, NullSpecification {
			e.pstr(params)
		}
	}
}

fn (e UpdateSource) eval(mut conn Connection, data Row, params map[string]Value) !Value {
	return match e {
		ValueExpression, NullSpecification {
			e.eval(mut conn, data, params)!
		}
	}
}

fn (e UpdateSource) eval_type(conn &Connection, data Row, params map[string]Value) !Type {
	return match e {
		ValueExpression, NullSpecification {
			e.eval_type(conn, data, params)!
		}
	}
}

fn (e UpdateSource) is_agg(conn &Connection, row Row, params map[string]Value) !bool {
	return match e {
		ValueExpression, NullSpecification {
			e.is_agg(conn, row, params)!
		}
	}
}

fn (e UpdateSource) resolve_identifiers(conn &Connection, tables map[string]Table) !UpdateSource {
	match e {
		ValueExpression {
			return e.resolve_identifiers(conn, tables)!
		}
		NullSpecification {
			return e.resolve_identifiers(conn, tables)!
		}
	}
}

fn parse_set_clause_append(set_clause_list map[string]UpdateSource, set_clause map[string]UpdateSource) !map[string]UpdateSource {
	mut new_set_clause_list := set_clause_list.clone()

	// Even though there will only be one of these.
	for k, v in set_clause {
		new_set_clause_list[k] = v
	}

	return new_set_clause_list
}

fn parse_set_clause(target Identifier, update_source UpdateSource) !map[string]UpdateSource {
	return {
		target.str(): update_source
	}
}
