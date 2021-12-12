# This here is a database of GDScript parser and compiler error messages and warnings.
# We use it to create a mapping between identifiable messages and some abstract codes which we
# can refer to internally.
#
# Warnings are already provided by codes, so we can just use an enum exactly like it is defined
# in the engine.
#
# Errors on the other hand are harder. There are two groups of errors, parser errors and compiler
# errors. There is only a few compiler errors, but around 300 well defined parser errors, with
# additional possibility for generic parser errors.
#
# Each error is received with a generic code (-1), and can only be identified by its message
# contents. We store those messages (cleaned up for better maintainability) as is, but we don't
# actually use the raw messages for anything. Instead, each noteworthy message is assigned a
# number of text snippets which are unique to it. These snippets are then used to figure out
# which message was received from the LSP. When we successfully identified the message, we give it
# a code from the enum below. That code is then used to fetch our custom error explanation,
# translation, etc. Multiple raw messages can share the same code.
#
class_name GDScriptCodes
extends Reference

# Codes start at 10000 to give some space for WarningCodes coming from the engine.
enum ErrorCode {
	CYCLIC_REFERENCE = 10000,
	
	INVALID_INDENTATION,
	UNEXPECTED_CHARACTER,
	UNEXPECTED_CHARACTER_IN_KEYWORD,
	
	UNEXPECTED_IDENTIFIER,
	NONEXISTENT_IDENTIFIER,
	MISPLACED_KEYWORD,
	EXPECTED_CONSTANT_EXPRESSION,
	
	DUPLICATE_DECLARATION,
	SIGNATURE_MISMATCH,
	INVALID_ARGUMENTS,
	TYPE_MISMATCH,
	TYPE_CANNOT_BE_INFERRED,
	RETURN_VALUE_MISMATCH,
	MISPLACED_STATIC_CALL
}

enum WarningCode {
	UNASSIGNED_VARIABLE, # Variable used but never assigned.
	UNASSIGNED_VARIABLE_OP_ASSIGN, # Variable never assigned but used in an assignment operation (+=, *=, etc).
	UNUSED_VARIABLE, # Local variable is declared but never used.
	SHADOWED_VARIABLE, # Variable name shadowed by other variable.
	UNUSED_CLASS_VARIABLE, # Class variable is declared but never used in the file.
	UNUSED_ARGUMENT, # Function argument is never used.
	UNREACHABLE_CODE, # Code after a return statement.
	STANDALONE_EXPRESSION, # Expression not assigned to a variable.
	VOID_ASSIGNMENT, # Function returns void but it's assigned to a variable.
	NARROWING_CONVERSION, # Float value into an integer slot, precision is lost.
	FUNCTION_MAY_YIELD, # Typed assign of function call that yields (it may return a function state).
	VARIABLE_CONFLICTS_FUNCTION, # Variable has the same name of a function.
	FUNCTION_CONFLICTS_VARIABLE, # Function has the same name of a variable.
	FUNCTION_CONFLICTS_CONSTANT, # Function has the same name of a constant.
	INCOMPATIBLE_TERNARY, # Possible values of a ternary if are not mutually compatible.
	UNUSED_SIGNAL, # Signal is defined but never emitted.
	RETURN_VALUE_DISCARDED, # Function call returns something but the value isn't used.
	PROPERTY_USED_AS_FUNCTION, # Function not found, but there's a property with the same name.
	CONSTANT_USED_AS_FUNCTION, # Function not found, but there's a constant with the same name.
	FUNCTION_USED_AS_PROPERTY, # Property not found, but there's a function with the same name.
	INTEGER_DIVISION, # Integer divide by integer, decimal part is discarded.
	UNSAFE_PROPERTY_ACCESS, # Property not found in the detected type (but can be in subtypes).
	UNSAFE_METHOD_ACCESS, # Function not found in the detected type (but can be in subtypes).
	UNSAFE_CAST, # Cast used in an unknown type.
	UNSAFE_CALL_ARGUMENT, # Function call argument is of a supertype of the require argument.
	DEPRECATED_KEYWORD, # The keyword is deprecated and should be replaced.
	STANDALONE_TERNARY # Return value of ternary expression is discarded.
}

