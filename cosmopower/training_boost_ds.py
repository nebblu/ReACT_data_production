import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
import os
import cosmopower as cp
from cosmopower import cosmopower_NN
import time

# checking that we are using a GPU
device = 'gpu:0' if tf.test.is_gpu_available() else 'cpu'
print('using', device, 'device \n')
# setting the seed for reproducibility - comment this when training your own model!
#np.random.seed(1)
#tf.random.set_seed(2)
####################################
########TRAINING SET################
####################################
training_parameters = np.load('data/npz/ds/ds_params_train_400k_500_all.npz')
training_features = np.load('data/npz/ds/ds_boost_train_400k_500_all.npz')
training_boost = training_features['features']
print('training boost shape: ', training_boost.shape)
#print('(number of training samples, number of k modes): ', training_log_spectra.shape)

####################################
########TESTING SET################
####################################
testing_parameters = np.load('data/npz/ds/ds_params_test_500_all.npz')
testing_features = np.load('data/npz/ds/ds_boost_test_500_all.npz')
testing_boost = testing_features['features']
print('testing boost shape: ', testing_boost.shape)

####################################
########INSTANIATION################
####################################
model_parameters = ['Omega_m', 'Omega_b', 'Omega_nu', 'H0', 'ns', 'As', 'w0', 'wa', 'xi', 'z']
k_range = training_features['modes']



cp_nn = cosmopower_NN(parameters=model_parameters, 
                      modes=k_range, 
                      n_hidden = [512, 512, 512, 512], # 4 hidden layers, each with 512 nodes
                      verbose=True, # useful to understand the different steps in initialisation and training
                      )



####################################
########TRAINING################
####################################
with tf.device(device):
    # train
    cp_nn.train(training_parameters=training_parameters,
                training_features=training_boost,
                filename_saved_model='mymodels/react_boost_ds_400k',
                # cooling schedule
                validation_split=0.01, #percentage of samples from the training set that will be used for validation
                learning_rates=[1e-2, 1e-3, 1e-4, 1e-5],
                batch_sizes=[500, 500, 500, 500],
                #batch_sizes=[1000, 1000, 1000, 1000, 1000],
                gradient_accumulation_steps = [1, 1, 1, 1],
                # early stopping set up
                patience_values = [100,100,100,100],
                max_epochs = [1000,1000,1000,1000],
                )


####################################
########TESTING################
####################################
cp_nn = cosmopower_NN(restore=True, 
                      restore_filename='mymodels/react_boost_ds_400k',
                      )


start = time.time()
predicted_testing_boost = cp_nn.predictions_np(testing_parameters) 
end = time.time()
print(end-start)                     


denominator = testing_boost[:, :] # use all of them
diff = np.abs((predicted_testing_boost[:, :] - testing_boost[:, :])/(denominator))
percentiles = np.zeros((4, diff.shape[1]))
percentiles[0] = np.percentile(diff, 68, axis = 0)
percentiles[1] = np.percentile(diff, 95, axis = 0)
percentiles[2] = np.percentile(diff, 99, axis = 0)
percentiles[3] = np.percentile(diff, 99.9, axis = 0)
np.savetxt('DS_test_plot.txt', np.c_[k_range, percentiles[0], percentiles[1], percentiles[2]])

from matplotlib import rc
plt.figure(figsize=(12, 9))
plt.fill_between(k_range, 0, percentiles[2,:], color = 'salmon', label = '99%', alpha=0.8)
plt.fill_between(k_range, 0, percentiles[1,:], color = 'red', label = '95%', alpha = 0.7)
plt.fill_between(k_range, 0, percentiles[0,:], color = 'darkred', label = '68%', alpha = 1)
#plt.ylim(0, 0.2)
plt.legend(frameon=False, fontsize=30, loc='upper left')
plt.ylabel(r'$\frac{|B_\mathrm{emu} - B_\mathrm{test}|} {B_\mathrm{test}}$', fontsize=50)
plt.xlabel(r'$k$',  fontsize=50)
plt.xscale('log')
ax = plt.gca()
#ax.xaxis.set_major_locator(plt.MaxNLocator(10))
#ax.yaxis.set_major_locator(plt.MaxNLocator(5))
plt.setp(ax.get_xticklabels(), fontsize=25)
plt.setp(ax.get_yticklabels(), fontsize=25)
plt.tight_layout()
plt.savefig('myplots/accuracy_emu_boost_400k_ds.png')


