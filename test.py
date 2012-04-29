import unittest
from ucursos import ElementWrapper

class UCursosTests(unittest.TestCase):

    def test_testsuite(self):
        self.assertEqual(2, 1+1)

    def test_parse(self):
        data = ElementWrapper("data.xml")

        files = data.all("material")
        self.assertEqual("Corte1.mp3", files[0].titulo)
        self.assertEqual("mp3", files[0].extension)
        self.assertEqual("uchile", files[0].curso.base)

if __name__ == "__main__":
    unittest.main()
