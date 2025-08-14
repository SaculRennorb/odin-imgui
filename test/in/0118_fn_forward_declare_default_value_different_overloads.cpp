namespace N0118 {
	void fn(int a = 1);
	void fn(float a = 2);
}

struct A0118 {
	void fn(int a = 1);
	void fn(float a = 2);
};

void fn0118(int a = 1);
void fn0118(float a = 2);

void N0118::fn(int a) { }
void N0118::fn(float a) { }

void A0118::fn(int a) { }
void A0118::fn(float a) { }

// Overload indices are wrong here, don't want to bother right now
void fn0118(int a) { }
void fn0118(float a) { }