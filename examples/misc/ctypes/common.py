
dll = None
LIST = []
def reg_fun(nom, fun):
    LIST.append(fun)
    dll.pyd_reg_fun(nom, fun)
