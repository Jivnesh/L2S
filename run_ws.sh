#!/bin/bash


#######################################################
### This code is for replicating PTB results
#######################################################

dir=models/Dep_ws
train=models/Dep_ws/ptb3.0-stanford.auto.cpos.train.conll		
dev=models/Dep_ws/ptb3.0-stanford.auto.cpos.test.conll
TAGS=models/Dep_ws/ptb_tags
start_time=`date +%s`
# # Variables

echo "#################################################################"
echo "Deleting old generated files ... "
echo "#################################################################"
cd $dir
rm -f *.model *.predictions *.parse  *.cache  *~ *.writing
cd ../..
# echo "#################################################################"
# echo "Generating data files in required format ..."
# echo "#################################################################"
# python2 parse_data.py $train $train.vw
# python2 parse_data.py $dev $dev.vw

echo "#################################################################"
echo "Building Model ... "
echo "#################################################################"

vw  -d $train.vw -k -c --search_rollin mix_per_roll --passes 3 \
--search_task dep_parser --search 45 --search_alpha 1e-5  --search_rollout oracle  \
--holdout_off -f $dir/dep.model --search_history_length 3 --search_no_caching -b 30 \
--root_label 45 --num_label 45 --nn 5 --ftrl --progress 1000

echo "#################################################################"
echo "Predict... "
echo "#################################################################"
# -p [ --predictions ] arg     File to output predictions to
# -i [ --initial_regressor ] arg  Initial regressor(s)
# -t [ --testonly ]                Ignore label information and just test
vw -d $dev.vw -t -i $dir/dep.model -p $dir/dep.test.predictions --progress 100
# $dir/dep.model 
echo "#################################################################"
echo "Getting parse file from model prediction ... "
echo "#################################################################"
python2 ./code/parse_test_result.py $dev.vw $dir/dep.test.predictions $TAGS > $dir/dep.test.parse

echo "#################################################################"
echo "Getting UAS and LAS score ... "
echo "#################################################################"
python2 ./code/evaluate_ws.py $dir/dep.test.parse $dev

end_time=`date +%s`
echo execution time was `expr $end_time - $start_time` s.