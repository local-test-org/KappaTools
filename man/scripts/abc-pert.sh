"${KAPPABIN}"KaSim ../../examples/abc-pert.ka -seed 822295616 -l 90 -p 0.3 -o abc-pert.csv -mode batch && \
gnuplot abc-pert.gplot && \
rm -f  *.csv inputs.ka
