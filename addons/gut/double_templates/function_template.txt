{func_decleration}
	__gut_spy('{method_name}', {param_array})
	if(__gut_should_call_super('{method_name}', {param_array})):
		return {super_call}
	else:
		return __gut_get_stubbed_return('{method_name}', {param_array})
