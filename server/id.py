class ID:
    def __init__(self, p_id: int = 0) -> None:
        self._id = p_id
    
    def __eq__(self, p_value: object) -> bool:
        return self._id == p_value._id
    


class IDGenerator:

    _id_value: int = 0

    @staticmethod
    def generate() -> ID:
        IDGenerator._id_value += 1
        return ID(IDGenerator._id_value)
