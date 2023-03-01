from generator import Generator

hw_generator = Generator("devices/ultra96_8b.ini")
hw_generator.get_maximum_arch_simp("archs/ultra96_8b_arch.ini")
