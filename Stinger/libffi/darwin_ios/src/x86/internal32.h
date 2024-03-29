#ifdef __i386__

#define X86_RET_FLOAT		0
#define X86_RET_DOUBLE		1
#define X86_RET_LDOUBLE		2
#define X86_RET_SINT8		3
#define X86_RET_SINT16		4
#define X86_RET_UINT8		5
#define X86_RET_UINT16		6
#define X86_RET_INT64		7
#define X86_RET_INT32		8
#define X86_RET_VOID		9
#define X86_RET_STRUCTPOP	10
#define X86_RET_STRUCTARG       11
#define X86_RET_STRUCT_1B	12
#define X86_RET_STRUCT_2B	13
#define X86_RET_UNUSED14	14
#define X86_RET_UNUSED15	15

#define X86_RET_TYPE_MASK	15
#define X86_RET_POP_SHIFT	4

#define R_EAX	0
#define R_EDX	1
#define R_ECX	2

#ifdef __PCC__
# define HAVE_FASTCALL 0
#else
# define HAVE_FASTCALL 1
#endif


#endif
