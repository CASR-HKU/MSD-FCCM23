# MSD Scheduler
The hardware scheduler in MSD framework. With this scheduler, the MSD can produce the optimal schedule based on the selected mixed-EB config for different DNN models.

# Structure
- `./archs/`: The hardware architecture description for different hardware platforms.
- `./aux/`: The auxiliary files for the mixed-EB search, including the latency results for different EBs for each layer.
- `./device/`: The hardware description for different hardware platforms.
- `./models/`: The DNN models description for different DNN models.
- `./results/`: The results for the standard EB search (all EB = 2).

The detailed description of each file is in the comments of the code.