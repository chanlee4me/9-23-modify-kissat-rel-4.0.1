#ifndef _vector_h_INCLUDED
#define _vector_h_INCLUDED

#include "stack.h"
#include "utilities.h"

#include <limits.h>

#ifdef COMPACT
#define LD_MAX_VECTORS (sizeof (word) == 8 ? 32u : 28u)
#else
#define LD_MAX_VECTORS (sizeof (word) == 8 ? 48u : 28u)
#endif

#define MAX_VECTORS (((uint64_t) 1) << LD_MAX_VECTORS)

#define INVALID_VECTOR_ELEMENT UINT_MAX

#define MAX_SECTOR MAX_SIZE_T

typedef struct vector vector;
typedef struct vectors vectors;

struct vectors {
  unsigneds stack;
  size_t usable;
};

struct vector {
#ifdef COMPACT
  unsigned offset;
  unsigned size;
#else
  unsigned *begin;
  unsigned *end;
#endif
};

struct kissat;

#ifdef CHECK_VECTORS
void kissat_check_vectors (struct kissat *);
#else
#define kissat_check_vectors(...) \
  do { \
  } while (0)
#endif

unsigned *kissat_enlarge_vector (struct kissat *, vector *);
void kissat_defrag_vectors (struct kissat *, size_t, vector *);
void kissat_remove_from_vector (struct kissat *, vector *, unsigned);
void kissat_resize_vector (struct kissat *, vector *, size_t);
void kissat_release_vectors (struct kissat *);
//added by cl
//todo:将下方函数变为 inline
//通过索引访问htab中的元素
unsigned get_htab_element(struct kissat *, vector *, size_t);
//通过索引修改htab中的元素
void set_htab_element(struct kissat *, vector *, size_t, unsigned);
//初始化函数，用于根据提供的大小初始化 'htab'，并将元素值初始化为 0
void initialize_htab(struct kissat *, vector *, size_t);
//扩展 htab 大小
void enlarge_htab(struct kissat *, vector *, size_t);
//类似 push_back 的函数，可以指定要添加的值
void push_back_htab(struct kissat *, vector *, unsigned);
#endif
