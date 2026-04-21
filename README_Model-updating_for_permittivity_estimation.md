
## `FDTD_&_Model-updating.ipynb`

The notebook `FDTD_&_Model-updating.ipynb` contains the code used to perform model updating and estimate the permittivity of material layers. As provided, the notebook demonstrates the workflow for one three-layer scenario: **“WS + St + Sand (wet)”**.

The experimental radar data recorded for all scenarios are available in the folder `Experimental_data`.

## Running the three-layer example

The current notebook is set up for the scenario:

```python
data = np.load('Experimental_data/WS(wet)90-Str90-Sand90(wet).npz')
p12, p23 = 0.9, 0.9 + 0.9
```

To estimate permittivity for the other three-layer scenarios listed in **Table 1** of the manuscript, update the following two lines in the notebook.

### 1. Change the input data file

Replace the file name in:

```python
data = np.load('Experimental_data/WS(wet)90-Str90-Sand90(wet).npz')
```

with the appropriate `.npz` file from the `Experimental_data` folder.

### 2. Change the layer boundary locations

Modify:

```python
p12, p23 = 0.9, 0.9 + 0.9
```

according to the thicknesses indicated in the selected file name.

For example, for the scenario **“WS + St + Sand”**, use:

```python
data = np.load('Experimental_data/WS(wet)85-Str90-Sand95.npz')
p12, p23 = 0.85, 0.85 + 0.9
```

Here, `p12` and `p23` represent the locations of the interfaces between adjacent layers.

## Bayesian optimization runs

In the section **“Model-updating using Bayesian optimization”**, the model updating is repeated **5 times**. The notebook prints the **mean** and **standard deviation** of the estimated permittivity values from these 5 runs below the corresponding cell.

## In-situ sensor measurements

The `.npz` files in the `Experimental_data` folder also contain the in-situ sensor readings and their measurement locations for comparison with the predictions. It also contains the radar receiver locations. These can be accessed using:

```python
data = np.load('Experimental_data/WS(wet)90-Str90-Sand90(wet).npz') # use the filename that you used to estimate permittivity
RAW = data['Teros']
measured_permittivity_at_in_situ_sensor_locations = (2.887e-9 * RAW**3 - 2.08e-5 * RAW**2 + 5.276e-2 * RAW - 43.39)**2
location_of_in_situ_measurements = data['Teros_loc']
location_of_Rx_data = data['Rx']
```

where:

- `RAW` is the raw in-situ TEROS sensor reading,
- `measured_permittivity_at_in_situ_sensor_locations` is the permittivity converted from the raw TEROS readings,
- `location_of_in_situ_measurements` gives the in-situ sensor measurement locations, and
- `location_of_Rx_data` gives the radar receiver locations.



## Extending the code to one- and two-layer scenarios

The current notebook is provided as an example for the **three-layer** case. To estimate the permittivity of **one-layer** or **two-layer** scenarios, the objective function and the optimization setup must be modified accordingly.

For example, for a **two-layer** scenario:

- remove `e3` and `p23`,
- replace the three-layer objective function with a two-layer objective function, and
- update the Bayesian optimization bounds to include only `e1` and `e2`.

The required changes in the section **“Model-updating using Bayesian optimization”** are:

```python
def objective_2layer(e1, e2)
Rx_sim, T_sim = model_discrete(e1=e1, e2=e2, p12=p12, num_layers=2, Lx=Lx, Tmax=Tmax, Rx_positions=Rx_positions_exp)
bounds = {'e1': (1, 15), 'e2': (1, 15)}
```

An example implementation for the two-layer case is shown below:

