import numpy as np
import pynq

class AccCtrl:
    def __init__(self, overlay, instr_array, debug_array, instr_txn=128, debug_txn=4):
        # build my registers
        base_addr = overlay.ip_dict['top_wrapper_0/s_axi_control']['phys_addr']
        for reg_name in self.my_reg_list:
            # print(reg_name, self.reg_list[reg_name])
            setattr(self, reg_name, pynq.Register(base_addr+self.my_reg_list[reg_name]))
        # build empty instr_array
        self.instr_array = instr_array  # burst_len=64, 1 instr/xfer
        # build empty debug_array
        self.debug_array = debug_array  # burst_len=16, 128/32b=4 data/xfer
        # write to registers
        self.aux_instr_scalar[:] = np.uint32(instr_txn)
        self.aux_debug_scalar[:] = np.uint32(debug_txn)
        self.aux_instr_addr_l[:] = (self.instr_array.physical_address)&0xFFFFFFFF
        self.aux_instr_addr_h[:] = self.instr_array.physical_address>>32
        self.aux_debug_addr_l[:] = (self.debug_array.physical_address)&0xFFFFFFFF
        self.aux_debug_addr_h[:] = self.debug_array.physical_address>>32
        
    def report_instr_array(self, instr_num):
        for idx in range(instr_num):
            print(f"{self.instr_array.flat[idx]:016x}")

    def report_debug_array(self, line_num):
        for line in range(line_num):
            print(
                [f"{data:08x}" for data in self.debug_array.flat[line*4:line*4+4][::-1]],
            )

    def report_my_registers(self):
        self.report_ap_ctrl()
        self.report_aux_instr()
        self.report_aux_debug()
        self.report_core_scalar()
        self.report_core_status()

    def report_ap_ctrl(self):
        print('ap_ctrl', self.ap_ctrl)
    
    def report_aux_instr(self):
        for reg_name in ['aux_instr_scalar', 'aux_instr_addr_l', 'aux_instr_addr_h', 'aux_instr_status']:
            print(f'{reg_name}: {getattr(self, reg_name)[:]:08x}')
    
    def report_aux_debug(self):
        for reg_name in ['aux_debug_scalar', 'aux_debug_addr_l', 'aux_debug_addr_h', 'aux_debug_status']:
            print(f'{reg_name}: {getattr(self, reg_name)[:]:08x}')
    
    def report_core_scalar(self):
        for i in range(4):
            reg_name = f'core_scalar_{i}'
            print(f'{reg_name}: {getattr(self, reg_name)[:]:08x}')

    def report_core_status(self):
        for i in range(2):
            reg_name = f'core_status_{i}'
            print(f'{reg_name}: {getattr(self, reg_name)[:]:08x}')

    def report_latency(self, clk_freq):
        i = 0
        while i < 103648:
            i = i + 1
            end_reg = self.core_status_1
            lat_reg = self.core_status_0
            end_data = int(end_reg)
            lat_cycle = int(lat_reg)
            lat_ms = 1/clk_freq * lat_cycle / 1000
            if end_data == 143:
                return lat_ms
        return 1
            
    def clear_arrays(self):
        self.clear_instr_array()
        self.clear_debug_array()

    def clear_instr_array(self):
        for array_idx in range(len(self.instr_array)):
            self.instr_array.flat[array_idx] = 0

    def clear_debug_array(self):
        for array_idx in range(len(self.debug_array)):
            self.debug_array.flat[array_idx] = 0

    def run(self, wait=True):
        self.instr_array.sync_to_device()
        self.debug_array.sync_to_device()
        self.ap_ctrl[0] = 1
#         print('Evaluation Results')
        if wait:
            while self.ap_ctrl[1]!=1:
                continue
            print('done')
            self.instr_array.sync_from_device()
            self.debug_array.sync_from_device()
#         self.report_my_registers()
        
    @property
    def my_reg_list(self):
        return {
            'ap_ctrl':          0x00,
            'aux_instr_scalar': 0x10, 'aux_instr_addr_l': 0x14, 'aux_instr_addr_h': 0x18, 'aux_instr_status': 0x1c,
            'aux_debug_scalar': 0x20, 'aux_debug_addr_l': 0x24, 'aux_debug_addr_h': 0x28, 'aux_debug_status': 0x2c,
            'core_scalar_0':    0x30, 'core_scalar_1':    0x34, 'core_scalar_2':    0x38, 'core_scalar_3':    0x3C,
            'core_status_0':    0x40, 'core_status_1':    0x44,
        }
    