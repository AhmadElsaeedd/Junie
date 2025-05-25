
from fastapi import UploadFile


class FileUtils:
    
    @staticmethod
    def assert_valid_file(*, file: UploadFile) -> None:
        """
        Asserts that the file is valid with a filename.
        """
        if not file or file.filename is None:
            raise Exception("No file or filename was uploaded.")