# Valid records have the following structure:
#{
#	"patterns": [], # Array of Array of String
#	"raw": [], # Array of String
#	"code": -1, # ErrorCode
#}
const MESSAGE_DATABASE := [
	# Compiler errors.
	{
		"_unused": [
			"Identifier not found: %IDENTIFIER%",
			"'self' not present in static function!",
			"Invalid native class type '%NATIVE_TYPE%'.",
			"Parser bug: unresolved data type.",
			"Attempt to call a non-identifier.",
			"'break'' not within loop",
			"'continue' not within loop",
			"Parser bug: invalid inheritance.",
			"Must use '%IDENTIFIER%' instead of 'self.%IDENTIFIER%' in getter.",
			"Must use '%IDENTIFIER%' instead of 'self.%IDENTIFIER%' in setter.",
			"Signal '%SIGNAL_NAME%' redefined (in current or parent class)",
			"Signal '%SIGNAL_NAME%' redefined (original in native class '%CLASS_NAME%')",
		],
	},

	{
		"patterns": [
			[ "Using own name in class file is not allowed (creates a cyclic reference)" ],
			[ "Can't load global class", ", cyclic reference?" ],
			[ "Cyclic class reference for" ],
		],
		"raw": [
			"Using own name in class file is not allowed (creates a cyclic reference)",
			"Can't load global class %IDENTIFIER%, cyclic reference?",
			"Cyclic class reference for '%CLASS_NAME%'.",
		],
		"code": ErrorCode.CYCLIC_REFERENCE,
	},

	# Parser errors.
	{
		"_unused": [
			"Yet another parser bug....",
			"Parser bug...",

			"Can't preload itself (use 'get_script()').",
			"Can't preload resource at path: %PATH%",
			"Static constant  '%CONSTANT_NAME%' not present in built-in type %BUILTIN_TYPE%.",
			"Using assignment with operation on a variable that was never assigned.",
			"Duplicate key found in Dictionary literal",
			"invalid index in constant expression",
			"invalid index '%INDEX_NAME%' in constant expression",
			"Can't assign to constant",
			"Can't assign to self.",
			"Can't assign to an expression",
			"Invalid operand for unary operator",
			"Invalid operands for operator",
			
			"'..' pattern only allowed at the end of an array pattern",
			"Not a valid pattern",
			"Expected identifier for binding variable name.",
			"'..' pattern only allowed at the end of a dictionary pattern",
			"Not a valid key in pattern",
			"Not a constant expression as key",
			"Expected pattern in dictionary value",
			"Not a valid pattern",
			"Expect constant expression or variables in a pattern",
			"Invalid operator in pattern. Only index (`A.B`) is allowed",
			"Only constant expression or variables allowed in a pattern",
			"Only constant expressions or variables allowed in a pattern",
			"Cannot use bindings with multipattern.",
			"Cannot match an array pattern with a non-array expression.",
			"Cannot match an dictionary pattern with a non-dictionary expression.",
			"Multipatterns can't contain bindings",
			"Parser bug: missing pattern bind variable.",
			
			"No class icon found at: %PATH%",
			"The optional parameter after \"class_name\" must be a string constant file path to an icon.",
			"default argument must be constant",
			"Parent constructor call found for a class without inheritance.",
			"Can't export null type.",
			"Can't export raw object type.",
			"Global filesystem hints may only be used in tool scripts.",
			"Type \"%TYPE_NAME%\" can't take hints.",
			"The export hint isn't a resource type.",
			"Invalid export type. Only built-in and native resource types can be exported.",
			"Use \"onready var %VARIABLE_NAME% = get_node(...)\" instead.",
			
			"The exported constant isn't a type or resource.",
			"Can't convert the provided value to the export type.",
			"Constants must be assigned immediately.",

			"Unexpected identifier.",
			"Unexpected end of file.",

			"Unexpected constant of type: %TYPE_NAME%",
			"Unexpected token: %TOKEN_NAME%:%IDENTIFIER%",

			"Couldn't resolve relative path for the parent class: %PATH%",
			"Couldn't load the base class: %PATH%",

			"Invalid cast. Cannot convert from \"%TYPE_NAME%\" to \"%TYPE_NAME%\".",
			"A value of type \"%TYPE_NAME%\" will never be an instance of \"%TYPE_NAME%\".",
			"A value of type \"%TYPE_NAME%\" will never be of type \"%TYPE_NAME%\".",
			"Assignment inside an expression isn't allowed (parser bug?).",
			"Can't get index \"%INDEX_NAME%\" on base \"%TYPE_NAME%\".",
			"Invalid index type (%TYPE_NAME%) for base \"%TYPE_NAME%\".",
			"Only strings can be used as an index in the base type \"%TYPE_NAME%\".",
			"Can't index on a value of type \"%TYPE_NAME%\".",
			"Parser bug: unhandled operation.",

			"The class \"%CLASS_NAME%\" was found in global scope, but its script couldn't be loaded.",

			"Parser bug: invalid argument default value.",
			"Parser bug: invalid argument default value operation.",
			
			"Can't assign a new value to a constant.",
			
			# A generic parser error (invalid token?).
			"Parse error: %ERROR_TOKEN%",
			# Any warning can be reported as error with an editor setting.
			"%WARNING_MESSAGE% (warning treated as error)",
		],
	},
	
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Couldn't fully preload the script, possible cyclic reference or compilation error. Use \"load()\" instead if a cyclic reference is intended.",
			"Script isn't fully loaded (cyclic preload?): %PATH%",
			"The class \"%CLASS_NAME%\" couldn't be fully loaded (script error or cyclic dependency).",
			"Class '%CLASS_NAME%' could not be fully loaded (script error or cyclic inheritance).",
			"Cyclic inheritance.",
			"The class \"%CLASS_NAME%\" couldn't be fully loaded (script error or cyclic dependency).",
			"The class \"%CLASS_NAME%\" was found in global scope, but its script couldn't be loaded.",
			"Class '%CLASS_NAME%' could not be fully loaded (script error or cyclic inheritance).",
			"Couldn't fully load singleton script '%SCRIPT_NAME%' (possible cyclic reference or parse error).",
			"The class \"%CLASS_NAME%\" couldn't be fully loaded (script error or cyclic dependency).",
			"Couldn't fully load the singleton script \"%IDENTIFIER%\" (possible cyclic reference or parse error).",
		],
		"code": ErrorCode.CYCLIC_REFERENCE,
	},
	{
		"patterns": [
			[ "Mixed tabs and spaces in indentation." ],
		],
		"raw": [
			"Invalid indentation.",
			"Expected an indented block after \"if\".",
			"Expected an indented block after \"elif\".",
			"Expected an indented block after \"else\".",
			"Expected an indented block after \"while\".",
			"Indented block expected.",
			"Expected indented block after \"for\".",
			"Expected indented pattern matching block after \"match\".",
			"Unexpected indentation.",
			"Invalid indentation. Bug?",
			"Unindent does not match any outer indentation level.",
			"Indented block expected after declaration of \"%FUNCTION_NAME%\" function.",
			"Mixed tabs and spaces in indentation.",
			"Expected block in pattern branch",
		],
		"code": ErrorCode.INVALID_INDENTATION,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"GDScriptParser bug, invalid operator in expression: %EXPRESSION%",
			"Unexpected end of expression...",
			"Expected else after ternary if.",
			"Expected value after ternary else.",
			"Unexpected two consecutive operators after ternary if.",
			"Unexpected two consecutive operators after ternary else.",
			"Unexpected two consecutive operators.",
			"Expected end of statement (\"%STATEMENT_NAME%\"), got %TOKEN_NAME% (\"%IDENTIFIER%\") instead.",
			"Expected end of statement (\"%STATEMENT_NAME%\"), got %TOKEN_NAME% instead.",
			"':' expected at end of line.",
			"Expression expected",
			"Expected ',' or ')'",
			"Expected ')' in expression",
			"Expected string constant or identifier after '$' or '/'.",
			"Path expected after $.",
			"Unterminated array",
			"expression or ']' expected",
			"',' or ']' expected",
			"Unterminated dictionary",
			"':' expected",
			"value expected",
			"key or '}' expected",
			"',' or '}' expected",
			"Expected '(' for parent function call.",
			"Error parsing expression, misplaced: %TOKEN_NAME%",
			"Expected identifier as member",
			"Expected ']'",
			"Unexpected 'as'.",
			"Unexpected assign.",
			"Expected \";\" or a line break.",
			"Expected \"{\" in the enum declaration.",
			"Unexpected \".\".",
			"Unexpected operator",
			"\"extends\" constant must be a string.",
			"Invalid \"extends\" syntax, expected string constant (path) and/or identifier (parent class).",
			"\"class_name\" syntax: \"class_name <UniqueName>\"",
			"The class icon must be separated by a comma.",
			"\"class\" syntax: \"class <Name>:\" or \"class <Name> extends <BaseClass>:\"",
			"Expected end of statement after expression, got %TOKEN_NAME% instead.",
			"Expected an identifier for the local variable name.",
			"Expected a type for the variable.",
			"Expected \"(\" for parent constructor arguments.",
			"Expected \",\" or \")\".",
			"Expected an identifier after \"func\" (syntax: \"func <identifier>([arguments]):\").",
			"Expected \"(\" after the identifier (syntax: \"func <identifier>([arguments]):\" ).",
			"Expected an identifier for an argument.",
			"Expected a type for an argument.",
			"Default parameter expected.",
			"Expected a return type for the function.",
			"Expected an identifier after \"signal\".",
			"Expected an identifier in a \"signal\" argument.",
			"Expected \",\" or \")\" after a \"signal\" parameter identifier.",
			"Expected \",\" in the bit flags hint.",
			"Expected a string constant in the named bit flags hint.",
			"Expected \")\" or \",\" in the named bit flags hint.",
			"Expected \")\" in the layers 2D render hint.",
			"Expected \")\" in the layers 2D physics hint.",
			"Expected \")\" in the layers 3D render hint.",
			"Expected \")\" in the layers 3D physics hint.",
			"Expected a string constant in the enumeration hint.",
			"Expected \")\" or \",\" in the enumeration hint.",
			"Expected \")\" in the hint.",
			"Expected \")\" or \",\" in the exponential range hint.",
			"Expected a range in the numeric hint.",
			"Expected \",\" or \")\" in the numeric range hint.",
			"Expected a number as upper bound in the numeric range hint.",
			"Expected \",\" or \")\" in the numeric range hint.",
			"Expected a number as step in the numeric range hint.",
			"Expected a string constant in the enumeration hint.",
			"Expected \"GLOBAL\" after comma in the directory hint.",
			"Expected \")\" or \",\" in the hint.",
			"Expected string constant with filter.",
			"Expected \"GLOBAL\" or string constant with filter.",
			"Color type hint expects RGB or RGBA as hints.",
			"Expected \"FLAGS\" after comma.",
			"Expected type for export.",
			"Expected \")\" or \",\" after the export hint.",
			"Expected an identifier for the member variable name.",
			"Expected a type for the class variable.",
			"Expected an identifier for the setter function after \"setget\".",
			"Expected an identifier for the getter function after \",\".",
			"Expected an identifier for the constant.",
			"Expected a type for the class constant.",
			"Unexpected %TOKEN_NAME%, expected an identifier.",
			"Expected an integer value for \"enum\".",
			"Built-in type constant or static function expected after \".\".",
			"Expected type after 'as'.",
			"Misplaced 'not'.",
			"Expected identifier before 'is' operator",
			"Identifier expected after \"for\".",
			"\"in\" expected after identifier.",
			"Expected a subclass identifier.",
		],
		"code": ErrorCode.UNEXPECTED_CHARACTER,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Expected '(' after 'preload'",
			"expected string constant as 'preload' argument.",
			"Expected ')' after 'preload' path",
			"Expected \"(\" after \"yield\".",
			"Expected \",\" after the first argument of \"yield\".",
			"Expected \")\" after the second argument of \"yield\".",
			"Expected '(' after assert",
		],
		"code": ErrorCode.UNEXPECTED_CHARACTER_IN_KEYWORD,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			
		],
		"code": ErrorCode.UNEXPECTED_IDENTIFIER,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Couldn't find the subclass: %SUBCLASS_NAME%",
			"Parser bug: undecidable inheritance.",
			"Couldn't resolve the constant \"%CONSTANT_NAME%\".",
			"Constant isn't a class: %IDENTIFIER%",
			"Couldn't find the subclass: %IDENTIFIER%",
			"Invalid inheritance (unknown class + subclasses).",
			"Unknown class: \"%CLASS_NAME%\"",
			"Couldn't determine inheritance.",
			"Parser bug: unresolved constant.",
			"The identifier \"%IDENTIFIER%\" isn't a valid type (not a script or class), or couldn't be found on base \"%CLASS_NAME%\".",
			"The method \"%CALLEE_NAME%\" isn't declared on base \"%TYPE_NAME%\".",
			"The method \"%CALLEE_NAME%\" isn't declared in the current class.",
			"The identifier \"%IDENTIFIER%\" isn't declared in the current scope.",
			"The setter function isn't defined.",
			"The getter function isn't defined.",
			"Invalid \"is\" test: the right operand isn't a type (neither a native type nor a script).",
		],
		"code": ErrorCode.NONEXISTENT_IDENTIFIER,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Expected a constant expression.",
		],
		"code": ErrorCode.EXPECTED_CONSTANT_EXPRESSION,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"\"yield()\" can only be used inside function blocks.",
			"\"self\" isn't allowed in a static function or constant expression.",
			"Expected \"var\", \"onready\", \"remote\", \"master\", \"puppet\", \"sync\", \"remotesync\", \"mastersync\", \"puppetsync\".",
			"Expected \"var\".",
			"Expected \"var\" or \"func\".",
			"Expected \"func\".",
			"Unexpected keyword \"continue\" outside a loop.",
			"Unexpected keyword \"break\" outside a loop.",
			"\"extends\" can only be present once per script.",
			"\"extends\" must be used before anything else.",
			"\"class_name\" is only valid for the main class namespace.",
			"\"class_name\" isn't allowed in built-in scripts.",
			"\"class_name\" can only be present once per script.",
			"The \"tool\" keyword can only be present once per script.",
		],
		"code": ErrorCode.MISPLACED_KEYWORD,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"The class \"%CLASS_NAME%\" shadows a native class.",
			"The argument name \"%ARGUMENT_NAME%\" is defined multiple times.",
			"Binding name of '%BINDING_NAME%' is already declared in this scope.",
			"Variable \"%VARIABLE_NAME%\" already defined in the scope (at line %LINE_NUMBER%).",
			"Unique global class \"%CLASS_NAME%\" already exists at path: %PATH%",
			"Can't override name of the unique global class \"%CLASS_NAME%\". It already exists at: %PATH%",
			"Another class named \"%CLASS_NAME%\" already exists in this scope (at line %LINE_NUMBER%).",
			"A constant named \"%CONSTANT_NAME%\" already exists in the outer class scope (at line%LINE_NUMBER%).",
			"A variable named \"%VARIABLE_NAME%\" already exists in the outer class scope (at line %LINE_NUMBER%).",
			"The function \"%FUNCTION_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"The function \"%FUNCTION_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"The signal \"%SIGNAL_NAME%\" already exists in this class (at line: %LINE_NUMBER%).",
			"Constant \"%CONSTANT_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"A constant named \"%CONSTANT_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"A constant named \"%CONSTANT_NAME%\" already exists in this class (at line: %LINE_NUMBER%).",
			"A variable named \"%VARIABLE_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"Variable \"%VARIABLE_NAME%\" already exists in this class (at line: %LINE_NUMBER%).",
			"A class named \"%CLASS_NAME%\" already exists in this class (at line %LINE_NUMBER%).",
			"The member \"%IDENTIFIER%\" already exists in a parent class.",
			"The signal \"%SIGNAL_NAME%\" already exists in a parent class.",
			"The class \"%CLASS_NAME%\" shadows a native class.",
			"The class \"%CLASS_NAME%\" conflicts with the AutoLoad singleton of the same name, and is therefore redundant. Remove the class_name declaration to fix this error.",
		],
		"code": ErrorCode.DUPLICATE_DECLARATION,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"No constructor of '%TYPE_NAME%' matches the signature '%TYPE_NAME%(%ARGUMENT_TYPE_LIST%)'.",
			"The function signature doesn't match the parent. Parent signature is: \"%FUNCTION_SIGNATURE%\".",
		],
		"code": ErrorCode.SIGNATURE_MISMATCH,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Invalid argument (#%ARGUMENT_NUMBER%) for '%TYPE_NAME%' constructor.",
			"Too many arguments for '%TYPE_NAME%' constructor.",
			"Too few arguments for '%TYPE_NAME%' constructor.",
			"Invalid arguments for '%TYPE_NAME%' constructor.",
			"Invalid argument (#%ARGUMENT_NUMBER%) for '%TYPE_NAME%' intrinsic function.",
			"Too many arguments for '%TYPE_NAME%' intrinsic function.",
			"Too few arguments for '%TYPE_NAME%' intrinsic function.",
			"Invalid arguments for '%TYPE_NAME%' intrinsic function.",
			"Wrong number of arguments, expected 1 or 2",
			"The first argument of \"yield()\" must be an object.",
			"The second argument of \"yield()\" must be a string.",
			"Parser bug: binary operation without 2 arguments.",
			"Parser bug: ternary operation without 3 arguments.",
			"Parser bug: operation without enough arguments.",
			"Too few arguments for \"%CALLEE_NAME%()\" call. Expected at least %ARGUMENT_COUNT%.",
			"Too many arguments for \"%CALLEE_NAME%()\" call. Expected at most %ARGUMENT_COUNT%.",
			"The setter function needs to receive exactly 1 argument. See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
			"The getter function can't receive arguments. See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
			"Parser bug: named index with invalid arguments.",
			"Parser bug: named index without identifier argument.",
			"Parser bug: function call without enough arguments.",
			"Parser bug: self method call without enough arguments.",
			"Parser bug: invalid function call argument.",
		],
		"code": ErrorCode.INVALID_ARGUMENTS,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"The pattern type (%PATTERN_TYPE%) isn't compatible with the type of the value to match (%MATCH_TYPE%).",
			"Invalid operand type (\"%ARGUMENT_TYPE%\") to unary operator \"%OPERATOR_NAME%\".",
			"Invalid operand types (\"%ARGUMENT_TYPE%\" and \"%ARGUMENT_TYPE%\") to operator \"%OPERATOR_NAME%\".",
			"At \"%CALLEE_NAME%()\" call, argument %ARGUMENT_NUMBER%. The passed argument's type (%TYPE_NAME%) doesn't match the function's expected argument type (%TYPE_NAME%).",
			"The constant value type (%TYPE_NAME%) isn't compatible with declared type (%TYPE_NAME%).",
			"The assigned expression's type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%).",
			"The export hint's type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%).",
			"The setter argument's type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%). See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
			"The getter return type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%). See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
			"Value type (%TYPE_NAME%) doesn't match the type of argument '%ARGUMENT_NAME%' (%TYPE_NAME%).",
			"The assigned value type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%).",
			"Invalid operand types (\"%TYPE_NAME%\" and \"%TYPE_NAME%\") to assignment operator \"%OPERATOR_NAME%\".",
			"The assigned value's type (%TYPE_NAME%) doesn't match the variable's type (%TYPE_NAME%).",
		],
		"code": ErrorCode.TYPE_MISMATCH,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"Unexpected ':=', use '=' instead. Expected end of statement after expression.",
			"Type-less export needs a constant expression assigned to infer type.",
			"Can't accept a null constant expression for inferring export type.",
			"The assigned value doesn't have a set type; the variable type can't be inferred.",
			"The variable type cannot be inferred because its value is \"null\".",
		],
		"code": ErrorCode.TYPE_CANNOT_BE_INFERRED,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"The constructor can't return a value.",
			"A non-void function must return a value in all possible paths.",
			"A void function cannot return a value.",
			"A non-void function must return a value.",
			"The returned value type (%TYPE_NAME%) doesn't match the function return type (%TYPE_NAME%).",
		],
		"code": ErrorCode.RETURN_VALUE_MISMATCH,
	},
	{
		"patterns": [
			[  ],
		],
		"raw": [
			"The constructor cannot be static.",
			"Can't call non-static function from a static function.",
			"Non-static function \"%CALLEE_NAME%\" can only be called from an instance.",
			"Can't access member variable (\"%VARIABLE_NAME%\") from a static function.",
			"The setter can't be a static function. See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
			"The getter can't be a static function. See \"%FUNCTION_NAME%()\" definition at line %LINE_NUMBER%.",
		],
		"code": ErrorCode.MISPLACED_STATIC_CALL,
	}
]
