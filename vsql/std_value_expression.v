module vsql

// ISO/IEC 9075-2:2016(E), 6.28, <value expression>
//
// # Function
//
// Specify a value.
//
// # Format
//~
//~ <value expression> /* ValueExpression */ ::=
//~     <common value expression>    -> ValueExpression
//~   | <boolean value expression>   -> ValueExpression
//~
//~ <common value expression> /* CommonValueExpression */ ::=
//~     <numeric value expression>    -> CommonValueExpression
//~   | <string value expression>     -> CommonValueExpression
//~   | <datetime value expression>   -> CommonValueExpression

type ValueExpression = BooleanValueExpression | CommonValueExpression

fn (e ValueExpression) pstr(params map[string]Value) string {
	return match e {
		CommonValueExpression, BooleanValueExpression {
			e.pstr(params)
		}
	}
}

fn (e ValueExpression) compile(mut c Compiler) !CompileResult {
	match e {
		CommonValueExpression, BooleanValueExpression {
			return e.compile(mut c)!
		}
	}
}

type CommonValueExpression = CharacterValueExpression | DatetimePrimary | NumericValueExpression

fn (e CommonValueExpression) pstr(params map[string]Value) string {
	return match e {
		NumericValueExpression, CharacterValueExpression, DatetimePrimary {
			e.pstr(params)
		}
	}
}

fn (e CommonValueExpression) compile(mut c Compiler) !CompileResult {
	match e {
		NumericValueExpression, CharacterValueExpression, DatetimePrimary {
			return e.compile(mut c)!
		}
	}
}
