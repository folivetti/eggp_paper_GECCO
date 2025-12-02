#!/bin/bash

mlr --csv --fs ',' --hi --prepipe "(tail -n+118 | grep -x '[0-9].*,*')" \
    cat --filename \
    then rename 1,gen,2,feval,3,len,4,nparam,5,fitness,6,dl,7,nll,8,func_compl,9,param_compl \
    then stats1 -a min -f dl,nll,func_compl,param_compl -g len \
    run_*.csv