%{
#include <iostream>
#include <string>
#include <sstream>
#include <map>
#include <fstream>
#include <vector>

#define YYSTYPE attributes

using namespace std;

struct attributes {
	string label; // nome da variável usada no cód. intermediário (ex: "t0")
	string type; // tipo no código intermediário (ex: "int")
	string transl; // código intermediário (ex: "int t11 = 1;")
};

typedef struct var_info {
	string type; // tipo da variável usada no cód. intermediário (ex: "int")
	string name; // nome da variável usada no cód. intermediário (ex: "t0")
} var_info;

string type1, type2, op, typeRes;
ifstream opMapFile;

map<string, string> opMap;
map<string, var_info> varMap;
int tempGen = 0;

string getNextVar();

int yylex(void);
void yyerror(string);
%}

%token TK_NUM TK_CHAR TK_BOOL
%token TK_MAIN TK_ID TK_INT_TYPE TK_FLOAT_TYPE TK_CHAR_TYPE
%token TK_DOUBLE_TYPE TK_LONG_TYPE TK_STRING_TYPE TK_BOOL_TYPE
%token TK_FIM TK_ERROR
%token TK_BREAK

%start S

%left '+' '-'
%left '*' '/'

%%

S 			: TK_INT_TYPE TK_MAIN '(' ')' BLOCK {
				cout << 
				"/* Succinct lang */" << endl <<
				"#include <iostream>" << endl <<
				"#include <string.h>" << endl <<
				"#include <stdio.h>" << endl <<
				"int main(void) {" << endl <<
				$5.transl << 
				"\treturn 0;\n}" << endl;
			};

BLOCK		: '{' STATEMENTS '}' {
				$$.transl = $2.transl;
			};

STATEMENTS	: STATEMENT STATEMENTS {
				$$.transl = $1.transl + "\n" + $2.transl;
			}
			| STATEMENT {
				$$.transl = $1.transl + "\n";
			};

STATEMENT 	: EXPR ';' {
				$$.transl = $1.transl;
			}
			| ATTRIBUTION ';' {
				$$.transl = $1.transl;
			};
			
ATTRIBUTION	: TYPE TK_ID '=' EXPR {
				if ($4.type == $1.transl) {
					$$.transl = $4.transl;
					
					varMap[$2.label] = {$1.transl, $4.label};
				} else {
					// handle conversion or throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			};

EXPR 		: EXPR '+' EXPR {
				string var = getNextVar();
				
				string resType = opMap[$1.type + "+" + $2.type];
				
				if (resType.size()) {
					$$.type = resType;
					$$.transl = $1.transl + $3.transl + 
						"\t" + $$.type + " " + var + " = " + $1.label + " + " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '-' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "-" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " - " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '*' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "*" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " * " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '/' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "/" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " / " + $3.label + ";\n";
				$$.label = var;
			}
			| TK_NUM {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_BOOL {
				string var = getNextVar();
				
				$1.label = ($1.label == "true"? "1" : "0");
				
				$$.transl = "\tint " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_CHAR {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_ID {
				var_info varInfo = varMap[$1.label];
				
				if (varInfo.name.size()) {
					$$.type = varInfo.type;
					$$.label = varInfo.name;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			};
			
TYPE		: TK_INT_TYPE
			| TK_FLOAT_TYPE
			| TK_DOUBLE_TYPE
			| TK_LONG_TYPE
			| TK_CHAR_TYPE
			| TK_STRING_TYPE
			| TK_BOOL_TYPE
			;

%%

#include "lex.yy.c"

int yyparse();

int main( int argc, char* argv[] ) {
	opMapFile.open("util/opmap.dat");
	
	if (opMapFile.is_open()) {
		while (opMapFile >> type1 >> op >> type2 >> typeRes) {
	    	opMap[type1 + op + type2] = typeRes;
		}
		
		opMapFile.close();
	} else {
		cout << "Unable to open operator map file";
	}

	yyparse();

	return 0;
}

void yyerror( string MSG ) {
	cout << MSG << endl;
	exit (0);
}

string getNextVar() {
    return "t" + to_string(tempGen++);
}