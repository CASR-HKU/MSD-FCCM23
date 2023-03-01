import math


def floor_func(a, b):
    return int(float(a) / b)


def ceil_func(a, b):
    return int(math.ceil(float(a) / b))


def sqrt_func(a):
    return int(math.floor(math.sqrt(a)))


def log2(a):
    return math.log(a) / math.log(2)
