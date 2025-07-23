import numpy as np
#kminp = 0.01
#kmaxp = 3.
#Nkp = 300

kminp = 0.01
kmaxp = 10.
Nkp = 1000

k_modes = [ kminp * np.exp(i*np.log(kmaxp/kminp)/(Nkp-1)) for i in range(Nkp)]



# f(R) boost params
#params = ['Omega_m', 'Omega_b', 'Omega_nu', 'H_0', 'n_s', 'A_s', 'f_R0', 'z']

# DS boost params 
params = ['Omega_m', 'Omega_b', 'Omega_nu', 'H_0', 'n_s', 'A_s', 'w0', 'wa', 'xi', 'z']
Npar = len(params)


### TRAINING ###

arr1 = np.empty(Nkp+Npar, dtype=float)

for i in range(100):
    print(i)
    dat=np.loadtxt("ds_/100k/boost"+str(i+1)+".dat")
    print('len data: ', len(dat))
    for j in range(len(dat)):
        arr1 = np.vstack([arr1,dat[j, 1:]])
#for i in range(100):
#    print(i)
#    dat=np.loadtxt("spph_boosts_om_fixed_wide/200k/boost"+str(i+1)+".dat")
#    print('len data: ', len(dat))
#    for j in range(len(dat)):
#        arr1 = np.vstack([arr1,dat[j, 1:]])
#for i in range(100):
#    print(i)
#    dat=np.loadtxt("spph_boosts_om_fixed_wide/300k/boost"+str(i+1)+".dat")
#    print('len data: ', len(dat))
#    for j in range(len(dat)):
#        arr1 = np.vstack([arr1,dat[j, 1:]])
arr1 = np.delete(arr1,0,0)
print('shape arr1: ', arr1.shape)
train_boost_and_params = arr1

train_parameters = train_boost_and_params[:, :Npar]
train_boost = train_boost_and_params[:, Npar:]

train_parameters_dict = {params[i]: train_parameters[:, i] for i in range(len(params))}
train_boost_dict = {'modes': k_modes,
                           'features': train_boost}

np.savez('npz/fr_spph_params_train_200k.npz', **train_parameters_dict)
np.savez('npz/fr_spph_boost_train_200k.npz', **train_boost_dict)
'''

### TESTING ###

arr2 = np.empty(Nkp+Npar, dtype=float)
for i in range(49):
    print(i)
    dat=np.loadtxt("spph_boosts_om_fixed_wide/450k/boost"+str(i+1)+".dat")
    for j in range(len(dat)):
        arr2 = np.vstack([arr2,dat[j, 1:]])
arr2 = np.delete(arr2,0,0)
test_boost_and_params = arr2

test_parameters = test_boost_and_params[:, :Npar]
test_boost = test_boost_and_params[:, Npar:]

test_parameters_dict = {params[i]: test_parameters[:, i] for i in range(len(params))}
test_boost_dict = {'modes': k_modes,
                            'features': test_boost}

np.savez('npz/fr_spph_params_test.npz', **test_parameters_dict)
np.savez('npz/fr_spph_boost_test.npz', **test_boost_dict)
'''