```python
t_exp = data['t']
Rx_data_exp = np.concatenate(Rx_data, axis=0)

# Envelope and normalization
A_exp = np.abs(hilbert(Rx_data_exp))
A_exp /= np.max(A_exp)
A_exp = A_exp**2

def objective_2layer(e1, e2):
    Lx = Rx_positions_exp[-1] + 0.02
    Tmax = t_exp[-1]

    # Simulate waveform
    Rx_sim, T_sim = model_discrete(
        e1=e1, e2=e2, p12=p12, num_layers=2,
        Lx=Lx, Tmax=Tmax, Rx_positions=Rx_positions_exp, delay_ns=delay_ns
    )
    A_sim = np.abs(hilbert(np.concatenate(Rx_sim)))
    A_sim /= np.max(A_sim)

    # Interpolate simulation to match experimental length
    interp_func = interp1d(
        np.linspace(0, Tmax, len(A_sim)),
        A_sim,
        kind='cubic',
        fill_value="extrapolate"
    )
    A_sim_interp = interp_func(np.linspace(0, Tmax, len(A_exp)))

    # Compute normalized RMSE
    rmse = np.sqrt(np.mean((A_exp - A_sim_interp) ** 2))
    normalized_rmse = -100 * rmse / np.sqrt(np.mean(A_exp**2))
    return normalized_rmse

from bayes_opt import BayesianOptimization

bounds = {'e1': (1, 15), 'e2': (1, 15)}

e1_vals = []
e2_vals = []
scores = []

num_runs = 5  # Number of optimization runs
for run in range(num_runs):
    print(f"\n--- Optimization Run {run+1} ---")
    optimizer = BayesianOptimization(f=objective_2layer, pbounds=bounds, verbose=0)
    optimizer.maximize(init_points=40, n_iter=30, allow_duplicate_points=True)

    best_params = optimizer.max['params']
    e1_vals.append(best_params['e1'])
    e2_vals.append(best_params['e2'])
    scores.append(optimizer.max['target'])

    print(
        f"Run {run+1} best e1: {best_params['e1']:.4f}, "
        f"e2: {best_params['e2']:.4f}, "
        f"Score: {optimizer.max['target']:.4f}"
    )

# Convert to arrays for statistics
e1_vals = np.array(e1_vals)
e2_vals = np.array(e2_vals)
scores = np.array(scores)

# Print mean and standard deviation
print("\n--- Summary over 5 Runs ---")
print(f"e1 mean: {e1_vals.mean():.4f}, std: {e1_vals.std():.4f}")
print(f"e2 mean: {e2_vals.mean():.4f}, std: {e2_vals.std():.4f}")
print(f"Objective score mean: {scores.mean():.4f}, std: {scores.std():.4f}")
```



## Using only selected receiver data (e.g. data from optimally placed receivers)

The code can also be used to estimate permittivity using only a selected subset of receiver data (for example, the optimal receivers). Locations of all recievers can be checked using 'data['Rx']', as mentioned above. To perform model updating while excluding some receivers, modify the section **“Load data recorded by multi-receiver radar”** as shown below.

The following example excludes the **1st**, **4th**, and **6th** receivers from the full set of receivers:

```python
exclude_keys = ['a1', 'a4', 'a6']

# Get all amplitude keys and filter out excluded ones
a_keys = sorted([key for key in data.files if key.startswith('a') and data[key].ndim >= 1])
a_keys = [key for key in a_keys if key not in exclude_keys]

# Extract filtered waveforms
Rx_data = [data[a_key] for a_key in a_keys]

# Update receiver positions accordingly
Rx_positions_all = list(data['Rx'])
included_indices = [int(key[1:]) - 1 for key in a_keys]  # e.g., 'a2' -> 1 (0-based)
Rx_positions = [Rx_positions_all[i] for i in included_indices]

# Build DataFrame
df_exp = pd.DataFrame({
    'x': np.concatenate([np.full(nt, x) for x in Rx_positions]),
    't': np.tile(t_values, len(Rx_positions)),
    'Rx': np.concatenate(Rx_data),
})
```


## Notes
This README is intended to help users reproduce the example workflow and adapt it to other scenarios included in the dataset.
