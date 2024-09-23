#ifndef _bump_h_INCLUDED
#define _bump_h_INCLUDED

#include <stdbool.h>

struct kissat;

void kissat_bump_analyzed (struct kissat *, int);
void kissat_update_scores (struct kissat *);
void kissat_rescale_scores (struct kissat *);
void kissat_bump_variable (struct kissat *, unsigned idx, int glue);
void kissat_bump_score_increment (struct kissat *);

#define MAX_SCORE 1e150

#endif
