module vsql

// ISO/IEC 9075-2:2016(E), 6.39, <boolean value expression>
//
// # Function
//
// Specify a boolean value.
//
// # Format
//~
//~ <boolean value expression> /* BooleanValueExpression */ ::=
//~     <boolean term>                                 -> boolean_value_expression_1
//~   | <boolean value expression> OR <boolean term>   -> boolean_value_expression_2
//~
//~ <boolean term> /* BooleanTerm */ ::=
//~     <boolean factor>                      -> boolean_term_1
//~   | <boolean term> AND <boolean factor>   -> boolean_term_2
//~
//~ <boolean factor> /* BooleanTest */ ::=
//~     <boolean test>
//~   | NOT <boolean test>   -> boolean_factor_not
//~
//~ <boolean test> /* BooleanTest */ ::=
//~     <boolean primary>                        -> boolean_test_1
//~   | <boolean primary> IS <truth value>       -> boolean_test_2
//~   | <boolean primary> IS NOT <truth value>   -> boolean_test_3
//~
//~ <truth value> /* Value */ ::=
//~     TRUE      -> true
//~   | FALSE     -> false
//~   | UNKNOWN   -> unknown
//~
//~ <boolean primary> /* BooleanPrimary */ ::=
//~     <predicate>           -> BooleanPrimary
//~   | <boolean predicand>   -> BooleanPrimary
//~
//~ <boolean predicand> /* BooleanPredicand */ ::=
//~     <parenthesized boolean value expression>      -> BooleanPredicand
//~   | <nonparenthesized value expression primary>   -> BooleanPredicand
//~
//~ <parenthesized boolean value expression> /* BooleanValueExpression */ ::=
//~     <left paren> <boolean value expression> <right paren>   -> parenthesized_boolean_value_expression

type BooleanPrimary = BooleanPredicand | Predicate

fn (e BooleanPrimary) pstr(params map[string]Value) string {
	return match e {
		Predicate, BooleanPredicand {
			e.pstr(params)
		}
	}
}

fn (e BooleanPrimary) compile(mut c Compiler) !CompileResult {
	match e {
		Predicate, BooleanPredicand {
			return e.compile(mut c)!
		}
	}
}

type BooleanPredicand = BooleanValueExpression | NonparenthesizedValueExpressionPrimary

fn (e BooleanPredicand) pstr(params map[string]Value) string {
	return match e {
		BooleanValueExpression, NonparenthesizedValueExpressionPrimary {
			e.pstr(params)
		}
	}
}

fn (e BooleanPredicand) compile(mut c Compiler) !CompileResult {
	match e {
		BooleanValueExpression, NonparenthesizedValueExpressionPrimary {
			return e.compile(mut c)!
		}
	}
}

struct BooleanValueExpression {
	expr ?&BooleanValueExpression
	term BooleanTerm
}

fn (e BooleanValueExpression) pstr(params map[string]Value) string {
	if expr := e.expr {
		return '${expr.pstr(params)} AND ${e.term.pstr(params)}'
	}

	return e.term.pstr(params)
}

fn (e BooleanValueExpression) compile(mut c Compiler) !CompileResult {
	if expr := e.expr {
		compiled_a := expr.compile(mut c)!
		compiled_b := e.term.compile(mut c)!

		return CompileResult{
			run:          fn [compiled_a, compiled_b] (mut conn Connection, data Row, params map[string]Value) !Value {
				a := compiled_a.run(mut conn, data, params)!
				b := compiled_b.run(mut conn, data, params)!

				// See ISO/IEC 9075-2:2016(E), 6.39, <boolean value expression>,
				// "Table 14 — Truth table for the OR boolean operator"

				if a.is_null {
					if b.bool_value() == .is_true {
						return new_boolean_value(true)
					}

					return new_unknown_value()
				}

				if a.bool_value() == .is_true {
					return new_boolean_value(true)
				}

				return b
			}
			typ:          new_type('BOOLEAN', 0, 0)
			contains_agg: compiled_a.contains_agg || compiled_b.contains_agg
		}
	}

	return e.term.compile(mut c)!
}

struct BooleanTerm {
	term   ?&BooleanTerm
	factor BooleanTest
}

fn (e BooleanTerm) pstr(params map[string]Value) string {
	if term := e.term {
		return '${term.pstr(params)} AND ${e.factor.pstr(params)}'
	}

	return e.factor.pstr(params)
}

