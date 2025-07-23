import numpy as np
import os
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




# Define your data folders in order
folders = ["ds_boost_data/100k", "ds_boost_data/200k", "ds_boost_data/300k","ds_boost_data/400k"]

#folders = ["ds_boost_data/validation"]
n_boost_per_folder = 40


### TRAINING ###

# Collect all valid rows
all_data = []

for folder_index, folder in enumerate(folders):
    for i in range(1, n_boost_per_folder + 1):
        file_path = os.path.join(folder, f"boost{i}.dat")
        if not os.path.isfile(file_path):
            print(f"File missing: {file_path}, skipping.")
            continue
        try:
            dat = np.loadtxt(file_path)
            if dat.ndim == 1:
                dat = np.expand_dims(dat, axis=0)
            for j, row in enumerate(dat):
                if len(row) == (Npar + Nkp+1):
                    all_data.append(row[1:]) # Drop leading index 
                elif len(row) == (Npar + Nkp):
                    all_data.append(row)
                else:
                    print(f"Skipping malformed row {j} in {file_path} (len={len(row)})")
                    continue
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue

# Convert to numpy array
arr1 = np.array(all_data)
print("Final data shape:", arr1.shape)

# Split parameters and boost features
train_parameters = arr1[:, :Npar]
train_boost = arr1[:, Npar:]

# Save to .npz
train_parameters_dict = {params[i]: train_parameters[:, i] for i in range(Npar)}
train_boost_dict = {'modes': k_modes, 'features': train_boost}

# Save k-modes to a text file
np.savetxt("kvals_ds.txt", k_modes, fmt="%.8e")
print("Saved k values to kvals_ds.txt")

np.savez('npz/ds_params_train_all.npz', **train_parameters_dict)
np.savez('npz/ds_boost_train_all.npz', **train_boost_dict)

#np.savez('npz/ds_params_test_all.npz', **train_parameters_dict)
#np.savez('npz/ds_boost_test_all.npz', **train_boost_dict)



print("✅ All boosts saved sequentially across folders.")


