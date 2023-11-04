module vsql

// ISO/IEC 9075-2:2016(E), 6.29, <numeric value expression>
//
// # Function
//
// Specify a numeric value.
//
// # Format
//~
//~ <numeric value expression> /* NumericValueExpression */ ::=
//~     <term>                                           -> numeric_value_expression_1
//~   | <numeric value expression> <plus sign> <term>    -> numeric_value_expression_2
//~   | <numeric value expression> <minus sign> <term>   -> numeric_value_expression_2
//~
//~ <term> /* Term */ ::=
//~     <factor>                     -> term_1
//~   | <term> <asterisk> <factor>   -> term_2
//~   | <term> <solidus> <factor>    -> term_2
//~
//~ <factor> /* NumericPrimary */ ::=
//~     <numeric primary>
//~   | <sign> <numeric primary>   -> factor_2
//~
//~ <numeric primary> /* NumericPrimary */ ::=
//~     <value expression primary>   -> NumericPrimary
//~   | <numeric value function>     -> NumericPrimary

struct NumericValueExpression {
	n    ?&NumericValueExpression
	op   string
	term Term
}

fn (e NumericValueExpression) pstr(params map[string]Value) string {
	if n := e.n {
		return '${n.pstr(params)} ${e.op} ${e.term.pstr(params)}'
	}

	return e.term.pstr(params)
}

fn (e NumericValueExpression) compile(mut c Compiler) !CompileResult {
	compiled_term := e.term.compile(mut c)!

	if n := e.n {
		compiled_n := n.compile(mut c)!

		return CompileResult{
			run: fn [e, compiled_n, compiled_term] (mut conn Connection, data Row, params map[string]Value) !Value {
				mut left := compiled_n.run(mut conn, data, params)!
				mut right := compiled_term.run(mut conn, data, params)!

				return eval_binary(mut conn, data, left, e.op, right, params)!
			}
			// TODO(elliotchance): This is not correct, we would have to return
			//  the highest resolution type (need to check the SQL standard about
			//  this behavior).
			typ: compiled_n.typ
			contains_agg: compiled_term.contains_agg || compiled_n.contains_agg
		}
	}

	return compiled_term
}

struct Term {
	term   ?&Term
	op     string
	factor NumericPrimary
}

fn (e Term) pstr(params map[string]Value) string {
	if term := e.term {
		return '${term.pstr(params)} ${e.op} ${e.factor.pstr(params)}'
	}

	return e.factor.pstr(params)
}

fn (e Term) compile(mut c Compiler) !CompileResult {
	compiled_factor := e.factor.compile(mut c)!

	if term := e.term {
		compiled_term := term.compile(mut c)!

		return CompileResult{
			run: fn [e, compiled_term, compiled_factor] (mut conn Connection, data Row, params map[string]Value) !Value {
				mut left := compiled_term.run(mut conn, data, params)!
				mut right := compiled_factor.run(mut conn, data, params)!

				return eval_binary(mut conn, data, left, e.op, right, params)!
			}
			typ: compiled_term.typ
			contains_agg: compiled_factor.contains_agg || compiled_term.contains_agg
		}
	}

	return compiled_factor
}

struct SignedValueExpressionPrimary {
	sign string
	e    NumericPrimary
}

fn (e SignedValueExpressionPrimary) pstr(params map[string]Value) string {
	return e.sign + e.e.pstr(params)
}

fn (e SignedValueExpressionPrimary) compile(mut c Compiler) !CompileResult {
	compiled := e.e.compile(mut c)!

	return CompileResult{
		run: fn [e, compiled] (mut conn Connection, data Row, params map[string]Value) !Value {
			value := compiled.run(mut conn, data, params)!

			key := '${e.sign} ${value.typ.typ}'
			if fnc := conn.unary_operators[key] {
				unary_fn := fnc as UnaryOperatorFunc
				return unary_fn(conn, value)!
			}

			return sqlstate_42883('operator does not exist: ${key}')
		}
		typ: compiled.typ
		contains_agg: compiled.contains_agg
	}
}

type NumericPrimary = RoutineInvocation | SignedValueExpressionPrimary | ValueExpressionPrimary

fn (e NumericPrimary) pstr(params map[string]Value) string {
	return match e {
		SignedValueExpressionPrimary, ValueExpressionPrimary, RoutineInvocation {
			e.pstr(params)
		}
	}
}

fn (e NumericPrimary) compile(mut c Compiler) !CompileResult {
	match e {
		SignedValueExpressionPrimary, ValueExpressionPrimary, RoutineInvocation {
			return e.compile(mut c)!
		}
	}
}

fn parse_factor_2(sign string, expr NumericPrimary) !NumericPrimary {
	return SignedValueExpressionPrimary{sign, expr}
}

fn parse_term_1(factor NumericPrimary) !Term {
	return Term{none, '', factor}
}

fn parse_term_2(term Term, op string, factor NumericPrimary) !Term {
	return Term{&term, op, factor}
}

fn parse_numeric_value_expression_1(term Term) !NumericValueExpression {
	return NumericValueExpression{none, '', term}
}

fn parse_numeric_value_expression_2(n NumericValueExpression, op string, term Term) !NumericValueExpression {
	return NumericValueExpression{&n, op, term}
}

fn eval_binary(mut conn Connection, data Row, x Value, op string, y Value, params map[string]Value) !Value {
	mut left := x
	mut right := y

	// There is a special case we need to deal with when using literals against
	// other approximate types.
	//
	// TODO(elliotchance): This won't be needed when we properly implement
	//  ISO/IEC 9075-2:2016(E), 6.29, <numeric value expression>
	mut key := '${left.typ.typ} ${op} ${right.typ.typ}'
	if left.typ.typ.is_number() && right.typ.typ.is_number() {
		supertype := most_specific_value(left, right) or {
			return sqlstate_42883('operator does not exist: ${key}')
		}
		left = cast_numeric(mut conn, cast_approximate(left, supertype.typ)!, supertype)!
		right = cast_numeric(mut conn, cast_approximate(right, supertype.typ)!, supertype)!
		key = '${supertype.typ} ${op} ${supertype.typ}'
	}

	if fnc := conn.binary_operators[key] {
		op_fn := fnc as BinaryOperatorFunc
		return op_fn(conn, left, right)
	}

	return sqlstate_42883('operator does not exist: ${key}')
}

fn cast_approximate(v Value, want SQLType) !Value {
	if v.typ.typ == .is_numeric && v.typ.size == 0 {
		match want {
			.is_double_precision {
				return new_double_precision_value(v.as_f64()!)
			}
			.is_real {
				return new_real_value(f32(v.as_f64()!))
			}
			.is_bigint {
				return new_bigint_value(i64(v.as_f64()!))
			}
			.is_smallint {
				return new_smallint_value(i16(v.as_f64()!))
			}
			.is_integer {
				return new_integer_value(int(v.as_f64()!))
			}
			else {
				// Let it fall through.
			}
		}
	}

	return v
}
