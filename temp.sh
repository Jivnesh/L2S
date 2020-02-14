#!/bin/bash
dir=./models/Dep_san_temp
train=./models/Dep_san_temp/ud_pos_ner_dp_train_san_with_rules
dev=./models/Dep_san_temp/ud_pos_ner_dp_test_san_with_rules
dev_org=./data/ud_pos_ner_dp_test_san
TAGS=./data/san_tags
start_time=`date +%s`
touch ./models/Dep_san_temp/train_log.txt
touch ./models/Dep_san_temp/result_log.txt
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
# --search: maximum action id
# --search_rollin how should past trajectories be generated?[policy|oracle|*mix_per_state|mix_per_roll]
# --passes arg                     Number of Training Passes
# --search_alpha arg (=1e-10, ) annealed beta = 1-(1-alpha)^t (only valid for search_interpolation=data)
# --holdout_off   no holdout data in multiple passes
# --search_history_length arg (=1, )  how much history their depend on; specify that here
# --search_no_caching  turn off the built-in caching ability
# --nn arg              Sigmoidal feedforward network with <k> hidden units
# --ftrl                FTRL: Follow the Proximal Regularized Leader
# --one_learner Using one learner instead of three learners for labeled parser
# --cost_to_go Estimating cost-to-go matrix based on dynamic oracle rathan than rolling-out
# --holdout_period 20
# # --passes 3
# --early_terminate 3
vw  -d $train.vw -k -c --search_rollin mix_per_roll \
--progress 100 --holdout_off --passes 3 --search_task dep_parser --search 23 --search_alpha 1e-5  \
--search_rollout oracle -f $dir/dep.model --search_history_length 3 --search_no_caching \
-b 30 --root_label 4 --num_label 23 --nn 5 --ftrl 2>&1 | tee ./models/Dep_san_temp/train_log.txt

# vw  -d $train.vw -k -c --search_rollin mix_per_roll --passes 3 --search_task dep_parser --search 46 --search_alpha 1e-5  --search_rollout oracle  --holdout_off -f $dir/dep.model --search_history_length 3 --search_no_caching -b 25 --root_label 45 --num_label 46 --nn 5 --ftrl
# -passes 5
echo "#################################################################"
echo "Predict... "
echo "#################################################################"
# -p [ --predictions ] arg     File to output predictions to
# -i [ --initial_regressor ] arg  Initial regressor(s)
# -t [ --testonly ]                Ignore label information and just test
vw -d $dev.vw -t -i $dir/dep.model -p $dir/dep.test.predictions --progress 10
# $dir/dep.model 
echo "#################################################################"
echo "Getting parse file from model prediction ... "
echo "#################################################################"
python2 ./code/parse_test_result.py $dev.vw $dir/dep.test.predictions $TAGS > $dir/dep.test.parse

echo "#################################################################"
echo "Getting UAS and LAS score ... "
echo "#################################################################"
python2 ./code/evaluate_san.py $dir/dep.test.parse $dev_org 2>&1 | tee ./models/Dep_san_temp/result_log.txt
# python2 evaluate.py $dir/dep.test.parse $dev

end_time=`date +%s`
echo execution time was `expr $end_time - $start_time` s.