fn (e BooleanTerm) compile(mut c Compiler) !CompileResult {
	if term := e.term {
		compiled_a := term.compile(mut c)!
		compiled_b := e.factor.compile(mut c)!

		return CompileResult{
			run:          fn [compiled_a, compiled_b] (mut conn Connection, data Row, params map[string]Value) !Value {
				a := compiled_a.run(mut conn, data, params)!
				b := compiled_b.run(mut conn, data, params)!

				// See ISO/IEC 9075-2:2016(E), 6.39, <boolean value expression>,
				// "Table 13 — Truth table for the AND boolean operator"

				if a.is_null {
					if b.bool_value() == .is_false {
						return new_boolean_value(false)
					}

					return new_unknown_value()
				}

				if a.bool_value() == .is_true {
					return b
				}

				return new_boolean_value(false)
			}
			typ:          new_type('BOOLEAN', 0, 0)
			contains_agg: compiled_a.contains_agg || compiled_b.contains_agg
		}
	}

	return e.factor.compile(mut c)!
}

// BooleanTest for "IS [ NOT ] { TRUE | FALSE | UNKNOWN }".
struct BooleanTest {
	expr  BooleanPrimary
	not   bool
	value ?Value
	// If a unary NOT exists before. We do not need to keep this separate as
	// stacking NOT operations simply inverts this value.
	inverse bool
}

fn (e BooleanTest) pstr(params map[string]Value) string {
	prefix := if e.inverse { 'NOT ' } else { '' }
	if v := e.value {
		if e.not {
			return '${prefix}${e.expr.pstr(params)} IS NOT ${v.str()}'
		}

		return '${prefix}${e.expr.pstr(params)} IS ${v.str()}'
	}

	return prefix + e.expr.pstr(params)
}

fn (e BooleanTest) unary_not(v Value) !Value {
	if v.is_null {
		return new_unknown_value()
	}

	if e.inverse {
		return match v.bool_value() {
			.is_true { new_boolean_value(false) }
			.is_false { new_boolean_value(true) }
		}
	}

	return v
}

fn (e BooleanTest) compile(mut c Compiler) !CompileResult {
	compiled := e.expr.compile(mut c)!

	if v := e.value {
		return CompileResult{
			run:          fn [e, v, compiled] (mut conn Connection, data Row, params map[string]Value) !Value {
				// See ISO/IEC 9075-2:2016(E), 6.39, <boolean value expression>,
				// "Table 15 — Truth table for the IS boolean operator"

				value := compiled.run(mut conn, data, params)!
				mut result := new_boolean_value(false)

				if value.is_null {
					result = new_boolean_value(v.is_null)
				} else if value.bool_value() == .is_true {
					result = new_boolean_value(v.bool_value() == .is_true)
				} else {
					result = new_boolean_value(v.bool_value() == .is_false)
				}

				if e.not {
					result = match result.bool_value() {
						.is_true { new_boolean_value(false) }
						.is_false { new_boolean_value(true) }
					}
				}

				return e.unary_not(result)!
			}
			typ:          new_type('BOOLEAN', 0, 0)
			contains_agg: compiled.contains_agg
		}
	}

	return CompileResult{
		run:          fn [e, compiled] (mut conn Connection, data Row, params map[string]Value) !Value {
			return e.unary_not(compiled.run(mut conn, data, params)!)!
		}
		typ:          compiled.typ
		contains_agg: compiled.contains_agg
	}
}

fn parse_boolean_term_1(factor BooleanTest) !BooleanTerm {
	return BooleanTerm{none, factor}
}

fn parse_boolean_term_2(term BooleanTerm, factor BooleanTest) !BooleanTerm {
	return BooleanTerm{&term, factor}
}

fn parse_boolean_factor_not(b BooleanTest) !BooleanTest {
	return BooleanTest{b.expr, b.not, b.value, !b.inverse}
}

fn parse_boolean_test_1(e BooleanPrimary) !BooleanTest {
	return BooleanTest{e, false, none, false}
}

fn parse_boolean_test_2(e BooleanPrimary, v Value) !BooleanTest {
	return BooleanTest{e, false, v, false}
}

fn parse_boolean_test_3(e BooleanPrimary, v Value) !BooleanTest {
	return BooleanTest{e, true, v, false}
}

fn parse_true() !Value {
	return new_boolean_value(true)
}

fn parse_false() !Value {
	return new_boolean_value(false)
}

fn parse_unknown() !Value {
	return new_unknown_value()
}

fn parse_boolean_value_expression_1(term BooleanTerm) !BooleanValueExpression {
	return BooleanValueExpression{none, term}
}

fn parse_boolean_value_expression_2(expr BooleanValueExpression, term BooleanTerm) !BooleanValueExpression {
	return BooleanValueExpression{&expr, term}
}

fn parse_parenthesized_boolean_value_expression(b BooleanValueExpression) !BooleanValueExpression {
	return b
}
