; =============================================================================
; KEYWORDS AND CONTROL FLOW
; =============================================================================

; Basic Keywords
(
  [
    "def"
    "elif"
    "else"
    "except"
    "finally"
    "fn"
    "for"
    "if"
    "let"
    "raise"
    "return"
    "struct"
    "trait"
    "try"
    "var"
    "while"
    "with"
  ] @keyword
)

; Additional Keywords via Pattern Matching
((identifier) @keyword
 (#match? @keyword "^(async|await|borrowed|class|copy|inout|mut|mutmove|owned|raise|read|sink|try|with)$"))

; Function/Method Modifiers
((identifier) @keyword.modifier
 (#match? @keyword.modifier "^(capturing|raises)$"))

; =============================================================================
; TYPES AND DECLARATIONS
; =============================================================================

; Standard Types
(type_identifier) @type

; Mojo numeric types
((identifier) @type.builtin
 (#match? @type.builtin "^(Int|UInt|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Int128|UInt128|Int256|UInt256|Float16|Float32|Float64|SIMD|DType)$"))

; Builtin Types
((identifier) @type.builtin
 (#match? @type.builtin "^(Bool|Object|Self|String|MyTensor|VariadicList|VariadicListMem|VariadicPack)$"))

; Pointer Type Identifiers
((identifier) @type.builtin
 (#match? @type.builtin "^(ArcPointer|OwnedPointer|Pointer|UnsafePointer)$"))

; Special MLIR Types
((identifier) @type.builtin
 (#match? @type.builtin "^(__mlir_type)$"))

; Function Type Aliases 
((identifier) @type.builtin
 (#match? @type.builtin "^(BinaryTile1DTileUnitFunc|Dynamic1DTileUnitFunc|Dynamic1DTileUnswitchUnitFunc|Static1DTileUnitFunc|Static1DTileUnitFuncWithFlag|Static1DTileUnitFuncWithFlags|Static1DTileUnswitchUnitFunc|Static2DTileUnitFunc|SwitchedFunction|SwitchedFunction2)$"))

; Type casting
((call_expression 
  function: (identifier) @type.cast)
 (#match? @type.cast "^(Int|UInt|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Int128|UInt128|Int256|UInt256|Float16|Float32|Float64|SIMD)$")
 (#set! priority 105))

; =============================================================================
; FUNCTIONS AND METHODS
; =============================================================================

; Function Definitions
(def_function
  name: (identifier) @function)

(fn_function
  name: (identifier) @function)

(function_definition
  name: (identifier) @function)

; Built-in Functions
((identifier) @function.builtin
 (#match? @function.builtin "^(int|float|len|print|range|str)$"))

; Functional Module Built-ins
((identifier) @function.builtin
 (#match? @function.builtin "^(elementwise|map|parallelize|stencil|stencil_gpu|sync_parallelize|tile|tile_and_unswitch|tile_middle_unswitch_boundaries|unswitch|vectorize)$"))

; MLIR Operations
((identifier) @function.builtin
 (#match? @function.builtin "^(__mlir_op)$"))

; Function Calls
(call_expression
  function: (identifier) @function.call)

; Method Calls
(call_expression
  function: (field_expression
    field: (identifier) @function.method.call))

; Tool Definition Objects
((object
  (pair
    key: (string (string_content) @keyword.tool)
    value: (object)))
 (#match? @keyword.tool "^(tools|parameters|function|type|properties)$"))

; Tool Definition Types
((string (string_content) @type.tool)
 (#match? @type.tool "^(function|string|object|boolean|number|array)$"))

; Tool-use Function Calls
((call_expression
  function: (identifier) @function.tool)
 (#match? @function.tool "^(get_weather|search_web|fetch_data|execute_command)$"))

; Tool Response Handling
((call_expression
  function: (field_expression
    object: (identifier) @variable.tool
    field: (identifier) @function.tool.method))
 (#match? @variable.tool "^(tool_response|client|response|completion)$")
 (#match? @function.tool.method "^(tool_calls|choices|message|create)$"))

; =============================================================================
; PARAMETERS AND ARGUMENTS
; =============================================================================

; Parameters (Compile-time)
(parameter_list
  (parameter
    name: (identifier) @parameter))

; Parameter Brackets (for Compile-time Parameters)
(parameter_list
  "[" @punctuation.bracket
  "]" @punctuation.bracket)

; Parameter Type Definitions
(parameter
  name: (identifier) @parameter
  type: (type_identifier) @type)

; Arguments (Runtime)
(argument_list
  (argument
    name: (identifier) @variable.parameter))

; =============================================================================
; STRUCTS AND OBJECTS
; =============================================================================

; Structure/Trait Definitions
(struct_definition
  name: (identifier) @type)

(trait_definition
  name: (identifier) @type)

; Pointer Methods
((call_expression
  function: (identifier) @function.method)
 (#match? @function.method "^(address_of)$"))

((call_expression
  function: (field_expression
    field: (identifier) @function.method))
 (#match? @function.method "^(each|get|len)$"))

; Pointer Dereferencing
(subscript_expression
  value: (identifier)
  subscript: (empty) @operator.special)

; =============================================================================
; LITERALS AND BASIC SYNTAX
; =============================================================================

; Numeric Literals
(integer_literal) @number
(hex_integer_literal) @number
(octal_integer_literal) @number
(binary_integer_literal) @number
(float_literal) @number.float

; SIMD vector declarations and operations
(subscript_expression
  value: ((identifier) @_simd_type)
  subscript: (tuple_expression
               (identifier) @type.builtin
               (integer_literal) @number)
  (#match? @_simd_type "^(SIMD)$")
  (#match? @type.builtin "^(DType|float32|float64|float16|int8|int16|int32|int64)$"))

; Basic Syntax Elements
(comment) @comment
(string) @string
(number) @number

; Special Punctuation 
"*" @punctuation.special
"**" @punctuation.special
"/" @punctuation.delimiter
"[]" @operator.special
"->" @operator.special

