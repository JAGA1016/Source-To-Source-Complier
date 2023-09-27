struct Symbol {
	char *Name;
	int Type, Size, BP, Binding;
	struct Symbol *next, *parent, *ArgList, *Scope;
};

struct Node {
	int value, type;
	struct Node *t1, *t2, *t3;
	struct Symbol *g, *h;
	struct Parameters *P;
};
