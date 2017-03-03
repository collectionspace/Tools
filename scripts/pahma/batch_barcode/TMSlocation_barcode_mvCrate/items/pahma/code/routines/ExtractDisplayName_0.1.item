package routines;

/*
 * user specification: the function's comment should contain keys as follows: 1. write about the function's comment.but
 * it must be before the "{talendTypes}" key.
 * 
 * 2. {talendTypes} 's value must be talend Type, it is required . its value should be one of: String, char | Character,
 * long | Long, int | Integer, boolean | Boolean, byte | Byte, Date, double | Double, float | Float, Object, short |
 * Short
 * 
 * 3. {Category} define a category for the Function. it is required. its value is user-defined .
 * 
 * 4. {param} 's format is: {param} <type>[(<default value or closed list values>)] <name>[ : <comment>]
 * 
 * <type> 's value should be one of: string, int, list, double, object, boolean, long, char, date. <name>'s value is the
 * Function's parameter name. the {param} is optional. so if you the Function without the parameters. the {param} don't
 * added. you can have many parameters for the Function.
 * 
 * 5. {example} gives a example for the Function. it is optional.
 */
/**
 * extractDispName: generate a person's display name from refName
 * 
 * {talendTypes} String
 * 
 * {Category} User Defined
 * 
 */
public class ExtractDisplayName {
	
    public static String extractDispName (String refName ) {

	int bgn_quote = refName.indexOf("'");
	int end_quote = refName.lastIndexOf("'");
	String fullDisplayName = refName.substring(bgn_quote+1, end_quote);
	String displayName;
	int bgn_paren = fullDisplayName.indexOf("(");
	int bgn_sqr = fullDisplayName.indexOf("[");
	int pos_end;
	if (bgn_paren > 0) {		// has '('
		if (bgn_sqr > 0) {		// also has '['
			if (bgn_sqr < bgn_paren) {	// '[' comes before '('
				pos_end = bgn_sqr;
			}
			else {// '(' comes before '['
				pos_end = bgn_paren;
			}
		}
		else {			// only has '(', no '['
			pos_end = bgn_paren;
		}
	}
	else if (bgn_sqr > 0) {		// only has '['
		pos_end = bgn_sqr;
	}
	else {		// no '(' or '['
		pos_end = fullDisplayName.length();
	}
	displayName = fullDisplayName.substring(0, pos_end);

	return displayName.trim();
    }
}
